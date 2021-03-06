require 'HDLRuby'

configure_high


require 'HDLRuby/std/clocks'
include HDLRuby::High::Std


# A simple test of the event multiplication constructs
system :with_clocks do
    input :clk,:rst
    output :sig0, :sig1

    configure_clocks(rst)

    par(clk.posedge * 2) do
        hif(rst) { sig0 <= 0 }
        helse { sig0 <= ~sig0 }
    end

    par(clk.posedge * 3) do
        hif(rst) { sig1 <= 0 }
        helse { sig1 <= ~sig1 }
    end
end

# Instantiate it for checking.
with_clocks :with_clocksI

# Generate the low level representation.
low = with_clocksI.systemT.to_low

# Displays it
puts low.to_yaml
