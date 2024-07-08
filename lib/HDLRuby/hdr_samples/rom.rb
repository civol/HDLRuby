
signed[7..0].typedef(:typ)

# Describes an 8-bit data 4-bit address ROM.
system :rom4_8 do
    [2..0].input :addr
    [7..0].output :data0,:data1,:data2

    bit[7..0][0..7].constant content0: [_00000000,_00000001,_00000010,_00000011,
                                        _00000100,_00000101,_00000110,_00000111]
    signed[7..0][-8].constant content1: [_sh00,_sh01,_sh02,_sh03,
                                         _sh04,_sh05,_sh06,_sh07]
    typ[-8].constant content2: (8).times.map {|i| i.to_expr.as(typ) }.reverse

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
