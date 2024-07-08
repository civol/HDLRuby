# A test of def.
def lut84(content,addr)
   bit[8][-4].inner tbl? => content.to_a
   tbl![addr]
end


# A benchmark for testing the initialization of signals.
system :def_bench do

    [2].inner :addr
    [8].inner :val0, :val1, :val2, :val3

    par do
        val0 <= lut84([_b8d0,_b8d1,_b8d4,_b8d9],addr)
        val1 <= lut84([_b8d0,_b8d1,_b8d4,_b8d9],3-addr)
    end

    bit[8][-4].inner otbl: [_b8d0,_b8d1,_b8d4,_b8d9]

    par do
        val2 <= otbl[addr]
        val3 <= otbl[3-addr]
    end

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
