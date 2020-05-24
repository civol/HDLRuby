module HDLRuby::High::Std

##
# Standard HDLRuby::High library: tasks
# 
########################################################################
    
    ## Describes a high-level task type.
    class TaskT

        # The name of the task type.
        attr_reader :name

        # Creates a new task type with +name+ built whose
        # instances are created from +ruby_block+.
        def initialize(name,&ruby_block)
            # Checks and sets the name.
            @name = name.to_sym
            # Sets the block for instantiating a task.
            @ruby_block = ruby_block
            # Sets the instantiation procedure if named.
            return if @name.empty?
            obj = self
            HDLRuby::High.space_reg(@name) do |*args|
                obj.instantiate(*args)
            end
        end

        ## Intantiates a task
        def instantiate(*args)
            obj = self
            # No argument, so not an instantiation but actually
            # an access to the task type.
            return obj if args.empty?
            # Process the case of generic task.
            if @ruby_block.arity > 0 then
                # Actually the arguments are generic arguments,
                # generates a new task type with these arguments
                # fixed.
                ruby_block = @ruby_block
                return TaskT.new(:"") do
                    HDLRuby::High.top_user.instance_exec(*args,&ruby_block)
                end
            end
            # Generates the tasks.
            taskI = nil
            args.each do |nameI|
                taskI = TaskI.new(name,&@ruby_block)
                HDLRuby::High.space_reg(nameI) { taskI }
            end
            taskI
        end

        alias_method :call, :instantiate
    end


    ## Creates a new task type named +name+ whose instances are
    #  creating executing +ruby_block+.
    def self.task(name,&ruby_block)
        return TaskT.new(name,&ruby_block)
    end

    ## Creates a new task type named +name+ whose instances are
    #  creating executing +ruby_block+.
    def task(name,&ruby_block)
        HDLRuby::High::Std.task(name,&ruby_block)
    end

    ## Creates directly an instance of task named +name+ using
    #  +ruby_block+ built with +args+.
    def self.task_instance(name,*args,&ruby_block)
        # return TaskT.new(:"",&ruby_block).instantiate(name,*args)
        return self.task(:"",&ruby_block).instantiate(name,*args)
    end

    ## Creates directly an instance of task named +name+ using
    #  +ruby_block+ built with +args+.
    def task_instance(name,*args,&ruby_block)
        HDLRuby::High::Std.task_instance(name,*args,&ruby_block)
    end



    # ##
    # #  Module for wrapping task ports.
    # module TaskPortWrapping
    #     # Wrap with +args+ arguments.
    #     def wrap(*args)
    #         return TaskPortB.new(self,*args)
    #     end
    # end


    ##
    # Describes a runner port to a task.
    class TaskPortS
        # include TaskPortWrapping

        # Creates a new task runner running in +namespace+ and
        # reading using +runner_proc+ and reseting using +reseter_proc+.
        def initialize(namespace,runner_proc,reseter_proc = nil)
            unless namespace.is_a?(Namespace)
                raise "Invalid class for a namespace: #{namespace.class}"
            end
            @namespace = namespace
            @runner_proc = runner_proc.to_proc
            @rester_proc = reseter_proc ? reseter_proc.to_proc : proc {}
        end

        ## Performs a run on the task using +args+ and +ruby_block+
        #  as arguments.
        def run(*args,&ruby_block)
            # Gain access to the runner as local variable.
            runner_proc = @runner_proc
            # Execute the code generating the accesser in context.
            HDLRuby::High.space_push(@namespace)
            HDLRuby::High.cur_block.open do
                instance_exec(ruby_block,*args,&runner_proc)
            end
            HDLRuby::High.space_pop
        end

        ## Performs a reset on the task using +args+ and +ruby_block+
        #  as arguments.
        def reset(*args,&ruby_block)
            # Gain access to the accesser as local variable.
            reseter_proc = @reseter_proc
            # Execute the code generating the accesser in context.
            HDLRuby::High.space_push(@namespace)
            HDLRuby::High.cur_block.open do
                instance_exec(ruby_block,*args,&reseter_proc)
            end
            HDLRuby::High.space_pop
        end
    end


    ##
    # Describes an finisher port to a task.
    class TaskPortA
        # include TaskPortWrapping

        # Creates a new task finisher running in +namespace+ and
        # writing using +finisher_proc+ and reseting using +reseter_proc+.
        def initialize(namespace,finisher_proc,reseter_proc = nil)
            unless namespace.is_a?(Namespace)
                raise "Invalid class for a namespace: #{namespace.class}"
            end
            @namespace = namespace
            @finisher_proc = finisher_proc.to_proc
            # @reseter_proc = reseter_proc ? reseter_proc.to_proc : proc {}
        end

        ## Performs a finish on the task using +args+ and +ruby_block+
        #  as arguments.
        def finish(*args,&ruby_block)
            # Gain access to the finisher as local variable.
            finisher_proc = @finisher_proc
            # Execute the code generating the accesser in context.
            HDLRuby::High.space_push(@namespace)
            HDLRuby::High.cur_block.open do
                instance_exec(ruby_block,*args,&finisher_proc)
            end
            HDLRuby::High.space_pop
        end

        # ## Performs a reset on the task using +args+ and +ruby_block+
        # #  as arguments.
        # def reset(*args,&ruby_block)
        #     # Gain access to the accesser as local variable.
        #     reseter_proc = @reseter_proc
        #     # Execute the code generating the accesser in context.
        #     HDLRuby::High.space_push(@namespace)
        #     HDLRuby::High.cur_block.open do
        #         instance_exec(ruby_block,*args,&reseter_proc)
        #     end
        #     HDLRuby::High.space_pop
        # end
    end


    ##
    # Describes an runner and finisher port to a task.
    class TaskPortSA
        # include TaskPortWrapping

        # Creates a new task accesser running in +namespace+
        # and reading using +runner_proc+, writing using +finisher_proc+,
        # and reseting using +reseter_proc+.
        def initialize(namespace,runner_proc,finisher_proc,reseter_proc = nil)
            unless namespace.is_a?(Namespace)
                raise "Invalid class for a namespace: #{namespace.class}"
            end
            @namespace = namespace
            unless runner_proc || finisher_proc then
                raise "An accesser must have at least a reading or a writing procedure."
            end
            @runner_proc  = runner_proc ? runner_proc.to_proc : proc { }
            @finisher_proc  = finisher_proc ? finisher_proc.to_proc : proc { }
            @reseter_proc = reseter_proc ? reseter_proc.to_proc : proc {}
        end

        ## Performs a run on the task using +args+ and +ruby_block+
        #  as arguments.
        def run(*args,&ruby_block)
            # Gain access to the accesser as local variable.
            runner_proc = @runner_proc
            # Execute the code generating the accesser in context.
            HDLRuby::High.space_push(@namespace)
            HDLRuby::High.cur_block.open do
                instance_exec(ruby_block,*args,&runner_proc)
            end
            HDLRuby::High.space_pop
        end

        ## Performs a finish on the task using +args+ and +ruby_block+
        #  as arguments.
        def finish(*args,&ruby_block)
            # Gain access to the accesser as local variable.
            finisher_proc = @finisher_proc
            # Execute the code generating the accesser in context.
            HDLRuby::High.space_push(@namespace)
            HDLRuby::High.cur_block.open do
                instance_exec(ruby_block,*args,&finisher_proc)
            end
            HDLRuby::High.space_pop
        end

        ## Performs a reset on the task using +args+ and +ruby_block+
        #  as arguments.
        def reset(*args,&ruby_block)
            # Gain access to the accesser as local variable.
            reseter_proc = @reseter_proc
            # Execute the code generating the accesser in context.
            HDLRuby::High.space_push(@namespace)
            HDLRuby::High.cur_block.open do
                instance_exec(ruby_block,*args,&reseter_proc)
            end
            HDLRuby::High.space_pop
        end
    end


    # ##
    # # Describes port wrapper (Box) for fixing arugments.
    # class TaskPortB
    #     include TaskPortWrapping

    #     # Creates a new task box over task port +port+ fixing +args+
    #     # as arguments.
    #     # +args+ is a list of arguments to apply to all read, write
    #     # and access procedure, nil values meaning that the corresponding
    #     # argument is not overwritten.
    #     # It can also be three lists for seperate read, write and access
    #     # procedures using named arguments as:
    #     # read: <read arguments>, write: <write arguments>,
    #     # access: <access arguments>
    #     def initialize(port,*args)
    #         # Ensure port is a task port.
    #         unless port.is_a?(TaskPortS) || port.is_a?(TaskPortA) ||
    #                 port.is_a?(TaskPortSA) || port.is_a?(TaskPortB)
    #             raise "Invalid class for a task port: #{port.class}"
    #         end
    #         @port = port
    #         # Process the arguments.
    #         if args.size == 1 && args[0].is_a?(Hash) then
    #             # Read, write and access are separated.
    #             @args_run = args[0][:run]
    #             @args_finish = args[0][:finish]
    #         else
    #             @args_run = args
    #             @args_finish = args.clone
    #         end
    #     end

    #     ## Performs a run on the task using +args+ and +ruby_block+
    #     #  as arguments.
    #     def run(*args,&ruby_block)
    #         # Generate the final arguments: fills the nil with arguments
    #         # from args
    #         rargs = @args_run.clone
    #         rargs.map! { |arg| arg == nil ? args.shift : arg }
    #         # And add the remaining at the tail.
    #         rargs += args
    #         @port.run(*rargs,&ruby_block)
    #     end

    #     ## Performs a wait on a finish of the task using +args+ and +ruby_block+
    #     #  as arguments.
    #     def finish(*args,&ruby_block)
    #         # Generate the final arguments: fills the nil with arguments
    #         # from args
    #         rargs = @args_finish.clone
    #         rargs.map! { |arg| arg == nil ? args.shift : arg }
    #         # And add the remaining at the tail.
    #         rargs += args
    #         @port.finish(*rargs,&ruby_block)
    #     end

    #     ## Performs a reset on the task using +args+ and +ruby_block+
    #     #  as arguments.
    #     def reset(*args,&ruby_block)
    #         @port.reset(*@args,*args)
    #     end
    # end



    ## 
    # Describes a high-level task instance.
    class TaskI
        # include HDLRuby::High::HScope_missing
        include HDLRuby::High::Hmissing

        # The name of the task instance.
        attr_reader :name

        # The scope the task has been created in.
        attr_reader :scope

        # The namespace associated with the current execution when
        # building a task.
        attr_reader :namespace

        ## Creates a new task instance with +name+ built from +ruby_block+.
        def initialize(name,&ruby_block)
            # Check and set the name of the task.
            @name = name.to_sym
            # Generate a name for the scope containing the signals of
            # the task.
            @scope_name = HDLRuby.uniq_name

            # # Sets the scope.
            # @scope = HDLRuby::High.cur_scope

            # Keep access to self.
            obj = self

              
            # The runner input ports by name.
            @runner_inputs = {}
            # The runner output ports by name.
            @runner_outputs = {}
            # The runner inout ports by name.
            @runner_inouts = {}
              
            # # The stopper input ports by name.
            # @stopper_inputs = {}
            # # The stopper output ports by name.
            # @stopper_outputs = {}
            # # The stopper inout ports by name.
            # @stopper_inouts = {}
              
            # The finisher input ports by name.
            @finisher_inputs = {}
            # The finisher output ports by name.
            @finisher_outputs = {}
            # The finisher inout ports by name.
            @finisher_inouts = {}

            # Create the namespaces for building the task, its readers
            # its writers and its accessers.

            # Creates the namespace of the task.
            @namespace = Namespace.new(self)
            # Make it give access to the internal of the class.
            @namespace.add_method(:runner_input,   &method(:runner_input))
            @namespace.add_method(:runner_output,  &method(:runner_output))
            @namespace.add_method(:runner_inout,   &method(:runner_inout))
            # @namespace.add_method(:stopper_input,   &method(:stopper_input))
            # @namespace.add_method(:stopper_output,  &method(:stopper_output))
            # @namespace.add_method(:stopper_inout,   &method(:stopper_inout))
            @namespace.add_method(:finisher_input,     &method(:finisher_input))
            @namespace.add_method(:finisher_output,    &method(:finisher_output))
            @namespace.add_method(:finisher_inout,     &method(:finisher_inout))
            @namespace.add_method(:runner,         &method(:runner))
            # @namespace.add_method(:stopper,         &method(:stopper))
            @namespace.add_method(:finisher,           &method(:finisher))

            # Creates the namespace of the runner.
            @runner_namespace = Namespace.new(self)
            # # Creates the namespace of the stopper.
            # @stopper_namespace = Namespace.new(self)
            # Creates the namespace of the finisher.
            @finisher_namespace = Namespace.new(self)
            @controller_namespace = Namespace.new(self)

            # Builds the task within a new scope.
            HDLRuby::High.space_push(@namespace)
            # puts "top_user=#{HDLRuby::High.top_user}"
            scope_name = @scope_name
            scope = nil
            HDLRuby::High.top_user.instance_eval do 
                sub(scope_name) do
                    # Generate the task code.
                    ruby_block.call
                end
            end
            HDLRuby::High.space_pop

            # Keep access to the scope containing the code of the task.
            @scope = @namespace.send(scope_name)
            # puts "@scope=#{@scope}"
            # Adds the name space of the scope to the namespace of the
            # task
            @namespace.concat_namespace(@scope.namespace)

            # Gives access to the task by registering its name.
            obj = self
            # HDLRuby::High.space_reg(@name) { self }
            HDLRuby::High.space_reg(@name) { obj }
        end

        # The methods for defining the task
        
        # For the task itself
        
        # ## Defines new command +name+ to execute +ruby_block+ for the
        # #  task.
        # def command(name,&ruby_block)
        #     # Ensures name is a symbol.
        #     name = name.to_sym
        #     res = nil
        #     # Sets the new command.
        #     self.define_singleton_method(name) do |*args|
        #         HDLRuby::High.space_push(@namespace)
        #         HDLRuby::High.cur_block.open do
        #             res = instance_exec(*args,&ruby_block)
        #         end
        #         HDLRuby::High.space_pop
        #         res
        #     end
        # end
        
        # For the runner the stopper and the finisher

        ## Sets the signals accessible through +key+ to be run input port.
        def runner_input(*keys)
            # Registers each signal as run port
            keys.each do |key|
                # Ensure the key is a symbol.
                key = key.to_sym
                # Register it with the corresponding signal.
                name = HDLRuby.uniq_name # The name of the signal is uniq.
                @runner_inputs[name] = send(key)
            end
        end

        ## Sets the signals accessible through +key+ to be run output port.
        def runner_output(*keys)
            # Registers each signal as run port
            keys.each do |key|
                # Ensure the key is a symbol.
                key = key.to_sym
                # Register it with the corresponding signal.
                name = HDLRuby.uniq_name # The name of the signal is uniq.
                @runner_outputs[name] = send(key)
            end
        end

        ## Sets the signals accessible through +key+ to be run inout port.
        def runner_inout(*keys)
            # Registers each signal as run port
            keys.each do |key|
                # Ensure the key is a symbol.
                key = key.to_sym
                # Register it with the corresponding signal.
                name = HDLRuby.uniq_name # The name of the signal is uniq.
                @runner_inouts[name] = send(key)
            end
        end

        # ## Sets the signals accessible through +key+ to be stopper input port.
        # def stopper_input(*keys)
        #     # Registers each signal as stopper port
        #     keys.each do |key|
        #         # Ensure the key is a symbol.
        #         key = key.to_sym
        #         # Register it with the corresponding signal.
        #         name = HDLRuby.uniq_name # The name of the signal is uniq.
        #         @stopper_inputs[name] = send(key)
        #     end
        # end

        # ## Sets the signals accessible through +key+ to be stopper output port.
        # def stopper_output(*keys)
        #     # Registers each signal as stopper port
        #     keys.each do |key|
        #         # Ensure the key is a symbol.
        #         key = key.to_sym
        #         # Register it with the corresponding signal.
        #         name = HDLRuby.uniq_name # The name of the signal is uniq.
        #         @stopper_outputs[name] = send(key)
        #     end
        # end

        # ## Sets the signals accessible through +key+ to be stopper inout port.
        # def stopper_inout(*keys)
        #     # Registers each signal as stopper port
        #     keys.each do |key|
        #         # Ensure the key is a symbol.
        #         key = key.to_sym
        #         # Register it with the corresponding signal.
        #         name = HDLRuby.uniq_name # The name of the signal is uniq.
        #         @stopper_inouts[name] = send(key)
        #     end
        # end

        ## Sets the signals accessible through +key+ to be finisher input port.
        def finisher_input(*keys)
            # Registers each signal as finisher port
            keys.each do |key|
                # Ensure the key is a symbol.
                key = key.to_sym
                # Register it with the corresponding signal.
                name = HDLRuby.uniq_name # The name of the signal is uniq.
                @finisher_inputs[name] = send(key)
            end
        end

        ## Sets the signals accessible through +key+ to be finisher output port.
        def finisher_output(*keys)
            # Registers each signal as finisher port
            keys.each do |key|
                # Ensure the key is a symbol.
                key = key.to_sym
                # Register it with the corresponding signal.
                name = HDLRuby.uniq_name # The name of the signal is uniq.
                @finisher_outputs[name] = send(key)
            end
        end

        ## Sets the signals accessible through +key+ to be finisher inout port.
        def finisher_inout(*keys)
            # Registers each signal as finisher port
            keys.each do |key|
                # Ensure the key is a symbol.
                key = key.to_sym
                # Register it with the corresponding signal.
                name = HDLRuby.uniq_name # The name of the signal is uniq.
                @finisher_inouts[name] = send(key)
            end
        end


        ## Sets the read procedure to be +ruby_block+.
        def runner(&ruby_block)
            @runner_proc = ruby_block
        end

        # ## Sets the stopper procedure to be +ruby_block+.
        # def stopper(&ruby_block)
        #     @stopper_proc = ruby_block
        # end

        ## Sets the finisher procedure to be +ruby_block+.
        def finisher(&ruby_block)
            @finisher_proc = ruby_block
        end

        ## Sets the reset to be +ruby_block+.
        def reseter(&ruby_block)
            @reseter_proc = ruby_block
        end

        
        # The methods for accessing the task
        # Task side.

        ## Gets the list of the signals of the task to be connected
        #  to the runner.
        def runner_signals
            return @runner_inputs.values + @runner_outputs.values +
                   @runner_inouts.values
        end

        # # ## Gets the list of the signals of the task to be connected
        # # #  to the stopper.
        # # def stopper_signals
        # #     return @stopper_inputs.values + @stopper_outputs.values +
        # #            @stopper_inouts.values
        # # end

        ## Gets the list of the signals of the task to be connected
        #  to the finisher.
        def finisher_signals
            return @finisher_inputs.values + @finisher_outputs.values +
                   @finisher_inouts.values
        end


        ## Declares the ports for the runner and assigned them to +name+.
        def input(name)
            # Ensure name is a symbol.
            name = name.to_sym
            # Access the ports
            loc_inputs  = @runner_inputs
            loc_outputs = @runner_outputs
            loc_inouts  = @runner_inouts
            # The generated port with corresponding task port pairs.
            port_pairs = []
            # Add them to the current system.
            HDLRuby::High.cur_system.open do
                # The inputs
                loc_inputs.each  do |name,sig|
                    # puts "name=#{name} sig.name=#{sig.name}"
                    port_pairs << [sig, sig.type.input(name)]
                end
                # The outputs
                loc_outputs.each do |name,sig| 
                    port_pairs << [sig, sig.type.output(name)]
                end
                # The inouts
                loc_inouts.each  do |name,sig| 
                    port_pairs << [sig, sig.type.inout(name)]
                end
            end
            obj = self
            # Make the connection of the instance.
            HDLRuby::High.cur_system.on_instance do |inst|
                obj.scope.open do
                    port_pairs.each do |sig, port|
                        RefObject.new(inst,port.to_ref) <= sig
                    end
                end
            end

            # Fill the runner namespace with the access to the runner signals.
            @runner_inputs.each do |name,sig|
                @runner_namespace.add_method(sig.name) do
                    HDLRuby::High.top_user.send(name)
                end
            end
            @runner_outputs.each do |name,sig|
                @runner_namespace.add_method(sig.name) do
                    HDLRuby::High.top_user.send(name)
                end
            end
            @runner_inouts.each do |name,sig|
                @runner_namespace.add_method(sig.name) do
                    HDLRuby::High.top_user.send(name)
                end
            end

            # Give access to the ports through name.
            # NOTE: for now, simply associate the task to name.
            tp = TaskPortS.new(@runner_namespace,@runner_proc,@reseter_proc)
            HDLRuby::High.space_reg(name) { tp }
            return tp
        end

        ## Declares the ports for the finisher and assigned them to +name+.
        def output(name)
            # Ensure name is a symbol.
            name = name.to_sym
            # Access the ports
            loc_inputs  = @finisher_inputs
            loc_outputs = @finisher_outputs
            loc_inouts  = @finisher_inouts
            # The generated port with corresponding task port pairs.
            port_pairs = []
            # Add them to the current system.
            HDLRuby::High.cur_system.open do
                # The inputs
                loc_inputs.each  do |name,sig|
                    port_pairs << [sig, sig.type.input(name)]
                end
                # The outputs
                loc_outputs.each do |name,sig| 
                    port_pairs << [sig, sig.type.output(name)]
                end
                # The inouts
                loc_inouts.each  do |name,sig| 
                    port_pairs << [sig, sig.type.inout(name)]
                end
            end
            obj = self
            # Make the connection of the instance.
            HDLRuby::High.cur_system.on_instance do |inst|
                obj.scope.open do
                    port_pairs.each do |sig, port|
                        RefObject.new(inst,port.to_ref) <= sig
                    end
                end
            end

            # Fill the finisher namespace with the access to the finisher signals.
            @finisher_inputs.each do |name,sig|
                @finisher_namespace.add_method(sig.name) do
                    HDLRuby::High.top_user.send(name)
                end
            end
            @finisher_outputs.each do |name,sig|
                @finisher_namespace.add_method(sig.name) do
                    HDLRuby::High.top_user.send(name)
                end
            end
            @finisher_inouts.each do |name,sig|
                @finisher_namespace.add_method(sig.name) do
                    HDLRuby::High.top_user.send(name)
                end
            end

            # Give access to the ports through name.
            # NOTE: for now, simply associate the task to name.
            chp = TaskPortA.new(@finisher_namespace,@finisher_proc,@output_reseter_proc)
            HDLRuby::High.space_reg(name) { chp }
            return chp
        end


        ## Declares the ports for accessing the task as an inner component
        #  and assigned them to +name+.
        def inner(name)
            # Ensure name is a symbol.
            name = name.to_sym
            # Access the ports
            loc_inputs  = @runner_inputs.merge(@finisher_inputs)
            loc_outputs = @runner_outputs.merge(@finisher_outputs)
            loc_inouts  = @runner_inouts.merge(@finisher_inouts)
            locs = loc_inputs.merge(loc_outputs).merge(loc_inouts)
            # The generated port with corresponding task port pairs.
            port_pairs = []
            # Add them to the current system.
            HDLRuby::High.cur_system.open do
                locs.each  do |name,sig|
                    port_pairs << [sig, sig.type.inner(name)]
                end
            end
            obj = self
            # Make the inner connection
            port_pairs.each do |sig, port|
                sig.parent.open do
                    port.to_ref <= sig
                end
            end

            # Set ups the controller's namespace
            loc_inputs.each do |name,sig|
                @controller_namespace.add_method(sig.name) do
                    HDLRuby::High.top_user.send(name)
                end
            end
            loc_outputs.each do |name,sig|
                @controller_namespace.add_method(sig.name) do
                    HDLRuby::High.top_user.send(name)
                end
            end
            loc_inouts.each do |name,sig|
                @controller_namespace.add_method(sig.name) do
                    HDLRuby::High.top_user.send(name)
                end
            end

            # Give access to the ports through name.
            # NOTE: for now, simply associate the task to name.
            tp = TaskPortSA.new(@controller_namespace,@runner_proc,@finisher_proc,@reseter_proc)
            HDLRuby::High.space_reg(name) { chp }
            return tp
        end

       
        ## Runs the task using +args+ and +ruby_block+
        #  as arguments.
        def run(*args,&ruby_block)
            # Gain access to the runner as local variable.
            runner_proc = @runner_proc
            # # The context is the one of the reader.
            # Execute the code generating the reader in context.
            HDLRuby::High.space_push(@namespace)
            HDLRuby::High.cur_block.open do
                instance_exec(ruby_block,*args,&runner_proc)
            end
            HDLRuby::High.space_pop
        end
       
        ## Performs a wait from the end of the computation of the task using
        #  +args+ and +ruby_block+ as arguments.
        def finish(*args,&ruby_block)
            # Gain access to the finisher as local variable.
            finisher_proc = @finisher_proc
            # # The context is the one of the finisher.
            # Execute the code generating the finisher in context.
            HDLRuby::High.space_push(@namespace)
            HDLRuby::High.cur_block.open do
                instance_exec(ruby_block,*args,&finisher_proc)
            end
            HDLRuby::High.space_pop
        end

        ## Performs a reset on the task using +args+ and +ruby_block+
        #  as arguments.
        def reset(*args,&ruby_block)
            # Gain access to the writer as local variable.
            reseter_proc = @inout_reseter_proc
            # # The context is the one of the writer.
            # Execute the code generating the writer in context.
            HDLRuby::High.space_push(@namespace)
            HDLRuby::High.cur_block.open do
                instance_exec(ruby_block,*args,&reseter_proc)
            end
            HDLRuby::High.space_pop
        end
    end


    ## Encapsulate a task for integrating a control with simple 
    #  reset (+rst+), request and acknowledge (+ack+) signals, 
    #  synchronised on +clk_e+.
    #  +port+ is assumed to return a TaskPortSA.
    #  If +clk_e+ is nil, work in asynchronous mode.
    #  If +rst+ is nil, no reset is handled.
    def rst_req_ack(clk_e,rst,req,ack,port)
        if clk_e then
            # Ensures clk_e is an event.
            clk_e = clk_e.posedge unless clk_e.is_a?(Event)
            par(clk_e) do
                # Handle the reset.
                hif(rst) { port.reset } if rst
                ack <= 0
                # Control the start of the task.
                hif(req) { port.run }
                # Control the end of the task: set ack to 1.
                port.finish { ack <= 1 }
            end
        else
            par do
                # Handle the reset
                hif(rst) { port.reset } if rst
                # Control the start of the task.
                hif(req) { port.run }
                ack <= 0
                # Control the end of the task: set ack to 1.
                port.finish { ack <= 1 }
            end
        end
    end


    ## Encapsulate a task for integrating a control with simple 
    #  request and acknowledge (+ack+) signals, 
    #  synchronised on +clk_e+.
    #  +port+ is assumed to return a TaskPortSA.
    #  If +clk_e+ is nil, work in asynchronous mode.
    def req_ack(clk_e,req,ack,port)
        rst_req_ack(clk_e,nil,req,ack,port)
    end

end
