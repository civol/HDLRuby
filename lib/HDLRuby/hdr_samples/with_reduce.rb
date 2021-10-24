

# A benchmark for testing the enumarable properties of expression (reduce).
system :with_reduce_bench do
    [8].inner :val,:res
    [64].inner :val64

    timed do
        val <= _01101010
        res <= val.reduce(_00000000,:+)
        !10.ns
        val <= _01010010
        res <= val.reduce(_00000000,:+)
        !10.ns
        val <= _01101111
        res <= val.reduce(_00000000,:+)
        !10.ns
        val64 <= _0110101001101010011010100110101001101010011010100110101001101010
        res <= val64.reduce(_00000000,:+)
        !10.ns
        res <= val64[7..0]
        !10.ns
        res <= res.reduce(_00000000,:+)
        !10.ns
        res <= val64[63..60]
        !10.ns
        res <= res.reduce(_00000000,:+)
        !10.ns
        val64 <= ~(val64 ^ val64)
        res <= val64.reduce(_00000000,:+)
        !10.ns
        val64[0] <= _0
        val64[3] <= _0
        val64[63] <= _0
        res <= val64.reduce(_00000000,:+)
        !10.ns
    end
end
