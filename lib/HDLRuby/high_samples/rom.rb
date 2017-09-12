require 'HDLRuby'

configure_high

# Describes an 8-bit data 16-bit address ROM.
system :rom8_16 do
    [15..0].input :addr
    [7..0].inout :data

    bit[7..0][2**16].inner :content

    data <= content[addr]
end

# Instantiate it for checking.
rom8_16 :rom8_16I


# Generate the low level representation.
low = rom8_16I.to_low

# Displays it
puts low.to_yaml
