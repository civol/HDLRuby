require "HDLRuby/hruby_base"

##
# Low-level libraries for describing digital hardware.        
#######################################################
module HDLRuby::Low

    Base = HDLRuby::Base

    ## 
    # Describes system type.
    class SystemT < Base::SystemT

        # Library of the existing system types.
        SystemTs = { }
        private_constant :SystemTs

        # Get an existing system type by +name+.
        def self.get(name)

            return name if name.is_a?(SystemT)
            return SystemTs[name.to_sym]
        end

        # Creates a new system type named +name+.
        def initialize(name)
            # Initialize the system type structure.
            super(name)
            # Update the library of existing system types.
            # Note: no check is made so an exisiting system type with a same
            # name is overwritten.
            SystemTs[@name] = self
        end

        # Handling the signals.

        # # Adds input signal instance +signalI+.
        # def add_input(signalI)
        #     # Checks and add the signalI.
        #     unless signalI.is_a?(SignalI)
        #         raise "Invalid class for a signal instance: #{signalI.class}"
        #     end
        #     if @inputs.has_key?(signalI.name) then
        #         raise "SignalI #{signalI.name} already present."
        #     end
        #     @inputs[signalI.name] = signalI
        # end

        # # Adds output  signal instance +signalI+.
        # def add_output(signalI)
        #     # Checks and add the signalI.
        #     unless signalI.is_a?(SignalI)
        #         raise "Invalid class for a signal instance: #{signalI.class}"
        #     end
        #     if @outputs.has_key?(signalI.name) then
        #         raise "SignalI #{signalI.name} already present."
        #     end
        #     @outputs[signalI.name] = signalI
        # end

        # # Adds inout signal instance +singalI+.
        # def add_inout(signalI)
        #     # Checks and add the signalI.
        #     unless signalI.is_a?(SignalI)
        #         raise "Invalid class for a signal instance: #{signalI.class}"
        #     end
        #     if @inouts.has_key?(signalI.name) then
        #         raise "SignalI #{signalI.name} already present."
        #     end
        #     @inouts[signalI.name] = signalI
        # end

        # # Adds inner signal instance +signalI+.
        # def add_inner(signalI)
        #     # Checks and add the signalI.
        #     unless signalI.is_a?(SignalI)
        #         raise "Invalid class for a signal instance: #{signalI.class}"
        #     end
        #     if @inners.has_key?(signalI.name) then
        #         raise "SignalI #{signalI.name} already present."
        #     end
        #     @inners[signalI.name] = signalI
        # end

        # # Iterates over the input signal instances.
        # #
        # # Returns an enumerator if no ruby block is given.
        # def each_input(&ruby_block)
        #     # No ruby block? Return an enumerator.
        #     return to_enum(:each_input) unless ruby_block
        #     # A block? Apply it on each input signal instance.
        #     @inputs.each_value(&ruby_block)
        # end

        # # Iterates over the output signal instances.
        # #
        # # Returns an enumerator if no ruby block is given.
        # def each_output(&ruby_block)
        #     # No ruby block? Return an enumerator.
        #     return to_enum(:each_output) unless ruby_block
        #     # A block? Apply it on each output signal instance.
        #     @outputs.each_value(&ruby_block)
        # end

        # # Iterates over the inout signal instances.
        # #
        # # Returns an enumerator if no ruby block is given.
        # def each_inout(&ruby_block)
        #     # No ruby block? Return an enumerator.
        #     return to_enum(:each_inout) unless ruby_block
        #     # A block? Apply it on each inout signal instance.
        #     @inouts.each_value(&ruby_block)
        # end

        # # Iterates over the inner signal instances.
        # #
        # # Returns an enumerator if no ruby block is given.
        # def each_inner(&ruby_block)
        #     # No ruby block? Return an enumerator.
        #     return to_enum(:each_inner) unless ruby_block
        #     # A block? Apply it on each inner signal instance.
        #     @inners.each_value(&ruby_block)
        # end

        # # Iterates over all the signal instances (input, output, inout, inner).
        # #
        # # Returns an enumerator if no ruby block is given.
        # def each_signalI(&ruby_block)
        #     # No ruby block? Return an enumerator.
        #     return to_enum(:each_signalI) unless ruby_block
        #     # A block? Apply it on each signal instance.
        #     @inputs.each_value(&ruby_block)
        #     @outputs.each_value(&ruby_block)
        #     @inouts.each_value(&ruby_block)
        #     @inners.each_value(&ruby_block)
        # end

        # ## Gets an input by +name+.
        # def get_input(name)
        #     return @inputs[name]
        # end

        # ## Gets an output by +name+.
        # def get_output(name)
        #     return @outputs[name]
        # end

        # ## Gets an inout by +name+.
        # def get_inout(name)
        #     return @inouts[name]
        # end

        # ## Gets an inner by +name+.
        # def get_inner(name)
        #     return @inners[name]
        # end

        # ## Gets a signal instance by +name+.
        # def get_signalI(name)
        #     # Try in the inputs.
        #     signalI = get_input(name)
        #     return signalI if signalI
        #     # Try in the outputs.
        #     signalI = get_output(name)
        #     return signalI if signalI
        #     # Try in the inouts.
        #     signalI = get_inout(name)
        #     return signalI if signalI
        #     # Not found yet, look into the inners.
        #     return get_inner(name)
        # end

        # Handling the system instances.

        # Adds system instance +systemI+.
        def add_systemI(systemI)
            # Checks and add the systemI.
            unless systemI.is_a?(SystemI)
                raise "Invalid class for a system instance: #{systemI.class}"
            end
            if @systemIs.has_key?(systemI.name) then
                raise "SystemI #{systemI.name} already present."
            end
            @systemIs[systemI.name] = systemI
        end
        
        # Adds input signal +signal+.
        def add_input(signal)
            # Checks and add the signal.
            unless signal.is_a?(Signal)
                raise "Invalid class for a signal instance: #{signal.class}"
            end
            if @inputs.has_key?(signal.name) then
                raise "Signal #{signal.name} already present."
            end
            @inputs[signal.name] = signal
        end

        # Adds output  signal +signal+.
        def add_output(signal)
            # Checks and add the signal.
            unless signal.is_a?(Signal)
                raise "Invalid class for a signal instance: #{signal.class}"
            end
            if @outputs.has_key?(signal.name) then
                raise "Signal #{signal.name} already present."
            end
            @outputs[signal.name] = signal
        end

        # Adds inout signal +signal+.
        def add_inout(signal)
            # Checks and add the signal.
            unless signal.is_a?(Signal)
                raise "Invalid class for a signal instance: #{signal.class}"
            end
            if @inouts.has_key?(signal.name) then
                raise "Signal #{signal.name} already present."
            end
            @inouts[signal.name] = signal
        end

        # Adds inner signal +signal+.
        def add_inner(signal)
            # Checks and add the signal.
            unless signal.is_a?(Signal)
                raise "Invalid class for a signal instance: #{signal.class}"
            end
            if @inners.has_key?(signal.name) then
                raise "Signal #{signal.name} already present."
            end
            @inners[signal.name] = signal
        end

        # Iterates over the input signals.
        #
        # Returns an enumerator if no ruby block is given.
        def each_input(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_input) unless ruby_block
            # A block? Apply it on each input signal instance.
            @inputs.each_value(&ruby_block)
        end

        # Iterates over the output signals.
        #
        # Returns an enumerator if no ruby block is given.
        def each_output(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_output) unless ruby_block
            # A block? Apply it on each output signal instance.
            @outputs.each_value(&ruby_block)
        end

        # Iterates over the inout signals.
        #
        # Returns an enumerator if no ruby block is given.
        def each_inout(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_inout) unless ruby_block
            # A block? Apply it on each inout signal instance.
            @inouts.each_value(&ruby_block)
        end

        # Iterates over the inner signals.
        #
        # Returns an enumerator if no ruby block is given.
        def each_inner(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_inner) unless ruby_block
            # A block? Apply it on each inner signal instance.
            @inners.each_value(&ruby_block)
        end

        # Iterates over all the signals (input, output, inout, inner).
        #
        # Returns an enumerator if no ruby block is given.
        def each_signal(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_signal) unless ruby_block
            # A block? Apply it on each signal instance.
            @inputs.each_value(&ruby_block)
            @outputs.each_value(&ruby_block)
            @inouts.each_value(&ruby_block)
            @inners.each_value(&ruby_block)
        end

        ## Gets an input signal by +name+.
        def get_input(name)
            return @inputs[name]
        end

        ## Gets an output signal by +name+.
        def get_output(name)
            return @outputs[name]
        end

        ## Gets an inout signal by +name+.
        def get_inout(name)
            return @inouts[name]
        end

        ## Gets an inner signal by +name+.
        def get_inner(name)
            return @inners[name]
        end

        ## Gets a signal by +name+.
        def get_signal(name)
            # Try in the inputs.
            signal = get_input(name)
            return signal if signal
            # Try in the outputs.
            signal = get_output(name)
            return signal if signal
            # Try in the inouts.
            signal = get_inout(name)
            return signal if signal
            # Not found yet, look into the inners.
            return get_inner(name)
        end

        # Iterates over the system instances.
        #
        # Returns an enumerator if no ruby block is given.
        def each_systemI(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_systemI) unless ruby_block
            # A block? Apply it on each system instance.
            @systemIs.each_value(&ruby_block)
        end

        ## Gets a system instance by +name+.
        def get_systemI(name)
            return @systemIs[name]
        end

        # Handling the connections.

        # Adds a +connection+.
        def add_connection(connection)
            unless connection.is_a?(Connection)
                raise "Invalid class for a connection: #{connection.class}"
            end
            @connections << connection
        end

        # Iterates over the connections.
        #
        # Returns an enumerator if no ruby block is given.
        def each_connection(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_connection) unless ruby_block
            # A block? Apply it on each connection.
            @connections.each(&ruby_block)
        end

        # Handling the behaviors.

        # Adds a +behavior+.
        def add_behavior(behavior)
            unless behavior.is_a?(Behavior)
                raise "Invalid class for a behavior: #{behavior.class}"
            end
            @behaviors << behavior
        end

        # Iterates over the behaviors.
        #
        # Returns an enumerator if no ruby block is given.
        def each_behavior(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_behavior) unless ruby_block
            # A block? Apply it on each behavior.
            @behaviors.each(&ruby_block)
        end

    end


    ##
    # Describes a data type.
    class Type < Base::Type
        # The base type
        attr_reader :base

        # The size in bits
        attr_reader :size

        # Library of the existing types.
        Types = { }
        private_constant :Types

        # Get an existing signal type by +name+.
        def self.get(name)
            return name if name.is_a?(Type)
            return Types[name.to_sym]
        end

        # Creates a new type named +name+ based of +base+ and of +size+ bits.
        def initialize(name,base,size)
            # Initialize the structure of the data type.
            super(name)
            # Check and set the base.
            @base = base.to_sym
            # Check and set the size.
            @size = size.to_i

            # Update the library of existing types.
            # Note: no check is made so an exisiting type with a same
            # name is overwritten.
            Types[@name] = self
        end
    end


    ##
    # Describes a behavior.
    class Behavior < Base::Behavior
    end


    ##
    # Describes a timed behavior.
    #
    # NOTE: 
    # * this is the only kind of behavior that can include time statements. 
    # * this kind of behavior is not synthesizable!
    class TimeBehavior < Base::TimeBehavior
    end


    ## 
    # Describes an event.
    class Event < Base::Event
    end


    ## 
    # Describes a block.
    class Block < Base::Block
    end

    # Describes a timed block.
    #
    # NOTE: 
    # * this is the only kind of block that can include time statements. 
    # * this kind of block is not synthesizable!
    class TimeBlock < Base::Block
    end


    ##
    # Decribes a piece of software code.
    class Code < Base::Code
    end


    ##
    # Describes a signal.
    class Signal < Base::Signal
        # Creates a new signal named +name+ typed as +type+.
        def initialize(name,type)
            # Ensures type is from Low::Type
            type = Type.get(type)
            # Initialize the signal structure.
            super(name,type)
        end
    end


    ## 
    # Describes a system instance.
    class SystemI < Base::SystemI

        # Creates a new system instance of system type +systemT+ named +name+.
        def initialize(name, systemT)
            # Ensures systemT is from Low::SystemT
            systemT = SystemT.get(systemT)
            # Initialize the system instance structure.
            super(name,systemT)
        end
    end



    ## 
    # Describes a statement.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Statement < Base::Statement
    end


    # ##
    # # Describes a declare statement.
    # class Declare < Base::Declare
    # end


    ## 
    # Decribes a transmission statement.
    class Transmit < Base::Transmit
    end


    ## 
    # Describes an if statement.
    class If < Base::If
    end


    ## 
    # Describes a case statement.
    class Case < Base::Case
    end


    ## 
    # Describes a time statement: not synthesizable!
    class Time < Base::Type
    end



    ## 
    # Describes a connection.
    #
    # NOTE: eventhough a connection is semantically different from a
    # transmission, it has a common structure. Therefore, it is described
    # as a subclass of a transmit.
    class Connection < Base::Connection
    end



    ## 
    # Describes an expression.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Expression < Base::Expression
    end
    

    ##
    # Describes a value.
    class Value < Base::Value
        # Creates a new value typed as +type+ and containing numeric +content+.
        def initialize(type,content)
            # Ensures type is from Low::Type
            type = Type.get(type)
            # Ensures the content is valid for low-level hardware.
            unless content.is_a?(Numeric) then
                raise "Invalid type for a value content: #{content.class}."
            end
            # Initialize the value structure.
            super(type,content)
        end
    end


    ##
    # Describes an operation.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Operation < Base::Operation
    end


    ## 
    # Describes an unary operation.
    class Unary < Base::Unary
    end


    ##
    # Describes an binary operation.
    class Binary < Base::Binary
    end


    # ##
    # # Describes a ternary operation.
    # class Ternary < Base::Ternary
    # end

    
    ##
    # Describes a section operation (generalization of the ternary operator).
    #
    # NOTE: choice is using the value of +select+ as an index.
    class Select < Base::Select
    end


    ## 
    # Describes a concatenation expression.
    class Concat < Base::Concat
    end


    ## 
    # Describes a reference expression.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Ref < Base::Ref
    end


    ##
    # Describes reference concatenation.
    class RefConcat < Base::RefConcat
    end


    ## 
    # Describes an index reference.
    class RefIndex < Base::RefIndex
    end


    ## 
    # Describes a range reference.
    class RefRange < Base::RefRange
    end


    ##
    # Describes a name reference.
    class RefName < Base::RefName
    end


    ## 
    # Describe a this reference.
    #
    # This is the current system.
    class RefThis < Base::RefThis
    end


    # Ensures constants defined is this module are prioritary.
    # @!visibility private
    def self.included(base) # :nodoc:
        if base.const_defined?(:Signal) then
            base.send(:remove_const,:Signal)
            base.const_set(:Signal,HDLRuby::Low::Signal)
        end
    end

end
