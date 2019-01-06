require 'yaml'

require "HDLRuby/hruby_bstr"


module HDLRuby

    # Reduce a constant +name+ to +num+ number of namespace levels.
    def self.const_reduce(name, num = 1)
        levels = name.split("::")
        return levels[-([num,levels.size].min)..-1].join("::")
    end


    # The classes meant to support to_basic.
    TO_BASICS = [
                 # Low::SystemT, Low::SignalT, Low::Behavior, Low::TimeBehavior,
                 Low::SystemT,
                 Low::Scope,
                 Low::Type, # Low::TypeNumeric,
                 Low::TypeDef,
                 Low::TypeVector,
                 Low::TypeSigned, Low::TypeUnsigned, Low::TypeFloat,
                 Low::TypeTuple, Low::TypeStruct,
                 Low::Behavior, Low::TimeBehavior, 
                 Low::Event, Low::Block, Low::TimeBlock, Low::Code, 
                 # Low::SignalI, Low::SystemI, Low::Connection, 
                 Low::SignalI, Low::SystemI, Low::Connection, 
                 # Low::Declare, 
                 Low::Transmit, Low::If, Low::Case, Low::When, Low::Cast,
                 Low::TimeWait, Low::TimeRepeat,
                 Low::Delay,
                 # Low::Value, Low::Unary, Low::Binary, Low::Ternary, Low::Concat,
                 Low::Value, Low::Unary, Low::Binary, Low::Select, Low::Concat,
                 Low::RefConcat, Low::RefIndex, Low::RefRange,
                 Low::RefName, Low::RefThis,

                 BitString
                ] 
    # The names of the classes of HDLRuby supporting to_basic
    TO_BASIC_NAMES = TO_BASICS.map { |klass| const_reduce(klass.to_s) }
    # The classes describing types (must be described only once)
    TO_BASICS_TYPES = [Low::SystemT,
                       Low::Type, Low::TypeDef,
                       Low::TypeVector, Low::TypeTuple, Low::TypeStruct]

    # The list of fields to exclude from serialization.
    FIELDS_TO_EXCLUDE = { Low::SystemT => [:@interface,:@parent ] }
    FIELDS_TO_EXCLUDE.default = [ :@parent ]

    # The list of fields that correspond to reference.
    FIELDS_OF_REF     = { Low::SystemI => [ :@systemT ] }
    FIELDS_OF_REF.default = [:@type ]

    # The name of the reference argument if any.
    REF_ARG_NAMES = { Low::SystemI    => "systemT",
                      Low::SignalI    => "type",
                      Low::TypeVector => "base",
                      Low::TypeTuple  => "types",
                      Low::RefThis    => "type",
                      Low::RefName    => "type",
                      Low::RefIndex   => "type",
                      Low::Unary      => "type",
                      Low::Binary     => "type",
                      Low::Select     => "type",
                      Low::Value      => "type"
                    }

    # The table of the object that can be refered to, used when deserializing.
    FROM_BASICS_REFS = { }

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
    # def self.value_to_basic(value, types = {})
    # Converts a +value+ to a basic structure easy-to-write YAML string.
    #
    # Other parameters:
    #   +ref+:: indicates if the object is a reference or not.
    #   +types+:: contains the type objects which will have to be converted
    #   separately.
    #   +generated+:: is the stack of the generated named objects in the current
    #   context.
    def self.value_to_basic(ref, value, types = {}, generated = [[]])
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
        elsif  value.is_a?(Range)
            # Convert to an array made of the converted first and last.
            return [value_to_basic(ref,value.first,types,generated),
                    value_to_basic(ref,value.last,types,generated)]
        elsif value.is_a?(Array) then
            # Arrays are kept as they are, but their content is converted
            # to basic.
            return value.map { |elem| value_to_basic(ref,elem,types,generated) }
        # elsif value.is_a?(Base::HashName) then
        elsif value.is_a?(Low::HashName) then
            # Hash name, convert it to an array.
            return value.map { |v| value_to_basic(ref,v,types,generated) }
        elsif value.is_a?(Hash) then
            # Maybe the hash is empty.
            if value.empty? then
                return { }
            end
            # Convert its content to basic.
            return value.map do |k,v|
                [value_to_basic(ref,k,types,generated),
                 value_to_basic(ref,v,types,generated)]
            end.to_h
        else
            # For the other cases, only HDLRuby classes supporting to_basic
            # are supported.
            unless TO_BASICS.include?(value.class) then
                raise AnyError, "Invalid class for converting to basic structure: #{value.class}"
            end
            # return value.to_basic(false,types)
            return value.to_basic(false,ref,types,generated)
        end
    end


    # Convert a +basic+ structure to a ruby object.
    def self.basic_to_value(basic)
        # print "For basic=#{basic} (#{basic.class})\n"
        # Detect which kind of basic struture it is.
        if basic.is_a?(NilClass) or basic.is_a?(Numeric) or 
                basic.is_a?(Low::Value) then
            # Nil, Numeric or Value objects are kept as they are.
            return basic
        elsif basic.is_a?(Range) then
            # First and last of range are converted.
            return basic_to_value(basic.first)..basic_to_value(basic.last)
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
            # if basic.size == 1 then
            #     print "name = #{HDLRuby.const_reduce(basic.keys[0])}\n"
            # end
            if is_basic_HDLRuby?(basic) then
                # Yes, rebuild the object.
                # First get the class.
                klass = HDLRuby.const_get(basic.keys[0])
                # print "klass=#{klass}\n"
                # The the content.
                content = basic.values[0]
                # Handle the case of the ranges
                content.each do |k,v|
                    if k.to_sym == :range and v.is_a?(Array) then
                        content[k] = basic_to_value(v[0])..basic_to_value(v[1])
                    end
                end
                # Single instance variables are set with the structure,
                # separate them from the multiple instances.
                multiples,singles = content.partition do |k,v|
                    (v.is_a?(Hash) or v.is_a?(Array)) and !is_basic_HDLRuby?(v)
                end
                # Create the object.
                # Get the name of the reference used in the constructor if any
                ref = REF_ARG_NAMES[klass]
                # Process the arguments of the object constructor.
                singles.map! do |k,v|
                    # puts "ref=#{ref} k=#{k} v=#{v}"
                    elem = basic_to_value(v)
                    # puts "elem=#{elem}"
                    if ref == k and elem.is_a?(String) then
                        # The argument is actually a reference, get the
                        # corresponding object.
                        elem = FROM_BASICS_REFS[elem.to_sym]
                    end
                    # puts "elem=#{elem}"
                    elem
                end
                # Build the object with the processed arguments.
                # object = klass.new(*singles.map{|k,v| basic_to_value(v) })
                # puts "klass=#{klass}, singles=#{singles.join("\n")}, multiples=#{multiples.join("\n")}"
                object = klass.new(*singles)
                # Adds the multiple instances.
                multiples.each do |k,v|
                    # puts "k=#{k} v=#{v}"
                    # Construct the add method: add_<key name without ending s>
                    add_meth = ("add_" + k)[0..-2].to_sym
                    # Treat the values a an array.
                    v = v.values if v.is_a?(Hash)
                    v.each do |elem|
                        # object.send(add_meth, *basic_to_value(elem) )
                        elem = basic_to_value(elem)
                        # puts "ref=#{ref}, k=#{k}"
                        if ref == k and elem.is_a?(String) then
                            # The argument is actually a reference, get the
                            # corresponding object.
                            elem = FROM_BASICS_REFS[elem.to_sym]
                        end
                        # puts "elem=#{elem}"
                        object.send(add_meth, *elem )
                    end
                end
                # Store the objects if it is named.
                if object.respond_to?(:name) then
                    # puts "Registering name=#{object.name} with #{object}"
                    FROM_BASICS_REFS[object.name] = object
                end
                # Returns the resulting object.
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
            raise AnyError, "Invalid class for a basic object: #{basic.class}."
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
        # def to_basic(top = true, types = {})
        # Converts the object to a basic structure which can be dumped into an
        # easy-to-write YAML string.
        #
        # Other parameters:
        #   +top+:: indicates if the object is the top of the
        #   description or not. If it is the top, the namespace it comes
        #   from is kept.
        #   +ref+:: indicates if the object is a reference or not.
        #           If it is a reference, its generation is to be skipped
        #           for later.
        #   +types+:: contains the type objects which will have to be converted
        #   separately.
        #   +generated+:: is the stack of the generated named objects in the
        #   current context.
        def to_basic(top = true, ref = false, types = {}, generated = [[]])
            # if !top and TO_BASICS_TYPES.include?(self.class) and
            if !top and ref then
                # Refered object, but not the top, add it to the types list
                # without converting it if not already generated.
                unless generated.flatten.include?(self.name)
                    # puts "Adding type with name=#{self.name}\n"
                    types[self.name] = self
                end
                # puts "types=#{types}"
                # And return the name.
                return self.name.to_s
            end
            # puts "generating #{self.class} with name=#{self.name}\n" if self.respond_to?(:name)
            # Self is generated, remove it from the types to generate.
            generated[-1] << self.name if self.respond_to?(:name)
            # Add a level to the stack of generated named objects.
            generated << []
            # print "to_basic for class=#{self.class}\n"
            # Create the hash which will contains the content of the object.
            content = { }
            # Create the resulting hash with a single entry whose key
            # is the class name and whose value is the content of the
            # object.
            class_name = self.class.to_s
            # Keep only the class name
            class_name = HDLRuby.const_reduce(class_name)

            result = { class_name => content }
            # Fills the contents with the instance variables value.
            self.instance_variables.each do |var_sym|
                # Skip the fields that should not be serialized
                # next if var_sym == :@parent # Now added to FIELDS_TO_EXCLUDE
                next if (FIELDS_TO_EXCLUDE[self.class] and 
                         FIELDS_TO_EXCLUDE[self.class].include?(var_sym) )
                # print "for instance variable #{var_sym}...\n"
                # Skip the parent.
                # Get the value of the variable.
                var_val = self.instance_variable_get(var_sym)
                # Sets the content.
                # content[var_sym] = HDLRuby.value_to_basic(var_val,types)
                value = HDLRuby.value_to_basic(
                    FIELDS_OF_REF[self.class].include?(var_sym), var_val,
                    types,generated)
                # Remove the @ from the symbol.
                var_sym = var_sym.to_s[1..-1]
                # EMPTY VALUES ARE NOT SKIPPED
                # # Empty values are skipped
                # unless value.respond_to?(:empty?) and value.empty? then
                #     content[var_sym] = value
                # end
                content[var_sym] = value
            end

            if top and !types.empty? then
                # It is a top and there where types.
                # The result is a sequence including each type and the
                # current object.
                result = [ result ]
                # Sort the type so that data types comes first.
                to_treat = types.each.partition {|name,type| !type.is_a?(Type) }
                to_treat.flatten!(1)
                while !to_treat.empty?
                    others = {}
                    to_treat.each do |name,type|
                        # print "Dumping type with name=#{name}\n"
                        # type_basic = type.to_basic(true)
                        type_basic = type.to_basic(true,others)
                        type_basic = type_basic.last if type_basic.is_a?(Array)
                        result.unshift(type_basic)
                    end
                    to_treat = others
                end
                    
            end

            # Restore the stack of generated named objets.
            generated.pop

            # Return the resulting hash.
            return result
        end

        # Converts the object to YAML string.
        def to_yaml
            # Convert the object to basic representations
            basics = to_basic
            # Remove duplicate descripions
            basics.uniq! { |elem| elem.first[1]["name"] }
            # Convert the basic representations to YAML
            return YAML.dump_stream(*basics)
        end
    end


    # Adds the serializing features to the HDLRuby classes supporting to_basic.
    TO_BASICS.each { |klass| klass.include(Serializer) }
end
