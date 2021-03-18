
signed[7..0].typedef(:typ)

# Describes an 8-bit data 4-bit address ROM.
system :rom4_8 do
    [2..0].input :addr
    [7..0].output :data0,:data1,:data2

    bit[7..0][0..7].constant content0: [0,1,2,3,4,5,6,7]
    signed[7..0][-8].constant content1: [0,1,2,3,4,5,6,7]
    typ[-8].constant content2: (8).times.to_a

    data0 <= content0[addr]
    data1 <= content1[addr]
    data2 <= content2[addr]
end



system :test_rom do
    [2..0].inner :addr
    [7..0].inner :data0,:data1,:data2

    rom4_8(:my_rom).(addr,data0,data1,data2)

    timed do
        8.times do |i|
            addr <= i
            !10.ns
        end
    end
end
