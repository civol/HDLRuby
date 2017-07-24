require 'HDLRuby'

configure_high


# A simple D-FF
system :dff do
    input :clk, :rst, :d
    output :q, :qb

    qb <= ~q

    behavior(clk.posedge) { q <= d & ~rst }
end

# Instantiate it for checking.
dff :dffI

# Generate the low level representation.
low = dffI.to_low

# Displays it
puts low.to_yaml
