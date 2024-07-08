# Sample for testing constant declaration in function.


# function :func do |addr|
hdef :func do |addr|
    bit[4][-4].constant tbl: [ _b1000, _b1001, _b1010, _b1011 ]
    
    tbl[addr]
end


system :with_func do
    [4].inner :addr, :val
    # bit[4][-4].constant tbl: [ _b1000, _b1001, _b1010, _b1011 ]

    val <= func(addr)
    # val <= 1
    # val <= tbl[addr]

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
