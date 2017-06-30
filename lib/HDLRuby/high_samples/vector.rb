require 'HDLRuby'
include HDLRuby::High

# Describes a system including several vector types.
system :vectors do
    [7..0].input :byte
    [ bit[8], signed[16], unsigned[16] ].output :bss
end


# Instantiate it for checking.
Universe.vectors :vectorsI