require 'yaml'

module HDLRuby

    # Reduce a constant +name+ to +num+ number of namespace levels.
    def self.const_reduce(name, num = 1)
        levels = name.split("::")
        return levels[-([num,levels.size].min)..-1].join("::")
    end


    # The classes meant to support to_basic.
    TO_BASICS = [
                 # Low::SystemT, Low::SignalT, Low::Behavior, Low::TimeBehavior,
                 Low::SystemT, Low::Type, Low::Behavior, Low::TimeBehavior, 
                 Low::Event, Low::Block, Low::TimeBlock, Low::Code, 
                 # Low::SignalI, Low::SystemI, Low::Connection, 
                 Low::Signal, Low::SystemI, Low::Connection, 
                 # Low::Declare, 
                 Low::Transmit, Low::If, Low::Case,
                 Low::TimeWait, Low::TimeRepeat,
                 Low::Delay,
                 # Low::Value, Low::Unary, Low::Binary, Low::Ternary, Low::Concat,
                 Low::Value, Low::Unary, Low::Binary, Low::Select, Low::Concat,
                 Low::RefConcat, Low::RefIndex, Low::RefRange,
                 Low::RefName, Low::RefThis
                ] 
    # The names of the classes of HFLRuby supporting to_basic
    TO_BASIC_NAMES = TO_BASICS.map { |klass| const_reduce(klass.to_s) }
    # The classes describing types (must be described only once)
    # TO_BASICS_TYPES = [Low::SystemT, Low::SignalT]
    TO_BASICS_TYPES = [Low::SystemT, Low::Type]

    # Tells if a +basic+ structure is a representation of an HDLRuby object.
    def self.is_basic_HDLRuby?(basic)
        return ( basic.is_a?(Hash) and basic.size == 1 and
            TO_BASIC_NAMES.include?(HDLRuby.const_reduce(basic.keys[0])) )
    end


    # Converts a +value+ to a basic structure easy-to-write YAML string.
    #
    # Other parameters:
    #   +top+:: indicates if the object is the top of the
    #   description or not. If it is the top, the namespace it comes
    #   from is kept.
    #   +types+:: contains the type objects which will have to be converted
    #   separately.
    def self.value_to_basic(value, types = {})
        # Depending on the class.
        if value.is_a?(Symbol) then
            # Symbol objects are converted to strings.
            return value.to_s
        elsif value.is_a?(String) then
            # String objects are cloned for avoid side effects.
            return value.clone
        elsif value.is_a?(Numeric) or value.is_a?(NilClass) then
            # Nil and Numeric objects are kept as they are.
            return value
        elsif value.is_a?(Array) then
            # Arrays are kept as they are, but their content is converted
            # to basic.
            return value.map { |elem| value_to_basic(elem,types) }
        elsif value.is_a?(Hash) then
            # Maybe the hash is empty.
            if value.empty? then
                return { }
            end
            # Maybe it is a hash of named objects.
            if TO_BASICS.include?(value.first[1].class) then
                # Yes, convert it to an array since it is a hash with names.
                return value.map { |k,v| value_to_basic(v,types) }
            else
                # No, basic hash. They are kept as they are, but their content
                # is converted to basic.
                return value.map do |k,v|
                    [value_to_basic(k,types), value_to_basic(v,types)]
                end.to_h
            end
        else
            # For the other cases, only HDLRuby classes supporting to_basic
            # are supported.
            unless TO_BASICS.include?(value.class) then
                raise "Invalid class for converting to basic structure: #{value.class}"
            end
            return value.to_basic(false,types)
        end
    end


    # Convert a +basic+ structure to a ruby object.
    def self.basic_to_value(basic)
        # print "For basic=#{basic} (#{basic.class})\n"
        # Detect which kind of basic struture it is.
        if basic.is_a?(NilClass) or basic.is_a?(Numeric) then
            # String or Numeric objects are kept as they are.
            return basic
        elsif basic.is_a?(String) then
            # String objects are cloned for avoiding side effects.
            return basic.clone
        elsif basic.is_a?(Array) then
            # Array objects are kept as they are, but their content is converted
            # to basic.
            return basic.map { |elem| basic_to_value(elem) }
        elsif basic.is_a?(Hash) then
            # Is the hash representing a class?
            # print "basic.size = #{basic.size}\n"
            if basic.size == 1 then
                # print "name = #{HDLRuby.const_reduce(basic.keys[0])}\n"
            end
            if is_basic_HDLRuby?(basic) then
                # Yes, rebuild the object.
                # First get the class.
                klass = HDLRuby.const_get(basic.keys[0])
                # print "klass=#{klass}\n"
                # The the content.
                content = basic.values[0]
                # Single instance variables are set with the constructure,
                # separate them from the multiple instances.
                multiples,singles = content.partition do |k,v|
                    (v.is_a?(Hash) or v.is_a?(Array)) and !is_basic_HDLRuby?(v)
                end
                # Create the object.
                object = klass.new(*singles.map{|k,v| basic_to_value(v) })
                # Adds the multiple instances.
                multiples.each do |k,v|
                    # Construct the add method: add_<key name without ending s>
                    add_meth = ("add_" + k)[0..-2].to_sym
                    # Treat the values a an array.
                    v = v.values if v.is_a?(Hash)
                    v.each do |elem|
                        object.send(add_meth, basic_to_value(elem) )
                    end
                end
                return object
            else
                # No, this a standard hash, keep it as is but convert its 
                # contents.
                return basic.map do |k,v|
                    [ basic_to_value(k), basic_to_value(v) ]
                end.to_h
            end
        else
            # Other cases should happen.
            raise "Invalid class for a basic object: #{basic.class}."
        end
    end


    # Convert a stream to a HDLRuby list of objects.
    def self.from_yaml(stream)
        # Get the basic structure from the stream.
        basic = YAML.load_stream(stream)
        # Convert the basic structure to HDLRuby objects.
        return basic_to_value(basic)
    end
    
    #
    # Module adding serialization capability to HDLRuby classes
    ###########################################################
    module Serializer
    
        # Converts the object to a basic structure which can be dumped into an
        # easy-to-write YAML string.
        #
        # Other parameters:
        #   +top+:: indicates if the object is the top of the
        #   description or not. If it is the top, the namespace it comes
        #   from is kept.
        #   +types+:: contains the type objects which will have to be converted
        #   separately.
        def to_basic(top = true, types = {})
            if !top and TO_BASICS_TYPES.include?(self.class) then
                # Type object, but not the top, add it to the types list
                # without converting it.
                # print "Adding type with name=#{self.name}\n"
                types[self.name] = self
                # And return the name.
                return self.name.to_s
            end
            # print "to_basic for class=#{self.class}\n"
            # Create the hash which will contains the content of the object.
            content = { }
            # Create the resulting hash with a single entry whose key
            # is the class name and whose value is the content of the
            # object.
            class_name = self.class.to_s
            # if top then
            #     # Top object: keep the right-most module in the name.
            #     class_name = HDLRuby.const_reduce(class_name,2)
            # else
            #     # Not a top object: keep only the class name.
            #     class_name = HDLRuby.const_reduce(class_name)
            # end
            # Keep only the class name
            class_name = HDLRuby.const_reduce(class_name)

            result = { class_name => content }
            # Fills the contents with the instance variables value.
            self.instance_variables.each do |var_sym|
                # print "for instance variable #{var_sym}...\n"
                # Get the value of the variable.
                var_val = self.instance_variable_get(var_sym)
                # Remove the @ from the symbol.
                var_sym = var_sym.to_s[1..-1]
                # Sets the content.
                content[var_sym] = HDLRuby.value_to_basic(var_val,types)
            end

            if top and !types.empty? then
                # It is a top and there where types.
                # The result is a sequence including each type and the
                # current object.
                result = [ result ]
                types.each do |name,type|
                    # print "Dumping type with name=#{name}\n"
                    type_basic = type.to_basic(true)
                    type_basic = type_basic.last if type_basic.is_a?(Array)
                    result.unshift(type_basic)
                end
            end

            # Return the resulting hash.
            return result
        end

        # Converts the object to YAML string.
        def to_yaml
            return YAML.dump_stream(*to_basic)
        end
    end


    # Adds the serializing features to the HDLRuby classes supporting to_basic.
    TO_BASICS.each { |klass| klass.include(Serializer) }
end
