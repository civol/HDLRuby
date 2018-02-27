require "HDLRuby/hruby_bstr"


module HDLRuby
    # Some useful constants
    Infinity = +1.0/0.0
end
    


##
# Library for describing the basic structures of the hardware component.
#
# NOTE: not meant do be used directly, please @see HDLRuby::High and
# @see HDLRuby::Low
########################################################################
module HDLRuby::Base

    ##
    # Describes a hash for named HDLRuby objects
    class HashName < Hash
        # Adds a named +object+.
        def add(object)
            self[object.name] = object
        end

        # Tells if +object+ is included in the hash.
        def include?(object)
            return self.has_key?(object.name)
        end

        # Iterate over the objects included in the hash.
        alias :each :each_value
    end

    ##
    # Gives parent definition and access properties to an hardware object.
    module Hparent
        # The parent.
        attr_reader :parent

        # Set the +parent+.
        #
        # Note: if +parent+ is nil, the current parent is removed.
        def parent=(parent)
            if @parent and parent and !@parent.equal?(parent) then
                # The parent is already defined,it is not to be removed,
                # and the new parent is different, error.
                raise "Parent already defined."
            else
                @parent = parent
            end
        end
    end


    ## 
    # Describes system type.
    class SystemT

        # The name of the system.
        attr_reader :name

        # Creates a new system type named +name+.
        def initialize(name)
            # Set the name as a symbol.
            @name = name.to_sym
            # Initialize the signal instance lists.
            # @inputs = {}
            # @outputs = {}
            # @inouts = {}
            # @inners = {}
            @inputs  = HashName.new
            @outputs = HashName.new
            @inouts  = HashName.new
            @inners  = HashName.new
            # Initialize the system instances list.
            # @systemIs = {}
            @systemIs = HashName.new
            # Initialize the connections list.
            @connections = []
            # Initialize the behaviors lists.
            @behaviors = []
        end

        # Handling the system instances.

        # Adds system instance +systemI+.
        def add_systemI(systemI)
            # Checks and add the systemI.
            unless systemI.is_a?(SystemI)
                raise "Invalid class for a system instance: #{systemI.class}"
            end
            # if @systemIs.has_key?(systemI.name) then
            if @systemIs.include?(systemI) then
                raise "SystemI #{systemI.name} already present."
            end
            # @systemIs[systemI.name] = systemI
            # Set the parent of the instance
            systemI.parent = self
            # puts "systemI = #{systemI}, parent=#{self}"
            # Add the instance
            @systemIs.add(systemI)
        end

        # Iterates over the system instances.
        #
        # Returns an enumerator if no ruby block is given.
        def each_systemI(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_systemI) unless ruby_block
            # A block? Apply it on each system instance.
            # @systemIs.each_value(&ruby_block)
            @systemIs.each(&ruby_block)
        end

        # Tells if there is any system instance.
        def has_systemI?
            return !@systemIs.empty?
        end

        # Gets a system instance by +name+.
        def get_systemI(name)
            return @systemIs[name]
        end

        # Deletes system instance systemI.
        def delete_systemI(systemI)
            if @systemIs.key?(systemI.name) then
                # The instance is present, do remove it.
                @systemIs.delete(systemI.name)
                # And remove its parent.
                systemI.parent = nil
            end
            systemI
        end

        # Handling the signals.
        
        # Adds input signal +signal+.
        def add_input(signal)
            # print "add_input with signal: #{signal.name}\n"
            # Checks and add the signal.
            unless signal.is_a?(SignalI)
                raise "Invalid class for a signal instance: #{signal.class}"
            end
            # if @inputs.has_key?(signal.name) then
            if @inputs.include?(signal) then
                raise "SignalI #{signal.name} already present."
            end
            # @inputs[signal.name] = signal
            # Set the parent of the signal.
            signal.parent = self
            # And add the signal.
            @inputs.add(signal)
        end

        # Adds output  signal +signal+.
        def add_output(signal)
            # Checks and add the signal.
            unless signal.is_a?(SignalI)
                raise "Invalid class for a signal instance: #{signal.class}"
            end
            # if @outputs.has_key?(signal.name) then
            if @outputs.include?(signal) then
                raise "SignalI #{signal.name} already present."
            end
            # @outputs[signal.name] = signal
            # Set the parent of the signal.
            signal.parent = self
            # And add the signal.
            @outputs.add(signal)
        end

        # Adds inout signal +signal+.
        def add_inout(signal)
            # Checks and add the signal.
            unless signal.is_a?(SignalI)
                raise "Invalid class for a signal instance: #{signal.class}"
            end
            # if @inouts.has_key?(signal.name) then
            if @inouts.include?(signal) then
                raise "SignalI #{signal.name} already present."
            end
            # @inouts[signal.name] = signal
            # Set the parent of the signal.
            signal.parent = self
            # And add the signal.
            @inouts.add(signal)
        end

        # Adds inner signal +signal+.
        def add_inner(signal)
            # Checks and add the signal.
            unless signal.is_a?(SignalI)
                raise "Invalid class for a signal instance: #{signal.class}"
            end
            # if @inners.has_key?(signal.name) then
            if @inners.include?(signal) then
                raise "SignalI #{signal.name} already present."
            end
            # @inners[signal.name] = signal
            # Set the parent of the signal.
            signal.parent = self
            # And add the signal.
            @inners.add(signal)
        end

        # Iterates over the input signals.
        #
        # Returns an enumerator if no ruby block is given.
        def each_input(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_input) unless ruby_block
            # A block? Apply it on each input signal instance.
            # @inputs.each_value(&ruby_block)
            @inputs.each(&ruby_block)
        end

        # Iterates over the output signals.
        #
        # Returns an enumerator if no ruby block is given.
        def each_output(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_output) unless ruby_block
            # A block? Apply it on each output signal instance.
            # @outputs.each_value(&ruby_block)
            @outputs.each(&ruby_block)
        end

        # Iterates over the inout signals.
        #
        # Returns an enumerator if no ruby block is given.
        def each_inout(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_inout) unless ruby_block
            # A block? Apply it on each inout signal instance.
            # @inouts.each_value(&ruby_block)
            @inouts.each(&ruby_block)
        end

        # Iterates over the inner signals.
        #
        # Returns an enumerator if no ruby block is given.
        def each_inner(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_inner) unless ruby_block
            # A block? Apply it on each inner signal instance.
            # @inners.each_value(&ruby_block)
            @inners.each(&ruby_block)
        end

        # Iterates over all the signals (input, output, inout, inner).
        #
        # Returns an enumerator if no ruby block is given.
        def each_signal(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_signal) unless ruby_block
            # A block? Apply it on each signal instance.
            # @inputs.each_value(&ruby_block)
            # @outputs.each_value(&ruby_block)
            # @inouts.each_value(&ruby_block)
            # @inners.each_value(&ruby_block)
            @inputs.each(&ruby_block)
            @outputs.each(&ruby_block)
            @inouts.each(&ruby_block)
            @inners.each(&ruby_block)
        end

        # Iterates over all the signals of the system type and its system
        # instances.
        def each_signal_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_signal_deep) unless ruby_block
            # A block?
            # First iterate over the current system type's signals.
            self.each_signal(&ruby_block)
            # Then apply on the behaviors (since in HDLRuby:High, blocks can
            # include signals).
            self.each_behavior do |behavior|
                behavior.block.each_signal_deep(&ruby_block)
            end
            # Then recurse on the system instances.
            self.each_systemI do |systemI|
                systemI.each_signal_deep(&ruby_block)
            end
        end

        # Tells if there is any input.
        def has_input?
            return !@inputs.empty?
        end

        # Tells if there is any output.
        def has_output?
            return !@outputs.empty?
        end

        # Tells if there is any output.
        def has_inout?
            return !@inouts.empty?
        end

        # Tells if there is any inner.
        def has_inner?
            return !@inners.empty?
        end

        # Tells if there is any signal.
        def has_signal?
            return ( self.has_input? or self.has_output? or self.has_inout? or
                     self.has_inner? )
        end

        ## Gets an input signal by +name+.
        def get_input(name)
            return @inputs[name.to_sym]
        end

        ## Gets an output signal by +name+.
        def get_output(name)
            return @outputs[name.to_sym]
        end

        ## Gets an inout signal by +name+.
        def get_inout(name)
            return @inouts[name.to_sym]
        end

        ## Gets an inner signal by +name+.
        def get_inner(name)
            return @inners[name.to_sym]
        end

        ## Gets a signal by +path+.
        #
        #  NOTE: +path+ can also be a single name or a reference object.
        def get_signal(path)
            path = path.path_each if path.respond_to?(:path_each) # Ref case.
            if path.respond_to?(:each) then
                # Path is iterable: look for the first name.
                path = path.each
                name = path.each.next
                # Maybe it is a system instance.
                systemI = self.get_systemI(name)
                if systemI then
                    # Yes, look for the remaining of the path into the
                    # corresponding system type.
                    return systemI.systemT.get_signal(path)
                else
                    # Maybe it is a signal name.
                    return self.get_signal(name)
                end
            else
                # Path is a single name, look for the signal in the system's
                # Try in the inputs.
                signal = get_input(path)
                return signal if signal
                # Try in the outputs.
                signal = get_output(path)
                return signal if signal
                # Try in the inouts.
                signal = get_inout(path)
                return signal if signal
                # Not found yet, look into the inners.
                return get_inner(path)
            end
        end

        # Deletes input +signal+.
        def delete_input(signal)
            if @inputs.key?(signal) then
                # The signal is present, delete it.
                @inputs.delete(signal.name)
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
                # And remove its parent.
                signal.parent = nil
            end
            signal
        end

        # Deletes inner +signal+.
        def delete_inner(signal)
            if @inners.key?(signal) then
                # The signal is present, delete it. 
                @inners.delete(signal.name)
                # And remove its parent.
                signal.parent = nil
            end
            signal
        end

        # Handling the connections.

        # Adds a +connection+.
        def add_connection(connection)
            unless connection.is_a?(Connection)
                raise "Invalid class for a connection: #{connection.class}"
            end
            # Set the parent of the connection.
            connection.parent = self
            # And add it.
            @connections << connection
            connection
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

        # Tells if there is any connection.
        def has_connection?
            return !@connections.empty?
        end

        # Deletes +connection+.
        def delete_connection(connection)
            if @connections.include?(connection) then
                # The connection is present, delete it.
                @connections.delete(connection)
                # And remove its parent.
                connection.parent = nil
            end
            connection
        end

        # Iterates over all the connections of the system type and its system
        # instances.
        def each_connection_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_connection_deep) unless ruby_block
            # A block?
            # First iterate over current system type's connection.
            self.each_connection(&ruby_block)
            # Then recurse on the system instances.
            self.each_systemI do |systemI|
                systemI.each_connection_deep(&ruby_block)
            end
        end

        # Handling the behaviors.

        # Adds a +behavior+.
        def add_behavior(behavior)
            unless behavior.is_a?(Behavior)
                raise "Invalid class for a behavior: #{behavior.class}"
            end
            # Set its parent
            behavior.parent = self
            # And add it
            @behaviors << behavior
            behavior
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

        # Reverse iterates over the behaviors.
        #
        # Returns an enumerator if no ruby block is given.
        def reverse_each_behavior(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_behavior) unless ruby_block
            # A block? Apply it on each behavior.
            @behaviors.reverse_each(&ruby_block)
        end

        # Returns the last behavior.
        def last_behavior
            return @behaviors[-1]
        end

        # Iterates over all the behaviors of the system type and its system
        # instances.
        def each_behavior_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_behavior_deep) unless ruby_block
            # A block?
            # First iterate over current system type's behavior.
            self.each_behavior(&ruby_block)
            # Then recurse on the system instances.
            self.each_systemI do |systemI|
                systemI.each_behavior_deep(&ruby_block)
            end
        end

        # Tells if there is any inner.
        def has_behavior?
            return !@behaviors.empty?
        end

        # Deletes +behavior+.
        def delete_behavior(behavior)
            if @behaviors.include?(behavior) then
                # The behavior is present, delete it.
                @behaviors.delete(behavior)
                # And remove its parent.
                behavior.parent = nil
            end
        end

        # Iterates over all the blocks of the system type and its system
        # instances.
        def each_block_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block_deep) unless ruby_block
            # A block?
            # First apply it on the current's block.
            ruby_block.call(self)
            # Then apply it on each behavior's block deeply.
            self.each_behavior_deep do |behavior|
                behavior.block.each_block_deep(&ruby_block)
            end
        end

        # Iterates over all the stamements of the system type and its system
        # instances.
        def each_statement_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_statement_deep) unless ruby_block
            # A ruby block?
            # Apply it on each block deeply.
            self.each_block_deep do |block|
                block.each_statement_deep(&ruby_block)
            end
        end

        # Iterates over all the statements and connections of the system type
        # and its system instances.
        def each_arrow_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_arrow_deep) unless ruby_block
            # A block?
            # First, apply it on each connection.
            self.each_connection do |connection|
                ruby_block.call(connection)
            end
            # Then recurse over its blocks.
            self.each_behavior do |behavior|
                behavior.each_block_deep(&ruby_block)
            end
            # Finally recurse on its system instances.
            self.each_systemI do |systemI|
                systemI.each_arrow_deep(&ruby_block)
            end
        end

        # Iterates over all the object executed when a specific event is
        # activated (they include the behaviors and the connections).
        #
        # NOTE: the arguments of the ruby block are the object and an enumerator
        # over the set of events it is sensitive to.
        def each_sensitive_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_sensitive_deep) unless ruby_block
            # A block?
            # First iterate over the current system type's connections.
            self.each_connection do |connection|
                ruby_block.call(connection,
                                connection.each_ref_deep.lazy.map do |ref|
                    Event.new(:change,ref)
                end)
            end
            # First iterate over the current system type's behaviors.
            self.each_behavior do |behavior|
                ruby_block.call(behavior,behavior.each_event)
            end
            # Then recurse on the system instances.
            self.each_systemI do |systemI|
                systemI.each_sensitive_deep(&ruby_block)
            end
        end

    end

    
    ##
    # Describes a data type.
    class Type
        # The name of the type
        attr_reader :name

        # Creates a new type named +name+.
        def initialize(name)
            # Check and set the name.
            @name = name.to_sym
        end

        # # The widths of the basic types.
        # WIDTHS = { :bit => 1, :unsigned => 1, :signed => 1 }

        # # The signs of the basic types.
        # SIGNS = { :signed => true, :fixnum => true, :float => true,
        #           :bignum => true }
        # SIGNS.default = false

        # # Gets the bitwidth of the type, nil for undefined.
        # #
        # # NOTE: must be redefined for specific types.
        # def width
        #     res = WIDTHS[self.name]
        #     unless res then
        #         raise "Invalid type for a width."
        #     end
        #     return res
        # end

        # # Tells if the type signed, false for unsigned.
        # def signed?
        #     return SIGNS[self.name]
        # end

        # # Tells if the type is unsigned, false for signed.
        # def unsigned?
        #     return !signed?
        # end

        # # Tells if the type is floating point.
        # def float?
        #     return self.name == :float
        # end

        # # Checks the compatibility with +type+
        # def compatible?(type)
        #     # # If type is void, compatible anyway.
        #     # return true if type.name == :void
        #     # Default: base types cases.
        #     case self.name
        #     # when :void then
        #     #     # void is compatible with anything.
        #     #     return true
        #     when :bit then
        #         # bit is compatible with bit signed and unsigned.
        #         return [:bit,:signed,:unsigned].include?(type.name)
        #     when :signed then
        #         # Signed is compatible with bit and signed.
        #         return [:bit,:signed].include?(type.name)
        #     when :unsigned then
        #         # Unsigned is compatible with bit and unsigned.
        #         return [:bit,:unsigned].include?(type.name)
        #     else
        #         # Unknown type for compatibility: not compatible by default.
        #         return false
        #     end
        # end

        # # Merges with +type+
        # def merge(type)
        #     # # If type is void, return self.
        #     # return self if type.name == :void
        #     # Default: base types cases.
        #     case self.name
        #     # when :void then
        #     #     # void: return type
        #     #     return type
        #     when :bit then
        #         # bit is compatible with bit signed and unsigned.
        #         if [:bit,:signed,:unsigned].include?(type.name) then
        #             return type
        #         else
        #             raise "Incompatible types for merging: #{self}, #{type}."
        #         end
        #     when :signed then
        #         # Signed is compatible with bit and signed.
        #         if [:bit,:signed].include?(type.name) then
        #             return self
        #         else
        #             raise "Incompatible types for merging: #{self}, #{type}."
        #         end
        #     when :unsigned then
        #         # Unsigned is compatible with bit and unsigned.
        #         if [:bit,:unsigned].include?(type.name)
        #             return self
        #         else
        #             raise "Incompatible types for merging: #{self}, #{type}."
        #         end
        #     else
        #         # Unknown type for compatibility: not compatible by default.
        #         raise "Incompatible types for merging: #{self}, #{type}."
        #     end
        # end


        # Tells if the type signed.
        def signed?
            return false
        end

        # Tells if the type is unsigned.
        def unsigned?
            return false
        end

        # Tells if the type is fixed point.
        def fixed?
            return false
        end

        # Tells if the type is floating point.
        def float?
            return false
        end

    end

    # The leaf types.
    
    ##
    # The bit types leaf.
    class << ( Bit = Type.new(:bit) )
        # Tells if the type fixed point.
        def fixed?
            return true
        end
        # Gets the bitwidth of the type, nil for undefined.
        def width
            1
        end
        # Gets the range of the type.
        def range
            0..0
        end
    end

    ##
    # The signed types leaf.
    class << ( Signed = Type.new(:signed) )
        # Tells if the type is signed.
        def signed?
            return true
        end
        # Tells if the type is fixed point.
        def fixed?
            return true
        end
        # Gets the bitwidth of the type, nil for undefined.
        def width
            1
        end
        # Gets the range of the type.
        def range
            0..0
        end
    end

    ##
    # The unsigned types leaf.
    class << ( Unsigned = Type.new(:unsigned) )
        # Tells if the type is unsigned.
        def unsigned?
            return true
        end
        # Tells if the type is fixed point.
        def fixed?
            return true
        end
        # Gets the bitwidth of the type, nil for undefined.
        def width
            1
        end
        # Gets the range of the type.
        def range
            0..0
        end
    end

    ##
    # The float types leaf.
    class << ( Float = Type.new(:float) )
        # Tells if the type is signed.
        def signed?
            return true
        end
        # Tells if the type is floating point.
        def float?
            return true
        end
        # Gets the bitwidth of the type, nil for undefined.
        def width
            1
        end
        # Gets the range of the type.
        def range
            0..0
        end
    end


    ##
    # Describes a vector type.
    class TypeVector < Type
        # The base type of the vector
        attr_reader :base

        # The range of the vector.
        attr_reader :range

        # Creates a new vector type named +name+ from +base+ type and with
        # +range+.
        def initialize(name,base,range)
            # Initialize the type.
            super(name)

            # Check and set the base
            unless base.is_a?(Type)
                raise "Invalid class for VectorType base: #{base.class}."
            end
            @base = base

            # Check and set the range.
            if range.respond_to?(:to_i) then
                # Integer case: convert to 0..(range-1).
                range = (range-1)..0
            elsif
                # Other cases: assume there is a first and a last to create
                # the range.
                range = range.first..range.last
            end
            @range = range
        end

        # Gets the bitwidth of the type, nil for undefined.
        #
        # NOTE: must be redefined for specific types.
        def width
            first = @range.first
            last  = @range.last
            return @base.width * (first-last).abs
        end

        # Gets the direction of the range.
        def dir
            return (@range.last - @range.first)
        end

        # Tells if the type signed.
        def signed?
            return @base.signed?
        end

        # Tells if the type is unsigned.
        def unsigned?
            return @base.unsigned?
        end

        # Tells if the type is fixed point.
        def fixed?
            return @base.signed?
        end

        # Tells if the type is floating point.
        def float?
            return @base.float?
        end

        # # Checks the compatibility with +type+
        # def compatible?(type)
        #     # # if type is void, compatible anyway.
        #     # return true if type.name == :void
        #     # Compatible if same width and compatible base.
        #     return false unless type.respond_to?(:dir)
        #     return false unless type.respond_to?(:base)
        #     return ( self.dir == type.dir and
        #              self.base.compatible?(type.base) )
        # end

        # # Merges with +type+
        # def merge(type)
        #     # # if type is void, return self anyway.
        #     # return self if type.name == :void
        #     # Compatible if same width and compatible base.
        #     unless type.respond_to?(:dir) and type.respond_to?(:base) then
        #         raise "Incompatible types for merging: #{self}, #{type}."
        #     end
        #     unless self.dir == type.dir then
        #         raise "Incompatible types for merging: #{self}, #{type}."
        #     end
        #     return TypeVector.new(@name,@range,@base.merge(type.base))
        # end
    end


    ##
    # Describes a signed integer data type.
    class TypeSigned < TypeVector

        # Creates a new vector type named +name+ from +base+ type and with
        # +range+.
        #
        # NOTE:
        # * The default range is 32-bit.
        def initialize(name,range = 31..0)
            # Initialize the type.
            super(name,Signed,range)
        end
    end

    ##
    # Describes a unsigned integer data type.
    class TypeUnsigned < TypeVector

        # Creates a new vector type named +name+ from +base+ type and with
        # +range+.
        #
        # NOTE:
        # * The default range is 32-bit.
        def initialize(name,range = 31..0)
            # Initialize the type.
            super(name,Unsigned,range)
        end
    end

    ##
    # Describes a float data type.
    class TypeFloat < TypeVector

        # Creates a new vector type named +name+ from +base+ type and with
        # +range+.
        #
        # NOTE:
        # * The bits of negative range stands for the exponent
        # * The default range is for 64-bit IEEE 754 double precision standart
        def initialize(name,range = 52..-11)
            # Initialize the type.
            super(name,Float,range)
        end
    end

    # Standard vector types.
    Integer = TypeSigned.new(:integer)
    Natural = TypeUnsigned.new(:natural)
    Bignum  = TypeSigned.new(:bignum,HDLRuby::Infinity..0)
    Real    = TypeFloat.new(:float)



    ##
    # Describes a tuple type.
    class TypeTuple < Type
        # Creates a new tuple type named +name+ whose sub types are given
        # by +content+.
        def initialize(name,*content)
            # Initialize the type.
            super(name)

            # Check and set the content.
            content.each do |sub|
                unless sub.is_a?(Type) then
                    raise "Invalid class for a type: #{sub.class}"
                end
            end
            @types = content
        end

        # Gets a sub type by +index+.
        def get_type(index)
            return @types[index.to_i]
        end

        # Iterates over the sub name/type pair.
        #
        # Returns an enumerator if no ruby block is given.
        def each(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each) unless ruby_block
            # A block? Apply it on each input signal instance.
            @types.each(&ruby_block)
        end

        # Iterates over the sub types.
        #
        # Returns an enumerator if no ruby block is given.
        def each_type(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_type) unless ruby_block
            # A block? Apply it on each input signal instance.
            @types.each_value(&ruby_block)
        end

        # Gets the bitwidth
        def width
            return @types.reduce(0) { |sum,type| sum + type.width }
        end
    end


    ##
    # Describes a structure type.
    class TypeStruct < Type
        # Creates a new structure type named +name+ whose hierachy is given
        # by +content+.
        def initialize(name,content)
            # Initialize the type.
            super(name)

            # Check and set the content.
            content = Hash[content]
            @types = content.map do |k,v|
                unless v.is_a?(Type) then
                    raise "Invalid class for a type: #{v.class}"
                end
                [ k.to_sym, v ]
            end.to_h
        end

        # Gets a sub type by +name+.
        def get_type(name)
            return @types[name.to_sym]
        end

        # Iterates over the sub name/type pair.
        #
        # Returns an enumerator if no ruby block is given.
        def each(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each) unless ruby_block
            # A block? Apply it on each input signal instance.
            @types.each(&ruby_block)
        end

        # Iterates over the sub types.
        #
        # Returns an enumerator if no ruby block is given.
        def each_type(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_type) unless ruby_block
            # A block? Apply it on each input signal instance.
            @types.each_value(&ruby_block)
        end

        # Iterates over the sub type names.
        #
        # Returns an enumerator if no ruby block is given.
        def each_name(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_name) unless ruby_block
            # A block? Apply it on each input signal instance.
            @types.each_key(&ruby_block)
        end

        # Gets the bitwidth of the type, nil for undefined.
        #
        # NOTE: must be redefined for specific types.
        def width
            return @types.reduce(0) {|sum,type| sum + type.width }
        end

        # Checks the compatibility with +type+
        def compatible?(type)
            # # If type is void, compatible anyway.
            # return true if type.name == :void
            # Not compatible if different types.
            return false unless type.is_a?(TypeStruct)
            # Not compatibe unless each entry has the same name in same order.
            return false unless self.each_name == type.each_name
            self.each do |name,sub|
                return false unless sub.compatible?(self.get_type(name))
            end
            return true
        end

        # Merges with +type+
        def merge(type)
            # # if type is void, return self anyway.
            # return self if type.name == :void
            # Not compatible if different types.
            unless type.is_a?(TypeStruct) then
                raise "Incompatible types for merging: #{self}, #{type}."
            end
            # Not compatibe unless each entry has the same name and same order.
            unless self.each_name == type.each_name then
                raise "Incompatible types for merging: #{self}, #{type}."
            end
            # Creates the new type content
            content = {}
            self.each do |name,sub|
                content[name] = self.get_type(name).merge(sub)
            end
            return TypeStruct.new(@name,content)
        end  
    end



    ##
    # Describes a behavior.
    class Behavior

        include Hparent

        # # Creates a new behavior.
        # def initialize
        #     # Initialize the sensitivity list.
        #     @events = []
        #     # Initialize the block list.
        #     @blocks = []
        # end

        # The block executed by the behavior.
        attr_reader :block

        # Creates a new behavior executing +block+.
        def initialize(block)
            # Initialize the sensitivity list.
            @events = []
            # Check and set the block.
            return unless block # No block case
            # There is a block
            self.block = block
            # unless block.is_a?(Block)
            #     raise "Invalid class for a block: #{block.class}."
            # end
            # # Time blocks are only supported in Time Behaviors.
            # if block.is_a?(TimeBlock)
            #     raise "Timed blocks are not supported in common behaviors."
            # end
            # # Set the block's parent.
            # block.parent = self
            # # And set the block
            # @block = block
        end

        # Sets the block if not already set.
        def block=(block)
            # Check the block.
            unless block.is_a?(Block)
                raise "Invalid class for a block: #{block.class}."
            end
            # Time blocks are only supported in Time Behaviors.
            if block.is_a?(TimeBlock)
                raise "Timed blocks are not supported in common behaviors."
            end
            # Set the block's parent.
            block.parent = self
            # And set the block
            @block = block
        end

        # Handle the sensitivity list.

        # Adds an +event+ to the sensitivity list.
        def add_event(event)
            unless event.is_a?(Event)
                raise "Invalid class for a event: #{event.class}"
            end
            # Set the event's parent.
            event.parent = self
            # And add the event.
            @events << event
            event
        end

        # Iterates over the events of the sensitivity list.
        #
        # Returns an enumerator if no ruby block is given.
        def each_event(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_event) unless ruby_block
            # A block? Apply it on each event.
            @events.each(&ruby_block)
        end

        # Tells if there is any event.
        def has_event?
            return !@events.empty?
        end

        # Tells if there is a positive or negative edge event.
        def on_edge?
            @events.each do |event|
                return true if event.on_edge?
            end
            return false
        end

        # Short cuts to the enclosed block.
        
        # Iterates over the statements.
        #
        # Returns an enumerator if no ruby block is given.
        def each_statement(&ruby_block)
            @block.each_statement(&ruby_block)
        end

        # Reverse iterates over the statements.
        #
        # Returns an enumerator if no ruby block is given.
        def reverse_each_statement(&ruby_block)
            @block.reverse_each_statement(&ruby_block)
        end

        # Returns the last statement.
        def last_statement
            @block.last_statement
        end

    end


    ##
    # Describes a timed behavior.
    #
    # NOTE: 
    # * this is the only kind of behavior that can include time statements. 
    # * this kind of behavior is not synthesizable!
    class TimeBehavior < Behavior
        # Creates a new time behavior executing +block+.
        def initialize(block)
            # Initialize the sensitivity list.
            @events = []
            # Check and set the block.
            unless block.is_a?(Block)
                raise "Invalid class for a block: #{block.class}."
            end
            # Time blocks are supported here.
            @block = block
        end

        # Time behavior do not have other event than time, so deactivate
        # the relevant methods.
        def add_event(event)
            raise "Time behaviors do not have any sensitivity list."
        end
    end


    ## 
    # Describes an event.
    class Event

        include Hparent

        # The type of event.
        attr_reader :type

        # The reference of the event.
        attr_reader :ref

        # Creates a new +type+ sort of event on signal refered by +ref+.
        def initialize(type,ref)
            # Check and set the type.
            @type = type.to_sym
            # Check and set the reference.
            unless ref.is_a?(Ref)
                raise "Invalid class for a reference: #{ref.class}"
            end
            @ref = ref
        end

        # Tells if there is a positive or negative edge event.
        #
        # NOTE: checks if the event type is :posedge or :negedge
        def on_edge?
            return (@type == :posedge or @type == :negedge)
        end
    end


    ##
    # Describes a signal.
    class SignalI

        include Hparent
        
        # The name of the signal
        attr_reader :name

        # The type of the signal
        attr_reader :type

        # Creates a new signal named +name+ typed as +type+.
        def initialize(name,type)
            # Check and set the name.
            @name = name.to_sym
            # Check and set the type.
            if type.is_a?(Type) then
                @type = type
            else
                raise "Invalid class for a type: #{type.class}."
            end
        end

        # Gets the bit width.
        def width
            return @type.width
        end
    end


    ## 
    # Describes a system instance.
    class SystemI

        include Hparent

        # The name of the instance if any.
        attr_reader :name

        # The instantiated system.
        attr_reader :systemT

        # Creates a new system instance of system type +systemT+ named +name+.
        def initialize(name, systemT)
            # Set the name as a symbol.
            @name = name.to_sym
            # Check and set the systemT.
            if !systemT.is_a?(SystemT) then
                raise "Invalid class for a system type: #{systemT.class}"
            end
            @systemT = systemT
        end

        # Rename with +name+
        #
        # NOTE: use with care since it can jeopardise the lookup structures.
        def name=(name)
            @name = name.to_sym
        end
        # protected :name=

        # Delegate inner accesses to the system type.
        extend Forwardable
        
        # @!method each_input
        #   @see SystemT#each_input
        # @!method each_output
        #   @see SystemT#each_output
        # @!method each_inout
        #   @see SystemT#each_inout
        # @!method each_inner
        #   @see SystemT#each_inner
        # @!method each_signal
        #   @see SystemT#each_signal
        # @!method get_input
        #   @see SystemT#get_input
        # @!method get_output
        #   @see SystemT#get_output
        # @!method get_inout
        #   @see SystemT#get_inout
        # @!method get_inner
        #   @see SystemT#get_inner
        # @!method get_signal
        #   @see SystemT#get_signal
        # @!method each_signal
        #   @see SystemT#each_signal
        # @!method each_signal_deep
        #   @see SystemT#each_signal_deep
        # @!method each_systemI
        #   @see SystemT#each_systemI
        # @!method get_systemI
        #   @see SystemT#get_systemI
        # @!method each_statement_deep
        #   @see SystemT#each_statement_deep
        # @!method each_connection
        #   @see SystemT#each_connection
        # @!method each_connection_deep
        #   @see SystemT#each_connection_deep
        # @!method each_arrow_deep
        #   @see SystemT#each_arrow_deep
        # @!method each_behavior
        #   @see SystemT#each_behavior
        # @!method each_behavior_deep
        #   @see SystemT#each_behavior_deep
        # @!method each_block_deep
        #   @see SystemT#each_block_deep
        # @!method each_sensitive_deep
        #   @see SystemT#each_sensitive_deep
        def_delegators :@systemT,
                       :each_input, :each_output, :each_inout, :each_inner,
                       :each_signal, :each_signal_deep,
                       :get_input, :get_output, :get_inout, :get_inner,
                       :get_signal,
                       :each_systemI, :get_systemI,
                       :each_connection, :each_connection_deep,
                       :each_statement_deep, :each_arrow_deep,
                       :each_behavior, :each_behavior_deep, :each_block_deep,
                       :each_sensitive_deep
    end



    ## 
    # Describes a statement.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Statement
        include Hparent
    end


    # ##
    # # Describes a declare statement.
    # class Declare < Statement
    #     # The declared signal instance.
    #     attr_reader :signal

    #     # Creates a new statement declaring +signal+.
    #     def initialize(signal)
    #         # Check and set the declared signal instance.
    #         unless signal.is_a?(SignalI)
    #             raise "Invalid class for declaring a signal: #{signal.class}"
    #         end
    #         @signal = signal
    #     end
    # end


    ## 
    # Decribes a transmission statement.
    class Transmit < Statement
        
        # The left reference.
        attr_reader :left
        
        # The right expression.
        attr_reader :right

        # Creates a new transmission from a +right+ expression to a +left+
        # reference.
        def initialize(left,right)
            # Check and set the left reference.
            unless left.is_a?(Ref)
                raise "Invalid class for a reference (left value): #{left.class}"
            end
            @left = left
            # and set its parent.
            left.parent = self
            # Check and set the right expression.
            unless right.is_a?(Expression)
                raise "Invalid class for an expression (right value): #{right.class}"
            end
            @right = right
            # and set its parent.
            right.parent = self
        end

        # Iterates over the expression children if any.
        def each_child(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_child) unless ruby_block
            # A block? Apply it on the children.
            ruby_block.call(@left)
            ruby_block.call(@right)
        end
    end


    ## 
    # Describes an if statement.
    class If < Statement
        # The condition
        attr_reader :condition

        # The yes and no statements
        attr_reader :yes, :no

        # Creates a new if statement with a +condition+ and a +yes+ and +no+
        # blocks.
        def initialize(condition, yes, no = nil)
            # Check and set the condition.
            unless condition.is_a?(Expression)
                raise "Invalid class for a condition: #{condition.class}"
            end
            @condition = condition
            # And set its parent.
            condition.parent = self
            # Check and set the yes statement.
            unless yes.is_a?(Statement)
                raise "Invalid class for a statement: #{yes.class}"
            end
            @yes = yes
            # And set its parent.
            yes.parent = self
            # Check and set the yes statement.
            if no and !no.is_a?(Statement)
                raise "Invalid class for a statement: #{no.class}"
            end
            @no = no
            # And set its parent.
            no.parent = self if no

            # Initialize the list of alternative if statements (elsif)
            @noifs = []
        end

        # Sets the no block.
        #
        # No shoud only be set once, but this is not checked here for
        # sake of flexibility.
        def no=(no)
            # if @no != nil then
            #     raise "No already set in if statement."
            # end # Actually better not lock no here.
            # Check and set the yes statement.
            unless no.is_a?(Statement)
                raise "Invalid class for a statement: #{no.class}"
            end
            @no = no
            # And set its parent.
            no.parent = self
        end

        # Adds an alternative if statement (elsif) testing +next_cond+
        # and executing +next_yes+ when the condition is met.
        def add_noif(next_cond, next_yes)
            # Check the condition.
            unless next_cond.is_a?(Expression)
                raise "Invalid class for a condition: #{next_cond.class}"
            end
            # And set its parent.
            next_cond.parent = self
            # Check yes statement.
            unless next_yes.is_a?(Statement)
                raise "Invalid class for a statement: #{next_yes.class}"
            end
            # And set its parent.
            yes.parent = self
            # Add the statement.
            @noifs << [next_cond,next_yes]
        end

        # Iterates over the alternate if statements (elsif).
        def each_noif(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_noif) unless ruby_block
            # A block?
            # Appy it on the alternate if statements.
            @noifs.each do |next_cond,next_yes|
                yield(next_cond,next_yes)
            end
        end
            

        # Iterates over all the blocks contained in the current block.
        def each_block_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block_deep) unless ruby_block
            # A block?
            # Apply it on the yes, the alternate ifs and the no blocks.
            @yes.each_block_deep(&ruby_block)
            @noifs.each do |next_cond,next_yes|
                next_cond.each_block_deep(&ruby_block)
                next_yes.each_block_deep(&ruby_block)
            end
            @no.each_block_deep(&ruby_block)
        end
    end


    ## 
    # Describes a case statement.
    class Case < Statement
        # The tested value
        attr_reader :value

        # The default block.
        attr_reader :default

        # Creates a new case statement whose excution flow is decided from
        # +value+.
        def initialize(value)
            # Check and set the value.
            unless value.is_a?(Expression)
                raise "Invalid class for a value: #{value.class}"
            end
            @value = value
            # And set its parent.
            value.parent = self
            # Initialize the match cases.
            @whens = []
        end

        # Adds a possible +match+ for the case's value that lead to the 
        # execution of +statement+.
        def add_when(match,statement)
            # Checks and sets the match.
            unless match.is_a?(Expression)
                raise "Invalid class for a case match: #{match.class}"
            end
            # Checks and sets the statement.
            unless statement.is_a?(Statement)
                raise "Invalid class for a statement: #{statement.class}"
            end
            @whens << [match,statement]
            # And set their parents.
            match.parent = statement.parent = self
            [match,statement]
        end

        # Sets the default block.
        #
        # No can only be set once.
        def default=(default)
            if @default != nil then
                raise "Default already set in if statement."
            end
            # Check and set the yes statement.
            unless default.is_a?(Statement)
                raise "Invalid class for a statement: #{default.class}"
            end
            @default = default
            # And set its parent.
            default.parent = self
            @default
        end

        # Iterates over the match cases.
        #
        # Returns an enumerator if no ruby block is given.
        def each_when(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_when) unless ruby_block
            # A block? Apply it on each when case.
            @whens.each(&ruby_block)
        end

        # Iterates over all the blocks contained in the current block.
        def each_block_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block_deep) unless ruby_block
            # A block?
            # Apply it on each when's block.
            self.each_when do |value,block|
                block.each_block_deep(&ruby_block)
            end
            # And apply it on the default if any.
            @default.each_block_deep(&ruby_block) if @default
        end
    end


    ##
    # Describes a delay: not synthesizable.
    class Delay

        include Hparent

        # The time unit.
        attr_reader :unit

        # The time value.
        attr_reader :value

        # Creates a new delay of +value+ +unit+ of time.
        def initialize(value,unit)
            # Check and set the value.
            unless value.is_a?(Numeric)
                raise "Invalid class for a delay value: #{value.class}."
            end
            @value = value
            # Check and set the unit.
            @unit = unit.to_sym
        end
    end


    ## 
    # Describes a wait statement: not synthesizable!
    class TimeWait < Statement
        # The delay to wait.
        attr_reader :delay

        # Creates a new statement waiting +delay+.
        def initialize(delay)
            # Check and set the delay.
            unless delay.is_a?(Delay)
                raise "Invalid class for a delay: #{delay.class}."
            end
            @delay = delay
            # And set its parent.
            delay.parent = self
        end

    end


    ## 
    # Describes a timed loop statement: not synthesizable!
    class TimeRepeat < Statement
        # The delay until the loop is repeated
        attr_reader :delay

        # The statement to execute.
        attr_reader :statement

        # Creates a new timed loop statement execute in a loop +statement+ until
        # +delay+ has passed.
        def initialize(statement,delay)
            # Check and set the statement.
            unless statement.is_a?(Statement)
                raise "Invalid class for a statement: #{statement.class}."
            end
            @statement = statement
            # And set its parent.
            statement.parent = self

            # Check and set the delay.
            unless delay.is_a?(Delay)
                raise "Invalid class for a delay: #{delay.class}."
            end
            @delay = delay
            # And set its parent.
            delay.parent = self
        end
    end


    ## 
    # Describes a block.
    class Block < Statement
        # The execution mode of the block.
        attr_reader :mode

        # Creates a new +mode+ sort of block.
        def initialize(mode)
            # Check and set the type.
            @mode = mode.to_sym
            # Initializes the list of inner statements.
            # @inners = {}
            @inners = HashName.new
            # Initializes the list of statements.
            @statements = []
        end

        # Adds inner signal +signal+.
        def add_inner(signal)
            # Checks and add the signal.
            unless signal.is_a?(SignalI)
                raise "Invalid class for a signal instance: #{signal.class}"
            end
            # if @inners.has_key?(signal.name) then
            if @inners.include?(signal) then
                raise "SignalI #{signal.name} already present."
            end
            # @inners[signal.name] = signal
            # Set its parent.
            signal.parent = self
            # And add it
            @inners.add(signal)
        end

        # Iterates over the inner signals.
        #
        # Returns an enumerator if no ruby block is given.
        def each_inner(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_inner) unless ruby_block
            # A block? Apply it on each inner signal instance.
            # @inners.each_value(&ruby_block)
            @inners.each(&ruby_block)
        end
        alias :each_signal :each_inner

        ## Gets an inner signal by +name+.
        def get_inner(name)
            return @inners[name.to_sym]
        end
        alias :get_signal :get_inner

        # Iterates over all the signals of the block and its sub block's ones.
        def each_signal_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_signal_deep) unless ruby_block
            # A block?
            # First, apply on the signals of the block.
            self.each_signal(&ruby_block)
            # Then apply on each sub block. 
            self.each_block_deep do |block|
                block.each_signal_deep(&ruby_block)
            end
        end

        # Adds a +statement+.
        #
        # NOTE: TimeWait is not supported unless for TimeBlock objects.
        def add_statement(statement)
            unless statement.is_a?(Statement) then
                raise "Invalid class for a statement: #{statement.class}"
            end
            if statement.is_a?(TimeWait) then
                raise "Timed statements are not supported in common blocks."
            end
            @statements << statement
            # And set its parent.
            statement.parent = self
            statement
        end

        # Iterates over the statements.
        #
        # Returns an enumerator if no ruby block is given.
        def each_statement(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_statement) unless ruby_block
            # A block? Apply it on each statement.
            @statements.each(&ruby_block)
        end

        # Reverse iterates over the statements.
        #
        # Returns an enumerator if no ruby block is given.
        def reverse_each_statement(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_statement) unless ruby_block
            # A block? Apply it on each statement.
            @statements.reverse_each(&ruby_block)
        end

        # Returns the last statement.
        def last_statement
            return @statements[-1]
        end

        # Deletes +statement+.
        def delete_statement(statement)
            if @statements.include?(statement) then
                # Statement is present, delete it.
                @statements.delete(statement)
                # And remove its parent.
                statement.parent = nil
            end
            statement
        end

        # Iterates over all the blocks contained in the current block.
        def each_block_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block_deep) unless ruby_block
            # A block?
            # Apply it on each statement which contains blocks.
            self.each_statement do |statement|
                if statement.respond_to?(:each_block_deep) then
                    statement.each_block_deep(&ruby_block)
                end
            end
        end

        # Iterates over all the stamements of the block and its sub blocks.
        def each_statement_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_statement_deep) unless ruby_block
            # A block?
            # Apply it on each statement deeply.
            self.each_statement do |statement|
                if statement.respond_to?(:each_statement_deep) then
                    statement.each_statement_deep(&ruby_block)
                end
                ruby_block.call(statement)
            end
        end
    end

    # Describes a timed block.
    #
    # NOTE: 
    # * this is the only kind of block that can include time statements. 
    # * this kind of block is not synthesizable!
    class TimeBlock < Block
        # Adds a +statement+.
        # 
        # NOTE: TimeBlock is supported.
        def add_statement(statement)
            unless statement.is_a?(Statement) then
                raise "Invalid class for a statement: #{statement.class}"
            end
            @statements << statement
            # And set its parent.
            statement.parent = self
            statement
        end
    end


    ##
    # Decribes a piece of software code.
    class Code

        include Hparent

        ## The type of code.
        attr_reader :type

        # Creates a new piece of +type+ code from +content+.
        def initialize(type,&content)
            # Check and set type.
            @type = type.to_sym
            # Set the content.
            @content = content
            # Freeze it to avoid dynamic tempering of the hardware.
            content.freeze
        end
    end


    ## 
    # Describes a connection.
    #
    # NOTE: eventhough a connection is semantically different from a
    # transmission, it has a common structure. Therefore, it is described
    # as a subclass of a transmit.
    class Connection < Transmit
    end



    ## 
    # Describes an expression.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Expression

        include Hparent

        # Iterates over the expression children if any.
        def each_child(&ruby_block)
            # By default: no child.
        end

        # Iterates over all the references encountered in the expression.
        #
        # NOTE: do not iterate *inside* the references.
        def each_ref_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_ref_deep) unless ruby_block
            # puts "each_ref_deep for Expression which is:#{self}"
            # A block?
            # If the expression is a reference, applies ruby_block on it.
            ruby_block.call(self) if self.is_a?(Ref)
        end
    end

    
    ##
    # Describes a value.
    class Value < Expression

        # The type of value.
        attr_reader :type

        # The content of the value.
        attr_reader :content

        # Creates a new value typed +type+ and containing +content+.
        def initialize(type,content)
            # Check and set the type.
            if type.is_a?(Type) then
                @type = type
            else
                raise "Invalid class for a type: #{type.class}."
            end
            # Checks and set the content: Ruby Numeric and HDLRuby BitString 
            # are supported. Strings or equivalent are converted to BitString.
            unless content.is_a?(Numeric) or content.is_a?(HDLRuby::BitString)
                content = HDLRuby::BitString.new(content.to_s)
            end
            @content = content 
        end

        # Compare values.
        #
        # NOTE: mainly used for being supported by ranges.
        def <=>(value)
            value = value.content if value.respond_to?(:content)
            return self.content <=> value
        end

        # Gets the bit width of the value.
        def width
            return @type.width
        end

        # Tells if the value is even.
        def even?
            return @content.even?
        end

        # Tells if the value is odd.
        def odd?
            return @content.odd?
        end
    end


    ##
    # Describes an operation.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Operation < Expression
        # The operator of the operation.
        attr_reader :operator

        # Creates a new operation applying +operator+.
        def initialize(operator)
            # Check and set the operator.
            @operator = operator.to_sym
        end
    end


    ## 
    # Describes an unary operation.
    class Unary < Operation
        # The child.
        attr_reader :child

        # Creates a new unary expression applying +operator+ on +child+
        # expression.
        def initialize(operator,child)
            # Initialize as a general operation.
            super(operator)
            # Check and set the child.
            unless child.is_a?(Expression)
                raise "Invalid class for an expression: #{child.class}"
            end
            # @children = [ child ]
            @child = child
            # And set its parent.
            child.parent = self
        end

        # Iterates over the expression children if any.
        def each_child(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_child) unless ruby_block
            # A block? Apply it on the child.
            ruby_block.call(@child)
        end

        # Iterates over all the references encountered in the expression.
        #
        # NOTE: do not iterate *inside* the references.
        def each_ref_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_ref_deep) unless ruby_block
            # puts "each_ref_deep for Unary"
            # A block?
            # Recurse on the child.
            @child.each_ref_deep(&ruby_block)
        end
    end


    ##
    # Describes an binary operation.
    class Binary < Operation
        # The left child.
        attr_reader :left

        # The right child.
        attr_reader :right

        # Creates a new binary expression applying +operator+ on +left+
        # and +right+ children expressions.
        def initialize(operator,left,right)
            # Initialize as a general operation.
            super(operator)
            # Check and set the children.
            unless left.is_a?(Expression)
                raise "Invalid class for an expression: #{left.class}"
            end
            unless right.is_a?(Expression)
                raise "Invalid class for an expression: #{right.class}"
            end
            @left = left
            @right = right
            # And set their parents.
            left.parent = right.parent = self
        end

        # Iterates over the expression children if any.
        def each_child(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_child) unless ruby_block
            # A block? Apply it on the children.
            ruby_block.call(@left)
            ruby_block.call(@right)
        end

        # Iterates over all the references encountered in the expression.
        #
        # NOTE: do not iterate *inside* the references.
        def each_ref_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_ref_deep) unless ruby_block
            # puts "each_ref_deep for Binary"
            # A block?
            # Recurse on the children.
            @left.each_ref_deep(&ruby_block)
            @right.each_ref_deep(&ruby_block)
        end
    end


    ##
    # Describes a section operation (generalization of the ternary operator).
    #
    # NOTE: choice is using the value of +select+ as an index.
    class Select < Operation
        # The selection child (connection).
        attr_reader :select

        # Creates a new operator selecting from the value of +select+ one
        # of the +choices+.
        def initialize(operator,select,*choices)
            # Initialize as a general operation.
            # super(:"?")
            super(operator)
            # Check and set the selection.
            # puts "select = #{select}"
            unless select.is_a?(Expression)
                raise "Invalid class for an expression: #{select.class}"
            end
            @select = select
            # And set its parent.
            select.parent = self
            # Check and set the choices.
            @choices = []
            choices.each do |choice|
                # unless choice.is_a?(Expression)
                #     raise "Invalid class for an expression: #{choice.class}"
                # end
                # @choices << choice
                # # And set its parent.
                # choice.parent = self
                self.add_choice(choice)
            end
        end

        # Iterates over the expression children if any.
        def each_child(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_child) unless ruby_block
            # A block? Apply it on the children.
            ruby_block.call(@select)
            @choices.each(&ruby_block)
        end

        # Adds a +choice+.
        def add_choice(choice)
            unless choice.is_a?(Expression)
                raise "Invalid class for an expression: #{choice.class}"
            end
            # Set the parent of the choice.
            choice.parent = self
            # And add it.
            @choices << choice
            choice
        end

        # Iterates over the choices.
        #
        # Returns an enumerator if no ruby block is given.
        def each_choice(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_choice) unless ruby_block
            # A block? Apply it on each choice.
            @choices.each(&ruby_block)
        end

        # Gets a choice by +index+.
        def get_choice(index)
            return @choices[index]
        end

        # Iterates over all the references encountered in the expression.
        #
        # NOTE: do not iterate *inside* the references.
        def each_ref_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_ref_deep) unless ruby_block
            # puts "each_ref_deep for Select"
            # A block?
            # Recurse on the children.
            self.select.each_ref_deep(&ruby_block)
            self.each_choice do |choice|
                choice.each_ref_deep(&ruby_block)
            end
        end
    end


    ## 
    # Describes a concatenation expression.
    class Concat < Expression
        # Creates a new expression concatenation several +expressions+ together.
        def initialize(expressions = [])
            # Initialize the array of expressions that are concatenated.
            @expressions = []
            # Check and add the expressions.
            expressions.each { |expression| self.add_expression(expression) }
        end

        # Adds an +expression+ to concat.
        def add_expression(expression)
            # Check expression.
            unless expression.is_a?(Expression) then
                raise "Invalid class for an expression: #{expression.class}"
            end
            # Add it.
            @expressions << expression
            # And set its parent.
            expression.parent = self
            expression
        end

        # Iterates over the concatenated expressions.
        #
        # Returns an enumerator if no ruby block is given.
        def each_expression(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_expression) unless ruby_block
            # A block? Apply it on each children.
            @expressions.each(&ruby_block)
        end
        alias :each_child :each_expression
    end


    ## 
    # Describes a reference expression.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Ref < Expression
        # Iterates over the names of the path indicated by the reference.
        #
        # NOTE: this is not a method for iterating over all the names included
        # in the reference. For instance, this method will return nil without
        # iterating if a RefConcat or is met.
        #
        # Returns an enumerator if no ruby block is given.
        def path_each(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:path_each) unless ruby_block
            # A block? Apply it on... nothing by default.
            return nil
        end

        # Iterates over the reference children if any.
        def each_child(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_child) unless ruby_block
            # A block? Apply it on the children: default none.
        end
    end


    ##
    # Describes concatenation reference.
    class RefConcat < Ref

        # Creates a new reference concatenating the references of +refs+
        # together.
        def initialize(refs = [])
            # Check and set the refs.
            refs.each do |ref|
                unless ref.is_a?(Expression) then
                    raise "Invalid class for an reference: #{ref.class}"
                end
            end
            @refs = refs
            # And set their parents.
            refs.each { |ref| ref.parent = self }
        end

        # Iterates over the concatenated references.
        #
        # Returns an enumerator if no ruby block is given.
        def each_ref(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_input) unless ruby_block
            # A block? Apply it on each children.
            @refs.each(&ruby_block)
        end
        alias :each_child :each_ref
    end


    ## 
    # Describes a index reference.
    class RefIndex < Ref
        # The accessed reference.
        attr_reader :ref

        # The access index.
        attr_reader :index

        # Create a new index reference accessing +ref+ at +index+.
        def initialize(ref,index)
            # Check and set the accessed reference.
            unless ref.is_a?(Ref) then
                raise "Invalid class for a reference: #{ref.class}."
            end
            @ref = ref
            # And set its parent.
            ref.parent = self
            # Check and set the index.
            unless index.is_a?(Expression) then
                raise "Invalid class for an index reference: #{index.class}."
            end
            @index = index
            # And set its parent.
            index.parent = self
        end

        # Iterates over the names of the path indicated by the reference.
        #
        # Returns an enumerator if no ruby block is given.
        def path_each(&ruby_block)
            # Recurse on the base reference.
            return ref.path_each(&ruby_block)
        end

        # Iterates over the reference children if any.
        def each_child(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_child) unless ruby_block
            # A block? Apply it on the child.
            ruby_block.call(@ref)
        end
    end


    ## 
    # Describes a range reference.
    class RefRange < Ref
        # The accessed reference.
        attr_reader :ref

        # The access range.
        attr_reader :range

        # Create a new range reference accessing +ref+ at +range+.
        def initialize(ref,range)
            # Check and set the accessed reference.
            unless ref.is_a?(Ref) then
                raise "Invalid class for a reference: #{ref.class}."
            end
            @ref = ref
            # And set its parent.
            ref.parent = self
            # Check and set the range.
            first = range.first
            unless first.is_a?(Expression) then
                raise "Invalid class for a range first: #{first.class}."
            end
            last = range.last
            unless last.is_a?(Expression) then
                raise "Invalid class for a range last: #{last.class}."
            end
            @range = first..last
            # And set their parents.
            first.parent = last.parent = self
        end

        # Iterates over the names of the path indicated by the reference.
        #
        # Returns an enumerator if no ruby block is given.
        def path_each(&ruby_block)
            # Recurse on the base reference.
            return ref.path_each(&ruby_block)
        end

        # Iterates over the reference children if any.
        def each_child(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_child) unless ruby_block
            # A block? Apply it on the child.
            ruby_block.call(@ref)
        end
    end


    ##
    # Describes a name reference.
    class RefName < Ref
        # The accessed reference.
        attr_reader :ref

        # The access name.
        attr_reader :name

        # Create a new named reference accessing +ref+ with +name+.
        def initialize(ref,name)
            # Check and set the accessed reference.
            unless ref.is_a?(Ref) then
                raise "Invalid class for a reference: #{ref.class}."
            end
            @ref = ref
            # And set its parent.
            ref.parent = self
            # Check and set the symbol.
            @name = name.to_sym
        end

        # Iterates over the names of the path indicated by the reference.
        #
        # Returns an enumerator if no ruby block is given.
        def path_each(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:path_each) unless ruby_block
            # Recurse on the base reference.
            ref.path_each(&ruby_block)
            # Applies the block on the current name.
            ruby_block.call(@name)
        end

        # Iterates over the reference children if any.
        def each_child(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_child) unless ruby_block
            # A block? Apply it on the child.
            ruby_block.call(@ref)
        end
    end


    ## 
    # Describe a this reference.
    #
    # This is the current system.
    class RefThis < Ref 
    end
end
