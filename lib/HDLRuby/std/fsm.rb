module HDLRuby::High::Std

    ##
    # Standard HDLRuby::High library: fsm
    # 
    ########################################################################


    ## 
    # Describes a high-level fsm type.
    class FsmT
        include HDLRuby::High::HScope_missing

        # The state class
        class State
            attr_accessor :value, :name, :code
        end

        # The name of the FSM type.
        attr_reader :name

        # The namespace associated with the FSM
        attr_reader :namespace

        # The current and next state signals.
        attr_accessor :cur_state, :next_state

        # Creates a new fsm type with +name+.
        #
        def initialize(name)
            # Check and set the name
            @name = name.to_sym

            # Initialize the internals of the FSM.


            # Initialize the environment for building the FSM

            # The states
            @states = []

            # The current and next state signals
            @cur_state = nil
            @next_state = nil

            # The event synchronizing the fsm
            @mk_ev = proc { $clk.posedge }

            # The reset
            @mk_rst = proc { $rst }

            # Creates the namespace to execute the fsm block in.
            @namespace = Namespace.new(self)

            # Generates the function for setting up the fsm
            # provided there is a name.
            obj = self # For using the right self within the proc
            HDLRuby::High.space_reg(@name) do |&ruby_block|
                if ruby_block then
                    # Builds the fsm.
                    obj.build(&ruby_block)
                else
                    # Return the fsm as is.
                    return obj
                end
            end unless name.empty?

        end

        ## builds the fsm by executing +ruby_block+.
        def build(&ruby_block)
            # Use local variable for accessing the attribute since they will
            # be hidden when opening the sytem.
            states = @states
            namespace = @namespace
            this = self
            mk_ev = @mk_ev
            mk_rst = @mk_rst

            return_value = nil

            # Enters the current system
            HDLRuby::High.cur_system.open do
                sub do
                    HDLRuby::High.space_push(namespace)
                    # Execute the instantiation block
                    return_value =HDLRuby::High.top_user.instance_exec(&ruby_block)
                    # HDLRuby::High.space_pop

                    # Create the state register.
                    name = HDLRuby.uniq_name
                    # Declare the state register.
                    this.cur_state = [states.size].inner(name)
                    # Declare the next state wire.
                    name = HDLRuby.uniq_name
                    this.next_state = [states.size].inner(name)

                    # Create the fsm code
                    # Control part: update of the state.
                    par(mk_ev.call) { this.cur_state <= this.next_state }
                    # Operative part: one case per state.
                    hcase(this.cur_state)
                    states.each do |st|
                        hwhen(st.value) do
                            # Prepare the default next state.
                            this.next_state <= mux(mk_rst.call , 0, this.cur_state + 1)
                            # Generate the content of the state.
                            st.code.call
                        end
                    end
                    HDLRuby::High.space_pop
                end
            end

            return return_value
        end

        ## The interface for building the fsm

        # Sets the event synchronizing the fsm.
        def for_event(event = nil,&ruby_block)
            if event then
                # An event is passed as argument, use it.
                @mk_ev = proc { event.to_event }
            else
                # No event given, use the ruby_block as event generator.
                @mk_ev = ruby_block
            end
        end

        # Sets the reset.
        def for_reset(reset = nil,&ruby_block)
            if reset then
                # An reset is passed as argument, use it.
                @mk_rst = proc { reset.to_expr }
            else
                # No reset given, use the ruby_block as event generator.
                @mk_rst = ruby_block
            end
        end


        # Declare a new state with +name+ and executing +ruby_block+.
        def state(name = :"", &ruby_block)
            # Create the resulting state
            result = State.new
            # Its value is the current number of states
            result.value = @states.size
            result.name = name.to_sym
            result.code = ruby_block
            # Add it to the list of states.
            @states << result
            # Return it.
            return result
        end

        # Set the next state. Arguments can be:
        #
        # +name+: the name of the next state.
        # +expr+, +names+: an expression with the list of the next statements
        #                  in order of the value of the expression, the last
        #                  one being necesserily the default case.
        def goto(*args)
            # Make reference to the fsm attributes.
            next_state = @next_state
            states = @states
            # Depending on the first argument type.
            unless args[0].is_a?(Symbol) then
                # expr + names arguments.
                hcase (args.shift)
                args[0..-2].each.with_index do |arg,i|
                    # Ensure the argument is a symbol.
                    arg = arg.to_sym
                    # Make the when statement.
                    hwhen(i) do
                        next_state <= 
                            (states.detect { |st| st.name == arg }).value
                    end
                end
                # The last name is the default case.
                # Ensure it is a symbol.
                arg = args[-1].to_sym
                # Make the default statement.
                helse do
                    next_state <= 
                        (states.detect { |st| st.name == arg }).value
                end
            else
                # single name argument, check it.
                raise AnyError, "Invalid argument for a goto: if no expression is given only a single name can be used." if args.size > 1
                # Ensure the name is a symbol.
                name = args[0].to_sym
                # Get the state with name.
                next_state <= (states.detect { |st| st.name == name }).value
            end
        end

    end


    ## Declare a new fsm.
    #  The arguments can be any of (but in this order):
    #
    #  - +name+:: name.
    #  - +clk+:: clock.
    #  - +event+:: clock event.
    #  - +rst+:: reset. (must be declared AFTER clock or clock event).
    #
    #  If provided, +ruby_block+ the fsm is directly instantiated with it.
    def fsm(*args, &ruby_block)
        # Sets the name if any
        unless args[0].respond_to?(:to_event) then
            name = args.shift.to_sym
        else
            name = :""
        end
        # Create the fsm.
        fsmI = FsmT.new(name)
        
        # Process the clock event if any.
        unless args.empty? then
            fsmI.for_event(args.shift)
        end
        # Process the reset if any.
        unless args.empty? then
            fsmI.for_reset(args.shift)
        end
        # Is there a ruby block?
        if ruby_block then
            # Yes, generate the fsm.
            fsmI.build(&ruby_block)
        else
            # No return the fsm structure for later generation.
            return fsmI
        end
    end

end
