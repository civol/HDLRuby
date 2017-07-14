require 'HDLRuby'

configure_high


# A simple D-FF
system :dff do
    input :clk, :rst, :d
    output :q

    behavior(clk.posedge) { q <= d & ~rst }
end

# A D-FF with inverted ouput inheriting from dff
system :dff_full,dff do
    output :qb

    qb <= ~q
end

# Instantiate it for checking.
dff_full :dff_fullI
