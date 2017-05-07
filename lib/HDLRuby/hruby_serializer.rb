require 'yaml'

module HDLRuby

    # Gather the classes meant to support to_basic.
    TO_BASICS = [Low::SystemT, Low::SignalT, Low::Behavior, Low::TimeBehavior, 
                 Low::Event, Low::Block, Low::TimeBlock, Low::Code, 
                 Low::SignalI, Low::SystemI, Low::Connection, 
                 Low::Declare, Low::Transmit, Low::If, Low::Case, Low::Time, 
                 Low::Value, Low::Unary, Low::Binary, Low::Ternary, Low::Concat,
                 Low::PortConcat, Low::PortIndex, Low::PortRange,
                 Low::PortName, Low::PortThis] 
    # Gather the name of the classes of HFLRuby supporting to_basic
    TO_BASIC_NAMES = TO_BASICS.map { |klass| klass.to_s }


    # Converts a +value+ to a basic structure easy-to-write YAML string
    def self.value_to_basic(value)
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
            return value.map { |elem| value_to_basic(elem) }
        elsif value.is_a?(Hash) then
            # Arrays are kept as they are, but their content is converted
            # to basic.
            return value.map do |k,v|
                [value_to_basic(k), value_to_basic(v)]
            end.to_h
        else
            # For the other cases, only HDLRuby classes supporting to_basic
            # are supported.
            unless TO_BASICS.include?(value.class) then
                raise "Invalid class for converting to basic structure: #{value.class}"
            end
            return value.to_basic(false)
        end
    end

    # Convert a +basic+ structure to a ruby object.
    def self.basic_to_value(basic)
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
            if basic.size == 1 and TO_BASIC_NAMES.include?(basic.keys[0]) then
                # Yes, rebuild the object.
                # First get the class.
                klass = HDLRuby.const_get(basic.key[0])
                # The the content.
                content = basic.values[0]
                # Single instance variables are set with the constructure,
                # separate them from the multiple instances.
                multiples,singles = content.partition do |k,v|
                    v.is_a?(Hash) or v.is_a?(Array)
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
            end
            # No, this a standard hash, keep it as is but convert its contents.
            return basic.map do |k,v|
                [ basic_to_value(k), basic_to_value(v) ]
            end.to_h
        else
            # Other cases should happen.
            raise "Invalid class for a basic object: #{basic.class}."
        end
    end
    
    #
    # Module adding serialization capability to HDLRuby classes
    ###########################################################
    module Serializer
    
        # Converts the object to a basic structure which can be dumped into an
        # easy-to-write YAML string.
        #
        # Parameter +top+ indicates if the object is the top of the
        # description or not. If it is the top, the namespace it comes
        # from is kept.
        def to_basic(top = true)
            # print "to_basic for class=#{self.class}\n"
            # Create the hash which will contains the content of the object.
            content = { }
            # Create the resulting hash with a single entry whose key
            # is the class name and whose value is the content of the
            # object.
            class_name = self.class.to_s
            if top then
                # Top object: keep the right-most module in the name.
                class_name = class_name.split("::")[-2..-1].join("::")
            else
                # Not a top object: keep only the class name.
                class_name = class_name.split("::").last
            end

            result = { class_name => content }
            # Fills the contents with the instance variables value.
            self.instance_variables.each do |var_sym|
                # print "for instance variable #{var_sym}...\n"
                # Get the value of the variable.
                var_val = self.instance_variable_get(var_sym)
                # Remove the @ from the symbol.
                var_sym = var_sym.to_s[1..-1]
                # Sets the content.
                content[var_sym] = HDLRuby.value_to_basic(var_val)
            end
            # Return the resulting hash.
            return result
        end

        # Converts the object to YAML string.
        def to_yaml
            return YAML.dump(to_basic)
        end
    end


    # Adds the serializing features to the HDLRuby classes supporting to_basic.
    TO_BASICS.each { |klass| klass.include(Serializer) }
end
