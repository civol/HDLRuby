module HDLRuby

##
# Library for describing the bit string and their computations.
#
########################################################################
    

    # Converts a value to a valid bit if possible.
    def make_bit(value)
        value = value.to_s.upcase
        unless ["0","1","X","Z"].include?(value)
            raise "Invalid value for a bit: #{value}"
        end
        return value
    end


    ##
    # Describes a bit string.
    #
    # NOTE: a bit string is immutable.
    class BitString

        # Creates a new bit string from +str+
        def initialize(str)
            # Check and set the value of the bit string.
            @str = str.to_s
            unless @str.match(/^[0-1zxZX]+$/) then
                raise "Invalid value for creating a bit string: #{str}"
            end
        end

        # Converts to a string.
        def to_str
            return @str.clone
        end

        # Gets a bit by +index+.
        def [](index)
            return @str[index]
        end

        # Sets the bit at +index+ to +value+.
        def []=(index,value)
            # Checks and convert the value
            value = make_bit(value)
            # Sets the value to a copy of the bit string.
            str = @str.clone
            str[index] = value
            # Return the result as a new bit string.
            return BitString.new(str)
        end

        # Iterates over the bits.
        #
        # Returns an enumerator if no ruby block is given.
        def each(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each) unless ruby_block
            # A block? Apply it on each bit.
            @str.each(&ruby_block)
        end
    end





end
