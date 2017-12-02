module HDLRuby

##
# Library for describing the bit string and their computations.
#
########################################################################
    

    # Converts a value to a valid bit if possible.
    def make_bit(value)
        value = value.to_s.downcase
        unless ["0","1","x","z"].include?(value)
            raise "Invalid value for a bit: #{value}"
        end
        return value
    end


    ##
    # Describes a bit string.
    #
    # NOTE: 
    # * a bit string is immutable.
    # * bit strings are always signed.
    # * the upper bit of a bit string is the sign.
    class BitString

        # Creates a new bit string from +str+ with +sign+.
        #
        # NOTE: 
        # * +sign+ can be "0", "1", "z" and "x", is positive when "0"
        #   and negative when "1".
        # * when not present it is assumed to be within str.
        def initialize(str,sign = nil)
            # Maybe str is an numeric.
            if str.is_a?(Numeric) then
                # Yes, convert it to a binary string.
                str = str.to_s(2)
                # And fix the sign.
                if str[0] == "-" then
                    str = str[1..-1]
                    sign = "-"
                else
                    sign = "+"
                end
                # puts "str=#{str} sign=#{sign}"
            end
            # Process the sign
            sign = sign.to_s unless sign.is_a?(Integer)
            case sign
            when 0, "0","+" then @str = "0"
            when 1, "1","-" then @str = "1"
            when 2, "z","Z" then @str = "z"
            when 3, "x","X" then @str = "x"
            when nil, ""    then @str = "" # The sign is in str
            else
                raise "Invalid bit string sign: #{sign}"
            end
            # Check and set the value of the bit string.
            if str.respond_to?(:to_a) then
                # Str is a bit list: convert it to a string.
                str = str.to_a.map do |e|
                    case e
                    when 0 then "0"
                    when 1 then "1"
                    when 2 then "z"
                    when 3 then "x"
                    else
                        e
                    end
                end.reverse.join
            end
            @str += str.to_s.downcase
            unless @str.match(/^[0-1zx]+$/) then
                raise "Invalid value for creating a bit string: #{str}"
            end
        end

        # Gets the bitwidth (sign bit is not comprised).
        def width
            return @str.size - 1
        end
        alias size width

        # Tells if the bit string is strictly.
        #
        # NOTE: return false if the sign is undefined of if it is unknown
        #       if the result is zero or not.
        def positive?
            return (@str[0] == "0" and self.nonzero?)
        end

        # Tells if the bit string is strictly negative.
        #
        # NOTE: return false if the sign is undefined
        def negative?
            return @str[0] == "1"
        end

        # Tells if the bit string is zero.
        #
        # NOTE: return false if the bit string is undefined.
        def zero?
            return ! @str.each_char.any? {|b| b != "0" }
        end

        # Tells if the bit string is not zero.
        def nonzero?
            return @str.each_char.any? {|b| b == "1" }
        end

        # Tells if the bit string could be zero.
        def maybe_zero?
            return ! self.nonzero?
        end

        # Converts to a string (sign bit is comprised).
        def to_s
            return @str.clone
        end
        alias str to_s

        # Gets a bit by +index+.
        #
        # NOTE: If the index is larger than the bit string width, returns the
        #       bit sign.
        def [](index)
            # Handle the negative index case.
            if index < 0 then
                return self[self.width+index]
            end
            # Process the index.
            index = index > @str.size ? @str.size : index
            # Get the corresponding bit.
            return @str[-index-1]
        end

        # Sets the bit at +index+ to +value+.
        #
        # NOTE: when index is larger than the bit width, the bit string is
        # sign extended accordingly.
        def []=(index,value)
            # Handle the negative index case.
            if index < 0 then
                return self[self.width+index] = value
            end
            # Duplicate the bit string content to ensure immutability.
            str = @str.clone
            # Process the index.
            if index >= str.size then
                # Overflow, sign extend the bit string.
                str += str[-1] * (index-str.size+1)
            end
            # Checks and convert the value
            value = make_bit(value)
            # Sets the value to a copy of the bit string.
            str[-index-1] = value
            # Return the result as a new bit string.
            return BitString.new(str)
        end

        # Truncs to +width+.
        #
        # NOTE:
        # * trunc remove the end of the bit string.
        # * if the width is already smaller than +width+, do nothing.
        # * do not preserve the sign, but keep the last bit as sign bit.
        def trunc(width)
            return self if width >= @str.size-1
            return BitString.new(@str[(@str.size-width-1)..-1])
        end

        # Trims to +width+.
        #
        # NOTE:
        # * trim remove the begining of the bit string.
        # * if the width is already smaller than +width+, do nothing.
        # * do not preserve the sign, but keep the last bit as sign bit.
        def trim(width)
            return self if width >= @str.size-1
            return BitString.new(@str[0..width])
        end

        # Extend to +width+.
        #
        # NOTE:
        # * if the width is already larger than +width+, do nothing.
        # * preserves the sign.
        def extend(width)
           return self if width <= @str.size - 1
           return BitString.new(@str[0] * (width-@str.size+1) + @str)
        end

        # Iterates over the bits.
        #
        # NOTE: the sign bit in comprised.
        #
        # Returns an enumerator if no ruby block is given.
        def each(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each) unless ruby_block
            # A block? Apply it on each bit.
            @str.each_char.reverse_each(&ruby_block)
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
            @str.each_char(&ruby_block)
        end

        # Gets the sign of the bit string.
        def sign
            return @str[0]
        end

        # Tell if the sign is specified.
        def sign?
            return (@str[0] == "0" or @str[0] == "1")
        end

        # Convert the bit string to a Ruby Numeric.
        #
        # NOTE: the result will be wrong is the bit string is unspecified.
        def to_numeric
            res = 0
            # Process the bits.
            @str[1..-1].each_char { |b| res = res << 1 | b.to_i }
            # Process the sign.
            res = res - (2**(@str.size-1)) if @str[0] == "1"
            # Return the result.
            return res
        end

        # Tell if the bit string is fully specified
        def specified?
            return ! @str.match(/[xz]/)
        end

        # Coerces.
        def coerce(other)
            return [BitString.new(other),self]
        end


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
        NOT_T =    { "0" => "1", "1" => "0", "z" => "x", "x" => "x" }
        
        # And truth table: 0, 1, 2=z, 3=x
        AND_T =  { "0" => {"0"=>"0", "1"=>"0", "z"=>"0", "x"=>"0"},  # 0 line
                   "1" => {"0"=>"0", "1"=>"1", "z"=>"x", "x"=>"x"},  # 1 line
                   "z" => {"0"=>"0", "1"=>"x", "z"=>"x", "x"=>"x"},  # z line
                   "x" => {"0"=>"0", "1"=>"x", "z"=>"x", "x"=>"x"} } # x line
        
        # Or truth table: 0, 1, 2=z, 3=x
        OR_T =   { "0" => {"0"=>"0", "1"=>"1", "z"=>"x", "x"=>"x"},  # 0 line
                   "1" => {"0"=>"1", "1"=>"1", "z"=>"1", "x"=>"1"},  # 1 line
                   "z" => {"0"=>"x", "1"=>"1", "z"=>"x", "x"=>"x"},  # z line
                   "x" => {"0"=>"x", "1"=>"1", "z"=>"x", "x"=>"x"} } # x line
        
        # Xor truth table: 0, 1, 2=z, 3=x
        XOR_T =  { "0" => {"0"=>"0", "1"=>"1", "z"=>"x", "x"=>"x"},  # 0 line
                   "1" => {"0"=>"1", "1"=>"0", "z"=>"x", "x"=>"x"},  # 1 line
                   "z" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"},  # z line
                   "x" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"} } # x line

        # Double xor truth table: 0, 1, 2=z, 3=x
        XOR3_T={ "0" => {
                   "0" => {"0"=>"0", "1"=>"1", "z"=>"x", "x"=>"x"}, 
                   "1" => {"0"=>"1", "1"=>"0", "z"=>"x", "x"=>"x"}, 
                   "z" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"},
                   "x" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"} }, # 0 line
                 "1" => {
                   "0" => {"0"=>"1", "1"=>"0", "z"=>"x", "x"=>"x"},
                   "1" => {"0"=>"0", "1"=>"1", "z"=>"x", "x"=>"x"}, 
                   "z" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"},
                   "x" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"} }, # 1 line
                 "z" => {
                   "0" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"},
                   "1" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"}, 
                   "z" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"},
                   "x" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"} }, # z line
                 "x" => {
                   "0" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"},
                   "1" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"},
                   "z" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"},
                   "x" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"} } }# x line

        # Majority truth table: 0, 1, 2=z, 3=x
        MAJ_T= { "0" => {
                   "0" => {"0"=>"0", "1"=>"0", "z"=>"0", "x"=>"0"},
                   "1" => {"0"=>"0", "1"=>"1", "z"=>"x", "x"=>"x"}, 
                   "z" => {"0"=>"0", "1"=>"x", "z"=>"x", "x"=>"x"},
                   "x" => {"0"=>"0", "1"=>"x", "z"=>"x", "x"=>"x"} }, # "0" line
                 "1" => { 
                   "0" => {"0"=>"0", "1"=>"1", "z"=>"x", "x"=>"x"},
                   "1" => {"0"=>"1", "1"=>"1", "z"=>"1", "x"=>"1"}, 
                   "z" => {"0"=>"x", "1"=>"1", "z"=>"x", "x"=>"x"},
                   "x" => {"0"=>"x", "1"=>"1", "z"=>"x", "x"=>"x"} }, # "1" line
                 "z" => {
                   "0" => {"0"=>"0", "1"=>"x", "z"=>"x", "x"=>"x"},
                   "1" => {"0"=>"x", "1"=>"1", "z"=>"x", "x"=>"x"}, 
                   "z" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"},
                   "x" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"} }, # z line
                 "x" => {
                   "0" => {"0"=>"0", "1"=>"x", "z"=>"x", "x"=>"x"},
                   "1" => {"0"=>"x", "1"=>"1", "z"=>"x", "x"=>"x"}, 
                   "z" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"},
                   "x" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"} } }# x line

        # Lower than truth table: 0, 1, 2=z, 3=x
        LT_T =   { "0" => {"0"=>"0", "1"=>"1", "z"=>"x", "x"=>"x"},  # 0 line
                   "1" => {"0"=>"0", "1"=>"0", "z"=>"x", "x"=>"x"},  # 1 line
                   "z" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"},  # z line
                   "x" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"} } # x line

        # Greater than truth table: 0, 1, 2=z, 3=x
        GT_T =   { "0" => {"0"=>"0", "1"=>"0", "z"=>"x", "x"=>"x"},  # 0 line
                   "1" => {"0"=>"1", "1"=>"0", "z"=>"x", "x"=>"x"},  # 1 line
                   "z" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"},  # z line
                   "x" => {"0"=>"x", "1"=>"x", "z"=>"x", "x"=>"x"} } # x line

        # Table of bitwise operations
        BITWISE = { :+  => :bitwise_add0,
                    :-  => :bitwise_sub0,
                    :-@ => :bitwise_neg0,
                    :+@ => :bitwise_pos,
                    :*  => :bitwise_mul0,
                    :/  => :bitwise_div0,
                    :%  => :bitwise_mod0,
                    :** => :bitwise_pow0,
                    :&  => :bitwise_and,
                    :|  => :bitwise_or,
                    :^  => :bitwise_xor,
                    :~  => :bitwise_not,
                    :<< => :bitwise_shl,
                    :>> => :bitwise_shr,
                    :== => :bitwise_eq0,
                    :<  => :bitwise_lt0,
                    :>  => :bitwise_gt0,
                    :<= => :bitwise_le0,
                    :>= => :bitwise_ge0,
                    :<=>=> :bitwise_cp0
        }



        # Binary operations

        [:+, :-, :*, :/, :%, :**, :&, :|, :^,
         :<<, :>>,
         :==, :<, :>, :<=, :>=, :<=>].each do |op|
            # Select the bitwise operation.
            bitwise = BITWISE[op]
            # Define the operation method.
            define_method(op) do |value|
                # Check the value.
                unless value.is_a?(Numeric) then
                    value = value.to_numeric if value.specified?
                end
                # Can the computation be performed with Ruby numeric values?
                if self.specified? and value.is_a?(Numeric) then
                    # Yes, do it.
                    if (op == :/ or op == :%) and value == 0 then
                        # Division by 0.
                        return UNKNOWN.extend(self.size)
                    end
                    res = self.to_numeric.send(op,value)
                    # Maybe the result was a boolean, change it to an integer
                    res = res ? 1 : 0 unless res.is_a?(Numeric)
                    return res
                else
                    # # No, is it a multiplication, division, modulo, or pow?
                    # # If it is the case, only specific values can be computed
                    # # otherwise the result is unspecified.
                    # case op
                    # when :*  then
                    #     svalue = self.specified? ? self.to_numeric : self
                    #     return BitString.multiplication(svalue,value)
                    # when :/  then 
                    #     svalue = self.specified? ? self.to_numeric : self
                    #     return BitString.division(svalue,value)
                    # when :%  then 
                    #     svalue = self.specified? ? self.to_numeric : self
                    #     return BitString.modulo(svalue,value)
                    # when :** then 
                    #     svalue = self.specified? ? self.to_numeric : self
                    #     return BitString.pow(svalue,value)
                    # end
                    # No, do it bitwise.
                    # Ensure value is a bit string.
                    s1 = value.is_a?(BitString) ? value : BitString.new(value) 
                    s0 = self
                    # # Convert to list of bits.
                    # value = value.to_list
                    # slist = self.to_list
                    # # Adjust the sizes.
                    # if value.size < slist.size then
                    #     value += [value[-1]] * (slist.size - value.size)
                    # elsif value.size > slist.size then
                    #     slist += [slist[-1]] * (value.size - slist.size)
                    # end
                    # # Perform the bitwise computation on the lists of bits
                    # res = BitString.send(bitwise,slist,value)
                    # return BitString.new(res[0..-2],res[-1])
                    
                    # Adjust the widths
                    if s0.width < s1.width then
                        s0 = s0.extend(s1.width)
                    elsif s1.width < s0.width then
                        s1 = s1.extend(s0.width)
                    end
                    # Perform the bitwise computation.
                    return BitString.send(bitwise,s0,s1)
                end
            end
        end

        # Unary operations
        
        [:+@, :-@, :~].each do |op|
            # Select the bitwise operation.
            bitwise = BITWISE[op]
            # Define the operation method.
            define_method(op) do 
                # Can the computation be performed with Ruby numeric values?
                if self.specified? then
                    # Yes, do it.
                    return self.to_numeric.send(op)
                else
                    # No, do it bitwise.
                    # Perform the bitwise computiation on the lists of bits
                    # res = BitString.send(bitwise,self.to_list)
                    # return BitString.new(res[0..-2],res[-1])
                    return BitString.send(bitwise,self)
                end
            end
        end


        # Bitwise operations: assume same bit width.
        
        # Bitwise addition without processing of the x and z states.
        def self.bitwise_add0(s0,s1)
            return BitString.new("x"*(s0.width+1))
        end
        
        # Bitwise addition
        def self.bitwise_add(s0,s1)
            res = ""  # The result list of bits
            c   = "0" # The current carry
            s0.each.zip(s1.each) do |b0,b1|
                res << XOR3_T[b0][b1][c]
                c = MAJ_T[b0][b1][c]
            end
            # Compute the sign extension (the sign bit of s0 and s1 is used
            # again)
            res << XOR3_T[s0.sign][s1.sign][c]
            return BitString.new(res.reverse)
        end

        # Bitwise subtraction without processing of the x and z states.
        def self.bitwise_sub0(s0,s1)
            return BitString.new("x"*(s0.width+1))
        end

        # Bitwise subtraction
        def self.bitwise_sub(s0,s1)
            # # Negate s1.
            # s1 = BitString.bitwise_neg(s1).trunc(s0.width)
            # # puts "s1.width = #{s1.width} s0.width = #{s0.width}"
            # # Add it to s0: but no need to add a bit since neg already added
            # # one.
            # return BitString.bitwise_add(s0,s1)
            # Perform the computation is a way to limit the propagation of
            # unspecified bits.
            # Is s1 specified?
            if s1.specified? then
                # Yes, perform -s1+s0
                return (-s1 + s0)
            else
                # No, perform s0+1+NOT(s1).
                # puts "s0=#{s0} s0+1=#{s0+1} not s1=#{bitwise_not(s1)}"
                return (s0 + 1 + bitwise_not(s1)).trunc(s0.width+1)
            end
        end

        # Bitwise positive sign: does nothing.
        def self.bitwise_pos(s)
            return s
        end

        # Bitwise negation without processing of the x and z states.
        def self.bitwise_neg0(s)
            return BitString.new("x"*(s.width+1))
        end

        # Bitwise negation
        def self.bitwise_neg(s)
            # -s = ~s + 1
            # # Not s.
            # s = BitString.bitwise_not(s)
            # # Add 1.
            # return BitString.bitwise_add(s,ONE.extend(s.width))
            return ~s + 1
        end

        # Bitwise and
        def self.bitwise_and(s0,s1)
            res = s0.each.zip(s1.each).map { |b0,b1| AND_T[b0][b1] }.join
            # puts "s0=#{s0}, s1=#{s1}, res=#{res}"
            return BitString.new(res.reverse)
        end

        # Bitwise or
        def self.bitwise_or(s0,s1)
            res = s0.each.zip(s1.each). map { |b0,b1| OR_T[b0][b1] }.join
            return BitString.new(res.reverse)
        end

        # Bitwise xor
        def self.bitwise_xor(s0,s1)
            res = s0.each.zip(s1.each). map { |b0,b1| XOR_T[b0][b1] }.join
            return BitString.new(res.reverse)
        end

        # Bitwise not
        def self.bitwise_not(s)
            return BitString.new(s.each.map { |b| NOT_T[b] }.join.reverse)
        end

        # Bitwise shift left.
        def self.bitwise_shl(s0,s1)
            # puts "s0=#{s0} s1=#{s1}"
            return BitString.new("x" * s0.width) unless s1.specified?
            s1 = s1.to_numeric
            if s1 >= 0 then
                return BitString.new(s0.str + "0" * s1)
            elsif -s1 > s0.width then
                return ZERO
            else
                return s0.trim(s0.width+s1)
            end
        end

        # Bitwise shift right.
        def self.bitwise_shr(s0,s1)
            # puts "s0=#{s0} s1=#{s1}"
            return BitString.new("x" * s0.width) unless s1.specified?
            s1 = s1.to_numeric
            if s1 <= 0 then
                return BitString.new(s0.str + "0" * -s1)
            elsif s1 > s0.width then
                return ZERO
            else
                return s0.trim(s0.width-s1)
            end
        end


        # Bitwise eq without processing of the x and z states.
        def self.bitwise_eq0(s0,s1)
            return UNKNOWN
        end

        # Bitwise eq.
        def self.bitwise_eq(s0,s1)
            return UNKNOWN unless (s0.specified? and s1.specified?)
            return s0.str == s1.str ? TRUE : FALSE
        end


        # Bitwise lt without processing of the x and z states.
        def self.bitwise_lt0(s0,s1)
            return UNKNOWN
        end

        # Bitwise lt.
        def self.bitwise_lt(s0,s1)
            # # Handle the zero cases.
            # if s0.zero? then
            #     return TRUE if s1.positive?
            #     return FALSE if s1.negative? or s1.zero?
            #     return UNKNOWN
            # elsif s1.zero? then
            #     return TRUE if s0.negative?
            #     return FALSE if s0.positive? or s0.zero?
            #     return UNKNOWN
            # end
            # # Handle the unspecified sign cases.
            # unless s0.sign? then
            #     # Check both sign cases.
            #     lt_pos = self.bitwise_lt(s0[-1] = "1",s1) 
            #     lt_neg = self.bitwise_lt(s0[-1] = "0",s1) 
            #     # At least one of the results is unspecified.
            #     return UNKNOWN unless (lt_pos.specified? and lt_neg.specified?)
            #     # Both results are specified and identical.
            #     return lt_pos if lt_pos == lt_neg
            #     # Results are different.
            #     return UNKNOWN
            # end
            # unless s1.sign? then
            #     # Check both sign cases.
            #     lt_pos = self.bitwise_lt(s0,s1[-1] = "1") 
            #     lt_neg = self.bitwise_lt(s0,s1[-1] = "0") 
            #     # At least one of the results is unspecified.
            #     return UNKNOWN unless (lt_pos.specified? and lt_neg.specified?)
            #     # Both results are specified and identical.
            #     return lt_pos if lt_pos == lt_neg
            #     # Results are different.
            #     return UNKNOWN
            # end
            # # Signs are specificied.
            # # Depending on the signs
            # if s0.positive? then
            #     if s1.positive? then
            #         # s0 and s1 are positive, need to compare each bit.
            #         s0.reverse_each.zip(s1.reverse_each) do |b0,b1|
            #             # puts "b0=#{b0} b1=#{b1}, LT_T[b0][b1]=#{LT_T[b0][b1]}"
            #             case LT_T[b0][b1]
            #             when "x" then return UNKNOWN
            #             when "1" then return TRUE
            #             when "0" then
            #                 return FALSE if GT_T[b0][b1] == "1"
            #             end
            #         end
            #     elsif s1.negative? then
            #         # s0 is positive and s1 is negative.
            #         return FALSE
            #     else
            #         # The sign of s1 is undefined, comparison is undefined too.
            #         return UNKNOWN
            #     end
            # elsif s0.negative? then
            #     if s1.positive? then
            #         # s0 is negative and s1 is positive
            #         return TRUE
            #     elsif s1.negative? then
            #         # s0 and s1 are negative, need to compare each bit.
            #         s0.reverse_each.zip(s1.reverse_each) do |b0,b1|
            #             case GT_T[b0][b1]
            #             when "x" then return UNKNOWN
            #             when "1" then return FALSE
            #             when "0" then
            #                 return TRUE if LT_T[b0][b1] == "1"
            #             end
            #         end
            #     end
            # else
            #     # The sign of s0 is undefined, comparison is undefined too.
            #     return UNKNOWN
            # end

            # Check the sign of the subtraction between s0 and s1.
            case (s0-s1).sign
            when "0" then return FALSE
            when "1" then return TRUE
            else 
                return UNKNOWN
            end
        end


        # Bitwise gt without processing of the x and z states.
        def self.bitwise_gt0(s0,s1)
            return UNKNOWN
        end

        # Bitwise gt.
        def self.bitwise_gt(s0,s1)
            return self.bitwise_lt(s1,s0)
        end


        # Bitwise le without processing of the x and z states.
        def self.bitwise_le0(s0,s1)
            return UNKNOWN
        end

        # Bitwise le.
        def self.bitwise_le(s0,s1)
            gt = self.bitwise_gt(s0,s1)
            if gt.eql?(TRUE) then
                return FALSE
            elsif gt.eql?(FALSE) then
                return TRUE
            else
                return UNKNOWN
            end
        end


        # Bitwise ge without processing of the x and z states.
        def self.bitwise_ge0(s0,s1)
            return UNKNOWN
        end

        # Bitwise ge.
        def self.bitwise_ge(s0,s1)
            lt = self.bitwise_lt(s0,s1)
            if lt.eql?(TRUE) then
                return FALSE
            elsif lt.eql?(FALSE) then
                return TRUE
            else
                return UNKNOWN
            end
        end


        # Bitwise cp without processing of the x and z states.
        def self.bitwise_cp0(s0,s1)
            return UNKNOWN
        end

        # Bitwise cp.
        def self.bitwise_cp(s0,s1)
            # Compare the signs.
            if s0.sign == "0" and s1.sign == "1" then
                return ONE
            elsif s0.sign == 0 and s1.sign == "1" then
                return MINUS_ONE
            end
            # Compare the other bits.
            sub = self.bitwise_sub(s0,s1)
            if sub.negative? then
                return MINUS_ONE
            elsif sub.zero? then
                return ZERO
            elsif sub.positive? then
                return ONE
            else
                return UNKNOWN
            end
        end

        # Bitwise mul without processing of the x and z states.
        def self.bitwise_mul0(s0,s1)
            return BitString.new("x"*(s0.width+s1.width))
        end

        # Bitwise mul.
        def self.bitwise_mul(s0,s1)
            # Initialize the result to ZERO of combined s0 and s1 widths
            res = ZERO.extend(s0.width + s1.width)
            # The zero cases.
            if s0.zero? or s1.zero? then
                return res
            end
            # Convert s1 and res to lists of bits which support computation
            # between unknown bits of same values.
            s1 = s1.extend(res.width).to_list
            res = res.to_list
            # The other cases: perform a multiplication with shifts and adds.
            s0.each.lazy.take(s0.width).each do |b|
                case b
                when "1" then self.list_add!(res,s1)
                when "x","z" then self.list_add!(res,self.list_and_unknown(s1))
                end
                # puts "res=#{res} s1=#{s1}"
                self.list_shl_1!(s1)
            end
            # Add the sign row.
            case s0.sign
            when "1" then self.list_sub!(res,s1)
            when "x","z" then self.list_sub!(res,list_and_unknown(s1))
            end
            # Return the result.
            return self.list_to_bstr(res)
        end

        # Bitwise div without processing of the x and z states.
        def self.bitwise_div0(s0,s1)
            return BitString.new("x"*(s0.width))
        end

        # Bitwise div.
        def self.bitwise_div(s0,s1)
            width = s0.width
            # The zero cases.
            if s0.zero? then
                return res
            elsif s1.maybe_zero? then
                return UNKNOWN.extend(width)
            end
            # Handle the sign: the division is only performed on positive
            # numbers.
            # NOTE: we are sure that s0 and s1 are not zero since these
            # cases have been handled before.
            sign = nil
            if s0.sign == "0" then
                if s1.sign == "0" then
                    sign = "0"
                elsif s1.sign == "1" then
                    sign = "1"
                    s1 = -s1
                else
                    # Unknown sign, unkown result.
                    return UNKNOWN.extend(width)
                end
            elsif s0.sign == "1" then
                s0 = -s0
                if s1.sign == "0" then
                    sign = "1"
                elsif s1.sign == "1" then
                    sign = "0"
                    s1 = -s1
                else
                    # Unknwown sign, unknown result.
                    return UNKNOWN.extend(width)
                end
            else
                # Unknown sign, unknown result.
                return UNKNOWN.extend(width)
            end
            # Convert s0 and s1 to list of bits of widths of s0 and s1 -1
            # (the largest possible value).
            # s0 will serve as current remainder.
            s0 = BitString.new(s0) if s0.is_a?(Numeric)
            s1 = BitString.new(s1) if s1.is_a?(Numeric)
            s0 = s0.extend(s0.width+s1.width-1)
            s1 = s1.extend(s0.width)
            s0 = s0.to_list
            s1 = s1.to_list
            puts "first s1=#{s1}"
            # Adujst s1 to the end of s0 and the corresponding 0s in front of q
            msb = s0.reverse.index {|b| b != 0}
            steps = s0.size-msb
            self.list_shl!(s1,steps-1)
            q = [ 0 ] * (width-steps)
            # Apply the non-restoring division algorithm.
            sub = true
            puts "steps= #{steps} s0=#{s0} s1=#{s1} q=#{q}"
            (steps).times do |i|
                if sub then
                    self.list_sub!(s0,s1)
                else
                    self.list_add!(s0,s1)
                end
                puts "s0=#{s0}"
                # Is the result positive?
                if s0[-1] == 0 then
                    # Yes, the next step is a subtraction and the current
                    # result bit is one.
                    sub = true
                    q.unshift(1)
                elsif s0[-1] == 1 then
                    # No, it is negative the next step is an addition and the
                    # current result bit is zero.
                    sub = false
                    q.unshift(0)
                else
                    # Unknown sign, the remaining of q is unknown.
                    (steps-i).times { q.unshift(self.new_unknown) }
                    # Still, can add the positive sign bit.
                    q.push(0)
                    break
                end
                self.list_shr_1!(s1)
            end
            # Generate the resulting bit string.
            puts "q=#{q}"
            q = self.list_to_bstr(q)
            puts "q=#{q}"
            # Set the sign.
            if sign == "1" then
                q = (-q).trunc(width)
            elsif q.zero? then
                q = 0
            else
                q = q.extend(width)
            end
            # Return the result.
            return q
        end


        # Bitwise mod without processing of the x and z states.
        def self.bitwise_mod0(s0,s1)
            return BitString.new("x"*(s1.width))
        end

        # Bitwise mod.
        def self.bitwise_div(s0,s1)
            raise "bitwise_div is not implemented yet."
        end
    

        # Computation with list of bits: 
        # "0" -> 0, "1" -> 1, and then 2, 3, 4, ...
        # Allows more precise computations (e.g., mul, div).
        
        # The counter of unknown bits.
        @@unknown = 1

        # Creates a new uniq unknown bit.
        def self.new_unknown
            @@unknown += 1
            return @@unknown
        end

        # Converts to a list of bits where unknown or high z bits are
        # differentiate from each other.
        #
        # NOTE:
        # * the sign bit is also added to the list.
        # * the distinction between z and x is lost.
        def to_list
            return @str.each_char.reverse_each.map.with_index do |b,i|
                case b
                when "0"     then 0
                when "1"     then 1
                when "z","x" then BitString.new_unknown
                else
                    raise "Internal error: invalid bit in bitstring: #{b}"
                end
            end
        end

        # Converts list of bits +l+ to a bit string.
        def self.list_to_bstr(l)
            str = l.reverse_each.map { |b| b > 1 ? "x" : b }.join
            return BitString.new(str)
        end

        # Compute the and between +l+ and an unknown value.
        def self.list_and_unknown(l)
            return l.map do |b|
                b == 0 ? 0 : BitString.new_unknown
            end
        end

        # Compute the not of +l+
        def self.list_not(l)
            return l.map do |b|
                case b
                when 0 then 1
                when 1 then 0
                else
                    BitString.new_unknown
                end
            end
        end

        # Adds +l1+ to +l0+.
        # 
        # NOTE:
        # * l0 is contains the result.
        # * The result has the same size as +l0+ (no sign extension).
        # * Assumes +l0+ and +l1+ have the same size.
        def self.list_add!(l0,l1)
            # puts "add l0=#{l0} l1=#{l1}"
            c = 0 # Current carry.
            l0.each_with_index do |b0,i|
                b1 = l1[i]
                # puts "i=#{i} b0=#{b0} b1=#{b1} c=#{c}"
                if b0 == b1 then
                    # The sum is c.
                    l0[i] = c
                    # The carry is b0.
                    c = b0
                elsif b0 == c then
                    # The sum is b1.
                    l0[i] = b1
                    # The carry is b0.
                    c = b0
                elsif b1 == c then
                    # The sum is b0.
                    l0[i] = b0
                    # The carry is b1.
                    c = b1
                else
                    l0[i] = self.new_unknown
                    c = self.new_unknown
                end
            end
            return l0
        end

        # Adds 1 to +l0+.
        # 
        # NOTE:
        # * l0 is contains the result.
        # * The result has the same size as +l0+ (no sign extension).
        def self.list_add_1!(l0)
            c = 1 # Current carry.
            l0.each_with_index do |b0,i|
                if c == 0 then
                    # The sum is b0.
                    l0[i] = b0
                    # The carry is unchanged.
                elsif b0 == 0 then
                    # The sum is c.
                    l0[i] = c
                    # The carry is 0.
                    c = 0
                elsif b0 == c then
                    # The sum is 0.
                    l0[i] = 0
                    # The carry is b0.
                    c = b0
                else
                    # Both sum and carry are unknown
                    l0[i] = BitString.new_unknown
                    c = BitString.new_unknown
                end
            end
            return l0
        end

        # Subtracts +l1+ from +l0+.
        # 
        # NOTE:
        # * l0 is contains the result.
        # * The result has the same size as +l0+ (no sign extension).
        # * Assumes +l0+ and +l1+ have the same size.
        def self.list_sub!(l0,l1)
            # Adds 1 to l0.
            BitString.list_add_1!(l0)
            # Adds ~l1 to l0.
            # puts "l0=#{l0} l1=#{l1} ~l1=#{self.list_not(l1)}}"
            self.list_add!(l0,self.list_not(l1))
            # puts "l0=#{l0}"
            # puts "now l0=#{l0}"
            return l0
        end

        # Left shifts +l+ once.
        #
        # NOTE:
        # * l contains the result.
        # * The result has the same size as +l+ (no sign extension).
        def self.list_shl_1!(l)
            l.pop
            l.unshift(0)
            return l
        end

        # Right shifts +l+ once.
        #
        # NOTE:
        # * l contains the result.
        # * The result has the same size as +l+ (no sign extension).
        def self.list_shr_1!(l)
            l.shift
            l.push(0)
            return l
        end


        # Left shifts +l+ +x+ times.
        #
        # NOTE:
        # * l contains the result.
        # * The result has the same size as +l+ (no sign extension).
        def self.list_shl!(l,x)
            l.pop(x)
            l.unshift(*([0]*x))
        end

    end

end
