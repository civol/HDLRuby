# Sample for testing constant declaration in function.


function :func do |addr|
    bit[4][-4].constant tbl: [ _0000, _0001, _0010, _0011 ]
    
    tbl[addr]
end


system :with_func do
    [4].inner :addr, :val

    val <= func(addr)
    # val <= 1

    timed do
        addr <= 0
        !10.ns
        addr <= 1
        !10.ns
        addr <= 2
        !10.ns
        addr <= 3
        !10.ns
    end
end
