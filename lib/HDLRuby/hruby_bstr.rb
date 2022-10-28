module HDLRuby

##
# Library for describing the bit string and their computations.
#
########################################################################
    

    # # Converts a value to a valid bit if possible.
    # def make_bit(value)
    #     value = value.to_s.downcase
    #     # Removed because assume value is always right.
    #     # unless ["0","1","x","z"].include?(value)
    #     #     raise "Invalid value for a bit: #{value}"
    #     # end
    #     return value
    # end

    # # Converts a value to a valid bit string of +width+ bits.
    # def make_bits(value,width)
    #     if value.is_a?(Numeric) then
    #         value = value.to_s(2)
    #     else
    #         value = value.to_s.downcase
    #     end
    #     # puts "first value=#{value} width=#{width}"
    #     if value.size > width then
    #         value = value[-width..-1]
    #     elsif value.size < width then
    #         value = value[0] * (width-value.size) + value
    #     end
    #     return value
    # end


    ##
    # Describes a bit string.
    #
    # NOTE: 
    # * bit strings are always signed.
    # * the representation is 2 complements.
    class BitString

        # Creates a new bit string from +val+.
        # NOTE:*  +val+ can be a Numeric or a String.
        #      * when +opt+ is :raw, val is considered to be the raw content.
        def initialize(val, opt = false)
            # puts "val=#{val} val.class=#{val.class} opt=#{opt}"
            if opt == :raw then
                @content = [*val]
            elsif val.is_a?(Numeric) then
                # Content is a numeric.
                @content = []
                if val == 0 then
                    @content << 0
                elsif val > 0 then
                    while val > 0 do
                        @content << (val & 1)
                        val /= 2
                    end
                    @content << 0
                else
                    while val < -1 do
                        @content << (val & 1)
                        val /= 2
                    end
                    @content << 1
                end
            else
                # Content is not a numeric nor a BitString.
                @content = []
                # Ensure it is a string.
                val = val.to_s.downcase
                val.each_byte.reverse_each do |c|
                    case c
                    when 48  # "0"
                        @content << 0
                    when 49  # "1"
                        @content << 1
                    when 120 # "x"
                        @content << 3
                    when 122 # "z"
                        @content << 2
                    else
                        raise "Invalid bit: #{b.chr}"
                    end
                end
            end
        end

        # Clone the bit string.
        def clone
            return BitString.new(@content,:raw)
        end

        # Reverse the content of the bit string assuming a bit width
        # of +width+.
        def reverse!(width)
            # Ensure content is large enough.
            if @content.size < width then
                @content.concat(content[-1]*(width-@content.size))
            else
                @content.trunc!(width)
            end
            @content.reverse!
        end


        # Give access to the raw content.
        # NOTE: the content is not copied, so there is a risk of side effect.
        def raw_content
            return @content
        end

        # Hash comparison.
        def eql?(bstr)
            return @content.eql?(bstr.raw_content)
        end

        # Tells if the bit string is strictly.
        #
        # NOTE: return false if the sign is undefined of if it is unknown
        #       if the result is zero or not.
        def positive?
            return (@content[-1] == 0)
        end

        # Force the BitSting to be positive by appending a 0 is required.
        def positive!
            @content << 0 if @content[-1] != 0
            return self
        end

        # Tells if the bit string is strictly negative.
        #
        # NOTE: return false if the sign is undefined
        def negative?
            return (@content[-1] == 1)
        end

        # Tells if the bit string is zero.
        #
        # NOTE: return false if the bit string is undefined.
        def zero?
            return ! @content.any? {|b| b != 0 }
        end

        # Tells if the bit string is not zero.
        def nonzero?
            return @content.any? {|b| b == 1 }
        end

        # Tells if the bit string could be zero.
        def maybe_zero?
            return ! self.nonzero?
        end

        # Converts to a string (sign bit is comprised).
        def to_s
            return @content.reverse_each.map { |b| B2S_T[b] }.join
        end
        alias_method :str, :to_s

        # Gets a bit by +index+. If +index+ is a range it is a range access.
        #
        # NOTE: * Assumes index is a numeric or a range of numerics.
        #       * Access is compatible with Ruby array access and not with
        #         hardware access, e.g., 0..4 is not reversed.
        #         This is compatible with sub access of Numeric.
        #       * If the index is larger than the bit string width, returns the
        #         bit sign.
        def [](index)
            if index.is_a?(Range) then
                # Process the left index.
                left = index.first
                left = left.to_i
                # Adjust left to @content size.
                left += @content.size if left < 0
                left = left >= @content.size ? @content.size-1 : left
                # Process the right index.
                right = index.last
                right = right.to_i
                # Adjust right to @content size.
                right += @content.size if right < 0
                right = right >= @content.size ? @content.size-1 : right
                # Do the access.
                if right >= left then
                    # puts "left=#{left} right=#{right}"
                    # Get the corresponding bits as a BitString
                    return BitString.new(@content[left..right],:raw)
                else
                    # Get the corresponding bits as a BitString
                    return BitString.new(@content[right..left].reverse,:raw)
                end
            else
                # Process the index.
                index = index.to_i
                # Handle the negative index case.
                if index < 0 then
                    return self[self.width+index]
                end
                # Process the index.
                index = index >= @content.size ? @content.size-1 : index
                b = @content[index]
                if b < 2 then
                    # b is specified return it as an Numeric.
                    return b
                else
                    # b is not specified, create a new BitString.
                    return BitString.new(b,:raw)
                end
            end
        end

        # Sets the bit at +index+ to +value+.
        #
        # NOTE: * Assumes index is a numeric or a range of numerics.
        #       * Access is compatible with Ruby array access and not with
        #         hardware access, e.g., 0..4 is not reversed.
        #         This is compatible with sub access of Numeric.
        #       * when index is larger than the bit width, the bit string is
        #         X extended accordingly.
        def []=(index,value)
            # Change inside the bit string, it is not know any longer if it
            # is specified or not
            @specified = nil
            # Process according to the kind of index.
            if index.is_a?(Range) then
                # Process the left index.
                left = index.first
                left = left.to_i
                # Adjust left and @content size.
                left += @content.size if left < 0
                if left >= @content.size then
                    # Overflow, sign extend the content.
                    sign = @content[-1]
                    @content.concat([sign] * (left-@content.size+1))
                end
                # Process the right index.
                right = index.last
                right = right.to_i
                # Adjust right and @content size.
                right += @content.size if right < 0
                if right >= @content.size then
                    # Overflow, sign extend the bit string.
                    sign = @content[-1]
                    @content.concat([sign] * (right-@content.size+1))
                end
                if right >= left then
                    # puts "left=#{left} right=#{right} value=#{value} (#{value.class})"
                    # Sets the value to a copy of the bit string.
                    @content[left..right] = value.is_a?(BitString) ?
                        value.raw_content[0..right-left] : 
                        (right-left+1).times.map do |i|
                            value[i]
                        end
                else
                    # Sets the value to a copy of the bit string.
                    @content[right..left] = value.is_a?(BitString) ?
                        value.raw_content[left-right..0] : 
                        (left-right).down_to(0).map do |i|
                            value[i]
                        end
                end
                # puts "now @content=#{@content}"
            else
                # Process the index.
                index = index.to_i
                # Handle the negative index case.
                if index < 0 then
                    return self[@content.size+index] = value
                end
                # Process the index.
                if index >= @content.size then
                    # Overflow, sign extend the bit string.
                    sign = @content[-1]
                    @content.concat([sign] * (index-@content.size+1))
                end
                # Sets the value to the bit string.
                @content[index] = value[0]
            end
            return value
        end

        # Truncs to +width+.
        #
        # NOTE:
        # * trunc remove the end of the bit string.
        # * if the width is already smaller or equal than +width+, do nothing.
        def trunc!(width)
            return self if width >= @content.size
            @content.pop(width-@content.size)
        end

        # # Trims to +width+.
        # #
        # # NOTE:
        # # * trim remove the begining of the bit string.
        # # * if the width is already smaller than +width+, do nothing.
        # # * do not preserve the sign, but keep the last bit as sign bit.
        # def trim(width)
        #     return self if width >= @str.size-1
        #     return BitString.new(@str[0..width])
        # end

        # # Sign extend to +width+.
        # #
        # # NOTE:
        # # * if the width is already larger than +width+, do nothing.
        # # * preserves the sign.
        # # def extend(width)
        # def sext(width)
        #    return self if width <= @str.size - 1
        #    return BitString.new(@str[0] * (width-@str.size) + @str)
        # end

        # # Zero extend to +width+.
        # #
        # # NOTE:
        # # * if the width is already larger than +width+, do nothing.
        # # * preserves the sign.
        # def zext(width)
        #    return self if width <= @str.size - 1
        #    return BitString.new("0" * (width-@str.size) + @str)
        # end

        # # X extend to +width+.
        # #
        # # NOTE:
        # # * if the width is already larger than +width+, do nothing.
        # # * preserves the sign.
        # def xext(width)
        #    return self if width <= @str.size - 1
        #    return BitString.new("x" * (width-@str.size) + @str)
        # end

        # # Concat with +value+ using +w0+ for current bit width and +w1+ for
        # # value bit width.
        # def concat(value,w0,w1)
        #     res = self[w0-1..0]
        #     res[w0+w1-1..w0] = value
        #     return res
        # end

        # Iterates over the bits.
        #
        # NOTE: the sign bit in comprised.
        #
        # Returns an enumerator if no ruby block is given.
        def each(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each) unless ruby_block
            # A block? Apply it on each bit.
            @content.each(&ruby_block)
        end

        # Reverse iterates over the bits.
        #
        # NOTE: the sign bit in comprised.
        #
        # Returns an enumerator if no ruby block is given.
        def reverse_each(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:reverse_each) unless ruby_block
            # A block? Apply it on each bit.
            @content.reverse_each(&ruby_block)
        end

        # # Gets the sign of the bit string.
        # def sign
        #     return @str[0]
        # end

        # # Tell if the sign is specified.
        # def sign?
        #     return (@str[0] == "0" or @str[0] == "1")
        # end

        # # Convert the bit string to a Ruby Numeric.
        # #
        # # NOTE: the result will be wrong is the bit string is unspecified.
        # def to_numeric
        #     res = 0
        #     # Process the bits.
        #     @str[1..-1].each_char { |b| res = res << 1 | b.to_i }
        #     # Process the sign.
        #     res = res - (2**(@str.size-1)) if @str[0] == "1"
        #     # Return the result.
        #     return res
        # end

        # Convert the bit string to a Ruby Numeric.
        #
        # NOTE: the result will be wrong is the bit string is unspecified.
        # def to_numeric
        def to_i
            # Compute the 2-complement's value.
            res = 0
            @content.reverse_each { |b| res = res * 2 | b }
            # Fix the sign.
            res = -((1 << @content.size) - res) if @content[-1] == 1
            return res
        end

        # Tell if the bit string is fully specified
        def specified?
            @specified = ! @content.any? {|b| b > 1 } if @specified == nil
            return @specified
        end

        # # Coerces.
        # def coerce(other)
        #     return [BitString.new(other),self]
        # end

        # String conversion table.
        B2S_T = [ "0", "1", "z", "x" ]

        # A few common bit strings.

        TRUE        = BitString.new("01")
        FALSE       = BitString.new("00")
        UNKNOWN     = BitString.new("xx")
        ZERO        = BitString.new("00")
        ONE         = BitString.new("01")
        TWO         = BitString.new("010")
        THREE       = BitString.new("011")
        MINUS_ONE   = BitString.new("11")
        MINUS_TWO   = BitString.new("10")
        MINUS_THREE = BitString.new("101")


        # The arithmetic and logic operations.
        
        # Not truth table
        # NOT_T =    { "0" => "1", "1" => "0", "z" => "x", "x" => "x" }
        NOT_T =   [ 1, 0, 3, 3 ] 
        
        # And truth table: 0, 1, 2=z, 3=x
        # AND_T =  { "0" => {"0"=>"0", "1"=>"0", "z"=>"0", "x"=>"0"},  # 0 line
        #            "1" => {"0"=>"0", "1"=>"1", "z"=>"x", "x"=>"x"},  # 1 line
        #            "z" => {"0"=>"0", "1"=>"x", "z"=>"x", "x"=>"x"},  # z line
        #            "x" => {"0"=>"0", "1"=>"x", "z"=>"x", "x"=>"x"} } # x line
        AND_T   =  [ [ 0, 0, 0, 0 ],   # 0 line
                     [ 0, 1, 3, 3 ],   # 1 line
                     [ 0, 3, 3, 3 ],   # z line
                     [ 0, 3, 3, 3 ] ]  # x line
        
        # Or truth table: 0, 1, 2=z, 3=x
        # OR_T =   { "0" => {"0"=>"0", "1"=>"1", "z"=>"x", "x"=>"x"},  # 0 line
        #            "1" => {"0"=>"1", "1"=>"1", "z"=>"1", "x"=>"1"},  # 1 line
        #            "z" => {"0"=>"x", "1"=>"1", "z"=>"x", "x"=>"x"},  # z line
        #            "x" => {"0"=>"x", "1"=>"1", "z"=>"x", "x"=>"x"} } # x line
        OR_T    =  [ [ 0, 1, 3, 3 ],   # 0 line
                     [ 1, 1, 1, 1 ],   # 1 line
                     [ 3, 1, 3, 3 ],   # z line
                     [ 3, 1, 3, 3 ] ]  # x line
        
        # Xor truth table: 0, 1, 2=z, 3=x
        # XOR_T =  { "0" => {"0"=>"0", "1"=>"1", "z"=>"x", "x"=>"x"},  # 0 line
        #            "1" => {"0"=>"1", "1"=>"0", "z"=>"x", "x"=>"x"},  # 1 line
        #            "z" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"},  # z line
        #            "x" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"} } # x line
        XOR_T   =  [ [ 0, 1, 3, 3 ],   # 0 line
                     [ 1, 0, 3, 3 ],   # 1 line
                     [ 3, 3, 3, 3 ],   # z line
                     [ 3, 3, 3, 3 ] ]  # x line

        LOGIC_T = [ AND_T, OR_T, XOR_T ]

        # # Double xor truth table: 0, 1, 2=z, 3=x
        # XOR3_T={ "0" => {
        #            "0" => {"0"=>"0", "1"=>"1", "z"=>"x", "x"=>"x"}, 
        #            "1" => {"0"=>"1", "1"=>"0", "z"=>"x", "x"=>"x"}, 
        #            "z" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"},
        #            "x" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"} }, # 0 line
        #          "1" => {
        #            "0" => {"0"=>"1", "1"=>"0", "z"=>"x", "x"=>"x"},
        #            "1" => {"0"=>"0", "1"=>"1", "z"=>"x", "x"=>"x"}, 
        #            "z" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"},
        #            "x" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"} }, # 1 line
        #          "z" => {
        #            "0" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"},
        #            "1" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"}, 
        #            "z" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"},
        #            "x" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"} }, # z line
        #          "x" => {
        #            "0" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"},
        #            "1" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"},
        #            "z" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"},
        #            "x" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"} } }# x line

        # # Majority truth table: 0, 1, 2=z, 3=x
        # MAJ_T= { "0" => {
        #            "0" => {"0"=>"0", "1"=>"0", "z"=>"0", "x"=>"0"},
        #            "1" => {"0"=>"0", "1"=>"1", "z"=>"x", "x"=>"x"}, 
        #            "z" => {"0"=>"0", "1"=>"x", "z"=>"x", "x"=>"x"},
        #            "x" => {"0"=>"0", "1"=>"x", "z"=>"x", "x"=>"x"} }, # "0" line
        #          "1" => { 
        #            "0" => {"0"=>"0", "1"=>"1", "z"=>"x", "x"=>"x"},
        #            "1" => {"0"=>"1", "1"=>"1", "z"=>"1", "x"=>"1"}, 
        #            "z" => {"0"=>"x", "1"=>"1", "z"=>"x", "x"=>"x"},
        #            "x" => {"0"=>"x", "1"=>"1", "z"=>"x", "x"=>"x"} }, # "1" line
        #          "z" => {
        #            "0" => {"0"=>"0", "1"=>"x", "z"=>"x", "x"=>"x"},
        #            "1" => {"0"=>"x", "1"=>"1", "z"=>"x", "x"=>"x"}, 
        #            "z" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"},
        #            "x" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"} }, # z line
        #          "x" => {
        #            "0" => {"0"=>"0", "1"=>"x", "z"=>"x", "x"=>"x"},
        #            "1" => {"0"=>"x", "1"=>"1", "z"=>"x", "x"=>"x"}, 
        #            "z" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"},
        #            "x" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"} } }# x line

        # # Lower than truth table: 0, 1, 2=z, 3=x
        # LT_T =   { "0" => {"0"=>"0", "1"=>"1", "z"=>"x", "x"=>"x"},  # 0 line
        #            "1" => {"0"=>"0", "1"=>"0", "z"=>"x", "x"=>"x"},  # 1 line
        #            "z" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"},  # z line
        #            "x" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"} } # x line

        # # Greater than truth table: 0, 1, 2=z, 3=x
        # GT_T =   { "0" => {"0"=>"0", "1"=>"0", "z"=>"x", "x"=>"x"},  # 0 line
        #            "1" => {"0"=>"1", "1"=>"0", "z"=>"x", "x"=>"x"},  # 1 line
        #            "z" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"},  # z line
        #            "x" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"} } # x line

        # The logic binary operators.
        [:&, :|, :^].each_with_index do |op,logic_num|
            tbl = LOGIC_T[logic_num]
            define_method(op) do |val|
                # puts "op=#{op} @content = #{@content} val=#{val} val.class=#{val.class}"
                if val.is_a?(BitString) then
                    if self.specified? && val.specified? then
                        return self.to_i.send(op,val.to_i)
                    end
                elsif val.is_a?(Numeric) && self.specified? then
                    return self.to_i.send(op,val)
                else
                    val = BitString.new(val)
                end
                vcontent = val.raw_content
                # puts "vcontent=#{vcontent}"
                width = vcontent.size > @content.size ? vcontent.size : @content.size
                res_content = width.times.map do |i|
                    # Get the bits to compute with
                    b0 = @content[i]
                    b0 = @content[-1] unless b0
                    # Compute
                    b1 = vcontent[i]
                    b1 = vcontent[-1] unless b1
                    tbl[b0][b1]
                end
                return BitString.new(res_content,:raw)
            end
        end

        # The unary logic operator.
        define_method(:~) do
            if self.specified? then
                return ~self.to_i
            else
                return BitString.new(@content.map {|b| NOT_T[b]},:raw)
            end
        end

        # The shift operators.
        define_method(:<<) do |val|
            if val.is_a?(BitString) then
                return UNKNOWN.clone unless val.specified?
            end
            return BitString.new(([0]*val.to_i) + @content,:raw)
        end
        define_method(:>>) do |val|
            if val.is_a?(BitString) then
                return UNKNOWN unless val.specified?
            end
            val = val.to_i
            val = @content.size if val > @content.size
            res_content = @content[val..-1]
            res_content << @content[-1] if res_content.empty?
            return BitString.new(res_content,:raw)
        end

        # The arithmetic binary operators.
        [:+, :-, :*, :**].each_with_index do |op|
            define_method(op) do |val|
                return UNKNOWN.clone unless self.specified?
                return UNKNOWN.clone if val.is_a?(BitString) && !val.specified?
                return self.to_i.send(op,val.to_i)
            end
        end

        # The dividing binary operators.
        [:/, :%].each_with_index do |op|
            define_method(op) do |val|
                return UNKNOWN.clone unless self.specified?
                return UNKNOWN.clone if val.is_a?(BitString) && !val.specified?
                val = val.to_i
                return UNKNOWN.clone if val == 0
                return self.to_i.send(op,val)
            end
        end

        # The arithmetic unary operator.
        define_method(:+@) do
            return self.clone
        end
        define_method(:-@) do
            if self.specified? then
                return -self.to_i
            else
                return UNKNOWN.clone
            end
        end

        # The comparison operators.
        [:==, :!=, :<, :>, :<=, :>=].each_with_index do |op|
            define_method(op) do |val|
                return UNKNOWN.clone unless self.specified?
                return UNKNOWN.clone if val.is_a?(BitString) && !val.specified?
                return self.to_i.send(op,val.to_i) ? 1 : 0
            end
        end




        # # Table of bitwise operations
        # BITWISE = { :+  => :bitwise_add0,
        #             :-  => :bitwise_sub0,
        #             :-@ => :bitwise_neg0,
        #             :+@ => :bitwise_pos,
        #             :*  => :bitwise_mul0,
        #             :/  => :bitwise_div0,
        #             :%  => :bitwise_mod0,
        #             :** => :bitwise_pow0,
        #             :&  => :bitwise_and,
        #             :|  => :bitwise_or,
        #             :^  => :bitwise_xor,
        #             :~  => :bitwise_not,
        #             :<< => :bitwise_shl,
        #             :>> => :bitwise_shr,
        #             :== => :bitwise_eq0,
        #             :!= => :bitwise_neq0,
        #             :<  => :bitwise_lt0,
        #             :>  => :bitwise_gt0,
        #             :<= => :bitwise_le0,
        #             :>= => :bitwise_ge0,
        #             :<=>=> :bitwise_cp0
        # }



        # # Binary operations

        # [:+, :-, :*, :/, :%, :**, :&, :|, :^,
        #  :<<, :>>,
        #  :==, :!=, :<, :>, :<=, :>=, :<=>].each do |op|
        #     # Select the bitwise operation.
        #     bitwise = BITWISE[op]
        #     # Define the operation method.
        #     define_method(op) do |value, sign0 = false, sign1 = false|
        #         # puts "op=#{op}, value=#{value}"
        #         # Check the value.
        #         unless value.is_a?(Numeric) || !value.specified? then
        #             value = sign1 ? value.to_numeric_signed : value.to_numeric
        #         end
        #         # Can the computation be performed with Ruby numeric values?
        #         if self.specified? and value.is_a?(Numeric) then
        #             # Yes, do it.
        #             if (op == :/ or op == :%) and value == 0 then
        #                 # Division by 0.
        #                 return UNKNOWN.sext(self.size)
        #             end
        #             res = sign0 ? self.to_numeric_signed.send(op,value) :
        #                           self.to_numeric.send(op,value)
        #             # Maybe the result was a boolean, change it to an integer
        #             res = res ? 1 : 0 unless res.is_a?(Numeric)
        #             return res
        #         else
        #             # No, do it bitwise.
        #             # Ensure value is a bit string.
        #             s1 = value.is_a?(BitString) ? value : BitString.new(value) 
        #             s0 = self
        #             # Adjust the widths
        #             if s0.width < s1.width then
        #                 s0 = s0.xext(s1.width)
        #             elsif s1.width < s0.width then
        #                 s1 = s1.xext(s0.width)
        #             end
        #             # Perform the bitwise computation.
        #             return BitString.send(bitwise,s0,s1)
        #         end
        #     end
        # end

        # # Unary operations
        # 
        # [:+@, :-@, :~].each do |op|
        #     # Select the bitwise operation.
        #     bitwise = BITWISE[op]
        #     # Define the operation method.
        #     define_method(op) do 
        #         # Can the computation be performed with Ruby numeric values?
        #         if self.specified? then
        #             # Yes, do it.
        #             return self.to_numeric.send(op)
        #         else
        #             # No, do it bitwise.
        #             # Perform the bitwise computiation on the lists of bits
        #             # res = BitString.send(bitwise,self.to_list)
        #             # return BitString.new(res[0..-2],res[-1])
        #             return BitString.send(bitwise,self)
        #         end
        #     end
        # end



        # # Bitwise operations: assume same bit width.
        # 
        # # Bitwise addition without processing of the x and z states.
        # def self.bitwise_add0(s0,s1)
        #     return BitString.new("x"*(s0.width+1))
        # end
        # 
        # # Bitwise addition
        # def self.bitwise_add(s0,s1)
        #     res = ""  # The result list of bits
        #     c   = "0" # The current carry
        #     s0.each.zip(s1.each) do |b0,b1|
        #         res << XOR3_T[b0][b1][c]
        #         c = MAJ_T[b0][b1][c]
        #     end
        #     # Compute the sign extension (the sign bit of s0 and s1 is used
        #     # again)
        #     res << XOR3_T[s0.sign][s1.sign][c]
        #     return BitString.new(res.reverse)
        # end

        # # Bitwise subtraction without processing of the x and z states.
        # def self.bitwise_sub0(s0,s1)
        #     return BitString.new("x"*(s0.width+1))
        # end

        # # Bitwise subtraction
        # def self.bitwise_sub(s0,s1)
        #     # # Negate s1.
        #     # s1 = BitString.bitwise_neg(s1).trunc(s0.width)
        #     # # puts "s1.width = #{s1.width} s0.width = #{s0.width}"
        #     # # Add it to s0: but no need to add a bit since neg already added
        #     # # one.
        #     # return BitString.bitwise_add(s0,s1)
        #     # Perform the computation is a way to limit the propagation of
        #     # unspecified bits.
        #     # Is s1 specified?
        #     if s1.specified? then
        #         # Yes, perform -s1+s0
        #         return (-s1 + s0)
        #     else
        #         # No, perform s0+1+NOT(s1).
        #         # puts "s0=#{s0} s0+1=#{s0+1} not s1=#{bitwise_not(s1)}"
        #         return (s0 + 1 + bitwise_not(s1)).trunc(s0.width+1)
        #     end
        # end

        # # Bitwise positive sign: does nothing.
        # def self.bitwise_pos(s)
        #     return s
        # end

        # # Bitwise negation without processing of the x and z states.
        # def self.bitwise_neg0(s)
        #     return BitString.new("x"*(s.width+1))
        # end

        # # Bitwise negation
        # def self.bitwise_neg(s)
        #     # -s = ~s + 1
        #     # # Not s.
        #     # s = BitString.bitwise_not(s)
        #     # # Add 1.
        #     # return BitString.bitwise_add(s,ONE.extend(s.width))
        #     return ~s + 1
        # end

        # # Bitwise and
        # def self.bitwise_and(s0,s1)
        #     # puts "bitwise_and with s0=#{s0} and s1=#{s1}"
        #     res = s0.each.zip(s1.each).map { |b0,b1| AND_T[b0][b1] }.join
        #     # puts "s0=#{s0}, s1=#{s1}, res=#{res.reverse}"
        #     return BitString.new(res.reverse)
        # end

        # # Bitwise or
        # def self.bitwise_or(s0,s1)
        #     res = s0.each.zip(s1.each).map { |b0,b1| OR_T[b0][b1] }.join
        #     return BitString.new(res.reverse)
        # end

        # # Bitwise xor
        # def self.bitwise_xor(s0,s1)
        #     res = s0.each.zip(s1.each). map { |b0,b1| XOR_T[b0][b1] }.join
        #     return BitString.new(res.reverse)
        # end

        # # Bitwise not
        # def self.bitwise_not(s)
        #     # puts "bitwise_not with s=#{s}"
        #     return BitString.new(s.each.map { |b| NOT_T[b] }.join.reverse)
        # end

        # # Bitwise shift left.
        # def self.bitwise_shl(s0,s1)
        #     # puts "s0=#{s0} s1=#{s1}"
        #     return BitString.new("x" * s0.width) unless s1.specified?
        #     s1 = s1.to_numeric
        #     if s1 >= 0 then
        #         return BitString.new(s0.str + "0" * s1)
        #     elsif -s1 > s0.width then
        #         return ZERO
        #     else
        #         return s0.trim(s0.width+s1)
        #     end
        # end

        # # Bitwise shift right.
        # def self.bitwise_shr(s0,s1)
        #     # puts "s0=#{s0} s1=#{s1}"
        #     return BitString.new("x" * s0.width) unless s1.specified?
        #     s1 = s1.to_numeric
        #     if s1 <= 0 then
        #         return BitString.new(s0.str + "0" * -s1)
        #     elsif s1 > s0.width then
        #         return ZERO
        #     else
        #         return s0.trim(s0.width-s1)
        #     end
        # end


        # # Bitwise eq without processing of the x and z states.
        # def self.bitwise_eq0(s0,s1)
        #     return UNKNOWN
        # end

        # # Bitwise eq without processing of the x and z states.
        # def self.bitwise_neq0(s0,s1)
        #     return UNKNOWN
        # end

        # # Bitwise eq.
        # def self.bitwise_eq(s0,s1)
        #     return UNKNOWN unless (s0.specified? and s1.specified?)
        #     return s0.str == s1.str ? TRUE : FALSE
        # end

        # # Bitwise neq.
        # def self.bitwise_neq(s0,s1)
        #     return UNKNOWN unless (s0.specified? and s1.specified?)
        #     return s0.str == s1.str ? FALSE : TRUE
        # end


        # # Bitwise lt without processing of the x and z states.
        # def self.bitwise_lt0(s0,s1)
        #     return UNKNOWN
        # end

        # # Bitwise lt.
        # def self.bitwise_lt(s0,s1)
        #     # # Handle the zero cases.
        #     # if s0.zero? then
        #     #     return TRUE if s1.positive?
        #     #     return FALSE if s1.negative? or s1.zero?
        #     #     return UNKNOWN
        #     # elsif s1.zero? then
        #     #     return TRUE if s0.negative?
        #     #     return FALSE if s0.positive? or s0.zero?
        #     #     return UNKNOWN
        #     # end
        #     # # Handle the unspecified sign cases.
        #     # unless s0.sign? then
        #     #     # Check both sign cases.
        #     #     lt_pos = self.bitwise_lt(s0[-1] = "1",s1) 
        #     #     lt_neg = self.bitwise_lt(s0[-1] = "0",s1) 
        #     #     # At least one of the results is unspecified.
        #     #     return UNKNOWN unless (lt_pos.specified? and lt_neg.specified?)
        #     #     # Both results are specified and identical.
        #     #     return lt_pos if lt_pos == lt_neg
        #     #     # Results are different.
        #     #     return UNKNOWN
        #     # end
        #     # unless s1.sign? then
        #     #     # Check both sign cases.
        #     #     lt_pos = self.bitwise_lt(s0,s1[-1] = "1") 
        #     #     lt_neg = self.bitwise_lt(s0,s1[-1] = "0") 
        #     #     # At least one of the results is unspecified.
        #     #     return UNKNOWN unless (lt_pos.specified? and lt_neg.specified?)
        #     #     # Both results are specified and identical.
        #     #     return lt_pos if lt_pos == lt_neg
        #     #     # Results are different.
        #     #     return UNKNOWN
        #     # end
        #     # # Signs are specificied.
        #     # # Depending on the signs
        #     # if s0.positive? then
        #     #     if s1.positive? then
        #     #         # s0 and s1 are positive, need to compare each bit.
        #     #         s0.reverse_each.zip(s1.reverse_each) do |b0,b1|
        #     #             # puts "b0=#{b0} b1=#{b1}, LT_T[b0][b1]=#{LT_T[b0][b1]}"
        #     #             case LT_T[b0][b1]
        #     #             when "x" then return UNKNOWN
        #     #             when "1" then return TRUE
        #     #             when "0" then
        #     #                 return FALSE if GT_T[b0][b1] == "1"
        #     #             end
        #     #         end
        #     #     elsif s1.negative? then
        #     #         # s0 is positive and s1 is negative.
        #     #         return FALSE
        #     #     else
        #     #         # The sign of s1 is undefined, comparison is undefined too.
        #     #         return UNKNOWN
        #     #     end
        #     # elsif s0.negative? then
        #     #     if s1.positive? then
        #     #         # s0 is negative and s1 is positive
        #     #         return TRUE
        #     #     elsif s1.negative? then
        #     #         # s0 and s1 are negative, need to compare each bit.
        #     #         s0.reverse_each.zip(s1.reverse_each) do |b0,b1|
        #     #             case GT_T[b0][b1]
        #     #             when "x" then return UNKNOWN
        #     #             when "1" then return FALSE
        #     #             when "0" then
        #     #                 return TRUE if LT_T[b0][b1] == "1"
        #     #             end
        #     #         end
        #     #     end
        #     # else
        #     #     # The sign of s0 is undefined, comparison is undefined too.
        #     #     return UNKNOWN
        #     # end

        #     # Check the sign of the subtraction between s0 and s1.
        #     case (s0-s1).sign
        #     when "0" then return FALSE
        #     when "1" then return TRUE
        #     else 
        #         return UNKNOWN
        #     end
        # end


        # # Bitwise gt without processing of the x and z states.
        # def self.bitwise_gt0(s0,s1)
        #     return UNKNOWN
        # end

        # # Bitwise gt.
        # def self.bitwise_gt(s0,s1)
        #     return self.bitwise_lt(s1,s0)
        # end


        # # Bitwise le without processing of the x and z states.
        # def self.bitwise_le0(s0,s1)
        #     return UNKNOWN
        # end

        # # Bitwise le.
        # def self.bitwise_le(s0,s1)
        #     gt = self.bitwise_gt(s0,s1)
        #     if gt.eql?(TRUE) then
        #         return FALSE
        #     elsif gt.eql?(FALSE) then
        #         return TRUE
        #     else
        #         return UNKNOWN
        #     end
        # end


        # # Bitwise ge without processing of the x and z states.
        # def self.bitwise_ge0(s0,s1)
        #     return UNKNOWN
        # end

        # # Bitwise ge.
        # def self.bitwise_ge(s0,s1)
        #     lt = self.bitwise_lt(s0,s1)
        #     if lt.eql?(TRUE) then
        #         return FALSE
        #     elsif lt.eql?(FALSE) then
        #         return TRUE
        #     else
        #         return UNKNOWN
        #     end
        # end


        # # Bitwise cp without processing of the x and z states.
        # def self.bitwise_cp0(s0,s1)
        #     return UNKNOWN
        # end

        # # Bitwise cp.
        # def self.bitwise_cp(s0,s1)
        #     # Compare the signs.
        #     if s0.sign == "0" and s1.sign == "1" then
        #         return ONE
        #     elsif s0.sign == 0 and s1.sign == "1" then
        #         return MINUS_ONE
        #     end
        #     # Compare the other bits.
        #     sub = self.bitwise_sub(s0,s1)
        #     if sub.negative? then
        #         return MINUS_ONE
        #     elsif sub.zero? then
        #         return ZERO
        #     elsif sub.positive? then
        #         return ONE
        #     else
        #         return UNKNOWN
        #     end
        # end


        # # Bitwise mul without processing of the x and z states.
        # def self.bitwise_mul0(s0,s1)
        #     return BitString.new("x"*(s0.width+s1.width))
        # end

        # # # Bitwise mul.
        # # def self.bitwise_mul(s0,s1)
        # #     # Initialize the result to ZERO of combined s0 and s1 widths
        # #     res = ZERO.extend(s0.width + s1.width)
        # #     # The zero cases.
        # #     if s0.zero? or s1.zero? then
        # #         return res
        # #     end
        # #     # Convert s1 and res to lists of bits which support computation
        # #     # between unknown bits of same values.
        # #     s1 = s1.extend(res.width).to_list
        # #     res = res.to_list
        # #     # The other cases: perform a multiplication with shifts and adds.
        # #     s0.each.lazy.take(s0.width).each do |b|
        # #         case b
        # #         when "1" then self.list_add!(res,s1)
        # #         when "x","z" then self.list_add!(res,self.list_and_unknown(s1))
        # #         end
        # #         # puts "res=#{res} s1=#{s1}"
        # #         self.list_shl_1!(s1)
        # #     end
        # #     # Add the sign row.
        # #     case s0.sign
        # #     when "1" then self.list_sub!(res,s1)
        # #     when "x","z" then self.list_sub!(res,list_and_unknown(s1))
        # #     end
        # #     # Return the result.
        # #     return self.list_to_bstr(res)
        # # end

        # # Bitwise div without processing of the x and z states.
        # def self.bitwise_div0(s0,s1)
        #     return BitString.new("x"*(s0.width))
        # end

        # # # Bitwise div.
        # # def self.bitwise_div(s0,s1)
        # #     width = s0.width
        # #     # The zero cases.
        # #     if s0.zero? then
        # #         return res
        # #     elsif s1.maybe_zero? then
        # #         return UNKNOWN.extend(width)
        # #     end
        # #     # Handle the sign: the division is only performed on positive
        # #     # numbers.
        # #     # NOTE: we are sure that s0 and s1 are not zero since these
        # #     # cases have been handled before.
        # #     sign = nil
        # #     if s0.sign == "0" then
        # #         if s1.sign == "0" then
        # #             sign = "0"
        # #         elsif s1.sign == "1" then
        # #             sign = "1"
        # #             s1 = -s1
        # #         else
        # #             # Unknown sign, unkown result.
        # #             return UNKNOWN.extend(width)
        # #         end
        # #     elsif s0.sign == "1" then
        # #         s0 = -s0
        # #         if s1.sign == "0" then
        # #             sign = "1"
        # #         elsif s1.sign == "1" then
        # #             sign = "0"
        # #             s1 = -s1
        # #         else
        # #             # Unknwown sign, unknown result.
        # #             return UNKNOWN.extend(width)
        # #         end
        # #     else
        # #         # Unknown sign, unknown result.
        # #         return UNKNOWN.extend(width)
        # #     end
        # #     # Convert s0 and s1 to list of bits of widths of s0 and s1 -1
        # #     # (the largest possible value).
        # #     # s0 will serve as current remainder.
        # #     s0 = BitString.new(s0) if s0.is_a?(Numeric)
        # #     s1 = BitString.new(s1) if s1.is_a?(Numeric)
        # #     s0 = s0.extend(s0.width+s1.width-1)
        # #     s1 = s1.extend(s0.width)
        # #     s0 = s0.to_list
        # #     s1 = s1.to_list
        # #     puts "first s1=#{s1}"
        # #     # Adujst s1 to the end of s0 and the corresponding 0s in front of q
        # #     msb = s0.reverse.index {|b| b != 0}
        # #     steps = s0.size-msb
        # #     self.list_shl!(s1,steps-1)
        # #     q = [ 0 ] * (width-steps)
        # #     # Apply the non-restoring division algorithm.
        # #     sub = true
        # #     puts "steps= #{steps} s0=#{s0} s1=#{s1} q=#{q}"
        # #     (steps).times do |i|
        # #         if sub then
        # #             self.list_sub!(s0,s1)
        # #         else
        # #             self.list_add!(s0,s1)
        # #         end
        # #         puts "s0=#{s0}"
        # #         # Is the result positive?
        # #         if s0[-1] == 0 then
        # #             # Yes, the next step is a subtraction and the current
        # #             # result bit is one.
        # #             sub = true
        # #             q.unshift(1)
        # #         elsif s0[-1] == 1 then
        # #             # No, it is negative the next step is an addition and the
        # #             # current result bit is zero.
        # #             sub = false
        # #             q.unshift(0)
        # #         else
        # #             # Unknown sign, the remaining of q is unknown.
        # #             (steps-i).times { q.unshift(self.new_unknown) }
        # #             # Still, can add the positive sign bit.
        # #             q.push(0)
        # #             break
        # #         end
        # #         self.list_shr_1!(s1)
        # #     end
        # #     # Generate the resulting bit string.
        # #     puts "q=#{q}"
        # #     q = self.list_to_bstr(q)
        # #     puts "q=#{q}"
        # #     # Set the sign.
        # #     if sign == "1" then
        # #         q = (-q).trunc(width)
        # #     elsif q.zero? then
        # #         q = 0
        # #     else
        # #         q = q.extend(width)
        # #     end
        # #     # Return the result.
        # #     return q
        # # end


        # # Bitwise mod without processing of the x and z states.
        # def self.bitwise_mod0(s0,s1)
        #     return BitString.new("x"*(s1.width))
        # end

        # # # Bitwise mod.
        # # def self.bitwise_mod(s0,s1)
        # #     raise "bitwise_mod is not implemented yet."
        # # end
    

        # # Computation with list of bits: 
        # # "0" -> 0, "1" -> 1, and then 2, 3, 4, ...
        # # Allows more precise computations (e.g., mul, div).
        # 
        # # The counter of unknown bits.
        # @@unknown = 1

        # # Creates a new uniq unknown bit.
        # def self.new_unknown
        #     @@unknown += 1
        #     return @@unknown
        # end

        # # Converts to a list of bits where unknown or high z bits are
        # # differentiate from each other.
        # #
        # # NOTE:
        # # * the sign bit is also added to the list.
        # # * the distinction between z and x is lost.
        # def to_list
        #     return @str.each_char.reverse_each.map.with_index do |b,i|
        #         case b
        #         when "0"     then 0
        #         when "1"     then 1
        #         when "z","x" then BitString.new_unknown
        #         else
        #             raise "Internal error: invalid bit in bitstring: #{b}"
        #         end
        #     end
        # end

        # # Converts list of bits +l+ to a bit string.
        # def self.list_to_bstr(l)
        #     str = l.reverse_each.map { |b| b > 1 ? "x" : b }.join
        #     return BitString.new(str)
        # end

        # # Compute the and between +l+ and an unknown value.
        # def self.list_and_unknown(l)
        #     return l.map do |b|
        #         b == 0 ? 0 : BitString.new_unknown
        #     end
        # end

        # # Compute the not of +l+
        # def self.list_not(l)
        #     return l.map do |b|
        #         case b
        #         when 0 then 1
        #         when 1 then 0
        #         else
        #             BitString.new_unknown
        #         end
        #     end
        # end

        # # Adds +l1+ to +l0+.
        # # 
        # # NOTE:
        # # * l0 is contains the result.
        # # * The result has the same size as +l0+ (no sign extension).
        # # * Assumes +l0+ and +l1+ have the same size.
        # def self.list_add!(l0,l1)
        #     # puts "add l0=#{l0} l1=#{l1}"
        #     c = 0 # Current carry.
        #     l0.each_with_index do |b0,i|
        #         b1 = l1[i]
        #         # puts "i=#{i} b0=#{b0} b1=#{b1} c=#{c}"
        #         if b0 == b1 then
        #             # The sum is c.
        #             l0[i] = c
        #             # The carry is b0.
        #             c = b0
        #         elsif b0 == c then
        #             # The sum is b1.
        #             l0[i] = b1
        #             # The carry is b0.
        #             c = b0
        #         elsif b1 == c then
        #             # The sum is b0.
        #             l0[i] = b0
        #             # The carry is b1.
        #             c = b1
        #         else
        #             l0[i] = self.new_unknown
        #             c = self.new_unknown
        #         end
        #     end
        #     return l0
        # end

        # # Adds 1 to +l0+.
        # # 
        # # NOTE:
        # # * l0 is contains the result.
        # # * The result has the same size as +l0+ (no sign extension).
        # def self.list_add_1!(l0)
        #     c = 1 # Current carry.
        #     l0.each_with_index do |b0,i|
        #         if c == 0 then
        #             # The sum is b0.
        #             l0[i] = b0
        #             # The carry is unchanged.
        #         elsif b0 == 0 then
        #             # The sum is c.
        #             l0[i] = c
        #             # The carry is 0.
        #             c = 0
        #         elsif b0 == c then
        #             # The sum is 0.
        #             l0[i] = 0
        #             # The carry is b0.
        #             c = b0
        #         else
        #             # Both sum and carry are unknown
        #             l0[i] = BitString.new_unknown
        #             c = BitString.new_unknown
        #         end
        #     end
        #     return l0
        # end

        # # Subtracts +l1+ from +l0+.
        # # 
        # # NOTE:
        # # * l0 is contains the result.
        # # * The result has the same size as +l0+ (no sign extension).
        # # * Assumes +l0+ and +l1+ have the same size.
        # def self.list_sub!(l0,l1)
        #     # Adds 1 to l0.
        #     BitString.list_add_1!(l0)
        #     # Adds ~l1 to l0.
        #     # puts "l0=#{l0} l1=#{l1} ~l1=#{self.list_not(l1)}}"
        #     self.list_add!(l0,self.list_not(l1))
        #     # puts "l0=#{l0}"
        #     # puts "now l0=#{l0}"
        #     return l0
        # end

        # # Left shifts +l+ once.
        # #
        # # NOTE:
        # # * l contains the result.
        # # * The result has the same size as +l+ (no sign extension).
        # def self.list_shl_1!(l)
        #     l.pop
        #     l.unshift(0)
        #     return l
        # end

        # # Right shifts +l+ once.
        # #
        # # NOTE:
        # # * l contains the result.
        # # * The result has the same size as +l+ (no sign extension).
        # def self.list_shr_1!(l)
        #     l.shift
        #     l.push(0)
        #     return l
        # end


        # # Left shifts +l+ +x+ times.
        # #
        # # NOTE:
        # # * l contains the result.
        # # * The result has the same size as +l+ (no sign extension).
        # def self.list_shl!(l,x)
        #     l.pop(x)
        #     l.unshift(*([0]*x))
        # end

    end

end
