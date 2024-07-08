# Describes an 8-bit data 16-bit address ROM.
system :huge_rom do
    [15..0].input :addr
    [7..0].output :data

    bit[7..0][-65536].constant content: 65536.times.map {|i| i.to_value.as(bit[8]) }

    data <= content[addr]
end



system :test_rom do
    [15..0].inner :addr
    [7..0].inner :data

    huge_rom(:my_rom).(addr,data)

    timed do
        8.times do |i|
            addr <= i
            !10.ns
        end
    end
end
