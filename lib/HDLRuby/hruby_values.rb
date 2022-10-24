module HDLRuby

    ##
    # Library for implementing the value processing.
    #
    ########################################################################

    # To include to classes for value processing support.
    module Vprocess

        # TRUNC_P_T = 65536.times.map { |i| 2**i - 1 }
        # TRUNC_N_T = 65536.times.map { |i|  (-1 * 2**i) }

        # Truncs integer +val+ to +width+
        def trunc(val,width)
            if val.bit_length > width then
                if val >= 0 then
                    # return val & (2**width-1)
                    return val % (2**width)
                    # return val & TRUNC_P_T[width]
                else
                    # return val | (-1 * 2**width)
                    return val % -(2**width)
                    # return val | TRUNC_N_T[width]
                end
            else
                return val
            end
        end

        # Redefinition of the arithmetic and logic operations binary operators
        [ :+, :-, :*, :/, :%, :&, :|, :^, :**,
          :<<, :>>,
          :==, :!=, :<, :>, :<=, :>=, :<=>  ].
          each do |op|
            define_method(op) do |val|
                # Ensures val is computable.
                unless val.to_value? then
                    # Not computable, use the former method that generates
                    # HDLRuby code.
                    return self.send(orig_operator(op),value)
                end
                # Handle Numeric op BitString case.
                if self.content.is_a?(Numeric) && val.content.is_a?(BitString)
                    if val.content.specified? then
                        res_content = self.content.send(op,val.content.to_i)
                        # puts "op=#{op} self.content=#{self.content} val.content=#{val.content.to_i} res_content=#{res_content}"
                    else
                        res_content = 
                            BitString.new(self.content).send(op,val.content)
                    end
                else
                    # Generate the resulting content.
                    res_content = self.content.send(op,val.content)
                    # puts "op=#{op} self.content=#{self.content} (#{self.content.class}) val.content=#{val.content} (#{val.content.class}) res_content=#{res_content} (#{res_content.class})"
                end
                res_type = self.type.resolve(val.type)
                # # Adjust the result content size.
                # res_width = res_type.width
                # if res_content.is_a?(BitString) then
                #     res_content.trunc!(res_width)
                # else 
                #     res_content = self.trunc(res_content,res_width)
                # end
                # Return the resulting value.
                return self.class.new(res_type,res_content)
            end
        end

        # Redefinition of the access operators.
        define_method(:[]) do |val|
            if val.is_a?(Range) then
                # Range case.
                # Ensures value is really a range of values.
                left = val.first
                right = val.last
                unless left.to_value? && right.to_value? then
                    # Not a value, use the former method.
                    # Assumed
                    return self.send(orig_operator(op),val)
                end
                # Process left.
                # unless left.is_a?(Numeric) || left.is_a?(BitString) then
                #     left = left.to_value.content
                # end
                left = left.content
                if left.is_a?(BitString) && !left.specified? then
                    return self.class.new(self.type.base,
                                          BitString::UNKNOWN.clone)
                end
                # left = left.to_i
                left = self.trunc(left.to_i,val.first.type.width)
                # Process right.
                # unless right.is_a?(Numeric) || right.is_a?(BitString) then
                #     right = right.to_value.content
                # end
                right = right.content
                if right.is_a?(BitString) && !right.specified? then
                    return self.class.new(self.type.base,
                                          BitString::UNKNOWN.clone)
                end
                # right = right.to_i
                right = self.trunc(right.to_i,val.last.type.width)
                # Generate the resulting type.
                res_type = self.type.base[(left-right+1).abs]
                # Generate the resulting value.
                width = res_type.base.width
                # puts "width=#{width}, left=#{left} right=#{right}"
                if self.content.is_a?(BitString) then
                    res_content = self.content[right*width..(left+1)*width-1]
                else
                    sh = right*width
                    mask = (-1 << sh) & ~(-1 << (left+1)*width)
                    res_content = (self.content & mask) >> sh
                end
                # Return the resulting value.
                return self.class.new(res_type,res_content)
            else
                # Index case.
                # Ensures val is really a value.
                unless val.to_value? then
                    # Not a value, use the former method.
                    # Assumed
                    return self.send(orig_operator(op),val)
                end
                # Process val.
                index = val.content
                if index.is_a?(BitString) && !index.specified? then
                    return self.class.new(self.type.base,
                                          BitString::UNKNOWN.clone)
                end
                index = self.trunc(index.to_i,val.type.width)
                # index = index.to_i
                # if index >= self.type.size then
                #     # puts "index=#{index}"
                #     index %= self.type.size
                #     # puts "now index=#{index}"
                # end
                # Generate the resulting type.
                res_type = self.type.base
                # Generate the resulting value.
                width = res_type.width
                # puts "type width=#{self.type.width}, element width=#{width}, index=#{index}"
                if self.content.is_a?(BitString) then
                    res_content = self.content[index*width..(index+1)*width-1]
                else
                    sh = index*width
                    mask = (-1 << sh) & ~(-1 << (index+1)*width)
                    res_content = (self.content & mask) >> sh
                end
                # Return the resulting value.
                return self.class.new(res_type,res_content)
            end
        end

        define_method(:[]=) do |index,val|
            if index.is_a?(Range) then
                # Range case.
                # Ensures indexes and val are really values.
                left = index.first
                right = index.last
                unless val.to_value? &&
                        left.to_value? && right.to_value? then
                    # Not a value, use the former method.
                    # Assumed
                    return self.send(orig_operator(op),index,value)
                end
                # Process val.
                val = val.content if val.is_a?(Value)
                # Process left.
                left = left.content if left.is_a?(Value)
                if left.is_a?(BitString) && !left.specified? then
                    return self.class.new(self.type.base,
                                          BitString::UNKNOWN.clone)
                end
                left = left.to_i
                # Process right.
                right = right.content if right.is_a?(Value)
                if right.is_a?(BitString) && !right.specified? then
                    return self.class.new(self.type.base,
                                          BitString::UNKNOWN.clone)
                end
                right = right.to_i
                # Compute the width of one element.
                width = self.type.base.width
                # Write the value at the right position.
                # puts "width=#{width}, left=#{left}, right=#{right}"
                if @content.is_a?(BitString) then
                    @content[right*width..(left+1)*width-1] = val
                else
                    sh = right*width
                    val = self.trunc(val,((left-right).abs+1)*width) << sh
                    mask = ~(-1 << sh) | (-1 << (left+1)*width)
                    @content =((@content & mask) | val)
                end
            else
                # Index case.
                # Ensures index and val are really values.
                unless val.to_value? && index.to_value? then
                    # Not a value, use the former method.
                    # Assumed
                    return self.send(orig_operator(op),index,value)
                end
                # Process val.
                val = val.content if val.is_a?(Value)
                # puts "val=#{val} (#{val.class})"
                # Process index.
                index = index.content if index.is_a?(Value)
                # puts "index=#{index} (#{index.class})"
                if index.is_a?(BitString) && !index.specified? then
                    return self.class.new(self.type.base,
                                          BitString::UNKNOWN.clone)
                end
                index = index.to_i
                # Compute the width of one element.
                width = self.type.base.width
                # Write the value at the right position.
                # puts "width=#{width}, index=#{index}, val=#{val}"
                # puts "first @content=#{@content}, index*width=#{index*width} next=#{(index+1)*width-1}"
                if @content.is_a?(BitString) then
                    @content[index*width..(index+1)*width-1] = val
                else
                    sh = index*width
                    val = self.trunc(val,width) << sh
                    mask = ~(-1 << sh) | (-1 << (index+1)*width)
                    @content = ((@content & mask) | val)
                end
                # puts "now @content=#{@content}"
            end
        end

        # Redefinition of the arithmetic and logic operations unary operators
        [ :-@, :+@, :~, :abs ].each do |op|
            # Actual redefinition.
            define_method(op) do
                # Generate the resulting type.
                res_type = self.type
                # Generate the resulting content.
                # puts "op=#{op} content=#{content.to_s}"
                res_content = self.content.send(op)
                # puts "res_content=#{res_content}"
                # Return the resulting value.
                return self.class.new(res_type,res_content)
            end
        end

        # Cast to +type+.
        # NOTE: nodir tells if the direction is to be ignored.
        def cast(type,nodir = false)
            # Handle the direction.
            if !nodir && type.direction != self.type.direction then
                if self.content.is_a?(Numeric) then
                    tmp = 0
                    res_content = self.content
                    self.type.width.times do |i|
                        tmp = tmp*2 | (res_content & 1)
                        res_content /= 2
                    end
                    res_content = tmp
                elsif self.content.is_a?(BitString) then
                    res_content = self.content.clone.reverse!(self.type.width)
                else
                    res_content = self.content.reverse
                end
            else
                res_content = self.content.clone
            end
            # Handle the sign.
            if type.unsigned? && !self.content.positive? then
                # Ensure the content is a positive value to match unsigned type.
                if res_content.is_a?(Numeric) then
                    res_content &= ~(-1 << type.width) if res_content < 0
                    # res_content &= ~(-1 * 2**type.width) if res_content < 0
                else
                    res_content.positive!
                end
            end
            # # truncs to the right size if necessary.
            # if res_content.is_a?(BitString) then
            #     res_content.trunc!(type.width)
            # else 
            #     res_content = self.trunc(res_content,type.width)
            # end
            # Generate the resulting value.
            return self.class.new(type,res_content)
        end

        # Concat the content of +vals+.
        def self.concat(*vals)
            # Compute the resulting type.
            types = vals.map {|v| v.type }
            if types.uniq.count <= 1 then
                res_type = types[0][types.size]
            else
                res_type = vals.map {|v| v.type }.to_type
            end
            # Concat the contents.
            res_content = []
            content = width = 0
            vals.each_with_index do |val,i|
                content = val.content
                width = types[i].width
                if content.is_a?(BitString) then
                    count = 0
                    content.raw_content.each do |b|
                        res_content << b
                        count += 1
                        break if count == width
                    end
                    if count < width then
                        res_content.concat(res_content[-1] * (width-count))
                    end
                else
                    width.times do |p|
                        res_content << content[p]
                    end
                end
            end
            # Make a bit string from res_content.
            res_content = BitString.new(res_content,:raw)
            # Return the resulting value.
            return vals[0].class.new(res_type,res_content)
        end


        # Conversion to an integer if possible.
        def to_i
            # if self.content.is_a?(BitString) then
            #     if self.type.signed? then
            #         return self.content.to_numeric_signed
            #     else
            #         return self.content.to_numeric
            #     end
            # else
            #     return self.content.to_i
            # end
            return self.content.to_i
        end

        # Conversion to a float if possible.
        def to_f
            return self.content.to_f
        end

        # # Conversion to a BitString of the right size.
        # def to_bstr
        #     # Ensure the content is a bit string.
        #     bstr = self.content
        #     if bstr.is_a?(Numeric) then
        #         # Handle negative values.
        #         bstr = 2**self.type.width + bstr if bstr < 0
        #     end
        #     bstr = BitString.new(bstr) unless bstr.is_a?(BitString)
        #     # Resize it if necessary.
        #     cwidth = self.content.width
        #     twidth = self.type.width
        #     if cwidth < twidth then
        #         # Its lenght must be extended.
        #         if self.type.signed? then
        #             return bstr.sext(twidth)
        #         else
        #             return bstr.zext(twidth)
        #         end
        #     elsif cwidth > twidth then
        #         # Its lenght must be reduced.
        #         return bstr.trunc(twidth)
        #     else
        #         return bstr.clone
        #     end
        # end

        # Coercion when operation from Ruby values.
        def coerce(other)
            return other,self.content
        end

        # Hash-map comparison of values.
        # Also use in simulation engines to know if a signal changed.
        def eql?(val)
            if self.content.is_a?(Numeric) then
                return self.content == val if val.is_a?(Numeric)
                return self.content == val.content if val.content.is_a?(Numeric)
                return false unless val.content.specified?
                return self.content == val.content.to_i
            else
                return self.content.to_i == val if val.is_a?(Numeric)
                return self.content.eql?(val.content) unless val.content.is_a?(Numeric)
                return false if self.content.specified?
                return self.content.to_i == val.content
            end
        end


        # Tell if the value is zero.
        def zero?
            return false unless @content
            if content.is_a?(Numeric) then
                return @content & (2**self.type.width-1) == 0
            else
                return !@content.raw_content[0..self.type.width-1].any?{|b| b!=0}
            end
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
