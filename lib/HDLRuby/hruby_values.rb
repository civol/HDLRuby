module HDLRuby

##
# Library for implementing the value processing.
#
########################################################################

    # To include to classes for value processing support.
    module Vprocess

        # Arithmetic and logic operations
        [ :+, :-, :*, :/, :&, :|, :**, :-@, :+@, :~,
          :<<, :>>,
          :==, :<, :>, :<=, :>=, :<=>  ].each do |op|
            define_method(op) do |value|
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
