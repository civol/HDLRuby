require 'HDLRuby'

configure_high


# A example of behavior with default seq
system :with_seq do
    [15..0].input :x,:y, :clk
    [16..0].inner :w
    [16..0].output :o

    behavior(clk.posedge,seq) do
       w <= x + y
       o <= w + y
    end
end

# Instantiate it for checking.
with_seq :with_seqI

# Generate the low level representation.
low = with_seqI.to_low

# Displays it
puts low.to_yaml
