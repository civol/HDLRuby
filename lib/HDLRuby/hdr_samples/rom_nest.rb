# Rom access generator, def case.
def rom_gen(addr,&func)
    bit[8][-8].constant tbl? => 8.times.map {|i| func.(i).to_value.as(bit[8]) }
    tbl![addr]
end



system :test_rom do
    [2..0].inner :addr
    [7..0].inner :data0, :data1, :data2, :data3

    data0 <= rom_gen(addr) { |i| i*i }
    data1 <= rom_gen(addr) { |i| i*i }

    par do
        data2 <= rom_gen(addr) { |i| i*i }
        data3 <= rom_gen(addr) { |i| i*i }
    end

    timed do
        8.times do |i|
            addr <= i
            !10.ns
        end
    end
end
