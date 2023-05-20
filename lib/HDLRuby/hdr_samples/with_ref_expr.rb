
# A benchmark for testing range reference and index reference on expressions.
system :with_concat do
    [8].inner :val0,:val1
    inner :val2
    [4].inner :val3, :count
    inner :val4
    [4].inner :val5

    val2 <= (val0+val1)[4]
    val3 <= (val0+val1)[3..0]

    val4 <= val0[4]
    val5 <= val0[3..0]

    timed do
        val0 <= _b00001111
        val1 <= _b11000011
        count <= 0
        !10.ns
        val0 <= _b11110000
        val1 <= _b00111100
        count <= 1
        !10.ns
        val0 <= _b10101010
        val1 <= _b01010101
        count <= 2
        !10.ns
    end
end
