module HDLRuby::High::Std

##
# Standard HDLRuby::High library: channels
# 
########################################################################

    ## 
    # Describes a high-level channel type.
    class ChannelT

        # The name of the channel type.
        attr_reader :name

        # The scope of the channel type.
        attr_reader :scope

        # Creates a new channel type with +name+ and 
        #
        # The proc +ruby_block+ is executed when instantiating the channel.
        def initialize(name,&ruby_block)
            # Check and set the name
            @name = name.to_sym

            # Create the scope
            @scope = Scope.new(@name)
            # Set the parent of the scope
            @scope.parent = self

            # Prepare the instantiation methods
            make_instantiater(&ruby_block)

            # The low level intialization part of ChannelT
            # Initialize the interface (signal instance lists).
            @inputs  = HashName.new # The input signals by name
            @outputs = HashName.new # The output signals by name
            @inouts  = HashName.new # The inout signals by name
            @interface = []         # The interface signals in order of
                                    # declaration
        end


        # Converts to a namespace user.
        def to_user
            # Returns the scope.
            return @scope
        end

        # Creates and adds a set of inputs typed +type+ from a list of +names+.
        #
        # NOTE: a name can also be a signal, is which case it is duplicated. 
        def make_inputs(type, *names)
            res = nil
            names.each do |name|
                if name.respond_to?(:to_sym) then
                    res = self.add_input(SignalI.new(name,type,:input))
                else
                    raise "Invalid class for a name: #{name.class}"
                end
            end
            return res
        end

        # Creates and adds a set of outputs typed +type+ from a list of +names+.
        #
        # NOTE: a name can also be a signal, is which case it is duplicated. 
        def make_outputs(type, *names)
            # puts "type=#{type.inspect}"
            res = nil
            names.each do |name|
                # puts "name=#{name}"
                if name.respond_to?(:to_sym) then
                    res = self.add_output(SignalI.new(name,type,:output))
                else
                    raise "Invalid class for a name: #{name.class}"
                end
            end
            return res
        end

        # Creates and adds a set of inouts typed +type+ from a list of +names+.
        #
        # NOTE: a name can also be a signal, is which case it is duplicated. 
        def make_inouts(type, *names)
            res = nil
            names.each do |name|
                if name.respond_to?(:to_sym) then
                    res = self.add_inout(SignalI.new(name,type,:inout))
                else
                    raise "Invalid class for a name: #{name.class}"
                end
            end
            return res
        end

        # Opens for extension.
        #
        # NOTE: actually executes +ruby_block+ in the context of the scope
        #       of the channel.
        def open(&ruby_block)
            self.scope.open(&ruby_block)
        end

        # The proc used for instantiating the system type.
        attr_reader :instance_proc

        # Instantiate the channel type to an instance named +i_name+ with
        # possible arguments +args+.
        def instantiate(i_name,*args)
            # Create the eigen type.
            eigen = self.class.new(:"")

            # Fills the scope of the eigen class.
            eigen.scope.build_top(self.scope,*args)

            # # Fill the public namespace
            # space = eigen.public_namespace
            # Interface signals
            eigen.each_signal do |signal|
                # space.send(:define_singleton_method,signal.name) { signal }
                space.send(:define_singleton_method,signal.name) do
                    RefObject.new(eigen.owner.to_ref,signal)
                end
            end
            # # Exported objects
            # eigen.each_export do |export|
            #     # space.send(:define_singleton_method,export.name) { export }
            #     space.send(:define_singleton_method,export.name) do
            #         RefObject.new(eigen.owner.to_ref,export)
            #     end
            # end

            # Create the instance.
            instance = ChannelI.new(i_name,eigen)
            # Link it to its eigen system
            eigen.owner = instance

            # # Extend the instance.
            # instance.eigen_extend(@singleton_instanceO)
            # # puts "instance scope= #{instance.systemT.scope}"
            # # Return the resulting instance
            return instance
        end

        # Generates the instantiation capabilities 
        # whose eigen type is initialized by +ruby_block+.
        #
        # NOTE: actually creates two instantiater, a general one, being
        #       registered in the namespace stack, and one for creating an
        #       array of instances being registered in the Array class.
        def make_instantiater(&ruby_block)
            # Unnamed types do not have associated access method.
            return if @name.empty?
            # Set the instantiater
            @instance_proc = ruby_block

            obj = self # For using the right self within the proc

            # Create and register the general instantiater.
            High.space_reg(@name) do |*args|
                # If no name it is actually an access to the channel type.
                return obj if args.empty?
                # Get the names from the arguments.
                i_names = args.shift
                # puts "i_names=#{i_names}(#{i_names.class})"
                i_names = [*i_names]
                instance = nil # The current instance
                i_names.each do |i_name|
                    # Instantiate.
                    instance = obj.instantiate(i_name,*args)
                    # Add the instance.
                    High.top_user.send(add_instance,instance)
                end
                # Return the last instance.
                instance
            end

            # Create and register the array of instances instantiater.
            ::Array.class_eval do
                define_method(@name) { |*args| make(@name,*args) }
            end
        end



        # The "low-level" methods: there is no HDLRuby::Low::ChannelI, so
        # the corresponding methods are put there.

        # Handling the signals.

        # Adds input +signal+.
        def add_input(signal)
            # print "add_input with signal: #{signal.name}\n"
            # Checks and add the signal.
            unless signal.is_a?(SignalI)
                raise "Invalid class for a signal instance: #{signal.class}"
            end
            if @inputs.include?(signal) then
                raise "SignalI #{signal.name} already present."
            end
            # Set the parent of the signal.
            signal.parent = self
            # And add the signal.
            @inputs.add(signal)
            @interface << signal
        end

        # Adds output +signal+.
        def add_output(signal)
            # Checks and add the signal.
            unless signal.is_a?(SignalI)
                raise "Invalid class for a signal instance: #{signal.class}"
            end
            if @outputs.include?(signal) then
                raise "SignalI #{signal.name} already present."
            end
            # Set the parent of the signal.
            signal.parent = self
            # And add the signal.
            @outputs.add(signal)
            @interface << signal
        end

        # Adds inout +signal+.
        def add_inout(signal)
            # Checks and add the signal.
            unless signal.is_a?(SignalI)
                raise "Invalid class for a signal instance: #{signal.class}"
            end
            if @inouts.include?(signal) then
                raise "SignalI #{signal.name} already present."
            end
            # Set the parent of the signal.
            signal.parent = self
            # And add the signal.
            @inouts.add(signal)
            @interface << signal
        end

        # Iterates over the input signals.
        #
        # Returns an enumerator if no ruby block is given.
        def each_input(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_input) unless ruby_block
            # A block? Apply it on each input signal instance.
            @inputs.each(&ruby_block)
        end

        # Iterates over the output signals.
        #
        # Returns an enumerator if no ruby block is given.
        def each_output(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_output) unless ruby_block
            # A block? Apply it on each output signal instance.
            @outputs.each(&ruby_block)
        end

        # Iterates over the inout signals.
        #
        # Returns an enumerator if no ruby block is given.
        def each_inout(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_inout) unless ruby_block
            # A block? Apply it on each inout signal instance.
            @inouts.each(&ruby_block)
        end

        # Iterates over all the signals of the system including its
        # scope (input, output, inout, inner).
        #
        # Returns an enumerator if no ruby block is given.
        def each_signal(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_signal) unless ruby_block
            # A block? Apply it on each signal instance.
            @inputs.each(&ruby_block)
            @outputs.each(&ruby_block)
            @inouts.each(&ruby_block)
        end

        # Iterates over all the signals of the system type and its scope.
        def each_signal_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_signal_deep) unless ruby_block
            # A block?
            # First iterate over the current system type's signals.
            self.each_signal(&ruby_block)
            # Then apply on the behaviors (since in HDLRuby:High, blocks can
            # include signals).
            @scope.each_signal_deep(&ruby_block)
        end

        # Tells if there is any input signal.
        def has_input?
            return !@inputs.empty?
        end

        # Tells if there is any output signal.
        def has_output?
            return !@outputs.empty?
        end

        # Tells if there is any output signal.
        def has_inout?
            return !@inouts.empty?
        end

        # Tells if there is any signal (including in the scope of the system).
        def has_signal?
            return ( self.has_input? or self.has_output? or self.has_inout? or
                     self.has_inner? )
        end

        # Gets an array containing all the input signals.
        def get_all_inputs
            return each_input.to_a
        end

        # Gets an array containing all the output signals.
        def get_all_outputs
            return each_output.to_a
        end

        # Gets an array containing all the inout signals.
        def get_all_inouts
            return each_inout.to_a
        end

        # Gets an array containing all the signals.
        def get_all_signals
            return each_signal.to_a
        end

        # Gets an input signal by +name+.
        def get_input(name)
            return @inputs[name.to_sym]
        end

        # Gets an output signal by +name+.
        def get_output(name)
            return @outputs[name.to_sym]
        end

        # Gets an inout signal by +name+.
        def get_inout(name)
            return @inouts[name.to_sym]
        end

        # # Gets an inner signal by +name+.
        # def get_inner(name)
        #     return @inners[name.to_sym]
        # end

        # Gets a signal by +name+.
        def get_signal(name)
            return get_input(name) || get_output(name) || get_inout(name) # ||
                   # get_inner(name)
        end

        # Gets an interface signal by order of declaration +i+.
        def get_interface(i)
            return @interface[i]
        end

        # Deletes input +signal+.
        def delete_input(signal)
            if @inputs.key?(signal) then
                # The signal is present, delete it.
                @inputs.delete(signal.name)
                @interface.delete(signal)
                # And remove its parent.
                signal.parent = nil
            end
            signal
        end

        # Deletes output +signal+.
        def delete_output(signal)
            if @outputs.key?(signal) then
                # The signal is present, delete it.
                @outputs.delete(signal.name)
                @interface.delete(signal)
                # And remove its parent.
                signal.parent = nil
            end
            signal
        end

        # Deletes inout +signal+.
        def delete_inout(signal)
            if @inouts.key?(signal) then
                # The signal is present, delete it.
                @inouts.delete(signal.name)
                @interface.delete(signal)
                # And remove its parent.
                signal.parent = nil
            end
            signal
        end
    end

end
