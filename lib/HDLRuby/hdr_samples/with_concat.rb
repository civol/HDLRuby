
# A benchmark for testing the concat.
system :with_concat do
    [8].inner :count
    [4].inner :val0,:val1
    [8].inner :val2
    [12].inner :val3

    val2 <= [val0,val1]
    val3 <= [val2,val0]

    timed do
        val0 <= _1111
        val1 <= _0000
        count <= 0
        !10.ns
        val0 <= _1001
        val1 <= _0110
        count <= 1
        !10.ns
        val0 <= _1010
        val1 <= _0101
        count <= 2
        !10.ns
    end
end
