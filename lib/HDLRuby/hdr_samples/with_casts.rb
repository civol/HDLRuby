
# A benchmark for testing the casts.
system :with_cast do
    [8].inner :count
    [8].inner :val0,:val1
    [9].inner :val2,:val3

    timed do
        val0 <= _b11111111
        val1 <= _b00000010
        val3 <= _b000000000
        count <= 0
        !10.ns
        count <= 1
        val2 <= val0 + val1
        val3 <= val3 + 1
        !10.ns
        count <= 2
        val2 <= val0.as(bit[9]) + val1
        val3 <= val3.as(bit[10]) + 1
        !10.ns
        count <= 3
        val2 <= (val0 + val1).as(bit[9])
        val3 <= (val3 + 1).as(bit[10])
        !10.ns
        count <= 4
        val2 <= (val0 + val1).as(bit[8])
        !10.ns
    end
end
