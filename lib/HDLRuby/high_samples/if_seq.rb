require 'HDLRuby'

configure_high


# A example of behavior with an if using a seq block
system :if_seq do
    [15..0].input :x,:y, :clk
    [16..0].inner :w
    [16..0].output :o

    par(clk.posedge) do
        hif x>100, seq do
            w <= y
        end
    end
end

# Instantiate it for checking.
if_seq :if_seqI

# Generate the low level representation.
low = if_seqI.to_low

# Displays it
puts low.to_yaml
