require 'HDLRuby'

configure_high


require 'HDLRuby/std/counters'
include HDLRuby::High::Std


# A simple test of the after construct
system :with_after do
    input :clk,:rst
    output :timeout

    par(clk.posedge,rst.posedge) do
        timeout <= 0
        after(100,rst) { timeout <= 1 }
    end
end

# Instantiate it for checking.
with_after :with_afterI

# Generate the low level representation.
low = with_afterI.to_low

# Displays it
puts low.to_yaml
