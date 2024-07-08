require 'std/sequencer'

module HDLRuby::High::Std

    ##
    # Standard HDLRuby::High library: sequencer synchronizer generator.
    # The idea is to be able to write sw-like sequential code.
    # 
    ########################################################################
    


    # Describes a signal with shared write.
    class SharedSignalI

        # Create a new shared signal of type +typ+.
        # NOTE: for now the arbitration is the priority in order of write access
        # declaration.
        def initialize(typ, name, default_value = 0)
            # Process the arguments.
            typ = typ.to_type
            @type = typ
            name = name.to_sym
            @name = name
            @default_value = default_value
            # Create the name of the access process.
            @name_sub = HDLRuby.uniq_name(:"#{name}_sub")
            this = self
            # Register the shared signal.
            HDLRuby::High.space_reg(name) { this }
            # Create the output value and selection of the signal.
            value_out = nil
            select    = nil
            HDLRuby::High.cur_system.open do
                value_out  = typ.inner(HDLRuby.uniq_name(:"#{name}_out"))
                select     = [1].inner(HDLRuby.uniq_name(:"#{name}_select") => 0)
            end
            @value_out  = value_out
            @select     = select
            # First no access point.
            @size = 0
            # Create the input values.
            values_in  = nil
            HDLRuby::High.cur_system.open do
                values_in  = typ[-1].inner(HDLRuby.uniq_name(:"#{name}_in"))
            end
            @values_in  = values_in
            # The set of access points by sequencer.
            @points = { }
        end

        # Adds an access point.
        def add_point
            # Maybe a point already exist for current sequencer.
            sequ = SequencerT.current
            point = @points[sequ]
            return @values_in[point] if point # Yes, return it.
            # No, do create a new one.
            point = @points[sequ] = @size
            # Resize the flag and value vectors.
            @size += 1
            size = @size
            @values_in.type.instance_variable_set(:@range,0..size-1)
            @select.type.instance_variable_set(:@range,(size-1).width-1..0)
            # (Re)Generate the access arbitrer.
            name_sub = @name_sub
            values_in  = @values_in
            value_out = @value_out
            select = @select
            default_value = @default_value
            # The access arbitrer.
            HDLRuby::High.cur_system.open do
                sub(name_sub) do
                    par do
                        hcase(select)
                        size.times do |i|
                            hwhen(i) { value_out <= values_in[i] }
                        end
                        helse { value_out <= default_value }
                    end
                end
            end
            # Return the current access point.
            return values_in[size-1]
        end

        # Write access code generation.
        def <=(expr)
            # Create a new access point.
            value_in = self.add_point
            # Actually implement the access.
            value_in <= expr.to_expr
            return self
        end

        # Read access code generation: 
        # actually hidden in the conversion to expression.
        def to_expr
            # Return the resulting value.
            @value_out
        end

        # Selection of the output value code generation.
        # +arg+ can be the index or directly the selected sequencer.
        # If no arg is given, return access to the selection signal direction.
        def select(arg = nil)
            return @select unless arg
            if arg.is_a?(SequencerT) then
                pt = @points[arg]
                @select <= @points[arg] if pt
            else
                @select <= arg
            end
        end

        # For to_expr an all the other methods.
        def method_missing(m, *args, &ruby_block)
            self.to_expr.send(m,*args,&ruby_block)
        end

    end


    # Describes an arbiter for a shared signal.
    class ArbiterT

        # Create a new arbitrer named +name+ for shared signals +sigs+.
        def initialize(name,*sigs)
            # Sets the name.
            name = name.to_sym
            @name = name
            # Register the signals.
            @signals = []
            # Adds the signals.
            self.(*sigs)
            # Create the set of access points.
            @size = 0
            @points = {}
            # Create the acquire/release bit vector.
            acquires = nil
            HDLRuby::High.cur_system.open do
                acquires = [1].inner(HDLRuby.uniq_name(:"#{name}_acq") => 0)
            end
            @acquires = acquires
            # Register the arbiter.
            this = self
            HDLRuby::High.space_reg(name) { this }
        end

        # Adds the signals.
        def call(*sigs)
            sigs.each do |sig|
                unless sig.is_a?(SharedSignalI) then
                    raise "An arbitrer only works on a shared signal, not a #{sig.class}"
                end
                @signals << sig
            end
        end

        # Adds an access point.
        def add_point
            # Maybe a point already exist for current sequencer.
            sequ = SequencerT.current
            point = @points[sequ]
            return point if point
            # No add it.
            point = @size
            @points[sequ] = point
            @size += 1
            # Resize the acquire vector according to the new point.
            @acquires.type.instance_variable_set(:@range,0..point)
            return point
        end

        # Shared signal selection code generation.
        def select(point)
            @signals.each do |signal|
                signal.select(@points.key(point))
            end
        end

        # Arbiter access code generation: 1 for acquire and 0 for release.
        def <=(val)
            # Add an access point if required.
            point = self.add_point
            # Do the access.
            @acquires[point] <= val
        end
    end


    # Describes a priority-based arbiter.
    class PriorityArbiterT < ArbiterT

        # Create a new priority-based arbiter named +name+ with priority table
        # +tbl+ or priority algorithm +ruby_block+ for shared signals +sigs+.
        def initialize(name, tbl = nil, *sigs, &ruby_block)
            super(name,*sigs)
            # Set the priority policy.
            self.policy(tbl,&ruby_block)
            # Create the name of the access procedure sub.
            @name_sub = HDLRuby.uniq_name(:"#{name}_sub")
        end

        # Set the policy either using a priority table +tbl+ by directly
        # providing the priority algorithm through +ruby_block+
        def policy(tbl = nil, &ruby_block)
            # By default the priority table is the points declaration order.
            if !tbl && ruby_block == nil then
                @priority = proc { |acquires,i| acquires[i] == 1 }
            elsif tbl then
                @priority = proc do |acquires,i| 
                    pri = tbl[i]
                    raise "Invalid priority index: #{i}" unless pri
                    acquires[pri] == 1
                end
            else
                @priority = ruby_block
            end
        end

        # Add a point.
        def add_point
            point = super # The point is added by the parent class.
            # Update the access procedure.
            name_sub = @name_sub
            this = self
            size = @size
            acquires = @acquires
            priority = @priority
            HDLRuby::High.cur_system.open do
                sub(name_sub) do
                    seq do
                        if(size == 1) then
                            # Anyway, only one accesser.
                            this.select(0)
                        else
                            hif(priority.(acquires,0)) do
                                this.select(0)
                            end
                            (1..size-1).each do |i|
                                helsif(priority.(acquires,i)) do
                                    this.select(i)
                                end
                            end
                            helse do # No acquire at all, select the first point.
                                this.select(0)
                            end
                        end
                    end
                end
            end
            return point
        end
    end


    # Describes priority-based monitor.
    class PriorityMonitorT < PriorityArbiterT

        # Create a new priority-based arbiter named +name+ with priority table
        # +tbl+ or priority algorithm +ruby_block+ for shared signals +sigs+.
        def initialize(name, tbl = nil, *sigs, &ruby_block)
            super(name,tbl,*sigs,&ruby_block)
            # Declare the current selected point.
            selected_point = nil
            name = @name
            HDLRuby::High.cur_system.open do
                selected_point = [1].inner(HDLRuby.uniq_name(:"#{name}_selected"))
            end
            @selected_point = selected_point
        end

        # Add a point.
        def add_point
            # Redefine to update the size of @selected_point.
            point = super
            @selected_point.type.instance_variable_set(:@range,(@size-1).width-1..0)
            return point
        end

        # Shared signal selection code generation.
        def select(point)
            # Redefine to remember which point is selected.
            super(point)
            @selected_point <= point
        end

        # # Arbiter access code generation: 1 for acquire and 0 for release.
        # def <=(val)
        #     # Fully redefine to lock until selected if acquiring.
        #     # Add an access point if required.
        #     point = self.add_point
        #     # Do the access.
        #     res = (@acquires[point] <= val)
        #     selected_point = @selected_point
        #     # Lock until not selected.
        #     if val.respond_to?(:to_i) then
        #         if val.to_i == 1 then
        #             SequencerT.current.swhile(selected_point != point)
        #         end
        #     else
        #         SequencerT.current.swhile((val.to_expr == 1) & (selected_point != point))
        #     end
        #     return res
        # end
        
        # Arbiter access code generation: 1 for acquire and 0 for release.
        def <=(val)
            raise "For monitors, you must use the methods lock and unlock."
        end

        # Monitor lock code generation
        def lock
            # Fully redefine to lock until selected if acquiring.
            # Add an access point if required.
            point = self.add_point
            # Do the access.
            res = (@acquires[point] <= 1)
            selected_point = @selected_point
            # Lock until not selected.
            SequencerT.current.swhile(selected_point != point)
            return res
        end

        # Monitor unlock code generation
        def unlock
            # Fully redefine to lock until selected if acquiring.
            # Add an access point if required.
            point = self.add_point
            # Do the access.
            res = (@acquires[point] <= 0)
            selected_point = @selected_point
            return res
        end
    end


    # Declares an arbiter named +name+ with priority table +tbl+ or priority
    # procedure +rubyblock+.
    def arbiter(name,tbl = nil, &ruby_block)
        return PriorityArbiterT.new(name,tbl,&ruby_block)
    end

    # Declares a monitor named +name+ with priority table +tbl+ or priority
    # procedure +rubyblock+.
    def monitor(name,tbl = nil, &ruby_block)
        return PriorityMonitorT.new(name,tbl,&ruby_block)
    end
    



    # Enhance the Htype module for creating a shared signal.
    module HDLRuby::High::Htype

        # Create new shared signals from +args+.
        # +args+ can be a name of list of names or a hash associating names to
        # default values.
        def shared(*args)
            # # Process the arguments.
            # Create the shared signal.
            sig = nil
            args.each do |arg|
                if arg.is_a?(Hash) then
                    arg.each do |k,v|
                        sig = SharedSignalI.new(self,k,v)
                    end
                else
                    sig = SharedSignalI.new(self,arg)
                end
            end
            return sig
        end
    end


    class ::Array
        # Enhance the Array type for creating shared signals.
        
        # Create new shared signals from +args+.
        def shared(*names)
            return self.to_type.shared(*names)
        end
    end


    class ::Hash
        # Enhance the Struct type for creating shared signals.

        # Create new shared signals from +args+.
        def shared(*names)
            return self.to_type.shared(*names)
        end
    end




end
