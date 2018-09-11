require 'HDLRuby'

configure_high


# A simple D-FF
system :dff do
    input :clk, :rst, :d
    output :q

    par(clk.posedge) { q <= d & ~rst }
end

# A D-FF with inverted ouput inheriting from dff
system :dff_full,dff do
    output :qb

    qb <= ~q
end

# A D-FF with a secondary output
system :dff_fullest, dff_full do
    output :qq
    qq <= q
end

# Instantiate it for checking.
# dff_full :dff_fullI
dff_fullest :dff_fullestI

# Generate the low level representation.
# low = dff_fullI.systemT.to_low
low = dff_fullestI.systemT.to_low

# Displays it
puts low.to_yaml
