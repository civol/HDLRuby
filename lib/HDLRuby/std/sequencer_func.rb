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

        # The body of the function.
        attr_reader :body

        # The stack overflow code of the function if any.
        attr_reader :overflow

        # Creates a new sequencer function named +name+, with stack size +depth+
        # executing code given by +ruby_block+. Additionaly a HDLRuby block
        # +overflow+ can be added to be executed when a stack overflow occured.
        #
        # NOTE: if +depth+ is nil it will be automatically computed at call time.
        def initialize(name, depth = nil, overflow = nil, &ruby_block)
            @name = name.to_sym
            @body = ruby_block
            @depth = depth ? depth.to_i : nil
            @overflow = overflow ? overflow.to_proc : nil
        end

        # Call the function with arguments +args+.
        def call(*args)
            # Specialize the function with the types of the arguments.
            # (the result is the eigen function of funcI).
            funcE = SequencerFunctionE.new(self, args.map {|arg| arg.type })
            # Check if it is a recursion.
            funcI = SequencerFunctionI.recursion(funcE)
            if funcI then
                # puts "Recursive call"
                # Recursion, set the size of the stack.
                funcI.make_depth(@depth)
                # Call the function.
                st_call = funcI.recurse_call(*args)
                # adds the return address.
                depth = funcI.depth
                stack_ptr = funcI.stack_ptr
                # st_call.gotos << proc do
                old_code = st_call.code
                st_call.code = proc do
                    old_code.call
                    HDLRuby::High.top_user.instance_exec do
                        # hprint("returning with stack_ptr=",stack_ptr,"\n")
                        hif(stack_ptr <= depth) do
                            # hprint("poking recursive return value at idx=",funcI.returnIdx," with value=",st_call.value+1,"\n")
                            funcI.poke(funcI.returnIdx,st_call.value + 1)
                        end
                    end
                end
            else
                # puts "First call"
                # No recursion, create an instance of the function
                funcI = SequencerFunctionI.new(funcE)
                # Call the function.
                st_call = funcI.first_call(*args)
                # Build the function... Indeed after the call, that
                # allows to avoid one state.
                st_func = funcI.build
                # adds the return value.
                # st_call.gotos << proc do
                old_code = st_call.code
                st_call.code = proc do
                    old_code.call
                    HDLRuby::High.top_user.instance_exec do
                        # hprint("poking return value at idx=",funcI.returnIdx," with value=",st_func.value+1,"\n")
                        funcI.poke(funcI.returnIdx,st_func.value + 1)
                    end
                end
            end
            # Return the created funcI return value.
            return funcI.return_value
        end
    end

    # Describes a sequencer eigen function.
    # Here, an eigen function is a function definition specilized with
    # arguments types.
    class SequencerFunctionE

        attr_reader :funcT

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

        ## Gets the stack overflow code of the function.
        def overflow
            @funcT.overflow
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
        @@current_stack = [] # The stack of current function instance.

        # Get the function instance currently processing.
        def self.current
            @@current_stack[-1]
        end

        # The eigen function.
        attr_reader :funcE

        # The return index in the stacks.
        attr_reader :returnIdx

        # The stack pointer register.
        attr_reader :stack_ptr

        # The depth of the stack.
        attr_reader :depth

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
            stack_ptr = nil
            depth = @depth
            HDLRuby::High.cur_system.open do
                stack_ptr  = bit[depth.width].inner(HDLRuby.uniq_name(:stack_ptr) => 0)
            end
            @stack_ptr = stack_ptr
            # Create the stack for the returns.
            # @returnIdx = self.make_stack(bit[SequencerT.current.size.width])
            @returnIdx = self.make_stack(bit[8])
            # Create the stacks for the arguments.
            @funcE.each_argT { |argT| self.make_stack(argT) }
            # @argsIdx = @returnIdx + 2
            @argsIdx = @returnIdx + 1

            # Create the return value, however, at first their type is unknown
            # to set it as a simple bit.
            # The type of the return value is built when calling make_return.
            # @returnValIdx = self.make_stack(bit[1])
            # puts "@returnValIdx=#{@returnValIdx}"
            returnValue = nil
            name = @funcE.name
            HDLRuby::High.cur_system.open do
                returnValue = bit[1].inner(
                                      HDLRuby.uniq_name("#{name}_return"))
            end
            @returnValue = returnValue
            
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
                @depth = @funcE.each_argT.map {|t| t.width }.max
            end
            # Resize the stackes according to the depth.
            @stack_sigs.each do |sig|
                sig.type.instance_variable_set(:@range,0..@depth-1)
            end
            @stack_ptr.type.instance_variable_set(:@range,(@depth+1).width-1..0)
        end



        # Builds the code of the function.
        # Returns the last state of the buit function, will serve
        # for computing the return state of the first call.
        def build
            # Saves the current function to detect recursion.
            @@current_stack.push(self)

            # Get the body.
            body = @funcE.body

            # Create a state starting the function.
            SequencerT.current.step

            # Get the arguments.
            args = (@argsIdx...(@argsIdx+body.arity)).map {|idx| self.peek(idx) }
            # Place the body.
            # SequencerT.current.instance_exec(*args,&body)
            HDLRuby::High.top_user.instance_exec(*args,&body)
            # # Free the stack of current frame.
            # Moved to return...
            # self.pop_all

            # Create a state for returning.
            st = self.make_return

            # The function is built, remove it from recursion detection..
            @@current_stack.pop

            return st
        end

        # Call the function with arguments +args+ for the first time.
        def first_call(*args)
            # # Create a state for the call.
            # call_state = SequencerT.current.step

            # Push a new frame.
            self.push_all

            # Adds the arguments and the return state to the current stack frame.
            args.each_with_index { |arg,i| self.poke(@argsIdx + i,arg) }
            # The return is set afterward when the end of the function is
            # known, since the return position for the first call is just
            # after it.
            # self.poke(@returnIdx,call_state.value + 1)

            # Create a state for the call.
            call_state = SequencerT.current.step


            # Get the state value of the function: it is the state
            # following the first function call.
            func_state_value = call_state.value + 1
            # Do the call.
            call_state.gotos << proc do
                HDLRuby::High.top_user.instance_exec do
                    next_state_sig <= func_state_value
                end
            end

            # Sets the state of the first function call.
            @state = call_state

            # Return the state for inserting the push of the return state.
            return call_state
        end

        # Call the function with arguments +args+ for recursion.
        def recurse_call(*args)
            # # create a state for the call.
            # call_state = SequencerT.current.step

            # Get the variables for handling the stack overflow.
            stack_ptr = @stack_ptr
            depth = @depth 
            argsIdx = @argsIdx
            this = self

            # Adds the argument to the stack if no overflow.
            HDLRuby::High.top_user.hif(stack_ptr < depth) do
                # hprint("stack_ptr=",stack_ptr," depth=",depth,"\n")
                # Adds the arguments and the return state to the current stack frame.
                # Since not pushed the stack yet for not loosing the previous
                # arguments, add +1 to the offset when poking the new arguments.
                # args.each_with_index { |arg,i| self.poke(@argsIdx + i,arg,1) }
                args.each_with_index { |arg,i| this.poke(argsIdx + i,arg,1) }
            end

            # Push a new frame.
            self.push_all

            # create a state for the call.
            call_state = SequencerT.current.step

            # Prepare the handling of overflow
            call_state_value = call_state.value
            overflow = @funcE.overflow
            if overflow then
                HDLRuby::High.top_user.hif(stack_ptr > depth) do
                    HDLRuby::High.top_user.instance_exec(&overflow)
                end
            end

            # Get the state value of the function: it is the state
            # following the first function call.
            func_state_value = @state.value + 1
            # Do the call.
            call_state.gotos << proc do
                HDLRuby::High.top_user.instance_exec do
                    hif(stack_ptr <= depth) do
                        next_state_sig <= func_state_value
                    end
                    helse do
                        # Overflow! Skip the call.
                        next_state_sig <= call_state_value + 1
                        # if overflow then
                        #     # There is some overflow code to execute.
                        #     HDLRuby::High.top_user.instance_exec(&overflow)
                        # end
                    end
                end
            end

            return call_state
        end

        # Methods for handling the recursions and stacks.


        ## Check if the current function call with eigen +funcE+ would be
        #  recursive or not.
        def self.recursion(funcE)
            # puts "recursion with funcE=#{funcE}"
            return @@current_stack.find {|funcI| funcI.funcE == funcE }
        end

        ## Create a stack for elements of types +typ+.
        def make_stack(typ)
            # Create the signal array representing the stack.
            depth = @depth
            # puts "make stack with @depth=#{@depth}"
            stack_sig = nil
            name = @funcE.name
            HDLRuby::High.cur_system.open do
                stack_sig = typ[-depth].inner(
                                      HDLRuby.uniq_name("#{name}_stack"))
            end
            # Add it to the list of stacks to handle.
            @stack_sigs << stack_sig

            # Returns the index of the newly created stack.
            return @stack_sigs.size-1
        end

        ## Pushes a new frame to the top of the stacks.
        def push_all
            # HDLRuby::High.cur_system.hprint("push_all\n")
            @stack_ptr <= @stack_ptr + 1
        end

        ## Remove the top frame from the stacks.
        def pop_all
            # HDLRuby::High.cur_system.hprint("pop_all\n")
            @stack_ptr <= @stack_ptr -1
        end

        ## Get a value from the top of stack number +idx+
        #  If +off+ is the offeset in the stack.
        def peek(idx, off = 0)
            return @stack_sigs[idx][@stack_ptr-1+off]
        end

        ## Sets value +val+ to the top of stack number +idx+.
        #  If +off+ is the offeset in the stack.
        def poke(idx,val, off = 0)
            # puts "idx=#{idx} val=#{val} sig=#{@stack_sigs[idx].name}"
            @stack_sigs[idx][@stack_ptr-1+off] <= val
        end

        ## Access the return value signal.
        def return_value
            # return @stack_sigs[@returnValIdx][@stack_ptr-1]
            @returnValue
        end

        ## Creates a return point with value +val+.
        #  Returns the created state.
        #
        #  NOTE: when val is nil, no return value is provided.
        def make_return(val = nil)
            SequencerT.current.step
            # puts "make_return with val=#{val}"
            # Update the type of the return value.
            if val then
                # Update the type.
                @returnValue.instance_variable_set(:@type, @returnValue.type.resolve(val.to_expr.type))
                # Sets the return value if any.
                self.return_value <= val
            end
            # Create the state for the return command.
            state = SequencerT.current.step
            # Get the return state value.
            # ret_state_value = self.peek(@returnIdx, HDLRuby::High.top_user.mux(@stack_ptr < @depth,-1,0))
            # Peek before the stack pointer value to account from the fact that
            # the pop is performed beforehand.
            ret_state_value = self.peek(@returnIdx, HDLRuby::High.top_user.mux(@stack_ptr < @depth,0,+1))
            # Return.
            this = self
            state.gotos << proc do
                HDLRuby::High.top_user.instance_exec do
                    # Set the next state.
                    next_state_sig <= ret_state_value
                    # # Pop must be place after setting the return state.
                    # this.pop_all
                end
            end
            # Pop (done at clock edge, hence before the update of the state).
            old_code = state.code
            state.code = proc do
                old_code.call
                HDLRuby::High.top_user.instance_exec do
                    this.pop_all
                end
            end

            return state
        end
    end




    ## Remplement make_inners of block to support declaration within function.


    class HDLRuby::High::Block
        alias_method :old_make_inners, :make_inners

        def make_inners(typ,*names)
            if SequencerFunctionI.current then
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
    # You can specify a stack depth with +depth+ argument and a HDLRuby
    # block to execute in case of stack overflow with the +overflow+ argument.
    def sdef(name, depth=nil, overflow = nil, &ruby_block)
        # Create the function.
        funcT = SequencerFunctionT.new(name,depth,overflow,&ruby_block)
        # Register it for calling.
        if HDLRuby::High.in_system? then
            define_singleton_method(name.to_sym) do |*args|
                funcT.call(*args)
            end
        else
            define_method(name.to_sym) do |*args|
                funcT.call(*args)
            end
        end
        # Return the create function.
        funcT
    end

    # Returns value +val+ from a sequencer function.
    def sreturn(val)
        # HDLRuby::High.top_user.hprint("sreturn\n")
        # Get the top function.
        funcI = SequencerFunctionI.current
        unless funcI then
            raise "Cannot return since outside a function."
        end
        # Applies the return on it.
        funcI.make_return(val)
    end

end
