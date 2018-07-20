module HDLRuby

##
# Library for implementing the value processing.
#
########################################################################

    # To include to classes for value processing support.
    module Vprocess

        # Redefinition of the arithmetic and logic operations binary operators
        [ :+, :-, :*, :/, :%, :&, :|, :**,
          :<<, :>>,
          :==, :<, :>, :<=, :>=, :<=>  ].each do |op|
            # Actual redefinition.
            define_method(op) do |value|
                # puts "value=#{value}"
                # Ensures value is really a value.
                unless value.to_value? then
                    # Not a value, use the former method.
                    # Assumed
                    return self.send(orig_operator(op),value)
                end
                value = value.to_value
                # Generate the resulting type.
                res_type = self.type.send(op,value.type)
                # Generate the resulting content.
                res_content = self.content.send(op,value.content)
                # puts "op=#{op} value.content=#{value.content} res_content=#{res_content}"
                # Return the resulting value.
                return self.class.new(res_type,res_content)
            end
        end

        # Redefinition of the arithmetic and logic operations unary operators
        [ :-@, :+@, :~, :abs ].each do |op|
            # Actual redefinition.
            define_method(op) do
                # Generate the resulting type.
                res_type = self.type.send(op)
                # Generate the resulting content.
                res_content = self.content.send(op)
                # Return the resulting value.
                return self.class.new(res_type,res_content)
            end
        end

        # Conversion to an integer if possible.
        def to_i
            return self.content.to_i
        end

        # Conversion to a float if possible.
        def to_f
            return self.content.to_f
        end

        # Coercion when operation from Ruby values.
        def coerce(other)
            return other,self.content
        end
    end

end
