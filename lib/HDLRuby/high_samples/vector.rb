require 'HDLRuby'

configure_high

# Describes a system including several vector types.
system :vectors do
    [7..0].input :byte
    [ bit[8], signed[16], unsigned[16] ].output :bss
end


# Instantiate it for checking.
vectors :vectorsI

# Generate the low level representation.
low = vectorsI.to_low

# Displays it
puts low.to_yaml
