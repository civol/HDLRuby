require 'HDLRuby'

configure_high

# Describes an 8-bit data 8-bit address ROM.
system :rom8_8 do
    [7..0].input :addr
    [7..0].inout :data

    bit[7..0][2**8].inner :content

    content <= (2**8).times.to_a

    data <= content[addr]
end

# Instantiate it for checking.
rom8_8 :rom8_8I


# Generate the low level representation.
low = rom8_8I.to_low

# Displays it
puts low.to_yaml
