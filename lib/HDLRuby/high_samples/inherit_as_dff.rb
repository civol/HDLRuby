require 'HDLRuby'

configure_high


# A simple D-FF
system :dff do
    input :clk, :rst, :d
    output :q

    inner :db

    db <= ~d

    par(clk.posedge) { q <= d & ~rst }
end

# A D-FF with inverted ouput inheriting from dff
system :dff_full,dff do
    output :qb

    qb <= as(dff).db
end

# Instantiate it for checking.
dff_full :dff_fullI

# Generate the low level representation.
low = dff_fullI.systemT.to_low

# Displays it
puts low.to_yaml
