module HDLRuby::High::Std

    ##
    # Standard HDLRuby::High library: fsm generator.
    # 
    ########################################################################


    ## 
    # Describes a high-level fsm type.
    class FsmT
        include HDLRuby::High::HScope_missing

        # The state class
        class State
            attr_accessor :value, :name, :code, :gotos
        end

        # The name of the FSM type.
        attr_reader :name

        # The namespace associated with the FSM
        attr_reader :namespace

        # The reset codes for the synchronous and the asynchronous operative
        # parts of the fsm
        attr_reader :reset_sync, :reset_async

        # The current and next state signals.
        attr_accessor :cur_state_sig, :next_state_sig, :work_state

        # Creates a new fsm type with +name+.
        # +options+ allows to specify the type of fsm:
        # synchronous (default) / asynchronous and
        # mono-front(default) / dual front
        def initialize(name,*options)
            # Check and set the name
            @name = name.to_sym
            # Check and set the type of fsm depending of the options.
            @dual = false
            @type = :sync
            options.each do |opt|
                case opt
                when :sync,:synchronous then
                    @type = :sync
                when :async, :asynchronous then
                    @type = :async
                when :dual then
                    @dual = true
                else
                    raise AnyError, "Invalid option for a fsm: :#{type}"
                end
            end

            # Initialize the internals of the FSM.


            # Initialize the environment for building the FSM

            # The main states.
            @states = []

            # The extra synchronous states.
            @extra_syncs = []
            # The extra asynchronous states.
            @extra_asyncs = []

            # The default code of the operative part.
            @default_codes = []

            # The current and next state signals
            @cur_state_sig = nil
            @next_state_sig = nil

            # The event synchronizing the fsm
            @mk_ev = proc { $clk.posedge }

            # The reset check.
            @mk_rst = proc { $rst }

            # The code executed in case of reset.
            # (By default, nothing).
            @reset_sync  = nil
            @reset_async = nil

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
            this   = self
            mk_ev  = @mk_ev
            mk_rst = @mk_rst
            type = @type
            dual = @dual
            extra_syncs   = @extra_syncs
            extra_asyncs  = @extra_asyncs
            default_codes = @default_codes

            return_value = nil

            # Enters the current system
            HDLRuby::High.cur_system.open do
                # sub do
                    HDLRuby::High.space_push(namespace)
                    # Execute the instantiation block
                    return_value = HDLRuby::High.top_user.instance_exec(&ruby_block)

                    # Expands the extra state processing so that al all the
                    # parts of the state machine are in par (clear synthesis).
                    [extra_syncs,extra_asyncs].each do |extras|
                        # Set the values of the extra states from their name.
                        extras.each do |extra|
                            st = states.find {|st| st.name == extra.name }
                            unless st then
                                raise "Unknown state name: #{extra.name}"
                            end
                            extra.value = st.value
                        end
                        # Fills the holes in the extra syncs and asyncs.
                        if extras.any? then
                            # Sort by value in a new array using counter sort.
                            results = [ nil ] * states.size
                            extras.each {|st| results[st.value] = st }
                            # Fill the whole with empty states.
                            results.map!.with_index do |st,i| 
                                unless st then
                                    st = State.new
                                    st.value = i
                                    st.code = proc {}
                                end
                                st
                            end
                            # Replace the content of extras
                            extras.clear
                            results.each {|st| extras << st }
                        end
                    end

                    # Create the state register.
                    name = HDLRuby.uniq_name
                    # Declare the state register.
                    this.cur_state_sig = [states.size.width].inner(name)
                    # Declare the next state wire.
                    name = HDLRuby.uniq_name
                    this.next_state_sig = [states.size.width].inner(name)

                    # Create the fsm code

                    # Control part: update of the state.
                    par(mk_ev.call) do
                        hif(mk_rst.call) do
                            # Reset: current state is to put to 0.
                            this.cur_state_sig <= 0
                        end
                        helse do
                            # No reset: current state is updated with
                            # next state value.
                            this.cur_state_sig <= this.next_state_sig
                        end
                    end

                    # Operative main-part: one case per state.
                    # (clock-dependent if synchronous mode).
                    if type == :sync then
                        # Synchronous case.
                        event = mk_ev.call
                        event = event.invert if dual
                    else
                        # Asynchronous case: no event required.
                        event = []
                    end
                    # The process
                    par(*event) do
                        # The operative code.
                        oper_code =  proc do
                            # The default code.
                            default_codes.each(&:call)
                            # Depending on the state.
                            hcase(this.cur_state_sig)
                            states.each do |st|
                                # Register the working state (for the gotos)
                                this.work_state = st
                                hwhen(st.value) do
                                    # Generate the content of the state.
                                    st.code.call
                                end
                            end
                        end
                        # Is there reset code?
                        if type == :sync and this.reset_sync then
                            # Yes in case of synchronous fsm,
                            # use it before the operative code.
                            hif(mk_rst.call) do
                                this.reset_sync.call
                            end
                            helse(&oper_code)
                        elsif type == :async and this.reset_async then
                            # Yes in case of asynchronous fsm,
                            # use it before the operative code.
                            hif(mk_rst.call) do
                                this.reset_async.call
                            end
                            helse(&oper_code)
                        else
                            # Use only the operative code.
                            oper_code.call
                        end
                    end

                    # Control part: computation of the next state.
                    # (clock-independent)
                    hcase(this.cur_state_sig)
                    states.each do |st|
                        hwhen(st.value) do
                            if st.gotos.any? then
                                # Gotos were present, use them.
                                st.gotos.each(&:call)
                            else
                                # No gotos, by default the next step is
                                # current + 1
                                # this.next_state_sig <= mux(mk_rst.call , 0, this.cur_state_sig + 1)
                                this.next_state_sig <=  this.cur_state_sig + 1
                            end
                        end
                    end
                    # By default set the next state to 0.
                    helse do
                        this.next_state_sig <= 0
                    end

                    # Operative additional parts.
                    # Extra synchronous operative part.
                    if extra_syncs.any? then
                        event = mk_ev.call
                        event = event.invert if @dual
                        # The extra code.
                        par(*event) do
                            # Build the extra synchronous part.
                            sync_code = proc do
                                hcase(this.cur_state_sig)
                                extra_syncs.each do |st|
                                    hwhen(st.value) do
                                        # Generate the content of the state.
                                        st.code.call
                                    end
                                end
                            end
                            # Place it.
                            if this.reset_sync then
                                # There some synchronous reset code, use
                                # it.
                                hif(mk_rst.call) do
                                    this.reset_sync.call
                                end
                                helse(&sync_code)
                            else
                                # No syncrhonous code, place the extra
                                # synchronous states as is.
                                sync_code.call
                            end
                        end
                    end

                    # Extra asynchronous operative part.
                    if extra_asyncs.any? then
                        par do
                            # Build the extra synchronous part.
                            async_code = proc do
                                hcase(this.cur_state_sig)
                                extra_asyncs.each do |st|
                                    hwhen(st.value) do
                                        # Generate the content of the state.
                                        st.code.call
                                    end
                                end
                            end
                            # Place it with possible reset.
                            if this.reset_async then
                                # There some synchronous reset code, use
                                # it.
                                hif(mk_rst.call) do
                                    this.reset_async.call
                                end
                                helse(&sync_code)
                            else
                                # No syncrhonous code, place the extra
                                # synchronous states as is.
                                sync_code.call
                            end
                        end
                    end

                    HDLRuby::High.space_pop
                # end
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

        # Adds a code to be executed in case of reset.
        # +type+ indicates if it is the synchronous part or the
        # asynchronous part that is to reset.
        def reset(type = @type,&ruby_block)
            if type == :sync or type == :synchronous then
                # Reset of the synchronous part.
                if @reset_sync then 
                    raise AnyError.new("Reset of the synchronous part already declared.")
                end
                @reset_sync = ruby_block
            elsif type == :async or type == :asynchronous then
                # Reset if the asynchronous part.
                if @reset_async then
                    raise AnyError.new("Reset of the asynchronosu part already declared.")
                end
            else
                raise AnyError.new("Invalid fsm type for declaring a reset code: #{type}")
            end
        end

        # Adds a default operative code.
        def default(&ruby_block)
            @default_codes << ruby_block
        end

        # Declares a new state with +name+ and executing +ruby_block+.
        def state(name = :"", &ruby_block)
            # Create the resulting state
            result = State.new
            # Its value is the current number of states
            result.value = @states.size
            result.name = name.to_sym
            result.code = ruby_block
            result.gotos = []
            # Add it to the list of states.
            @states << result
            # Return it.
            return result
        end

        # Declares an extra synchronous code to execute for state +name+.
        def sync(name, &ruby_block)
            # Create the resulting state.
            result = State.new
            result.name = name.to_sym
            result.code = ruby_block
            # Add it to the lis of extra synchronous states.
            @extra_syncs << result
            # Return it
            return result
        end

        # Declares an extra asynchronous code to execute for state +name+.
        def async(name, &ruby_block)
            # Create the resulting state.
            result = State.new
            result.name = name.to_sym
            result.code = ruby_block
            # Add it to the lis of extra synchronous states.
            @extra_asyncs << result
            # Return it
            return result
        end

        # Sets the next state. Arguments can be:
        #
        # +name+: the name of the next state.
        # +expr+, +names+: an expression with the list of the next statements
        #                  in order of the value of the expression, the last
        #                  one being necesserily the default case.
        def goto(*args)
            # Make reference to the fsm attributes.
            next_state_sig = @next_state_sig
            states = @states
            # Add the code of the goto to the working state.
            @work_state.gotos << proc do
                # Depending on the first argument type.
                unless args[0].is_a?(Symbol) then
                    # expr + names arguments.
                    # Get the predicate
                    pred = args.shift
                    # hif or hcase?
                    if args.size <= 2 then
                        # 2 or less cases, generate an hif
                        arg = args.shift
                        hif(pred) do
                            next_state_sig <=
                                (states.detect { |st| st.name == arg }).value
                        end
                        arg = args.shift
                        if arg then
                            # There is an else.
                            helse do
                                next_state_sig <=
                                (states.detect { |st| st.name == arg }).value
                            end
                        end
                    else
                        # More than 2, generate a hcase
                        hcase (pred)
                        args[0..-2].each.with_index do |arg,i|
                            # Ensure the argument is a symbol.
                            arg = arg.to_sym
                            # Make the when statement.
                            hwhen(i) do
                                next_state_sig <= 
                                (states.detect { |st| st.name == arg }).value
                            end
                        end
                        # The last name is the default case.
                        # Ensure it is a symbol.
                        arg = args[-1].to_sym
                        # Make the default statement.
                        helse do
                            next_state_sig <= 
                                (states.detect { |st| st.name == arg }).value
                        end
                    end
                else
                    # single name argument, check it.
                    raise AnyError, "Invalid argument for a goto: if no expression is given only a single name can be used." if args.size > 1
                    # Ensure the name is a symbol.
                    name = args[0].to_sym
                    # Get the state with name.
                    next_state_sig <= (states.detect { |st| st.name == name }).value
                end
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
        # Get the options from the arguments.
        options, args = args.partition {|arg| arg.is_a?(Symbol) }
        # Create the fsm.
        fsmI = FsmT.new(name,*options)
        
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
