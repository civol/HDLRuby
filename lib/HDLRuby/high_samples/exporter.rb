require 'HDLRuby'

configure_high

# A simple D-FF
system :dff do
    input :clk, :rst, :d
    output :q

    behavior(clk.posedge) { q <= d & ~rst }
end

# A system wrapping a D-FF and exporting things.
system :exporter do
    input :d
    inner :clk, :rst

    dff(:dff0).(clk: clk, rst: rst, d: d)

    # Comment one of the following to check that without export, they cannot
    # be used in a system inheriting from exporter
    export :clk, :rst , :dff0 
end

# A system inheriting from exporter
system :importer, exporter do
    input :clk0, :rst0
    output :q

    clk <= clk0
    rst <= rst0
    dff0.q <= q
end

# # Instantiate it for checking.
importer :importerI

# Generate the low level representation.
low = importerI.to_low

# Displays it
puts low.to_yaml
