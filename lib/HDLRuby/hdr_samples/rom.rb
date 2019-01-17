
# Describes an 8-bit data 4-bit address ROM.
system :rom4_8 do
    [3..0].input :addr
    [7..0].output :data

    bit[7..0][2**4].constant content: (2**4).times.to_a

    data <= content[addr]
end
