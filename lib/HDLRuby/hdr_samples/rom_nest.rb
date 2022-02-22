$count = 0

# Rom access generator, def case.
def rom_gen(addr,&func)
    bit[8][-8].constant "tbl#{$count}": 8.times.map {|i| func.(i).to_i }
    $count = $count + 1
    send(:"tbl#{$count-1}")[addr]
end

# # Rom access generator, function case.
# function :rom_genF do |addr,func|
#     bit[8][-8].constant "tbl#{$count}": 8.times.map {|i| func.(i).to_i }
#     $count = $count + 1
#     send(:"tbl#{$count-1}")[addr]
# end

# Rom access generator, uniq names case
def rom_genU(addr,&func)
end


system :test_rom do
    [2..0].inner :addr
    [7..0].inner :data0, :data1, :data2, :data3

    data0 <= rom_gen(addr) { |i| i*i }
    # data1 <= rom_genU(addr,proc { |i| i*i })

    par(addr) do
        data2 <= rom_gen(addr) { |i| i*i }
        # data3 <= rom_genU(addr,proc { |i| i*i })
    end

    timed do
        8.times do |i|
            addr <= i
            !10.ns
        end
    end
end
