
# A benchmark for testing array references.
system :with_concat do
    [8].inner :count
    [8].inner :val0,:val1
    [3].inner :val2
    [8].inner :val3

    val2 <= val0[4..2]
    val3[6..3] <= val1[7..4]

    timed do
        val0 <= _00001111
        val1 <= _11000011
        count <= 0
        !10.ns
        val0 <= _11110000
        val1 <= _00111100
        count <= 1
        !10.ns
        val0 <= _10101010
        val1 <= _01010101
        count <= 2
        !10.ns
    end
end
