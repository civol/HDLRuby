require 'set'
require 'HDLRuby'
require 'hruby_high_fullname'
require 'hruby_sim/hruby_sim'


module HDLRuby::High


##
# Library for describing the hybrid Ruby-C simulator of HDLRuby
#
########################################################################

    ## Provides tools for converting HDLRuby::High objects to C.
    module High2C

        ## Gives the width of an int in the current computer.
        def self.int_width
            # puts "int_width=#{[1.to_i].pack("i").size*8}"
            return [1.to_i].pack("i").size*8
        end

        ## Converts string +str+ to a C-compatible string.
        def self.c_string(str)
            str = str.gsub(/\n/,"\\n")
            str.gsub!(/\t/,"\\t")
            return str
        end

        ## Converts a +name+ to a C-compatible name.
        def self.c_name(name)
            name = name.to_s
            # Convert special characters.
            name = name.each_char.map do |c|
                if c=~ /[a-z0-9]/ then
                    c
                elsif c == "_" then
                    "__"
                else
                    "_" + c.ord.to_s
                end
            end.join
            # First character: only letter is possible.
            unless name[0] =~ /[a-z_]/ then
                name = "_" + name
            end
            return name
        end

        @@hdrobj2c = {}

        ## Generates a uniq name for an object.
        def self.obj_name(obj)
            id = obj.hierarchy.map! {|obj| obj.object_id}
            oname = @@hdrobj2c[id]
            unless oname then
                oname = "_" << @@hdrobj2c.size.to_s(36)
                @@hdrobj2c[id] = oname
            end
            return oname
        end

        ## Generates the name of a type.
        def self.type_name(obj)
            return "type#{Low2C.obj_name(obj)}"
        end

        ## Generates the name of a unit.
        def self.unit_name(obj)
            return "#{obj.to_s.upcase}"
        end
    end


    RCSim = RCSimCinterface


    
    ## Starts the simulation for top system +top+.
    #  NOTE: +name+ is the name of the simulation, +outpath+ is the path where
    #        the output is to save, and +outmode+ is the output mode as follows:
    #        0: standard
    #        1: mute
    #        2: vcd
    def self.rcsim(top,name,outpath,outmode)
        RCSim.rcsim_main(top.rcsystemT,outpath +"/" + name,outmode)
    end



    ## Extends the SystemT class for hybrid Ruby-C simulation.
    class SystemT

        attr_reader :rcsystemT # The access to the C version of the systemT

        # Generate the C description of the systemT.
        # +rcowner+ is the owner if any.
        def to_rcsim(rcowner = nil)
            # puts "to_rcsim for systemT=#{self.name}(#{self})"
            # Create the systemT C object.
            @rcsystemT = RCSim.rcsim_make_systemT(self.name.to_s)
            # Sets the owner if any.
            if rcowner then
                RCSim.rcsim_set_owner(@rcsystemT,rcowner)
            end
            # Create and add the interface signals.
            # self.each_input do |sig|
            #     rcsig = sig.to_rcsim(@rcsystemT)
            #     RCSim.rcsim_add_systemT_input(@rcsystemT,rcsig)
            # end
            if self.each_input.any? then
                RCSim.rcsim_add_systemT_inputs(@rcsystemT,
                                               self.each_input.map do |sig|
                    sig.to_rcsim(@rcsystemT)
                end)
            end
            # self.each_output do |sig|
            #     rcsig = sig.to_rcsim(@rcsystemT)
            #     RCSim.rcsim_add_systemT_output(@rcsystemT,rcsig)
            # end
            if self.each_output.any? then
                RCSim.rcsim_add_systemT_outputs(@rcsystemT,
                                                self.each_output.map do |sig|
                    sig.to_rcsim(@rcsystemT)
                end)
            end
            # self.each_inout do |sig|
            #     rcsig = sig.to_rcsim(@rcsystemT)
            #     RCSim.rcsim_add_systemT_inout(@rcsystemT,rcsig)
            # end
            if self.each_inout.any? then
                RCSim.rcsim_add_systemT_inouts(@rcsystemT,
                                               self.each_inout.map do |sig|
                    sig.to_rcsim(@rcsystemT)
                end)
            end
            # Create and add the scope.
            RCSim.rcsim_set_systemT_scope(@rcsystemT,
                                          self.scope.to_rcsim(@rcsystemT))

            # The owner is set afterward.
            # # Set the owner if any.
            # if @owner then
            #     if @owner.is_a?(SystemI) then
            #         puts "@owner=#{@owner} rcsystemI=#{@owner.rcsystemI.class}"
            #         RCSim.rcsim_set_owner(@rcsystemT,@owner.rcsystemI)
            #     end
            #     # The non-SystemI owner are discarded for the simulation.
            # end

            return @rcsystemT
        end
    end


    ## Extends the Scope class for hybrid Ruby-C simulation.
    class Scope

        attr_reader :rcscope # The access to the C version of the scope.

        # Generate the C description of the scope comming from object
        # whose C description is +rcowner+
        def to_rcsim(rcowner)
            # puts "to_rcsim for scope=#{self}"
            # Create the scope C object.
            @rcscope = RCSim.rcsim_make_scope(self.name.to_s)

            # Set the owner.
            RCSim.rcsim_set_owner(@rcscope,rcowner)

            # Of the scope is a son of a SystemT, the owner of the sub objects
            # will be this systemT. Otherwise, it is the scope.
            subowner = self.parent.is_a?(SystemT) ? rcowner : @rcscope

            # Create and add the inner signals.
            # self.each_inner do |sig|
            #     rcsig = sig.to_rcsim(@rcscope)
            #     RCSim.rcsim_add_scope_inner(@rcscope,rcsig)
            # end
            if self.each_inner.any? then
                RCSim.rcsim_add_scope_inners(@rcscope,self.each_inner.map do|sig|
                    # sig.to_rcsim(@rcscope)
                    sig.to_rcsim(subowner)
                end)
            end
            
            # Create and add the system instances.
            # self.each_systemI do |sys|
            #     rcsys = sys.to_rcsim(@rcscope)
            #     RCSim.rcsim_add_scope_systemI(@rcscope,rcsys)
            # end
            if self.each_systemI.any? then
                RCSim.rcsim_add_scope_systemIs(@rcscope,
                                               self.each_systemI.map do |sys|
                    # sys.to_rcsim(@rcscope)
                    sys.to_rcsim(subowner)
                end)
            end

            # Create and add the behaviors.
            if self.each_behavior.any? then
                RCSim.rcsim_add_scope_behaviors(@rcscope,
                                                self.each_behavior.map do |beh|
                    # beh.to_rcsim(@rcscope)
                    beh.to_rcsim(subowner)
                end)
            end

            # Create and add the connections.
            if self.each_connection.any? then
                RCSim.rcsim_add_scope_behaviors(@rcscope, 
                                                self.each_connection.map do |cxt|
                    # cxt.to_rcsim(@rcscope)
                    cxt.to_rcsim(subowner)
                end)
            end

            # Create and add the codes.
            # TODO!!

            # Create and add the sub scopes.
            # self.each_scope do |sub|
            #     rcsub = sub.to_rcsim(@rcscope)
            #     RCSim.rcsim_add_scope_scope(@rcscope,rcsub)
            # end
            if self.each_scope.any? then
                RCSim.rcsim_add_scope_scopes(@rcscope,self.each_scope.map do|sub|
                    # sub.to_rcsim(@rcscope)
                    sub.to_rcsim(subowner)
                end)
            end

            return @rcscope
        end
    end



    ## Extends the Type class for hybrid Ruby-C simulation.
    class Type

        attr_reader :rctype # The access to the C version of the scope.

        # Generate the C description of the type comming from object
        # whose C description is +rcowner+.
        # NOTE: +rcowner+ is not used here.
        def to_rcsim
            # Create the type C object.
            if self.name == :bit || self.name == :unsigned then
                @rctype = RCSim.rcsim_get_type_bit()
            elsif self.name == :signed then
                @rctype = RCSim.rcsim_get_type_signed()
            else
                raise "Unknown type: #{self.name}"
            end
            return @rctype
        end
    end

    ## Extends the TypeDef class for hybrid Ruby-C simulation.
    class TypeDef

        # Generate the C description of the type.
        def to_rcsim
            # Create the type C object.
            @rctype = self.def.to_rcsim
            return @rctype
        end
    end

    ## Extends the TypeVector class for hybrid Ruby-C simulation.
    class TypeVector

        # Generate the C description of the type.
        def to_rcsim
            # Create the type C object.
            @rctype = RCSim.rcsim_get_type_vector(self.base.to_rcsim,self.size)
            return @rctype
        end
    end

    ## Extends the TypeTuple class for hybrid Ruby-C simulation.
    class TypeTuple
        # Add the possibility to change the direction.
        def direction=(dir)
            @direction = dir == :little ? :little : :big
        end

        # Generate the C description of the type.
        def to_rcsim
            # @rctype = self.to_vector.to_rcsim
            @rctype = RCSim.rcsim_get_type_vector(Bit.to_rcsim,self.width)
            return @rctype
        end
    end


    ## Extends the TypeStruct class for hybrid Ruby-C simulation.
    class TypeStruct
        # Add the possibility to change the direction.
        def direction=(dir)
            @direction = dir == :little ? :little : :big
        end

        # Generate the C description of the type.
        def to_rcsim
            # @rctype = self.to_vector.to_rcsim
            @rctype = RCSim.rcsim_get_type_vector(Bit.to_rcsim,self.width)
            return @rctype
        end
    end


    ## Module for extending the behavior classes for hybrid Ruby-C simulation.
    module RCSimBehavior

        attr_reader :rcbehavior

        # Generate the C description of the behavior comming from object
        # whose C description is +rcowner+
        def to_rcsim(rcowner)
            # puts "to_rcsim for behavior=#{self}"
            # Process the sensitivity list.
            # Is it a clocked behavior?
            events = self.each_event.to_a
            # puts "events=#{events.map {|ev| ev.ref.object.name }}"
            if !self.is_a?(TimeBehavior) && events.empty? then
                # No events, this is not a clock behavior.
                # And it is not a time behavior neigther.
                # Generate the events list from the right values.
                # First get the references.
                refs = self.block.each_node_deep.select do |node|
                    node.is_a?(RefObject) && !node.leftvalue? && 
                        !node.parent.is_a?(RefObject) 
                end.to_a
                # puts "refs=#{refs}"
                # Keep only one ref per signal.
                refs.uniq! { |node| node.fullname }
                # Remove the inner signals from the list.
                self.block.each_inner do |inner|
                    refs.delete_if {|r| r.name == inner.name }
                end
                # Generate the event.
                events = refs.map {|ref| Event.new(:anyedge,ref.clone) }
                # Add them to the behavior for further processing.
                events.each {|event| self.add_event(event) }
            end

            # Create the behavior C object.
            # puts "make behavior with self.class=#{self.class}"
            @rcbehavior = RCSim.rcsim_make_behavior(self.is_a?(TimeBehavior))

            # Set the owner.
            RCSim.rcsim_set_owner(@rcbehavior,rcowner)

            # Create and add the events.
            # self.each_event do |ev|
            #     RCSim.rcsim_add_behavior_event(@rcbehavior,ev.to_rcsim)
            # end
            if self.each_event.any? then
                RCSim.rcsim_add_behavior_events(@rcbehavior,
                                                self.each_event.map do |ev|
                    # puts "adding event: #{ev.ref.object.name}(#{ev.type})"
                    ev.to_rcsim(@rcbehavior)
                end)
            end

            # Create and add the block.
            RCSim.rcsim_set_behavior_block(@rcbehavior,self.block.to_rcsim)

            return @rcbehavior
        end
    end


    ## Extends the Behavior class for hybrid Ruby-C simulation.
    class Behavior
        include RCSimBehavior
    end

    ## Extends the TimeBehavior class for hybrid Ruby-C simulation.
    class TimeBehavior
        include RCSimBehavior
    end


    ## Extends the Event class for hybrid Ruby-C simulation.
    class Event

        attr_reader :rcevent

        # Generate the C description of the event comming from object
        # whose C description is +rcowner+
        def to_rcsim(rcowner)
            # Create the event C object.
            @rcevent = RCSim.rcsim_make_event(self.type,self.ref.to_rcsim)

            # Set the owner.
            RCSim.rcsim_set_owner(@rcevent,rcowner)

            return @rcevent
        end
    end


    ## Extends the SignalI class for hybrid Ruby-C simulation.
    class SignalI

        attr_reader :rcsignalI

        # Generate the C description of the signal comming from object
        # whose C description is +rcowner+
        def to_rcsim(rcowner)
            # Create the signal C object.
            @rcsignalI = RCSim.rcsim_make_signal(self.name.to_s,
                                           self.type.to_rcsim)
            # puts "to_rcsim for signal=(#{self.name})#{self}, @rcsignalI=#{@rcsignalI}"

            # Set the owner.
            RCSim.rcsim_set_owner(@rcsignalI,rcowner)

            # Set the initial value if any.
            if self.value then
                RCSim.rcsim_set_signal_value(@rcsignalI,self.value.to_rcsim)
            end

            return @rcsignalI
        end
    end


    ## Extends the SignalC class for hybrid Ruby-C simulation.
    class SignalC

        attr_reader :rcsignalC

        # Generate the C description of the signal comming from object
        # whose C description is +rcowner+
        def to_rcsim(rcowner)
            # Create the signal C object.
            @rcsignalC = RCSim.rcsim_make_signal(self.name.to_s,
                                           self.type.to_rcsim)

            # Set the owner.
            RCSim.rcsim_set_owner(@rcsignalC,rcowner)

            # Set the initial value.
            RCSim.rcsim_set_signal_value(@rcsignalC,self.value.to_rcsim)

            return @rcsignalC
        end
    end


    ## Extends the SystemI class for hybrid Ruby-C simulation.
    class SystemI

        attr_reader :rcsystemI

        # Generate the C description of the signal comming from object
        # whose C description is +rcowner+
        def to_rcsim(rcowner)
            # puts "to_rcsim for systemI=#{self.name}(#{self})"
            # Create the system instance C object.
            @rcsystemI = RCSim.rcsim_make_systemI(self.name.to_s,
                                                  self.systemT.to_rcsim)
            # # Set the owner of the systemT.
            # RCSim.rcsim_set_owner(self.systemT.rcsystemT,@rcsystemI)
            # Set the owner of the systemT as the same as the systemI since
            # it is an Eigen system.
            RCSim.rcsim_set_owner(self.systemT.rcsystemT,rcowner)

            # Set the owner.
            RCSim.rcsim_set_owner(@rcsystemI,rcowner)

            # Add the alternate system types.
            # self.each_systemT do |systemT|
            #     rcsys = systemT.to_rcsim(@rcsystemI)
            #     RCSim.rcsim_add_systemI_systemT(@rcsystemI,rcsys)
            # end
            if self.each_systemI.any? then
                RCSim.rcsim_add_systemI_systemTs(@rcsystemI,
                                                 self.each_systemT.select do|sys|
                    sys != self.systemT
                end.map do |sys|
                    # sys.to_rcsim(@rcsystemI)
                    sys.to_rcsim(rcowner)
                end)
            end

            return @rcsystemI
        end
    end


    ## Extends the Chunk class for hybrid Ruby-C simulation.
    class Chunk
        # TODO!!
    end

    ## Extends the Code class for hybrid Ruby-C simulation.
    class Code
        # TODO!!
    end


    ## Extends the Statement class for hybrid Ruby-C simulation.
    class Statement

        attr_reader :rcstatement

        # Generate the C description of the statement.
        def to_rcsim
            raise "to_rcsim must be implemented in #{self.class}"
        end
    end


    ## Extends the Transmit class for hybrid Ruby-C simulation.
    class Transmit
        attr_reader :rcstatement

        # Generate the C description of the transmit.
        def to_rcsim
            # Create the transmit C object.
            @rcstatement = RCSim.rcsim_make_transmit(self.left.to_rcsim,
                                               self.right.to_rcsim)

            return @rcstatement
        end
    end


    ## Extends the Print class for hybrid Ruby-C simulation.
    class Print
        attr_reader :rcstatement

        # Generate the C description of the print.
        def to_rcsim
            # Create the print C object.
            @rcstatement = RCSim.rcsim_make_print()

            # Adds the arguments.
            # self.each_arg do |arg|
            #     RCSim.rcsim_add_print_arg(@rcstatement,arg.to_rcsim)
            # end
            if self.each_arg.any? then
                RCSim.rcsim_add_print_args(@rcstatement,
                                           self.each_arg.map(&:to_rcsim))
            end

            return @rcstatement
        end
    end


    ## Extends the TimeTerminate class for hybrid Ruby-C simulation.
    class TimeTerminate
        attr_reader :rcstatement

        # Generate the C description of the terminate.
        def to_rcsim
            # Create the terminate C object.
            @rcstatement = RCSim.rcsim_make_timeTerminate()

            return @rcstatement
        end
    end

    ## Extends the Configure class for hybrid Ruby-C simulation.
    class Configure
        attr_reader :rcstatement
        # TODO!!!
    end

    
    ## Extends the If class for hybrid Ruby-C simulation.
    class If
        attr_reader :rcstatement

        # Generate the C description of the hardware if.
        def to_rcsim
            # Create the hardware if C object.
            @rcstatement = RCSim.rcsim_make_hif(self.condition.to_rcsim,
                                          self.yes.to_rcsim, 
                                          self.no ? self.no.to_rcsim : nil)

            # Add the alternate ifs if any.
            # self.each_noif do |cond,stmnt|
            #     RCSim.rcsim_add_hif_noif(@rcstatement,cond.to_rcsim,stmnt.to_rcsim)
            # end
            rcsim_conds = self.each_noif.map {|cond,stmnt| cond.to_rcsim }
            rcsim_stmnts = self.each_noif.map {|cond,stmnt| stmnt.to_rcsim }
            if rcsim_conds.any? then
                RCSim.rcsim_add_hif_noifs(@rcstatement,rcsim_conds,rcsim_stmnts)
            end

            return @rcstatement
        end
    end


    ## Extends the When class for hybrid Ruby-C simulation.
    class When
        # Nothing to add.
    end

    ## Extends the Case class for hybrid Ruby-C simulation.
    class Case
        attr_reader :rcstatement

        # Generate the C description of the hardware case.
        def to_rcsim
            # Create the hardware case C object.
            @rcstatement = RCSim.rcsim_make_hcase(self.value.to_rcsim,
                                    self.default ? self.default.to_rcsim : nil)

            # Add the hardware whens.
            # self.each_when do |wh|
            #     RCSim.rcsim_add_hcase_when(@rcstatement,
            #                          wh.match.to_rcsim,wh.statement.to_rcsim)
            # end
            rcsim_matches = self.each_when.map {|wh| wh.match.to_rcsim }
            rcsim_stmnts = self.each_when.map {|wh| wh.statement.to_rcsim }
            if rcsim_matches.any? then
                RCSim.rcsim_add_hcase_whens(@rcstatement,rcsim_matches,
                                            rcsim_stmnts)
            end

            return @rcstatement
        end
    end


    ## Extends the Delay class for hybrid Ruby-C simulation.
    class Delay
        # Nothing to do.
    end

    ## Extends the TimeWait class for hybrid Ruby-C simulation.
    class TimeWait
        attr_reader :rcstatement

        # Generate the C description of the time wait.
        def to_rcsim
            # Create the time wait C object.
            @rcstatement = RCSim.rcsim_make_timeWait(self.delay.unit,
                                               self.delay.value.to_i)

            return @rcstatement
        end
    end


    ## Extends the TimeRepeat class for hybrid Ruby-C simulation.
    class TimeRepeat
        attr_reader :rcstatement

        # Generate the C description of the hardware case.
        # +owner+ is a link to the C description of the owner behavior if any.
        def to_rcsim(owner = nil)
            # Create the timeRepeat C object.
            @rcstatement = RCSim.rcsim_make_timeRepeat(self.number,
                                                       self.statement.to_rcsim)

            # Sets the owner if any.
            if owner then
                RCSim.rcsim_set_owner(@rcstatement,owner)
            end

            return @rcstatement
        end
    end


    ## Module for extending the Block classes for hybrid Ruby-C simulation.
    module RCSimBlock
        attr_reader :rcstatement

        # Generate the C description of the hardware case.
        # +owner+ is a link to the C description of the owner behavior if any.
        def to_rcsim(owner = nil)
            # Create the block C object.
            @rcstatement = RCSim.rcsim_make_block(self.mode)

            # Sets the owner if any.
            if owner then
                RCSim.rcsim_set_owner(@rcstatement,owner)
            end

            # Add the inner signals.
            # self.each_inner do |inner|
            #     RCSim.rcsim_add_block_inner(@rcstatement,inner.to_rcsim(@rcstatement))
            # end
            if self.each_inner.any? then
                RCSim.rcsim_add_block_inners(@rcstatement,
                                             self.each_inner.map do |sig|
                    sig.to_rcsim(@rcstatement)
                end)
            end

            # Add the statements.
            # self.each_statement do |stmnt|
            #     RCSim.rcsim_add_block_statement(@rcstatement,stmnt.to_rcsim)
            # end
            if self.each_statement.any? then
                RCSim.rcsim_add_block_statements(@rcstatement,
                                            self.each_statement.map do |stmnt|
                    stmnt.to_rcsim
                end)
            end

            return @rcstatement
        end
    end

    ## Extends the Block class for hybrid Ruby-C simulation.
    class Block
        include RCSimBlock
    end

    ## Extends the TimeBlock class for hybrid Ruby-C simulation.
    class TimeBlock
        include RCSimBlock
    end


    ## Extends the Connection class for hybrid Ruby-C simulation.
    class Connection
        attr_reader :rcbehavior

        # Generate the C description of the connection.
        # +rcowner+ is a link to the C description of the owner scope.
        def to_rcsim(rcowner)
            # puts "make behavior with self.class=#{self.class}"
            # Create the connection C object, actually it is a behavior.
            @rcbehavior = RCSim.rcsim_make_behavior(false)

            # Set the owner.
            RCSim.rcsim_set_owner(@rcbehavior,rcowner)

            # Create and add the events.
            rcevs = []
            self.right.each_node_deep do |node|
                if node.is_a?(RefObject) && !node.parent.is_a?(RefObject) then
                    ev = RCSim.rcsim_make_event(:anyedge,node.to_rcsim)
                    RCSim.rcsim_set_owner(ev,@rcbehavior)
                    rcevs << ev
                end
            end
            if rcevs.any? then
                RCSim.rcsim_add_behavior_events(@rcbehavior,rcevs)
            end

            # Create and set the block.
            rcblock = RCSim.rcsim_make_block(:par)
            # RCSim.rcsim_add_block_statement(
            #     RCSim.rcsim_make_transmit(self.left.to_rcsim,
            #                         self.right.to_rcsim))
            # puts "self.left=#{self.left} self.right=#{self.right}"
            RCSim.rcsim_add_block_statements(rcblock,
                [RCSim.rcsim_make_transmit(self.left.to_rcsim, self.right.to_rcsim)])
            RCSim.rcsim_set_behavior_block(@rcbehavior,rcblock)

            return @rcbehavior
        end
    end


    ## Extends the Expression class for hybrid Ruby-C simulation.
    class Expression

        # attr_reader :rcexpression

        # Generate the C description of the expression.
        def to_rcsim
            raise "to_rcsim must be implemented in #{self.class}"
        end
    end


    ## Extends the Value class for hybrid Ruby-C simulation.
    class Value
        # attr_reader :rcexpression

        # Generate the C description of the value.
        def to_rcsim
            # Create the value C object.
            if self.content.is_a?(::Integer) then
                # puts "self.type.width=#{self.type.width} and content=#{self.content}" ; $stdout.flush
                if self.type.width <= 64 then
                    if self.content.bit_length <= 63 then
                        return RCSim.rcsim_make_value_numeric(self.type.to_rcsim,
                                                              self.content)
                    else
                        return RCSim.rcsim_make_value_numeric(self.type.to_rcsim,
                                                              self.content & 0xFFFFFFFFFFFF)
                    end
                else
                    if self.content < 0 then
                        str = (2**self.type.width + self.content).to_s(2)
                        str = "1" * (self.type.width-str.length) + str
                    else
                        str = self.content.to_s(2)
                        str = "0" * (self.type.width-str.length) + str
                    end
                    # puts "now str=#{str} (#{str.length})" ; $stdout.flush
                    return RCSim.rcsim_make_value_bitstring(self.type.to_rcsim,
                                                            str.reverse)
                end
            else
                return RCSim.rcsim_make_value_bitstring(self.type.to_rcsim,
                                                        self.content.to_s.reverse)
            end
        end
    end

    ## Extends the StringE class for hybrid Ruby-C simulation.
    class StringE

        # Generate the C description of the value.
        def to_rcsim
            # Create the value C object.
            return RCSim.rcsim_make_stringE(self.content);
        end
    end


    ## Extends the Cast class for hybrid Ruby-C simulation.
    class Cast
        # attr_reader :rcexpression

        # Generate the C description of the cast.
        def to_rcsim
            # puts "Cast to width=#{self.type.width} and child=#{self.child}"
            # Shall we reverse when casting?
            if self.type.direction != self.child.type.direction then
                # Yes, reverse the direction of the child.
                if self.child.type.respond_to?(:direction=) then
                    self.child.type.direction = self.type.direction
                end
            end
            # Create the cast C object.
            return RCSim.rcsim_make_cast(self.type.to_rcsim,self.child.to_rcsim)
        end
    end


    ## Extends the Operation class for hybrid Ruby-C simulation.
    class Operation
        # Nothing to do.
    end

    ## Extends the Unary class for hybrid Ruby-C simulation.
    class Unary
        attr_reader :rcexpression

        # Generate the C description of the unary operation.
        def to_rcsim
            # Create the unary C object.
            return RCSim.rcsim_make_unary(self.type.to_rcsim,self.operator,
                                    self.child.to_rcsim)
        end
    end

    ## Extends the Binary class for hybrid Ruby-C simulation.
    class Binary
        # attr_reader :rcexpression

        # Generate the C description of the binary operation.
        def to_rcsim
            # Create the binary C object.
            return RCSim.rcsim_make_binary(self.type.to_rcsim,self.operator,
                                     self.left.to_rcsim,
                                     self.right.to_rcsim)
        end
    end


    ## Extends the Select class for hybrid Ruby-C simulation.
    class Select
        # attr_reader :rcexpression

        # Generate the C description of the select operation.
        def to_rcsim
            # Create the select C object.
            rcexpression = RCSim.rcsim_make_select(self.type.to_rcsim,
                                              self.select.to_rcsim)

            # Add the choice expressions. */
            # self.each_choice do |choice|
            #     rcsim_add_select_choice(rcexpression,choice.to_rcsim)
            # end
            if self.each_choice.any? then
                RCSim.rcsim_add_select_choices(rcexpression,
                                               self.each_choice.map(&:to_rcsim))
            end
            
            return rcexpression
        end
    end


    ## Extends the Concat class for hybrid Ruby-C simulation.
    class Concat
        # attr_reader :rcexpression

        # Generate the C description of the concat operation.
        def to_rcsim
            # Create the concat C object.
            rcexpression = RCSim.rcsim_make_concat(self.type.to_rcsim,
                                             self.type.direction)

            # Add the concatenated expressions. */
            # self.each_expression do |expr|
            #     RCSim.rcsim_add_concat_expression(rcexpression,expr.to_rcsim)
            # end
            if self.each_expression.any? then
                RCSim.rcsim_add_concat_expressions(rcexpression,
                                         self.each_expression.map(&:to_rcsim))
            end
            
            return rcexpression
        end
    end



    ## Extends the Ref class for hybrid Ruby-C simulation.
    class Ref
        # attr_reader :rcref
        # alias_method :rcexpression, :rcref

        # Generate the C description of the reference.
        def to_rcsim
            raise "to_rcsim must be implemented in #{self.class}"
        end
    end


    ## Extends the RefConcat class for hybrid Ruby-C simulation.
    class RefConcat
        # attr_reader :rcref
        # alias_method :rcexpression, :rcref

        # Generate the C description of the reference concat.
        def to_rcsim
            # Create the reference concat C object.
            rcref = RCSim.rcsim_make_refConcat(self.type.to_rcsim,
                                         self.type.direction)

            # Add the concatenated expressions. */
            # self.each_ref do |ref|
            #     RCSim.rcsim_add_refConcat_ref(rcref,ref.to_rcsim)
            # end
            if self.each_ref.any? then
                RCSim.rcsim_add_refConcat_refs(rcref,self.each_ref.map(&:to_rcsim))
            end
            
            return rcref
        end
    end


    ## Extends the RefIndex class for hybrid Ruby-C simulation.
    class RefIndex
        # attr_reader :rcref
        # alias_method :rcexpression, :rcref

        # Generate the C description of the reference index.
        def to_rcsim
            # Create the reference index C object.
            return RCSim.rcsim_make_refIndex(self.type.to_rcsim,
                                       self.index.to_rcsim,self.ref.to_rcsim)
        end
    end


    ## Extends the RefRange class for hybrid Ruby-C simulation.
    class RefRange
        # attr_reader :rcref
        # alias_method :rcexpression, :rcref

        # Generate the C description of the reference range.
        def to_rcsim
            # Create the reference range C object.
            return RCSim.rcsim_make_refRange(self.type.to_rcsim,
                                       self.range.first.to_rcsim,
                                       self.range.last.to_rcsim,
                                       self.ref.to_rcsim)
        end
    end


    ## Extends the RefName class for hybrid Ruby-C simulation.
    class RefName
        # Should not be used with rcsim.
    end


    ## Extends the RefThis class for hybrid Ruby-C simulation.
    class RefThis 
        # attr_reader :rcref
        # alias_method :rcexpression, :rcref

        # Generate the C description of the reference range.
        def to_rcsim
            return nil
        end
    end


    ## Extends the RefObject class for hybrid Ruby-C simulation.
    class RefObject
        # attr_reader :rcref
        # alias_method :rcexpression, :rcref

        # Generate the C description of the reference object.
        def to_rcsim
            # puts "object=#{self.object.name}(#{self.object})"
            if self.object.is_a?(SignalI)
                return self.object.rcsignalI
            elsif self.object.is_a?(SignalC)
                return self.object.rcsignalC
            else
                raise "Invalid object: #{self.object}"
            end
        end
    end


end
