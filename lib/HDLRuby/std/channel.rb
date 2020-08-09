module HDLRuby::High::Std

##
# Standard HDLRuby::High library: channels
# 
########################################################################
    
    ## Describes a high-level channel type.
    class ChannelT

        # The name of the channel type.
        attr_reader :name

        # Creates a new channel type with +name+ built whose
        # instances are created from +ruby_block+.
        def initialize(name,&ruby_block)
            # Checks and sets the name.
            @name = name.to_sym
            # Sets the block for instantiating a channel.
            @ruby_block = ruby_block
            # Sets the instantiation procedure if named.
            return if @name.empty?
            obj = self
            HDLRuby::High.space_reg(@name) do |*args|
                obj.instantiate(*args)
            end
        end

        ## Intantiates a channel
        def instantiate(*args)
            obj = self
            # No argument, so not an instantiation but actually
            # an access to the channel type.
            return obj if args.empty?
            # Process the case of generic channel.
            if @ruby_block.arity > 0 then
                # Actually the arguments are generic arguments,
                # generates a new channel type with these arguments
                # fixed.
                ruby_block = @ruby_block
                return ChannelT.new(:"") do
                    HDLRuby::High.top_user.instance_exec(*args,&ruby_block)
                end
            end
            # Generates the channels.
            channelI = nil
            args.each do |nameI|
                channelI = ChannelI.new(name,&@ruby_block)
                HDLRuby::High.space_reg(nameI) { channelI }
            end
            channelI
        end

        alias_method :call, :instantiate
    end


    ## Creates a new channel type named +name+ whose instances are
    #  creating executing +ruby_block+.
    def self.channel(name,&ruby_block)
        return ChannelT.new(name,&ruby_block)
    end

    ## Creates a new channel type named +name+ whose instances are
    #  creating executing +ruby_block+.
    def channel(name,&ruby_block)
        HDLRuby::High::Std.channel(name,&ruby_block)
    end

    ## Creates directly an instance of channel named +name+ using
    #  +ruby_block+ built with +args+.
    def self.channel_instance(name,*args,&ruby_block)
        # return ChannelT.new(:"",&ruby_block).instantiate(name,*args)
        return self.channel(:"",&ruby_block).instantiate(name,*args)
    end

    ## Creates directly an instance of channel named +name+ using
    #  +ruby_block+ built with +args+.
    def channel_instance(name,*args,&ruby_block)
        HDLRuby::High::Std.channel_instance(name,*args,&ruby_block)
    end


    # ##
    # #  Module for wrapping channel ports.
    # module ChannelPortWrapping
    #     # Wrap with +args+ arguments.
    #     def wrap(*args)
    #         return ChannelPortB.new(self,*args)
    #     end
    # end

    ## Describes a channel port.
    class ChannelPort
        # Wrap with +args+ arguments.
        def wrap(*args)
            return ChannelPortB.new(self,*args)
        end

        # The scope the port has been declared in.
        attr_reader :scope
    end


    ##
    # Describes a read port to a channel.
    class ChannelPortR < ChannelPort
        # include ChannelPortWrapping

        # Creates a new channel reader running in +namespace+ and
        # reading using +reader_proc+ and reseting using +reseter_proc+.
        def initialize(namespace,reader_proc,reseter_proc = nil)
            unless namespace.is_a?(Namespace)
                raise "Invalid class for a namespace: #{namespace.class}"
            end
            @namespace = namespace
            @reader_proc = reader_proc.to_proc
            @rester_proc = reseter_proc ? reseter_proc.to_proc : proc {}
            @scope = HDLRuby::High.cur_scope
        end

        ## Performs a read on the channel using +args+ and +ruby_block+
        #  as arguments.
        def read(*args,&ruby_block)
            # Gain access to the reader as local variable.
            reader_proc = @reader_proc
            # Execute the code generating the accesser in context.
            HDLRuby::High.space_push(@namespace)
            HDLRuby::High.cur_block.open do
                instance_exec(ruby_block,*args,&reader_proc)
            end
            HDLRuby::High.space_pop
        end

        ## Performs a reset on the channel using +args+ and +ruby_block+
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
    # Describes a writer port to a channel.
    class ChannelPortW < ChannelPort
        # include ChannelPortWrapping

        # Creates a new channel writer running in +namespace+ and
        # writing using +writer_proc+ and reseting using +reseter_proc+.
        def initialize(namespace,writer_proc,reseter_proc = nil)
            unless namespace.is_a?(Namespace)
                raise "Invalid class for a namespace: #{namespace.class}"
            end
            @namespace = namespace
            @writer_proc = writer_proc.to_proc
            @reseter_proc = reseter_proc ? reseter_proc.to_proc : proc {}
            @scope = HDLRuby::High.cur_scope
        end

        ## Performs a write on the channel using +args+ and +ruby_block+
        #  as arguments.
        def write(*args,&ruby_block)
            # Gain access to the writer as local variable.
            writer_proc = @writer_proc
            # Execute the code generating the accesser in context.
            HDLRuby::High.space_push(@namespace)
            HDLRuby::High.cur_block.open do
                instance_exec(ruby_block,*args,&writer_proc)
            end
            HDLRuby::High.space_pop
        end

        ## Performs a reset on the channel using +args+ and +ruby_block+
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
    # Describes an access port to a channel.
    class ChannelPortA < ChannelPort
        # include ChannelPortWrapping

        # Creates a new channel accesser running in +namespace+
        # and reading using +reader_proc+, writing using +writer_proc+,
        # and reseting using +reseter_proc+.
        def initialize(namespace,reader_proc,writer_proc,reseter_proc = nil)
            unless namespace.is_a?(Namespace)
                raise "Invalid class for a namespace: #{namespace.class}"
            end
            @namespace = namespace
            unless reader_proc || writer_proc then
                raise "An accesser must have at least a reading or a writing procedure."
            end
            @reader_proc  = reader_proc ? reader_proc.to_proc : proc { }
            @writer_proc  = writer_proc ? writer_proc.to_proc : proc { }
            @reseter_proc = reseter_proc ? reseter_proc.to_proc : proc {}
            @scope = HDLRuby::High.cur_scope
        end

        ## Performs a read on the channel using +args+ and +ruby_block+
        #  as arguments.
        def read(*args,&ruby_block)
            # Gain access to the accesser as local variable.
            reader_proc = @reader_proc
            # Execute the code generating the accesser in context.
            HDLRuby::High.space_push(@namespace)
            HDLRuby::High.cur_block.open do
                instance_exec(ruby_block,*args,&reader_proc)
            end
            HDLRuby::High.space_pop
        end

        ## Performs a write on the channel using +args+ and +ruby_block+
        #  as arguments.
        def write(*args,&ruby_block)
            # Gain access to the accesser as local variable.
            writer_proc = @writer_proc
            # Execute the code generating the accesser in context.
            HDLRuby::High.space_push(@namespace)
            HDLRuby::High.cur_block.open do
                instance_exec(ruby_block,*args,&writer_proc)
            end
            HDLRuby::High.space_pop
        end

        ## Performs a reset on the channel using +args+ and +ruby_block+
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
    # Describes port wrapper (Box) for fixing arugments.
    class ChannelPortB < ChannelPort
        # include ChannelPortWrapping

        # Creates a new channel box over channel port +port+ fixing +args+
        # as arguments.
        # +args+ is a list of arguments to apply to all read, write
        # and access procedure, nil values meaning that the corresponding
        # argument is not overwritten.
        # It can also be three lists for seperate read, write and access
        # procedures using named arguments as:
        # read: <read arguments>, write: <write arguments>,
        # access: <access arguments>
        def initialize(port,*args)
            # Ensure port is a channel port.
            unless port.is_a?(ChannelPortR) || port.is_a?(ChannelPortW) ||
                    port.is_a?(ChannelPortA) || port.is_a?(ChannelPortB)
                raise "Invalid class for a channel port: #{port.class}"
            end
            @port = port
            # Process the arguments.
            if args.size == 1 && args[0].is_a?(Hash) then
                # Read, write and access are separated.
                @args_read = args[0][:read]
                @args_write = args[0][:write]
                @args_access = args[0][:access]
            else
                @args_read = args
                @args_write = args.clone
                @args_access = args.clone
            end

            @scope = @port.scope
        end

        ## Performs a read on the channel using +args+ and +ruby_block+
        #  as arguments.
        def read(*args,&ruby_block)
            # Generate the final arguments: fills the nil with arguments
            # from args
            rargs = @args_read.clone
            rargs.map! { |arg| arg == nil ? args.shift : arg }
            # And add the remaining at the tail.
            rargs += args
            @port.read(*rargs,&ruby_block)
        end

        ## Performs a write on the channel using +args+ and +ruby_block+
        #  as arguments.
        def write(*args,&ruby_block)
            # Generate the final arguments: fills the nil with arguments
            # from args
            rargs = @args_write.clone
            rargs.map! { |arg| arg == nil ? args.shift : arg }
            # And add the remaining at the tail.
            rargs += args
            @port.write(*rargs,&ruby_block)
        end

        ## Performs a reset on the channel using +args+ and +ruby_block+
        #  as arguments.
        def reset(*args,&ruby_block)
            @port.reset(*@args,*args)
        end
    end



    ## 
    # Describes a high-level channel instance.
    class ChannelI
        # include HDLRuby::High::HScope_missing
        include HDLRuby::High::Hmissing

        # The name of the channel instance.
        attr_reader :name

        # The scope the channel has been created in.
        attr_reader :scope

        # The namespace associated with the current execution when
        # building a channel.
        attr_reader :namespace

        # The read port if any.
        attr_reader :read_port

        # The write port if any.
        attr_reader :write_port

        ## Creates a new channel instance with +name+ built from +ruby_block+.
        def initialize(name,&ruby_block)
            # Check and set the name of the channel.
            @name = name.to_sym
            # Generate a name for the scope containing the signals of
            # the channel.
            @scope_name = HDLRuby.uniq_name

            # # Sets the scope.
            # @scope = HDLRuby::High.cur_scope

            # Keep access to self.
            obj = self

            # At first there no read nor write port.
            @read_port = nil
            @write_port = nil

            # The reader input ports by name.
            @reader_inputs = {}
            # The reader output ports by name.
            @reader_outputs = {}
            # The reader inout ports by name.
            @reader_inouts = {}

            # The writer input ports by name.
            @writer_inputs = {}
            # The writer output ports by name.
            @writer_outputs = {}
            # The writer inout ports by name.
            @writer_inouts = {}

            # The accesser input ports by name.
            @accesser_inputs = {}
            # The accesser output ports by name.
            @accesser_outputs = {}
            # The accesser inout ports by name.
            @accesser_inouts = {}

            # The branch channels
            @branches = {}

            # Create the namespaces for building the channel, its readers
            # its writers and its accessers.

            # Creates the namespace of the channel.
            @namespace = Namespace.new(self)
            # Make it give access to the internal of the class.
            @namespace.add_method(:reader_input,   &method(:reader_input))
            @namespace.add_method(:reader_output,  &method(:reader_output))
            @namespace.add_method(:reader_inout,   &method(:reader_inout))
            @namespace.add_method(:writer_input,   &method(:writer_input))
            @namespace.add_method(:writer_output,  &method(:writer_output))
            @namespace.add_method(:writer_inout,   &method(:writer_inout))
            @namespace.add_method(:accesser_input, &method(:accesser_input))
            @namespace.add_method(:accesser_output,&method(:accesser_output))
            @namespace.add_method(:accesser_inout, &method(:accesser_inout))
            @namespace.add_method(:reader,         &method(:reader))
            @namespace.add_method(:writer,         &method(:writer))
            @namespace.add_method(:brancher,         &method(:brancher))

            # Creates the namespace of the reader.
            @reader_namespace = Namespace.new(self)
            # Creates the namespace of the writer.
            @writer_namespace = Namespace.new(self)
            # Creates the namespace of the accesser.
            @accesser_namespace = Namespace.new(self)

            # Builds the channel within a new scope.
            HDLRuby::High.space_push(@namespace)
            # puts "top_user=#{HDLRuby::High.top_user}"
            scope_name = @scope_name
            scope = nil
            HDLRuby::High.top_user.instance_eval do 
                sub(scope_name) do
                    # Generate the channel code.
                    ruby_block.call
                end
            end
            HDLRuby::High.space_pop

            # Keep access to the scope containing the code of the channel.
            @scope = @namespace.send(scope_name)
            # puts "@scope=#{@scope}"
            # Adds the name space of the scope to the namespace of the
            # channel
            @namespace.concat_namespace(@scope.namespace)

            # Gives access to the channel by registering its name.
            obj = self
            # HDLRuby::High.space_reg(@name) { self }
            HDLRuby::High.space_reg(@name) { obj }
        end

        # Get the parent system.
        def parent_system
            return self.scope.parent_system
        end

        # The methods for defining the channel
        
        # For the channel itself
        
        # ## Defines new command +name+ to execute +ruby_block+ for the
        # #  channel.
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
        
        # For the reader and the writer

        ## Sets the signals accessible through +key+ to be reader input port.
        def reader_input(*keys)
            # Registers each signal as reader port
            keys.each do |key|
                # Ensure the key is a symbol.
                key = key.to_sym
                # Register it with the corresponding signal.
                name = HDLRuby.uniq_name # The name of the signal is uniq.
                @reader_inputs[name] = send(key)
            end
        end

        ## Sets the signals accessible through +key+ to be reader output port.
        def reader_output(*keys)
            # Registers each signal as reader port
            keys.each do |key|
                # Ensure the key is a symbol.
                key = key.to_sym
                # Register it with the corresponding signal.
                name = HDLRuby.uniq_name # The name of the signal is uniq.
                @reader_outputs[name] = send(key)
            end
        end

        ## Sets the signals accessible through +key+ to be reader inout port.
        def reader_inout(*keys)
            # Registers each signal as reader port
            keys.each do |key|
                # Ensure the key is a symbol.
                key = key.to_sym
                # Register it with the corresponding signal.
                name = HDLRuby.uniq_name # The name of the signal is uniq.
                @reader_inouts[name] = send(key)
            end
        end

        ## Sets the signals accessible through +key+ to be writer input port.
        def writer_input(*keys)
            # Registers each signal as writer port
            keys.each do |key|
                # Ensure the key is a symbol.
                key = key.to_sym
                # Register it with the corresponding signal.
                name = HDLRuby.uniq_name # The name of the signal is uniq.
                @writer_inputs[name] = send(key)
            end
        end

        ## Sets the signals accessible through +key+ to be writer output port.
        def writer_output(*keys)
            # Registers each signal as writer port
            keys.each do |key|
                # Ensure the key is a symbol.
                key = key.to_sym
                # Register it with the corresponding signal.
                name = HDLRuby.uniq_name # The name of the signal is uniq.
                @writer_outputs[name] = send(key)
            end
        end

        ## Sets the signals accessible through +key+ to be writer inout port.
        def writer_inout(*keys)
            # Registers each signal as writer port
            keys.each do |key|
                # Ensure the key is a symbol.
                key = key.to_sym
                # Register it with the corresponding signal.
                name = HDLRuby.uniq_name # The name of the signal is uniq.
                @writer_inouts[name] = send(key)
            end
        end

        ## Sets the signals accessible through +key+ to be accesser input port.
        def accesser_input(*keys)
            # Registers each signal as accesser port
            keys.each do |key|
                # Ensure the key is a symbol.
                key = key.to_sym
                # Register it with the corresponding signal.
                name = HDLRuby.uniq_name # The name of the signal is uniq.
                @accesser_inputs[name] = send(key)
            end
        end

        ## Sets the signals accessible through +key+ to be accesser output port.
        def accesser_output(*keys)
            # Registers each signal as accesser port
            keys.each do |key|
                # Ensure the key is a symbol.
                key = key.to_sym
                # Register it with the corresponding signal.
                name = HDLRuby.uniq_name # The name of the signal is uniq.
                @accesser_outputs[name] = send(key)
            end
        end

        ## Sets the signals accessible through +key+ to be accesser inout port.
        def accesser_inout(*keys)
            # Registers each signal as accesser port
            keys.each do |key|
                # Ensure the key is a symbol.
                key = key.to_sym
                # Register it with the corresponding signal.
                name = HDLRuby.uniq_name # The name of the signal is uniq.
                @accesser_inouts[name] = send(key)
            end
        end


        ## Sets the read procedure to be +ruby_block+.
        def reader(&ruby_block)
            @reader_proc = ruby_block
        end

        ## Sets the writer procedure to be +ruby_block+.
        def writer(&ruby_block)
            @writer_proc = ruby_block
        end

        # ## Sets the accesser procedure to be +ruby_block+.
        # def accesser(&ruby_block)
        #     @accesser_proc = ruby_block
        # end

        ## Sets the input port reset to be +ruby_block+.
        def input_reseter(&ruby_block)
            @input_reseter_proc = ruby_block
        end

        ## Sets the output port reset to be +ruby_block+.
        def output_reseter(&ruby_block)
            @output_reseter_proc = ruby_block
        end

        ## Sets the inout port reset to be +ruby_block+.
        def inout_reseter(&ruby_block)
            @inout_reseter_proc = ruby_block
        end
        
        # The methods for accessing the channel
        # Channel side.

        ## Gets the list of the signals of the channel to be connected
        #  to the reader.
        def reader_signals
            return @reader_inputs.values + @reader_outputs.values +
                   @reader_inouts.values
        end

        ## Gets the list of the signals of the channel to be connected
        #  to the writer.
        def writer_signals
            return @writer_inputs.values + @writer_outputs.values +
                   @writer_inouts.values
        end

        ## Tells if the channel support inout port.
        def inout?
            return @accesser_inputs.any? || @accesser_outputs.any? ||
                   @accesser_inouts.any?
        end

        # Defines a branch in the channel named +name+ built executing
        # +ruby_block+.
        # Alternatively, a ready channel instance can be passed as argument
        # as +channelI+.
        def brancher(name,channelI = nil,&ruby_block)
            # Ensure name is a symbol.
            name = name.to_s unless name.respond_to?(:to_sym)
            name = name.to_sym
            # Is there a ready channel instance.
            if channelI then
                # Yes, use it directly.
                @branches[name] = channelI
                return self
            end
            # Now, create the branch.
            channelI = HDLRuby::High::Std.channel_instance(name, &ruby_block)
            @branches[name] = channelI
            return self
        end


        # Methods used on the channel outside its definition.
        
        # Gets branch channel +name+.
        # NOTE: +name+ can be of any type on purpose.
        def branch(name,*args)
            # Ensure name is a symbol.
            name = name.to_s unless name.respond_to?(:to_sym)
            name = name.to_sym
            # Get the branch.
            channelI = @branches[name]
            return @branches[name]
        end


        # Reader, writer and accesser side.

        ## Declares the reader port as and assigned them to +name+.
        def input(name)
            # Ensure name is a symbol.
            name = name.to_sym
            # Ensure the port is not already existing.
            if @read_port then
                raise "Read port already declared for channel instance: " +
                    self.name
            end

            # Access the ports
            # loc_inputs  = @reader_inputs
            # loc_outputs = @reader_outputs
            # loc_inouts  = @reader_inouts
            loc_inputs  = @reader_inputs.merge(@accesser_inputs)
            loc_outputs = @reader_outputs.merge(@accesser_outputs)
            loc_inouts  = @reader_inouts.merge(@accesser_inouts)
            locs = loc_inputs.merge(loc_outputs).merge(loc_inouts)
            # The generated port with corresponding channel port pairs.
            port_pairs = []
            if HDLRuby::High.cur_system == self.parent_system then
                # Port in same system as the channel case.
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
            else
                # Port in different system as the channel case.
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
            end

            # Fill the reader namespace with the access to the reader signals.
            loc_inputs.each do |name,sig|
                @reader_namespace.add_method(sig.name) do
                    HDLRuby::High.top_user.send(name)
                end
            end
            loc_outputs.each do |name,sig|
                @reader_namespace.add_method(sig.name) do
                    HDLRuby::High.top_user.send(name)
                end
            end
            loc_inouts.each do |name,sig|
                @reader_namespace.add_method(sig.name) do
                    HDLRuby::High.top_user.send(name)
                end
            end

            # Give access to the ports through name.
            # NOTE: for now, simply associate the channel to name.
            chp = ChannelPortR.new(@reader_namespace,@reader_proc,@input_reseter_proc)
            HDLRuby::High.space_reg(name) { chp }
            # Save the port in the channe to avoid conflicting declaration.
            @read_port = chp
            return chp
        end

        ## Declares the ports for the writer and assigned them to +name+.
        def output(name)
            # Ensure name is a symbol.
            name = name.to_sym
            # Ensure the port is not already existing.
            if @write_port then
                raise "Write port already declared for channel instance: " +
                    self.name
            end
            # Access the ports
            # loc_inputs  = @writer_inputs
            # loc_outputs = @writer_outputs
            # loc_inouts  = @writer_inouts
            loc_inputs  = @writer_inputs.merge(@accesser_inputs)
            loc_outputs = @writer_outputs.merge(@accesser_outputs)
            loc_inouts  = @writer_inouts.merge(@accesser_inouts)
            locs = loc_inputs.merge(loc_outputs).merge(loc_inouts)
            # The generated port with corresponding channel port pairs.
            port_pairs = []
            # puts "cur_system=#{HDLRuby::High.cur_system} self.parent_system=#{self.parent_system}"
            if HDLRuby::High.cur_system == self.parent_system then
                # puts "Inner found!"
                # Port in same system as the channel case.
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
            else
                # Portds in different system as the channel's case.
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
            end

            # Fill the writer namespace with the access to the writer signals.
            loc_inputs.each do |name,sig|
                @writer_namespace.add_method(sig.name) do
                    HDLRuby::High.top_user.send(name)
                end
            end
            loc_outputs.each do |name,sig|
                @writer_namespace.add_method(sig.name) do
                    HDLRuby::High.top_user.send(name)
                end
            end
            loc_inouts.each do |name,sig|
                @writer_namespace.add_method(sig.name) do
                    HDLRuby::High.top_user.send(name)
                end
            end

            # Give access to the ports through name.
            # NOTE: for now, simply associate the channel to name.
            chp = ChannelPortW.new(@writer_namespace,@writer_proc,@output_reseter_proc)
            HDLRuby::High.space_reg(name) { chp }
            # Save the port in the channe to avoid conflicting declaration.
            @write_port = chp
            return chp
        end


        ## Declares the accesser port and assigned them to +name+.
        def inout(name)
            # Ensure name is a symbol.
            name = name.to_sym
            # Ensure the port is not already existing.
            if @read_port then
                raise "Read port already declared for channel instance: " +
                    self.name
            end

            if @write_port then
                raise "Write port already declared for channel instance: " +
                    self.name
            end

            # Access the ports
            loc_inputs  = @accesser_inputs.merge(@reader_inputs).
                merge(@writer_inputs)
            loc_outputs = @accesser_outputs.merge(@reader_outputs).
                merge(@writer_outputs)
            loc_inouts  = @accesser_inouts.merge(@reader_inouts).
                merge(@writer_inouts)
            locs = loc_inputs.merge(loc_outputs).merge(loc_inouts)
            # The generated port with corresponding channel port pairs.
            port_pairs = []
            if HDLRuby::High.cur_system == self.parent_system then
                # Port in same system as the channel case.
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
            else
                # Port in different system as the channel case.
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
            end

            # Fill the reader namespace with the access to the reader signals.
            loc_inputs.each do |name,sig|
                @accesser_namespace.add_method(sig.name) do
                    HDLRuby::High.top_user.send(name)
                end
            end
            loc_outputs.each do |name,sig|
                @accesser_namespace.add_method(sig.name) do
                    HDLRuby::High.top_user.send(name)
                end
            end
            loc_inouts.each do |name,sig|
                @accesser_namespace.add_method(sig.name) do
                    HDLRuby::High.top_user.send(name)
                end
            end

            # Give access to the ports through name.
            # NOTE: for now, simply associate the channel to name.
            chp = ChannelPortA.new(@accesser_namespace,@reader_proc,@writer_proc,@inout_reseter_proc)
            HDLRuby::High.space_reg(name) { chp }
            # Save the port in the channe to avoid conflicting declaration.
            @read_port = chp
            @write_port = chp
            return chp
        end

        # ## Declares the ports for accessing the channel as an inner component
        # #  and assigned them to +name+.
        # def inner(name)
        #     # Ensure name is a symbol.
        #     name = name.to_sym
        #     # Access the ports
        #     loc_inputs  = @accesser_inputs.merge(@reader_inputs).
        #         merge(@writer_inputs)
        #     loc_outputs = @accesser_outputs.merge(@reader_outputs).
        #         merge(@writer_outputs)
        #     loc_inouts  = @accesser_inouts.merge(@reader_inouts).
        #         merge(@writer_inouts)
        #     locs = loc_inputs.merge(loc_outputs).merge(loc_inouts)
        #     # The generated port with corresponding channel port pairs.
        #     port_pairs = []
        #     # Add them to the current system.
        #     HDLRuby::High.cur_system.open do
        #         locs.each  do |name,sig|
        #             port_pairs << [sig, sig.type.inner(name)]
        #         end
        #     end
        #     obj = self
        #     # Make the inner connection
        #     port_pairs.each do |sig, port|
        #         sig.parent.open do
        #             port.to_ref <= sig
        #         end
        #     end

        #     # Set ups the accesser's namespace
        #     loc_inputs.each do |name,sig|
        #         @accesser_namespace.add_method(sig.name) do
        #             HDLRuby::High.top_user.send(name)
        #         end
        #     end
        #     loc_outputs.each do |name,sig|
        #         @accesser_namespace.add_method(sig.name) do
        #             HDLRuby::High.top_user.send(name)
        #         end
        #     end
        #     loc_inouts.each do |name,sig|
        #         @accesser_namespace.add_method(sig.name) do
        #             HDLRuby::High.top_user.send(name)
        #         end
        #     end

        #     # Give access to the ports through name.
        #     # NOTE: for now, simply associate the channel to name.
        #     chp = ChannelPortA.new(@accesser_namespace,@reader_proc,@writer_proc,@inout_reseter_proc)
        #     HDLRuby::High.space_reg(name) { chp }
        #     return chp
        # end


        
        ## Performs a read on the channel using +args+ and +ruby_block+
        #  as arguments.
        #  NOTE:
        #  * Will generate a port if not present.
        #  * Will generate an error if a read is tempted while the read
        #    port has been declared within another system.
        def read(*args,&ruby_block)
            # Is there a port to read?
            unless self.read_port then
                # No, generate a new one.
                # Is it possible to be inout?
                if self.inout? then
                    # Yes, create an inout port.
                    self.inout(HDLRuby.uniq_name)
                else
                    # No, create an input port.
                    self.input(HDLRuby.uniq_name)
                end
            end
            # Ensure the read port is within current system.
            unless self.read_port.scope.system != HDLRuby::High.cur_system then
                raise "Cannot read from a port external of current system for channel " + self.name
            end
            # Performs the read.
            self.read_port.read(*args,&ruby_block)
        end
        
        ## Performs a write on the channel using +args+ and +ruby_block+
        #  as arguments.
        #  NOTE:
        #  * Will generate a port if not present.
        #  * Will generate an error if a read is tempted while the read
        #    port has been declared within another system.
        def write(*args,&ruby_block)
            # Is there a port to write?
            unless self.write_port then
                # No, generate a new one.
                # Is it possible to be inout?
                if self.inout? then
                    # Yes, create an inout port.
                    self.inout(HDLRuby.uniq_name)
                else
                    # No, create an output port.
                    self.output(HDLRuby.uniq_name)
                end
            end
            # Ensure the write port is within current system.
            unless self.write_port.scope.system != HDLRuby::High.cur_system then
                raise "Cannot write from a port external of current system for channel " + self.name
            end
            # Performs the write.
            self.write_port.write(*args,&ruby_block)
        end
        

        ## Performs a reset on the channel using +args+ and +ruby_block+
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


    # Wrapper to make an object run like a channel port.
    class ChannelPortObject < ChannelPort
        # Create a new object wrapper for +obj+.
        def initialize(obj)
            @obj = obj

            @scope = HDLRuby::High.cur_scope
        end

        # Port read with arguments +args+ executing +ruby_block+ in
        # case of success.
        def read(*args,&ruby_block)
            # Get the target from the arguments.
            target = args.pop
            # Is there any argument left?
            unless (args.empty?) then
                # There are arguments left, perform an array access.
                target <= @obj[*args]
            else
                # There are no argument left, perform a direct access.
                target <= @obj
            end
            # Execute the ruby_block if any.
            ruby_block.call if ruby_block 
        end

        # Port write with argumnet +Args+ executing +ruby_block+ in
        # case of success.
        def write(*args,&ruby_block)
            # Get the value to write from the arguments.
            value = args.pop
            # Is there any argument left?
            unless (args.empty?) then
                # There are arguments left, perform an array access.
                @obj[*args] <= value
            else
                # There are no argument left, perform a direct access.
                @obj <= value
            end
            # Execute the ruby_block if any.
            ruby_block.call if ruby_block 
        end

    end


    # Wrap object +obj+ to act like a channel port.
    def self.channel_port(obj)
        return obj if obj.is_a?(ChannelPort) # No need to wrap.
        return ChannelPortObject.new(obj)
    end
    def channel_port(obj)
        return HDLRuby::High::Std.channel_port(obj)
    end
end


# module HDLRuby::High
# 
#     ## Enhance expressions with possibility to act like a reading branch.
#     module HExpression
#         ## Transmits the expression to +target+ and execute +ruby_block+ if
#         #  any.
#         def read(target,&ruby_block)
#             target <= self
#             ruby_block.call if ruby_block
#         end
#     end
# 
# 
#     ## Enhance references with possibility to act like a writing branch.
#     module HRef
#         ## Transmits +target+ to the reference and execute +ruby_block+ if
#         #  any.
#         def write(target,&ruby_block)
#             self <= target
#             ruby_block.call if ruby_block
#         end
#     end
# end
