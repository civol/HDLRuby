require 'set'
require 'HDLRuby'
require 'hruby_high_fullname'
require 'hruby_sim/hruby_sim'

require 'rubyHDL'


module HDLRuby::High


##
# Library for describing the hybrid Ruby-C simulator of HDLRuby
#
########################################################################

    ## Provides tools for converting HDLRuby::High objects to C.
    module High2C

        ## Gives the width of an int in the current computer.
        def self.int_width
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



    class SystemT
        ## Extends the SystemT class for hybrid Ruby-C simulation.

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
            if self.each_input.any? then
                RCSim.rcsim_add_systemT_inputs(@rcsystemT,
                                               self.each_input.map do |sig|
                    sig.to_rcsim(@rcsystemT)
                end)
            end
            if self.each_output.any? then
                RCSim.rcsim_add_systemT_outputs(@rcsystemT,
                                                self.each_output.map do |sig|
                    sig.to_rcsim(@rcsystemT)
                end)
            end
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


    class Scope
        ## Extends the Scope class for hybrid Ruby-C simulation.

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
            if self.each_inner.any? then
                RCSim.rcsim_add_scope_inners(@rcscope,self.each_inner.map do|sig|
                    # sig.to_rcsim(@rcscope)
                    sig.to_rcsim(subowner)
                end)
            end
            
            # Create and add the system instances.
            if self.each_systemI.any? then
                RCSim.rcsim_add_scope_systemIs(@rcscope,
                                               self.each_systemI.map do |sys|
                    # sys.to_rcsim(@rcscope)
                    sys.to_rcsim(subowner)
                end)
            end

            # Create and add the sub scopes.
            if self.each_scope.any? then
                RCSim.rcsim_add_scope_scopes(@rcscope,self.each_scope.map do|sub|
                    # sub.to_rcsim(@rcscope)
                    sub.to_rcsim(subowner)
                end)
            end

            # Create and add the behaviors and connections.
            rcbehs = self.each_behavior.map {|beh| beh.to_rcsim(subowner)} # +
                # self.each_connection.map {|cxt| cxt.to_rcsim(subowner) }
            self.each_connection do |cnx|
                if !cnx.right.is_a?(RefObject) then
                    rcbehs << cnx.to_rcsim(subowner)
                else
                    # puts "cnx.left.object=#{cnx.left.object.fullname} cnx.right.object=#{cnx.right.object.fullname}"
                    rcbehs << cnx.to_rcsim(subowner)
                    if cnx.left.is_a?(RefObject) then
                        sigL = cnx.left.object
                        prtL = sigL.parent
                        if prtL.is_a?(SystemT) and prtL.each_inout.any?{|e| e.object_id == sigL.object_id} then
                            # puts "write to right with sigL=#{sigL.fullname}."
                            rcbehs << Connection.new(cnx.right.clone,cnx.left.clone).to_rcsim(subowner)
                        end
                    end
                end
            end
            if rcbehs.any? then
                RCSim.rcsim_add_scope_behaviors(@rcscope,rcbehs)
            end

            # Create and add the programs.
            rcprogs = self.each_program.map {|prog| prog.to_rcsim(subowner)} 
            if rcprogs.any? then
                RCSim.rcsim_add_scope_codes(@rcscope,rcprogs);
            end

            return @rcscope
        end
    end



    class Type
        ## Extends the Type class for hybrid Ruby-C simulation.

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

    class TypeDef
        ## Extends the TypeDef class for hybrid Ruby-C simulation.

        # Generate the C description of the type.
        def to_rcsim
            # Create the type C object.
            @rctype = self.def.to_rcsim
            return @rctype
        end
    end

    class TypeVector
        ## Extends the TypeVector class for hybrid Ruby-C simulation.

        # Generate the C description of the type.
        def to_rcsim
            # Create the type C object.
            @rctype = RCSim.rcsim_get_type_vector(self.base.to_rcsim,self.size)
            return @rctype
        end
    end

    class TypeTuple
        ## Extends the TypeTuple class for hybrid Ruby-C simulation.
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


    class TypeStruct
        ## Extends the TypeStruct class for hybrid Ruby-C simulation.

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

        # Add sub leaf events from +sig+ of +type+.
        def add_sub_events(type,sig)
            if sig.each_signal.any? then
                # The event is hierarchical, recurse.
                sig.each_signal do |sub|
                    self.add_sub_events(type,sub)
                end
            else
                # Te event is not hierarchical, add it.
                ref = RefObject.new(this,sig)
                self.add_event(Event.new(type,ref))
            end
        end

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
                # The get the left references: the will be removed from the
                # events.
                left_refs = self.block.each_node_deep.select do |node|
                    node.is_a?(RefObject) && node.leftvalue? && 
                        !node.parent.is_a?(RefObject) 
                end.to_a
                # Keep only one left ref per signal.
                left_refs.uniq! { |node| node.fullname }
                # Remove the left refs.
                left_refs.each do |l| 
                    refs.delete_if {|r| r.fullname == l.fullname }
                end
                # Generate the event.
                events = refs.map {|ref| Event.new(:anyedge,ref.clone) }
                # Add them to the behavior for further processing.
                events.each {|event| self.add_event(event) }
            else
                # Maybe there are event on hierachical signals.
                events.each do |event|
                    if event.ref.object.each_signal.any? then
                        # This is a hierarchical event, remove it.
                        self.delete_event!(event)
                        # And replace it by event of the subs of the signal.
                        self.add_sub_events(event.type,event.ref)
                    end
                end
            end

            # Create the behavior C object.
            # puts "make behavior with self.class=#{self.class}"
            @rcbehavior = RCSim.rcsim_make_behavior(self.is_a?(TimeBehavior))

            # Set the owner.
            RCSim.rcsim_set_owner(@rcbehavior,rcowner)

            # Create and add the events.
            if self.each_event.any? then
                RCSim.rcsim_add_behavior_events(@rcbehavior,
                                                self.each_event.map do |ev|
                    ev.to_rcsim(@rcbehavior)
                end)
            end

            # Create and add the block.
            RCSim.rcsim_set_behavior_block(@rcbehavior,self.block.to_rcsim)

            return @rcbehavior
        end
    end


    class Behavior
        ## Extends the Behavior class for hybrid Ruby-C simulation.
        include RCSimBehavior
    end

    class TimeBehavior
        ## Extends the TimeBehavior class for hybrid Ruby-C simulation.
        include RCSimBehavior
    end


    class Event
        ## Extends the Event class for hybrid Ruby-C simulation.

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


    class SignalI
        ## Extends the SignalI class for hybrid Ruby-C simulation.

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

            # Create and add the sub signals if any.
            RCSim.rcsim_add_signal_signals(@rcsignalI,
                                           self.each_signal.each.map do |sig|
                sig.to_rcsim(@rcsignalI)
            end)

            # Set the initial value if any.
            if self.value then
                RCSim.rcsim_set_signal_value(@rcsignalI,self.value.to_rcsim)
            end

            return @rcsignalI
        end
    end


    class SignalC
        ## Extends the SignalC class for hybrid Ruby-C simulation.

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


    class SystemI
        ## Extends the SystemI class for hybrid Ruby-C simulation.

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


    class Chunk
        ## Extends the Chunk class for hybrid Ruby-C simulation.
        # Deprecated!!
    end

    class Code
        ## Extends the Code class for hybrid Ruby-C simulation.
        # Deprecated!!
    end

    class Program
        ## Extends the Program class for hybrid Ruby-C simulation.
        #  NOTE: produce a low-level Code, and not program. For now,
        #  Program is a high-level interface for software description and
        #  is not ment to be simulated as is. It may hcange in the future 
        #  though.

        attr_reader :rccode # The access to the C version of the code.

        # Generate the C description of the code comming from object
        # whose C description is +rcowner+.
        # NOTE: also update the table of signals accessed from software
        # code.
        def to_rcsim(rcowner)
            # puts "to_rcsim for program=#{self}"

            # Create the code C object.
            # puts "make code with self.class=#{self.class}"
            @rccode = RCSim.rcsim_make_code(self.language.to_s, self.function.to_s)

            # Set the owner.
            RCSim.rcsim_set_owner(@rccode,rcowner)

            # Create and add the events.
            if self.each_actport.any? then
                RCSim.rcsim_add_code_events(@rccode, self.each_actport.map do|ev|
                    ev.to_rcsim(@rccode)
                end)
            end

            # Create the software interface.
            if self.language == :ruby then
                # Loads the code files.
                self.each_code do |code|
                  if code.is_a?(Proc)
                    Object.instance_eval(&code)
                  else
                    Kernel.require("./"+code.to_s)
                  end
                end
                # Add the input ports.
                self.each_inport do |sym, sig|
                    RubyHDL.inport(sym,sig.rcsignalI)
                end
                # Add the output ports.
                self.each_outport do |sym, sig|
                    RubyHDL.outport(sym,sig.rcsignalI)
                end
                # Add the array ports.
                self.each_arrayport do |sym, sig|
                    RubyHDL.arrayport(sym,sig.rcsignalI)
                end
            elsif self.language == :c then
                # Loads the code file: only the last one remains.
                self.each_code do |code|
                    code = code.to_s
                    # Check if the file exists.
                    unless File.file?(code) then
                        # The code name may be not complete, 
                        # try ".so", ".bundle" or ".dll" extensions.
                        if File.file?(code+".so") then
                            code += ".so"
                        elsif File.file?(code + ".bundle") then
                            code += ".bundle"
                        elsif File.file?(code + ".dll") then
                            code += ".dll"
                        else
                            # Code not found.
                            raise "C code library not found: " + code
                        end
                    end
                    RCSim.rcsim_load_c(@rccode,code,self.function.to_s)
                end
                # Add the input ports.
                self.each_inport do |sym, sig|
                    RCSim::CPorts[sym] = sig.rcsignalI
                end
                # Add the output ports.
                self.each_outport do |sym, sig|
                    RCSim::CPorts[sym] = sig.rcsignalI
                end
                # Add the array ports.
                self.each_arrayport do |sym, sig|
                    RCSim::CPorts[sym] = sig.rcsignalI
                end
            end


            return @rccode
        end
    end


    class Statement
        ## Extends the Statement class for hybrid Ruby-C simulation.

        attr_reader :rcstatement

        # Generate the C description of the statement.
        def to_rcsim
            raise "to_rcsim must be implemented in #{self.class}"
        end
    end


    class Transmit
        ## Extends the Transmit class for hybrid Ruby-C simulation.
        attr_reader :rcstatement

        # Generate the C description of the transmit.
        def to_rcsim
            # Create the transmit C object.
            @rcstatement = RCSim.rcsim_make_transmit(self.left.to_rcsim,
                                               self.right.to_rcsim)

            return @rcstatement
        end
    end


    class Print
        ## Extends the Print class for hybrid Ruby-C simulation.
        attr_reader :rcstatement

        # Generate the C description of the print.
        def to_rcsim
            # Create the print C object.
            @rcstatement = RCSim.rcsim_make_print()

            # Adds the arguments.
            if self.each_arg.any? then
                RCSim.rcsim_add_print_args(@rcstatement,
                                           self.each_arg.map(&:to_rcsim))
            end

            return @rcstatement
        end
    end


    class TimeTerminate
        ## Extends the TimeTerminate class for hybrid Ruby-C simulation.
        attr_reader :rcstatement

        # Generate the C description of the terminate.
        def to_rcsim
            # Create the terminate C object.
            @rcstatement = RCSim.rcsim_make_timeTerminate()

            return @rcstatement
        end
    end

    class Configure
        ## Extends the Configure class for hybrid Ruby-C simulation.
        attr_reader :rcstatement
        # TODO!!!
    end

    
    class If
        ## Extends the If class for hybrid Ruby-C simulation.
        attr_reader :rcstatement

        # Generate the C description of the hardware if.
        def to_rcsim
            # Create the hardware if C object.
            @rcstatement = RCSim.rcsim_make_hif(self.condition.to_rcsim,
                                          self.yes.to_rcsim, 
                                          self.no ? self.no.to_rcsim : nil)

            # Add the alternate ifs if any.
            rcsim_conds = self.each_noif.map {|cond,stmnt| cond.to_rcsim }
            rcsim_stmnts = self.each_noif.map {|cond,stmnt| stmnt.to_rcsim }
            if rcsim_conds.any? then
                RCSim.rcsim_add_hif_noifs(@rcstatement,rcsim_conds,rcsim_stmnts)
            end

            return @rcstatement
        end
    end


    class When
        ## Extends the When class for hybrid Ruby-C simulation.
        # Nothing to add.
    end

    class Case
        ## Extends the Case class for hybrid Ruby-C simulation.
        attr_reader :rcstatement

        # Generate the C description of the hardware case.
        def to_rcsim
            # Create the hardware case C object.
            @rcstatement = RCSim.rcsim_make_hcase(self.value.to_rcsim,
                                    self.default ? self.default.to_rcsim : nil)

            # Add the hardware whens.
            rcsim_matches = self.each_when.map {|wh| wh.match.to_rcsim }
            rcsim_stmnts = self.each_when.map {|wh| wh.statement.to_rcsim }
            if rcsim_matches.any? then
                RCSim.rcsim_add_hcase_whens(@rcstatement,rcsim_matches,
                                            rcsim_stmnts)
            end

            return @rcstatement
        end
    end


    class Delay
        ## Extends the Delay class for hybrid Ruby-C simulation.
        # Nothing to do.
    end

    class TimeWait
        ## Extends the TimeWait class for hybrid Ruby-C simulation.
        attr_reader :rcstatement

        # Generate the C description of the time wait.
        def to_rcsim
            # Create the time wait C object.
            @rcstatement = RCSim.rcsim_make_timeWait(self.delay.unit,
                                               self.delay.value.to_i)

            return @rcstatement
        end
    end


    class TimeRepeat
        ## Extends the TimeRepeat class for hybrid Ruby-C simulation.
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
            if self.each_inner.any? then
                RCSim.rcsim_add_block_inners(@rcstatement,
                                             self.each_inner.map do |sig|
                    sig.to_rcsim(@rcstatement)
                end)
            end

            # Add the statements.
            if self.each_statement.any? then
                RCSim.rcsim_add_block_statements(@rcstatement,
                                            self.each_statement.map do |stmnt|
                    stmnt.to_rcsim
                end)
            end

            return @rcstatement
        end
    end

    class Block
        ## Extends the Block class for hybrid Ruby-C simulation.
        include RCSimBlock
    end

    class TimeBlock
        ## Extends the TimeBlock class for hybrid Ruby-C simulation.
        include RCSimBlock
    end


    class Connection
        ## Extends the Connection class for hybrid Ruby-C simulation.
        attr_reader :rcbehavior

        # Add recursively any event to +rcevs+ for activativing the 
        # connection from signal +sig+ attached to +rcbehavior+
        def self.add_rcevents(sig,rcevs,rcbehavior)
            # puts "add_rcevents for sig=#{sig.fullname}"
            # Recurse on sub signals if any.
            sig.each_signal do |sub|
                Connection.add_rcevents(sub,rcevs,rcbehavior)
            end
            # Apply on the current node.
            rcsig = sig.is_a?(SignalI) ? sig.rcsignalI : sig.rcsignalC
            ev = RCSim.rcsim_make_event(:anyedge,rcsig)
            RCSim.rcsim_set_owner(ev,rcbehavior)
            rcevs << ev
        end

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
                    Connection.add_rcevents(node.object,rcevs,@rcbehavior)
                    # ev = RCSim.rcsim_make_event(:anyedge,node.to_rcsim)
                    # RCSim.rcsim_set_owner(ev,@rcbehavior)
                    # rcevs << ev
                end
            end
            if rcevs.any? then
                RCSim.rcsim_add_behavior_events(@rcbehavior,rcevs)
            end

            # Create and set the block.
            rcblock = RCSim.rcsim_make_block(:par)
            RCSim.rcsim_set_owner(rcblock,@rcbehavior)
            # puts "self.left=#{self.left} self.right=#{self.right}"
            RCSim.rcsim_add_block_statements(rcblock,
                [RCSim.rcsim_make_transmit(self.left.to_rcsim, self.right.to_rcsim)])
            RCSim.rcsim_set_behavior_block(@rcbehavior,rcblock)

            return @rcbehavior
        end
    end


    class Expression
        ## Extends the Expression class for hybrid Ruby-C simulation.

        # attr_reader :rcexpression

        # Generate the C description of the expression.
        def to_rcsim
            raise "to_rcsim must be implemented in #{self.class}"
        end
    end


    class Value
        ## Extends the Value class for hybrid Ruby-C simulation.
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

    class StringE
        ## Extends the StringE class for hybrid Ruby-C simulation.

        # Generate the C description of the value.
        def to_rcsim
            # Create the value C object.
            return RCSim.rcsim_make_stringE(self.content);
        end
    end


    class Cast
        ## Extends the Cast class for hybrid Ruby-C simulation.
        # attr_reader :rcexpression

        # Generate the C description of the cast.
        def to_rcsim
          # puts "Cast to width=#{self.type.width} and child=#{self.child} and child.to_rcsim=#{child.to_rcsim}"
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


    class Operation
        ## Extends the Operation class for hybrid Ruby-C simulation.
        # Nothing to do.
    end

    class Unary
        ## Extends the Unary class for hybrid Ruby-C simulation.
        attr_reader :rcexpression

        # Generate the C description of the unary operation.
        def to_rcsim
            # Create the unary C object.
            return RCSim.rcsim_make_unary(self.type.to_rcsim,self.operator,
                                    self.child.to_rcsim)
        end
    end

    class Binary
        ## Extends the Binary class for hybrid Ruby-C simulation.
        # attr_reader :rcexpression

        # Generate the C description of the binary operation.
        def to_rcsim
            # Create the binary C object.
            return RCSim.rcsim_make_binary(self.type.to_rcsim,self.operator,
                                     self.left.to_rcsim,
                                     self.right.to_rcsim)
        end
    end


    class Select
        ## Extends the Select class for hybrid Ruby-C simulation.
        # attr_reader :rcexpression

        # Generate the C description of the select operation.
        def to_rcsim
            # Create the select C object.
            rcexpression = RCSim.rcsim_make_select(self.type.to_rcsim,
                                              self.select.to_rcsim)

            # Add the choice expressions. */
            if self.each_choice.any? then
                RCSim.rcsim_add_select_choices(rcexpression,
                                               self.each_choice.map(&:to_rcsim))
            end
            
            return rcexpression
        end
    end


    class Concat
        ## Extends the Concat class for hybrid Ruby-C simulation.
        # attr_reader :rcexpression

        # Generate the C description of the concat operation.
        def to_rcsim
            # Create the concat C object.
            rcexpression = RCSim.rcsim_make_concat(self.type.to_rcsim,
                                             self.type.direction)

            # Add the concatenated expressions. */
            if self.each_expression.any? then
                RCSim.rcsim_add_concat_expressions(rcexpression,
                                         self.each_expression.map(&:to_rcsim))
            end
            
            return rcexpression
        end
    end



    class Ref
        ## Extends the Ref class for hybrid Ruby-C simulation.
        # attr_reader :rcref
        # alias_method :rcexpression, :rcref

        # Generate the C description of the reference.
        def to_rcsim
            raise "to_rcsim must be implemented in #{self.class}"
        end
    end


    class RefConcat
        ## Extends the RefConcat class for hybrid Ruby-C simulation.
        # attr_reader :rcref
        # alias_method :rcexpression, :rcref

        # Generate the C description of the reference concat.
        def to_rcsim
            # Create the reference concat C object.
            rcref = RCSim.rcsim_make_refConcat(self.type.to_rcsim,
                                         self.type.direction)

            # Add the concatenated expressions. */
            if self.each_ref.any? then
                RCSim.rcsim_add_refConcat_refs(rcref,self.each_ref.map(&:to_rcsim))
            end
            
            return rcref
        end
    end


    class RefIndex
        ## Extends the RefIndex class for hybrid Ruby-C simulation.
        # attr_reader :rcref
        # alias_method :rcexpression, :rcref

        # Generate the C description of the reference index.
        def to_rcsim
            # Create the reference index C object.
            return RCSim.rcsim_make_refIndex(self.type.to_rcsim,
                                       self.index.to_rcsim,self.ref.to_rcsim)
        end
    end


    class RefRange
        ## Extends the RefRange class for hybrid Ruby-C simulation.
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


    class RefName
        ## Extends the RefName class for hybrid Ruby-C simulation.
        # Converted to RefRange.

        # Generate the C description of the reference range (not ref name!).
        def to_rcsim
            # Convert the base to a bit vector.
            type_base = Bit[self.ref.type.width]
            # self.ref.parent = nil
            # bit_base = Cast.new(type_base,self.ref)
            bit_base = RCSim.rcsim_make_cast(type_base.to_rcsim,self.ref.to_rcsim)
            # Compute range in bits of the field.
            last = 0
            self.ref.type.each.detect do |name,typ|
                last += typ.width
                name == self.name
            end
            first = last-self.type.width
            last -= 1
            # puts "name=#{self.name} first=#{first} last=#{last}"
            type_int = Bit[type_base.width.width]
            return RCSim.rcsim_make_refRange(self.type.to_rcsim,
                                             Value.new(type_int,last).to_rcsim,
                                             Value.new(type_int,first).to_rcsim,
                                             bit_base)
        end
    end


    class RefThis 
        ## Extends the RefThis class for hybrid Ruby-C simulation.
        # attr_reader :rcref
        # alias_method :rcexpression, :rcref

        # Generate the C description of the reference range.
        def to_rcsim
            return nil
        end
    end


    class RefObject
        ## Extends the RefObject class for hybrid Ruby-C simulation.
        # attr_reader :rcref
        # alias_method :rcexpression, :rcref
        
        # Generate the C description of the reference object with sub signals.
        def to_rcsim_subs
            # Create the reference concat C object.
            # The reference is always big endian, it is the sequence
            # of element which is reversed if necessary.
            rcref = RCSim.rcsim_make_refConcat(self.type.to_rcsim,:big)
                                         # self.type.direction)

            # Add the concatenated expressions. */
            if self.object.each_signal.any? then
                iter = self.object.each_signal
                iter = iter.reverse_each if self.type.direction == :big
                RCSim.rcsim_add_refConcat_refs(rcref, iter.map do|sig|
                    sig.is_a?(SignalI) ? sig.rcsignalI : sig.rcsignalC
                end)
            end
            
            return rcref
        end

        # Generate the C description of the reference object.
        def to_rcsim
            # puts "object=#{self.object.name}(#{self.object})"
            if self.object.is_a?(SignalI)
                return self.object.each_signal.any? ? self.to_rcsim_subs :
                    self.object.rcsignalI
            elsif self.object.is_a?(SignalC)
                return self.object.each_signal.any? ? self.to_rcsim_subs :
                    self.object.rcsignalC
            else
                raise "Invalid object: #{self.object}"
            end
        end
    end


end
