require 'HDLRuby'

configure_high


# A example of behavior with some unshifted statements in the top block
# of a behavior.
system :with_top_unshift do
    [15..0].input :x,:y, :clk
    [16..0].inner :w0,:w1
    [16..0].output :o

    seq(clk.posedge) do
        w0 <= x + y
        par do
            w1 <= w0 * x
            top_block.unshift { o <= w1 + y }
        end
    end
end

# Instantiate it for checking.
with_top_unshift :with_top_unshiftI

# Generate the low level representation.
low = with_top_unshiftI.systemT.to_low

# Displays it
puts low.to_yaml
