require 'HDLRuby'

configure_high


require 'HDLRuby/std/counters'
include HDLRuby::High::Std


# A simple test of the before construct
system :with_before do
    input :clk,:rst
    output :timeout

    par(clk.posedge,rst.posedge) do
        timeout <= 1
        before(100,rst) { timeout <= 0 }
    end
end

# Instantiate it for checking.
with_before :with_beforeI

# Generate the low level representation.
low = with_beforeI.systemT.to_low

# Displays it
puts low.to_yaml
