require 'HDLRuby'

configure_high


# A example of behavior with some unshifted statements in a block.
system :with_unshift do
    [15..0].input :x,:y, :clk
    [16..0].inner :w
    [16..0].output :o

    seq(clk.posedge) do
        w <= x + y
        unshift { o <= w + y }
    end
end

# Instantiate it for checking.
with_unshift :with_unshiftI

# Generate the low level representation.
low = with_unshiftI.systemT.to_low

# Displays it
puts low.to_yaml
