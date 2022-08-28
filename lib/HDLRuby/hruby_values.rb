module HDLRuby

    ##
    # Library for implementing the value processing.
    #
    ########################################################################

    # To include to classes for value processing support.
    module Vprocess

        # Redefinition of the arithmetic and logic operations binary operators
        [ :+, :-, :*, :/, :%, :&, :|, :^, :**,
          :<<, :>>,
          :==, :!=, :<, :>, :<=, :>=, :<=>  ].each do |op|
              # Actual redefinition.
              define_method(op) do |value|
                  # puts "op=#{op} value=#{value}"
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
                  # puts "op=#{op} self.content=#{self.content} value.content=#{value.content} res_content=#{res_content}, res_value=#{self.class.new(res_type,res_content).content}"
                  # Return the resulting value.
                  return self.class.new(res_type,res_content)
              end
          end

          # Redefinition of the access operators.
          define_method(:[]) do |value|
              if value.is_a?(Range) then
                  # Range case.
                  # Ensures value is really a range of values.
                  left = value.first
                  right = value.last
                  unless left.to_value? && right.to_value? then
                      # Not a value, use the former method.
                      # Assumed
                      return self.send(orig_operator(op),value)
                  end
                  left = left.to_value
                  right = right.to_value
                  # Generate the resulting type.
                  res_type = self.type.base
                  # Generate the resulting value.
                  width = res_type.width
                  idxl = left.to_i
                  idxr = right.to_i
                  # puts "width=#{width}, idxl=#{idxl} idxr=#{idxr}"
                  bstr = self.content.is_a?(BitString) ? self.content :
                      BitString.new(self.content)
                  res_content = bstr[((idxl+1)*width-1)..idxr*width]
                  if res_content.is_a?(String) then
                      res_content = BitString.new(res_content)
                  end
                  # puts "op=#{op} self.content=#{self.content} value.content=#{value.content} res_content=#{res_content}, res_value=#{self.class.new(res_type,res_content).content}"
                  # Return the resulting value.
                  return self.class.new(res_type,res_content)
              else
                  # Index case.
                  # Ensures value is really a value.
                  unless value.to_value? then
                      # Not a value, use the former method.
                      # Assumed
                      return self.send(orig_operator(op),value)
                  end
                  value = value.to_value
                  # Generate the resulting type.
                  res_type = self.type.base
                  # Generate the resulting value.
                  width = res_type.width
                  index = value.to_i
                  # puts "width=#{width}, index=#{index}"
                  bstr = self.content.is_a?(BitString) ? self.content :
                      BitString.new(self.content)
                  res_content = bstr[((index+1)*width-1)..index*width]
                  if res_content.is_a?(String) then
                      res_content = BitString.new(res_content)
                  end
                  # puts "op=#{op} self.content=#{self.content} value.content=#{value.content} res_content=#{res_content}, res_value=#{self.class.new(res_type,res_content).content}"
                  # Return the resulting value.
                  return self.class.new(res_type,res_content)
              end
          end

          define_method(:[]=) do |index,value|
              if index.is_a?(Range) then
                  # Range case.
                  # Ensures value is really a value.
                  unless value.to_value? &&
                         index.first.to_value? && index.last.to_value? then
                      # Not a value, use the former method.
                      # Assumed
                      return self.send(orig_operator(op),index,value)
                  end
                  # Process the arguments.
                  value = value.to_value.content
                  idxl = index.first.to_i
                  idxr = index.last.to_i
                  # Generate the resulting type.
                  res_type = self.type.base
                  width = res_type.width
                  # Generate the resulting value.
                  # puts "width=#{width}, idxl=#{idxl}, idxr=#{idxr}"
                  res_content = self.content.is_a?(BitString) ? self.content :
                      BitString.new(self.content)
                  res_content[((idxl+1)*width-1)..idxr*width] = value
                  # puts "first res_content=#{res_content}"
                  if res_content.is_a?(String) then
                      res_content = BitString.new(res_content)
                  end
                  # puts "op=[]= self.content=#{self.content} value=#{value} res_content=#{res_content}"
                  # Update the resulting value.
                  @content = res_content
              else
                  # Index case.
                  # Ensures value is really a value.
                  unless value.to_value? && index.to_value? then
                      # Not a value, use the former method.
                      # Assumed
                      return self.send(orig_operator(op),index,value)
                  end
                  # Process the arguments.
                  value = value.to_value.content
                  index = index.to_i
                  # Generate the resulting type.
                  res_type = self.type.base
                  width = res_type.width
                  # Generate the resulting value.
                  # puts "width=#{width}, index=#{index}"
                  res_content = self.content.is_a?(BitString) ? self.content :
                      BitString.new(self.content)
                  res_content[((index+1)*width-1)..index*width] = value
                  # puts "first res_content=#{res_content}"
                  if res_content.is_a?(String) then
                      res_content = BitString.new(res_content)
                  end
                  # puts "op=[]= self.content=#{self.content} value=#{value} res_content=#{res_content}"
                  # Update the resulting value.
                  @content = res_content
              end
          end

          # Redefinition of the arithmetic and logic operations unary operators
          [ :-@, :+@, :~, :abs ].each do |op|
              # Actual redefinition.
              define_method(op) do
                  # Generate the resulting type.
                  res_type = self.type.send(op)
                  # Generate the resulting content.
                  # puts "op=#{op} content.class=#{content.class}"
                  res_content = self.content.send(op)
                  # puts "res_content=#{res_content}"
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

          # Tell if the value is zero.
          def zero?
              return false unless content
              return content.zero?
          end

          ## Converts the value to a string of the right size.
          def to_vstr
              if self.content.is_a?(Numeric) then
                  if self.content >= 0 then 
                      str = "0" + self.content.to_s(2)
                  else
                      str = (2**((-self.content).width+1) + self.content).to_s(2)
                  end
              else
                  str = self.content.to_s
              end
              width = self.type.width
              if str.size >= width then
                  return str[-width..-1]
              else
                  return str[0] * (width-str.size) + str
              end
          end

    end

end
