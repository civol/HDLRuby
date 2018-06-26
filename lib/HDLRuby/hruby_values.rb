module HDLRuby

##
# Library for implementing the value processing.
#
########################################################################

    # To include to classes for value processing support.
    module Vprocess

        # Redefinition of the arithmetic and logic operations
        [ :+, :-, :*, :/, :%, :&, :|, :**, :-@, :+@, :~,
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
                # Return the resulting value.
                return self.class.new(res_type,res_content)
            end
        end
    end



end
