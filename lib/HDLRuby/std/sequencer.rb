require 'std/fsm'

module HDLRuby::High::Std

    ##
    # Standard HDLRuby::High library: sequencer generator.
    # The idea is to be able to write sw-like sequential code.
    # 
    ########################################################################
    


    # Defines a sequencer block.
    class SequencerT 
        @@current = nil # The current sequencer.

        # Get the sequencer currently processing.
        def self.current
            @@current
        end

        # The start and end states values.
        attr_reader :start_state_value, :end_state_value

        # Create a new sequencer block synchronized on +ev+ and starting
        # on +start+
        def initialize(ev,start,&ruby_block)
            this = self
            # Create the fsm from the block.
            @fsm = fsm(ev,start,:seq)
            # On reset (start) go to the first state.
            @fsm.reset do
                HDLRuby::High.top_user.instance_exec do
                    next_state_sig <= this.start_state_value
                end
            end

            # The status stack of the sequencer.
            @status = [ {} ]
            # Creates the namespace to execute the sequencer deescription 
            # block in.
            @namespace = Namespace.new(self)

            # The end state is actually 0, allows to sequencer to be stable
            # by default.
            @end_state = @fsm.state {}
            @end_state.gotos << proc do
                HDLRuby::High.top_user.instance_exec do
                    # next_state_sig <= st.value
                    next_state_sig <= this.end_state_value
                end
            end
            # Record the start and end state values.
            # For now, the start state is the one just following the end state.
            @end_state_value = @end_state.value
            @start_state_value = @end_state_value + 1

            # Process the ruby_block.
            @@current = self
            HDLRuby::High.space_push(@namespace)
            blk = HDLRuby::High::Block.new(:seq,&ruby_block)
            HDLRuby::High.space_pop

            # If the block is not empty, add it as last state.
            this = self
            if blk.each_statement.any? then
                st = @fsm.state do
                    this.fill_top_user(blk)
                end
            end
            # # Ends the fsm with an infinite loop state.
            # st = @fsm.state {}
            # st.gotos << proc do
            #     HDLRuby::High.top_user.instance_exec do
            #         # next_state_sig <= st.value
            #         next_state_sig <= EndStateValue
            #     end
            # end

            # Build the fsm.
            @fsm.build
        end

        # Mark a step.
        def step
            # Create a new block from all the statements in the previous block.
            blk = HDLRuby::High::Block.new(:seq) {}
            # Get all the statements of the builder block.
            stmnts = HDLRuby::High.cur_block.instance_variable_get(:@statements)
            # Add all the statements to blk.
            stmnts.each { |stmnt| stmnt.parent = nil; blk.add_statement(stmnt) }
            # Remove them from the builder block.
            stmnts.clear

            # Create a state for this block.
            this = self
            st = @fsm.state { this.fill_top_user(blk) }
            # # Set the previous step in sequence.
            # @status.last[:state] = st
            return st
        end

        # Breaks current iteration.
        def sbreak
            # Mark a step.
            st = self.step
            # Tell there is a break to process.
            # Do that in the first swhile status met.
            i = @status.size-1
            begin
               status = @status[i -= 1]
               raise "No loop for sbreak." unless status
            end while(!status[:swhile])
            status[:sbreaks] ||= []
            status[:sbreaks] << st
            return st
        end

        # Terminates the sequencer.
        def sterminate
            # Mark a step.
            st = self.step
            # Adds a goto the ending state.
            this = self
            st.gotos << proc do
                HDLRuby::High.top_user.instance_exec do
                    next_state_sig <= this.end_state_value
                end
            end
            return st
        end

        # Create a sequential if statement on +cond+.
        def sif(cond, &ruby_block)
            # Mark a step.
            st = self.step
            # Remember the condition.
            @status.last[:condition] = cond
            # Create a state to be executed if the condition is met.
            @status.push({})
            yes_name = HDLRuby.uniq_name("yes")
            yes_blk = HDLRuby::High::Block.new(:seq,&ruby_block)
            @status.pop
            this = self
            yes = @fsm.state(yes_name) { this.fill_top_user(yes_blk) }
            # Add a goto to the previous state.
            st.gotos << proc do
                HDLRuby::High.top_user.instance_exec do
                    hif(cond) { next_state_sig <= st.value + 1 }
                    helse { next_state_sig <= yes.value + 1 }
                end
            end
            # Remeber the if yes state for being able to add else afterward.
            @status.last[:sif_yes] = yes
            return st
        end

        # Create a sequential else statement.
        def selse(&ruby_block)
            # Create a state to be executed if the previous condition is
            # not met.
            @status.push({})
            no_name = HDLRuby.uniq_name("no")
            no_blk = HDLRuby::High::Block.new(:seq,&ruby_block)
            @status.pop
            this = self
            no = @fsm.state(no_name) { this.fill_top_user(no_blk) }
            # Adds a goto to the previous if yes state for jumping the no state.
            yes = @status.last[:sif_yes]
            raise "Cannot use selse here." unless yes
            cond = @status.last[:condition]
            yes.gotos << proc do
                HDLRuby::High.top_user.instance_exec do
                    next_state_sig <= no.value + 1
                end
            end
            return no
        end

        # Create a sequential while statement on +cond+.
        def swhile(cond,&ruby_block)
            # Mark a step.
            st = self.step

            # Tell we are building a while.
            @status.last[:swhile] = true

            # Create a state to be executed if the condition is met.
            @status.push({})
            # Build the loop sub sequence.
            yes_name = HDLRuby.uniq_name("yes")
            yes_blk = HDLRuby::High::Block.new(:seq,&ruby_block)
            @status.pop

            this = self
            yes = @fsm.state(yes_name) { this.fill_top_user(yes_blk) }
            # Add a goto to the previous state.
            st.gotos << proc do
                HDLRuby::High.top_user.instance_exec do
                    hif(cond) { next_state_sig <= st.value + 1 }
                    helse { next_state_sig <= yes.value + 1 }
                end
            end
            # And to the yes state.
            yes.gotos << proc do
                HDLRuby::High.top_user.instance_exec do
                    hif(cond) { next_state_sig <= st.value + 1 }
                    helse { next_state_sig <= yes.value + 1 }
                end
            end

            # Where there any break?
            if @status.last[:sbreaks] then
                # Yes, adds them the right goto since the end of loop state
                # is now defined.
                @status.last[:sbreaks].each do |st_brk|
                    st_brk.gotos << proc do
                        HDLRuby::High.top_user.instance_exec do
                            next_state_sig <= yes.value + 1
                        end
                    end
                end
                # And remove them from the status to avoid reprocessing them,
                @status.last.clear
            end

            return st
        end

        # Create a sequential for statement iterating over the elements
        # of +expr+.
        def sfor(expr,&ruby_block)
            # idx = nil
            # HDLRuby::High.cur_system.open do
            #     idx = [expr.type.size.width+1].inner(
            #         HDLRuby.uniq_name("for_idx"))
            # end
            # idx <= 0
            # # Iterate using a swhile.
            # swhile(idx < expr.type.size) do
            #     ruby_block.call(expr[idx],idx)
            #     idx <= idx + 1
            # end
            expr.seach.with_index(&ruby_block)
        end


        # Fills the top user with the content of block +blk+.
        def fill_top_user(blk)
            # Fill the current block with blk content.
            blk.each_statement do |stmnt|
                stmnt.parent = nil
                HDLRuby::High.top_user.add_statement(stmnt)
            end
        end
    end


    # Module adding functionalities to object including the +seach+ method.
    module SEnumerable
        
        # Tell if all the elements respect a given criterion given either
        # as +arg+ or as block.
        def all?(arg = nil,&ruby_block)
            # Declare the result signal.
            res = nil
            HDLRuby::High.cur_system.open do
                res = bit.inner(HDLRuby.uniq_name(:"all_cond"))
            end
            if arg then
                # Compare elements to arg.
                self.seach do |elem|
                    res <= res & (elem == arg)
                end
            elsif ruby_block then
                # Use the ruby block.
                self.seach do |elem|
                    res <= res & ruby_block.call(elem)
                end
            else
                # Check if each element is not 0.
                self.seach do |elem|
                    res <= res & (elem == 0)
                end
            end
            res
        end
    end


    # Defines a sequencer enumerator class that allows to generate HW iteration
    # over HW or SW objects within sequencers.
    class SEnumerator
        include SEnumerable

        attr_reader :size
        attr_reader :type
        attr_reader :result
        attr_reader :idx

        # Create a new sequencer for +size+ elements as +typ+ with an HW
        # array-like accesser +access+.
        def initialize(typ,size,&access)
            # Sets the size.
            @size = size
            # Sets the type.
            @type = typ
            # Sets the accesser.
            @access = access
            # Create the iterator and the iteration result.
            idx = nil
            result = nil
            HDLRuby::High.cur_system.open do
                idx = [size.width+1].inner({
                    HDLRuby.uniq_name("enum_idx") => 0 })
                result = typ.inner(HDLRuby.uniq_name("enum_res"))
            end
            @idx = idx
            @result = result
        end

        # Clones the enumerator.
        def clone
            return SEnumerator.new(@type,@size,&@access)
        end

        # View the next element without advancing the iteration.
        def speek
            @result <= @access.call(@idx)
            @result
        end

        # Get the next element.
        def snext
            @result <= @access.call(@idx)
            @idx <= @idx + 1
            @result
        end

        # Restart the iteration.
        def srewind
            @idx <= 0
        end

        # Iterate on each element.
        def seach(&ruby_block)
            return self unless ruby_block
            this = self
            # Reitialize the iteration.
            this.srewind
            # Performs the iteration.
            SequencerT.current.swhile(@idx < @size) do
                ruby_block.call(this.snext)
            end
        end

        # Iterate on each element with index.
        def seach_with_index(&ruby_block)
            idx = @idx
            seach do |elem|
                ruby_block.call(elem,idx-1)
            end
        end

        # Iterate on each element with arbitrary object +obj+.
        def seach_with_object(val,&ruby_block)
            seach do |elem|
                ruby_block(elem,val)
            end
        end

        # Iterates with an index.
        def with_index(&ruby_block)
            # Is there a ruby block?
            if ruby_block then
                # Yes, iterate directly.
                return self.seach_with_index(&ruby_block)
            end
            # No, create a new iterator.
            access = @access
            return SEnumerator.new(@type,@size) do |idx|
                [ access.call(idx),idx ]
            end
        end

        # Return a new SEnumerator with an arbitrary arbitrary object +obj+.
        def with_object(obj)
            # Is there a ruby block?
            if ruby_block then
                # Yes, iterate directly.
                return self.seach_with_object(obj,&ruby_block)
            end
            # No, create a new iterator.
            access = @access
            return SEnumerator.new(@type,@size) do |idx|
                [ access.call(idx),obj ]
            end
        end

        # Return a new SEnumerator going on iteration over enumerable +obj+
        def +(obj)
            enum = self.clone
            obj_enum = obj.seach
            res = nil
            typ = @type
            HDLRuby::High.cur_system.open do
                res = typ.inner(HDLRuby.uniq_name("enum_plus"))
            end
            return SEnumerator.new(typ,@size+obj_enum.size) do |idx|
                HDLRuby::High.top_user.hif(idx < @size) { res <= enum.snext }
                HDLRuby::High.top_user.helse        { res <= obj_enum.snext }
                res
            end
        end
    end


    # Enhance the HExpression module with sequencer iteration.
    module HDLRuby::High::HExpression
        # HW iteration on each element.
        def seach(&ruby_block)
            # Create the hardware iterator.
            this = self
            hw_enum = SEnumerator.new(this.type.base,this.type.size) do |idx|
                this[idx]
            end
            # Is there a ruby block?
            if(ruby_block) then
                # Yes, apply it.
                return hw_enum.seach(&ruby_block)
            else
                # No, return the resulting enumerator.
                return hw_enum
            end
        end
    end

    # Enhance the Enumerable module with sequencer iteration.
    module ::Enumerable
        # HW iteration on each element.
        def seach(&ruby_block)
            # Convert the enumrable to an array for easier processing.
            ar = self.to_a
            return if ar.empty? # The array is empty, nothing to do.
            # Compute the type of the elements.
            typ = ar[0].respond_to?(:type) ? ar[0].type : signed[32]
            # Create the hardware iterator.
            hw_enum = SEnumerator.new(typ,ar.size) do |idx|
                smux(idx,*ar)
            end
            # Is there a ruby block?
            if(ruby_block) then
                # Yes, apply it.
                return hw_enum.seach(&ruby_block)
            else
                # No, return the resulting enumerator.
                return hw_enum
            end
        end
    end

    # Enhance the Range class with sequencer iteration.
    class ::Range
        # HW iteration on each element.
        def seach(&ruby_block)
            # Create the hardware iterator.
            this = self
            hw_enum = SEnumerator.new(signed[32],this.size) do |idx|
                idx + self.first
            end
            # Is there a ruby block?
            if(ruby_block) then
                # Yes, apply it.
                return hw_enum.seach(&ruby_block)
            else
                # No, return the resulting enumerator.
                return hw_enum
            end
        end
    end

    # Enhance the Integer class with sequencer iterations.
    class ::Integer
        # HW times iteration.
        def stime(&ruby_block)
            return (0...self).seach(&ruby_block)
        end

        # HW upto iteration.
        def supto(val,&ruby_block)
            return (self..val).seach(&ruby_block)
        end

        # HW downto iteration.
        def sdownto(val,&ruby_block)
            # Create the hardware iterator.
            range = val..self
            hw_enum = SEnumerator.new(signed[32],range.size) do |idx|
                range.last - idx
            end
            # Is there a ruby block?
            if(ruby_block) then
                # Yes, apply it.
                return hw_enum.seach(&ruby_block)
            else
                # No, return the resulting enumerator.
                return hw_enum
            end
        end
    end



    # Create a sequencer of code synchronised of +clk+ and starting on +start+.
    def sequencer(clk,start,&ruby_block)
        return SequencerT.new(clk,start,&ruby_block)
    end


    # ## 
    # # Describes a high-level sequencer type.
    # class SequencerT
    #     include HDLRuby::High::HScope_missing

    #     # The state class
    #     class State
    #         attr_accessor :value, :name, :code, :gotos
    #     end

    #     # The name of the sequencer type.
    #     attr_reader :name

    #     # The namespace associated with the sequencer
    #     attr_reader :namespace

    #     # The reset code
    #     attr_reader :reset

    #     # The current and next state signals.
    #     attr_accessor :cur_state_sig, :next_state_sig, :work_state

    #     # Creates a new sequencer type with +name+.
    #     def initialize(name)
    #         # Check and set the name
    #         @name = name.to_sym

    #         # Initialize the internals of the sequencer.


    #         # Initialize the environment for building the sequencer.

    #         # The main states.
    #         @states = []

    #         # The working state.
    #         @work_state = nil

    #         # The current and next state signals
    #         @cur_state_sig = nil
    #         @next_state_sig = nil

    #         # The event synchronizing the fsm
    #         @mk_ev = proc { $clk.posedge }

    #         # The reset check.
    #         @mk_rst = proc { $rst }

    #         # The code executed in case of reset.
    #         # (By default, nothing).
    #         @reset  = nil

    #         # Creates the namespace to execute the fsm block in.
    #         @namespace = Namespace.new(self)

    #         # Generates the function for setting up the sequencer
    #         # provided there is a name.
    #         obj = self # For using the right self within the proc
    #         HDLRuby::High.space_reg(@name) do |&ruby_block|
    #             if ruby_block then
    #                 # Builds the fsm.
    #                 obj.build(&ruby_block)
    #             else
    #                 # Return the sequencer as is.
    #                 return obj
    #             end
    #         end unless name.empty?

    #     end

    #     ## builds the sequencer by executing +ruby_block+.
    #     def build(&ruby_block)
    #         # Use local variable for accessing the attribute since they will
    #         # be hidden when opening the sytem.
    #         states = @states
    #         namespace = @namespace
    #         this   = self
    #         mk_ev  = @mk_ev
    #         mk_rst = @mk_rst

    #         return_value = nil

    #         # Enters the current system
    #         HDLRuby::High.cur_system.open do
    #             HDLRuby::High.space_push(namespace)
    #             # Execute the instantiation block
    #             return_value = HDLRuby::High.top_user.instance_exec(&ruby_block)

    #             # Create the state register.
    #             name = HDLRuby.uniq_name
    #             # Declare the state register.
    #             this.cur_state_sig = [states.size.width].inner(name)
    #             # Declare the next state wire.
    #             name = HDLRuby.uniq_name
    #             this.next_state_sig = [states.size.width].inner(name)

    #             # Create the sequencer code

    #             # Control part: update of the state.
    #             par(mk_ev.call) do
    #                 hif(mk_rst.call) do
    #                     # Reset: current state is to put to 0.
    #                     this.cur_state_sig <= 0
    #                 end
    #                 helse do
    #                     # No reset: current state is updated with
    #                     # next state value.
    #                     this.cur_state_sig <= this.next_state_sig
    #                 end
    #             end

    #             # Operative main-part: one case per state.
    #             event = mk_ev.call
    #             event = event.invert
    #             # The process
    #             par(*event) do
    #                 # The operative code.
    #                 oper_code =  proc do
    #                     # Depending on the state.
    #                     hcase(this.cur_state_sig)
    #                     states.each do |st|
    #                         # Register the working state (for the gotos)
    #                         this.work_state = st
    #                         hwhen(st.value) do
    #                             # Generate the content of the state.
    #                             st.code.call
    #                         end
    #                     end
    #                 end
    #                 # Is there reset code?
    #                 if this.reset then
    #                     # Yes, use it before the operative code.
    #                     hif(mk_rst.call) do
    #                         this.reset.call
    #                     end
    #                     helse(&oper_code)
    #                 else
    #                     # Use only the operative code.
    #                     oper_code.call
    #                 end
    #             end

    #             # Control part: computation of the next state.
    #             # (clock-independent)
    #             hcase(this.cur_state_sig)
    #             states.each do |st|
    #                 hwhen(st.value) do
    #                     if st.gotos.any? then
    #                         # Gotos were present, use them.
    #                         st.gotos.each(&:call)
    #                     else
    #                         # No gotos, by default the next step is
    #                         # current + 1
    #                         this.next_state_sig <= this.cur_state_sig + 1
    #                     end
    #                 end
    #             end
    #             # By default set the next state to 0.
    #             helse do
    #                 this.next_state_sig <= 0
    #             end

    #             HDLRuby::High.space_pop
    #         end

    #         return return_value
    #     end


    #     ## The interface for building the sequencer.

    #     # Sets the event synchronizing the sequencer.
    #     def for_event(event = nil,&ruby_block)
    #         if event then
    #             # An event is passed as argument, use it.
    #             @mk_ev = proc { event.to_event }
    #         else
    #             # No event given, use the ruby_block as event generator.
    #             @mk_ev = ruby_block
    #         end
    #     end

    #     # Sets the reset.
    #     def for_reset(reset = nil,&ruby_block)
    #         if reset then
    #             # An reset is passed as argument, use it.
    #             @mk_rst = proc { reset.to_expr }
    #         else
    #             # No reset given, use the ruby_block as event generator.
    #             @mk_rst = ruby_block
    #         end
    #     end

    #     # Adds a code to be executed in case of reset.
    #     def reset(&ruby_block)
    #         @reset = ruby_block
    #     end

    #     # Declares a state with +name+ executing +ruby_block+.
    #     def state(name = :"",&ruby_block)
    #         # Create the resulting state
    #         result = State.new
    #         # Its value is the current number of states
    #         result.value = @states.size
    #         result.name = name.to_sym
    #         result.code = ruby_block
    #         result.gotos = []
    #         # Add it to the list of states.
    #         @states << result
    #         # Return it.
    #         return result
    #     end

    #     # Get a state by +name+.
    #     def get_state(name)
    #         name = name.to_sym
    #         (@states.detect { |st| st.name == name }).value
    #     end

    #     # Sets the next state. Arguments can be:
    #     #
    #     # +name+: the name of the next state.
    #     # +expr+, +names+: an expression with the list of the next statements
    #     #                  in order of the value of the expression, the last
    #     #                  one being necesserily the default case.
    #     def goto(*args)
    #         # Make reference to the fsm attributes.
    #         next_state_sig = @next_state_sig
    #         states = @states
    #         # Add the code of the goto to the working state.
    #         @work_state.gotos << proc do
    #             # Depending on the first argument type.
    #             unless args[0].is_a?(Symbol) then
    #                 # expr + names arguments.
    #                 # Get the predicate
    #                 pred = args.shift
    #                 # hif or hcase?
    #                 if args.size <= 2 then
    #                     # 2 or less cases, generate an hif
    #                     arg = args.shift
    #                     hif(pred) do
    #                         next_state_sig <=
    #                             (states.detect { |st| st.name == arg }).value
    #                     end
    #                     arg = args.shift
    #                     if arg then
    #                         # There is an else.
    #                         helse do
    #                             next_state_sig <=
    #                             (states.detect { |st| st.name == arg }).value
    #                         end
    #                     end
    #                 else
    #                     # More than 2, generate a hcase
    #                     hcase (pred)
    #                     args[0..-2].each.with_index do |arg,i|
    #                         # Ensure the argument is a symbol.
    #                         arg = arg.to_sym
    #                         # Make the when statement.
    #                         hwhen(i) do
    #                             next_state_sig <= 
    #                             (states.detect { |st| st.name == arg }).value
    #                         end
    #                     end
    #                     # The last name is the default case.
    #                     # Ensure it is a symbol.
    #                     arg = args[-1].to_sym
    #                     # Make the default statement.
    #                     helse do
    #                         next_state_sig <= 
    #                             (states.detect { |st| st.name == arg }).value
    #                     end
    #                 end
    #             else
    #                 # single name argument, check it.
    #                 raise AnyError, "Invalid argument for a goto: if no expression is given only a single name can be used." if args.size > 1
    #                 # Ensure the name is a symbol.
    #                 name = args[0].to_sym
    #                 # Get the state with name.
    #                 next_state_sig <= (states.detect { |st| st.name == name }).value
    #             end
    #         end
    #     end

    # end


    # ## Declare a new fsm.
    # #  The arguments can be any of (but in this order):
    # #
    # #  - +name+:: name.
    # #  - +clk+:: clock.
    # #  - +event+:: clock event.
    # #  - +rst+:: reset. (must be declared AFTER clock or clock event).
    # #
    # #  If provided, +ruby_block+ the fsm is directly instantiated with it.
    # def fsm(*args, &ruby_block)
    #     # Sets the name if any
    #     unless args[0].respond_to?(:to_event) then
    #         name = args.shift.to_sym
    #     else
    #         name = :""
    #     end
    #     # Get the options from the arguments.
    #     options, args = args.partition {|arg| arg.is_a?(Symbol) }
    #     # Create the fsm.
    #     fsmI = FsmT.new(name,*options)
    #     
    #     # Process the clock event if any.
    #     unless args.empty? then
    #         fsmI.for_event(args.shift)
    #     end
    #     # Process the reset if any.
    #     unless args.empty? then
    #         fsmI.for_reset(args.shift)
    #     end
    #     # Is there a ruby block?
    #     if ruby_block then
    #         # Yes, generate the fsm.
    #         fsmI.build(&ruby_block)
    #     else
    #         # No return the fsm structure for later generation.
    #         return fsmI
    #     end
    # end

end
