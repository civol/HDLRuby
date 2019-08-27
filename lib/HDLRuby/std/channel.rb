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
            # Sets the instantiation procedure.
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
            args.each do |nameI|
                channelI = ChannelI.new(name,&@ruby_block)
                HDLRuby::High.space_reg(nameI) { channelI }
                channelI
            end
        end

        alias_method :call, :instantiate
    end


    ## Creates a new channel type named +name+ whose instances are
    #  creating executing +ruby_block+.
    def channel(name,&ruby_block)
        return ChannelT.new(name,&ruby_block)
    end




    ## 
    # Describes a high-level channel instance.
    class ChannelI
        # include HDLRuby::High::HScope_missing
        include HDLRuby::High::Hmissing

        # The name of the channel instance.
        attr_reader :name

        # The namespace associated with the current execution when
        # building a channel, its reader or its writer.
        attr_reader :namespace

        ## Creates a new channel type with +name+ built from +ruby_block+
        def initialize(name,&ruby_block)
            # Check and set the name
            @name = name.to_sym

            obj = self

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

            # Create the namespaces for building the channel, its readers
            # and its writers.

            # Creates the namespace of the channel.
            @channel_namespace = Namespace.new(self)
            # Make it give access to the internal of the class.
            @channel_namespace.add_method(:reader_input, &method(:reader_input))
            @channel_namespace.add_method(:reader_output,&method(:reader_output))
            @channel_namespace.add_method(:reader_inout, &method(:reader_inout))
            @channel_namespace.add_method(:writer_input, &method(:writer_input))
            @channel_namespace.add_method(:writer_output,&method(:writer_output))
            @channel_namespace.add_method(:writer_inout, &method(:writer_inout))
            @channel_namespace.add_method(:reader,       &method(:reader))
            @channel_namespace.add_method(:writer,       &method(:writer))

            # Creates the namespace of the reader.
            @reader_namespace = Namespace.new(self)
            # Creates the namespace of the writer.
            @writer_namespace = Namespace.new(self)

            # By default the namespace is the one of the namespace
            @namespace = @channel_namespace

            # Builds the channel.
            HDLRuby::High.space_push(@namespace)
            # puts "top_user=#{HDLRuby::High.top_user}"
            HDLRuby::High.top_user.instance_eval(&ruby_block)
            HDLRuby::High.space_pop

            # Gives access to the channel by registering its name.
            obj = self
            HDLRuby::High.space_reg(@name) { self }
        end

        # The methods for defining the channel
        
        # For the channel itself
        
        ## Defines new command +name+ to execute +ruby_block+ for the
        #  channel.
        def command(name,&ruby_block)
            # Ensures name is a symbol.
            name = name.to_sym
            # Sets the new command.
            self.define_singleton_method(name) do
                # Executes the command in the right environment.
                HDLRuby::High.space_push(@namespace)
                res = HDLRuby::High.top_user.instance_exec(&ruby_block)
                HDLRuby::High.space_pop
                res
            end
        end
        
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

        ## Sets the read procedure to be +ruby_block+.
        def reader(&ruby_block)
            @reader_proc = ruby_block
        end

        ## Sets the writter procedure to be +ruby_block+.
        def writer(&ruby_block)
            @writer_proc = ruby_block
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

        # Reader an writer side.

        ## Declares the ports for the reader.
        def reader_ports
            loc_inputs  = @reader_inputs
            loc_outputs = @reader_outputs
            loc_inouts  = @reader_inouts
            HDLRuby::High.cur_system.open do
                # The inputs
                loc_inputs.each  { |name,sig| sig.type.input  name }
                # The outputs
                loc_outputs.each { |name,sig| sig.type.output name }
                # The inouts
                loc_inouts.each  { |name,sig| sig.type.inout  name }
            end
        end

        ## Declares the ports for the writer.
        def writer_ports
            loc_inputs  = @writer_inputs
            loc_outputs = @writer_outputs
            loc_inouts  = @writer_inouts
            HDLRuby::High.cur_system.open do
                # The inputs
                loc_inputs.each  { |name,sig| sig.type.input  name }
                # The outputs
                loc_outputs.each { |name,sig| sig.type.output name }
                # The inouts
                loc_inouts.each  { |name,sig| sig.type.inout  name }
            end
        end
        
        ## Performs a read on the channel using +args+ and +ruby_block+
        #  as arguments.
        def read(*args,&ruby_block)
            # Fill the reader namespace with the access to the reader signals.
            @reader_inputs.each do |name,sig|
                @reader_namespace.add_method(sig.name) do
                    HDLRuby::High.top_user.send(name)
                end
            end
            @reader_outputs.each do |name,sig|
                @reader_namespace.add_method(sig.name) do
                    HDLRuby::High.top_user.send(name)
                end
            end
            @reader_inouts.each do |name,sig|
                @reader_namespace.add_method(sig.name) do
                    HDLRuby::High.top_user.send(name)
                end
            end
            # Gain access to the reader as local variable.
            reader_proc = @reader_proc
            # The context is the one of the reader.
            @namespace = @reader_namespace
            # Execute the code generating the reader in context.
            HDLRuby::High.space_push(@namespace)
            HDLRuby::High.cur_block.open do
                instance_exec(ruby_block,*args,&reader_proc)
            end
            HDLRuby::High.space_pop
            # Restores the default context.
            @namespace = @channel_namespace
        end
        
        ## Performs a write on the channel using +args+ and +ruby_block+
        #  as arguments.
        def write(*args,&ruby_block)
            # Fill the writer namespace with the access to the writer signals.
            @writer_inputs.each do |name,sig|
                @writer_namespace.add_method(sig.name) do
                    HDLRuby::High.top_user.send(name)
                end
            end
            @writer_outputs.each do |name,sig|
                @writer_namespace.add_method(sig.name) do
                    HDLRuby::High.top_user.send(name)
                end
            end
            @writer_inouts.each do |name,sig|
                @writer_namespace.add_method(sig.name) do
                    HDLRuby::High.top_user.send(name)
                end
            end
            # Gain access to the writer as local variable.
            writer_proc = @writer_proc
            # The context is the one of the writer.
            @namespace = @writer_namespace
            # Execute the code generating the writer in context.
            HDLRuby::High.space_push(@namespace)
            HDLRuby::High.cur_block.open do
                instance_exec(ruby_block,*args,&writer_proc)
            end
            HDLRuby::High.space_pop
            # Restores the default context.
            @namespace = @channel_namespace
        end
    end

end

