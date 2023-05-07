require 'std/sequencer'

module HDLRuby::High::Std

    ##
    # Standard HDLRuby::High library: sequencer function generator.
    # The idea is to be able to write sw-like sequential code.
    # 
    ########################################################################
    


    # Describes a sequencer function definition.
    #
    # NOTE: like with ruby, functions does not have types for their arguments,
    #       their are set when the function is called.
    #       This is handle by the eigen functions (see SequencerFunctionE).
    class SequencerFunctionT
        # The name of the function.
        attr_reader :name

        # Creates a new sequencer function named +name+, with stack size +depth+
        # executing code given by +ruby_block+.
        #
        # NOTE: if +depth+ is nil it will be automatically computed at call time.
        def initialize(name, depth = nil, &ruby_block)
            @name = name.to_sym
            @body = ruby_block
            @depth = depth ? depth.to_i : nil
        end

        # Call the function with arguments +args+.
        def call(*args)
            # Specialize the function with the types of the arguments.
            # (the result is the eigen function of funcI).
            funcE = SequencerFunctionE.new(self, args.map {|arg| arg.type })
            # Check if it is a recursion.
            funcI = SequencerFunctionI.recursion(funcE)
            if funcI then
                # Recursion, set the size of the stack.
                funcI.make_depth(@depth)
                # Call the function.
                funcI.call(*args)
            else
                # No recursion, create an instance of the function
                funcI = SequencerFunctionI.new(funcE)
                # Call the function.
                funcI.call(*args)
                # Build the function... Indeed after the call, that
                # allows to avoid one state.
                funcI.build
            end
            # Return the created funcI
            return funcI
        end
    end

    # Describes a sequencer eigen function.
    # Here, an eigen function is a function definition specilized with
    # arguments types.
    class SequencerFunctionE

        ## Creates a new eigen function with function type +funcT+ and arguments
        #  types +argTs+.
        def initialize(funcT, argTs)
            @funcT = funcT
            @argTs = argTs.to_a
        end

        ## Gets the name of the function.
        def name
            @funcT.name
        end

        ## Gets the body of the function.
        def body
            @funcT.body
        end

        # Iterates over the argument types.
        #
        # Returns an enumerator if no ruby block is given.
        def each_argT(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_argT) unless ruby_block
            # A ruby block? Apply it on each agument type.
            @argTs.each(&ruby_block)
        end

        # Comparison of eigen functions.
        def ==(obj)
            # Is obj an eigen function?
            return false unless obj.is_a?(SequencerFunctionE)
            # Has obj the same function type?
            return false unless self.funcT == obj.funcT
            # Has obj the same argument types?
            return obj.each_argT.zip(self.each_argT).all? {|t0,t1| t0 == t1 }
        end
    end


    # Describes a sequencer function instance.
    class SequencerFunctionI
        @@current = [] # The stack of current function instance.

        # Get the function instance currently processing.
        def self.current
            @@current[-1]
        end

        # The eigen function.
        attr_reader :funcE

        # Creates a new instance of function from +funcE+ eigen function,
        # and possible default stack depth +depth+.
        def initialize(funcE)
            # Sets the eigen function.
            @funcE = funcE
            # Initialize the depth.
            # At first, no recursion is assumed, hence the depth is 1.
            @depth = 1
            # Create the table of signal stacks (by name).
            # For further updating.
            @stack_sigs = [] # Signal stacks
            # Signal stacks pointer.
            @stack_ptr  =  HDLRuby::High.cur_system.make_inners(
                bit[@depth].width, HDLRuby.uniq_name(:stack_ptr) => 0)
            # Create the stack for the returns.
            @returnIdx = self.make_stack(bit[SequencerT.current.size.width])
            # And the return values, however, at first their type is unknown
            # to set it as a simple bit.
            # The type of the return value is built when calling make_return.
            @returnValIdx = self.make_stack(bit)
            # Create the stacks for the arguments.
            @funcE.each_argT { |argT| self.make_stack(argT) }
            @argsIdx = @returnIdx + 2
            
            # Initialize the state where the initial function call will be.
            @state = nil
        end
        
        ## Give access to the return value.
        #
        #  NOTE: is automatically called when within an expression.
        def to_expr
            return self.return_value
        end

        # There is actually recurse, compute the depth: if +depth+ is given
        # as argument, this is the depth, otherwise compute it from the
        # bit width of the argument.
        #
        # NOTE: uses the heuristic that the depth is more or less equal to the 
        #       bit width of the largest argument type.
        def make_depth(depth)
            if depth then
                @depth = depth
            else
                # There is no default depth, use the heuristic that the
                # depth is more or less equal to the bit width of the
                # largest argument type.
                @depth = @argTs.max { |t0,t1| t0.width <=> t1.width }
            end
            # Resize the stackes according to the depth.
            @stack_sigs.each do |sig|
                sig.type.instance_variable_set(:@range,0..@depth-1)
            end
            @stack_ptr.type.instance_variable_set(:@range,@depth.width-1..0)
        end



        # Builds the code of the function.
        def build
            # Saves the current function to detect recursion.
            @@current.push(self)

            # Get the body.
            body = @funcE.body

            # Create a state starting the function.
            SequencerT.current.step

            # Get the arguments.
            args = (@argsIdx...(argsIdx+body.arity)).map {|idx| self.peek(idx) }
            # Place the body.
            self.return_value <= body.call(*args)
            # Get the return state.
            ret_state_value = self.peek(@returnIdx)
            # Free the stack of current frame.
            self.pop_all

            # Create a state for returning.
            self.make_return

            # The function is built, remove it from recursion detection..
            @@current.pop
        end

        # Call the function with arguments +args+.
        def call(*args)
            # Crate a state for the call.
            call_state = step

            # Push a new frame.
            self.push_all

            # Adds the arguments and the return state to the current stack frame.
            args.each_with_index { |arg,i| self.poke(@argsIdx + i,arg) }
            self.poke(@returnIdx,call_state.value + 1)

            # Get the state value of the function: it is the state
            # following the first function call.
            func_state_value = @state ? @state.value + 1 : call_state + 1
            # Do the call.
            call_state.gotos << proc do
                HDLRuby::High.top_user.instance_exec do
                    next_state_sig <= func_state_value
                end
            end

            # Sets the state of the first function call if not set.
            @state = call_state unless @state

            # Returns.
            return self.return_value
        end


        # Methods for handling the recursions and stacks.


        ## Check if the current function call with eigen +funcE+ would be
        #  recursive or not.
        def recursion(funcE)
            return @@current.find {|funcI| funcI.funcE == funcE }
        end

        ## Create a stack for elements of types +typ+.
        def make_stack(typ)
            # Create the signal array representing the stack.
            stack_sig = HDLRuby::High.cur_system.make_inners(typ[-depth],
                                      HDLRuby.uniq_name("#{@funcE.name}_stack")
            # Add it to the list of stacks to handle.
            @stack_sigs = [stack_sig]
        end

        ## Pushes a new frame to the top of the stacks.
        def push_all
            @stack_ptr <= @stack_ptr + 1
        end

        ## Remove the top frame from the stacks.
        def pop_all
            @stack_ptr <= @stack_ptr -1
        end

        ## Get a value from the top of stack number +idx+
        def peek(idx)
            return @stack_sigs[idx][@stack_ptr]
        end

        ## Sets value +val+ to the top of stack number +idx+.
        def poke(idx,val)
            @stack_sigs[idx][@stack_ptr] <= val
        end

        ## Access the return value signal.
        def return_value
            return @stack_sigs[@returnValIdx][@stack_ptr]
        end

        ## Creates a return point with value +val+.
        #
        #  NOTE: when val is nil, no return value is provided.
        def make_return(val = nil)
            # Update the type of the return value.
            self.return_value.instance_variable_set(:@type,
                                    self.return_value.type.resolve(val.type))
            # Sets the return value if any.
            self.return_value <= val if val
            # Create the state for returning.
            state = SequencerT.current.state
            # Return.
            state.gotos << proc do
                HDLRuby::High.top_user.instance_exec do
                    next_state_sig <= ret_state_value
                end
            end
            return self.return_value
        end
    end




    ## Remplement make_inners of block to support declaration within function.


    class HDLRuby::High::Block
        alias_method :old_make_inners, :make_inners

        def make_inners(typ,*names)
            if SequencerFunctionI.current.any? then
                unames = names.map {|name| HDLRuby.uniq_name(name) }
                HDLRuby::High.cur_scope.make_inners(typ, *unames)
                names.zip(unames).each do |name,uname|
                    HDLRuby::High.space_reg(name) { send(uname) }
                end
            else
                self.old_make_inners(typ,*names)
            end
        end
    end




    # Declares a sequencer function named +name+ using +ruby_block+ as body.
    # You can specify a stack depth with +depth+ argument.
    def sdef(name, depth=nil, &ruby_block)
        # Create the function.
        funcT = SequencerFunctionT.new(name,depth,&ruby_block)
        # Register it for calling.
        HDLRuby::High.space_reg(name) do |*args| 
            funcT.call(*arg)
        end
        # Return the create function.
        funcT
    end

    # Returns value +val+ from a sequencer function.
    def sreturn(val)
        # Get the top function.
        funcI = SequencerFunctionI.current[-1]
        unless funcI then
            raise "Cannot return since outside a function."
        end
        # Applies the return on it.
        funcI.make_return(val)
    end

end
