

# A benchmark for testing the enumarable properties of expression (reduce).
system :with_reduce_bench do
    [8].inner :val,:res
    [64].inner :val64

    timed do
        val <= _b01101010
        res <= val.reduce(_b00000000,:+)
        !10.ns
        val <= _01010010
        res <= val.reduce(_b00000000,:+)
        !10.ns
        val <= _01101111
        res <= val.reduce(_b00000000,:+)
        !10.ns
        val64 <= _b0110101001101010011010100110101001101010011010100110101001101010
        res <= val64.reduce(_b00000000,:+)
        !10.ns
        res <= val64[7..0]
        !10.ns
        res <= res.reduce(_b00000000,:+)
        !10.ns
        res <= val64[63..60]
        !10.ns
        res <= res.reduce(_b00000000,:+)
        !10.ns
        val64 <= ~(val64 ^ val64)
        res <= val64.reduce(_b00000000,:+)
        !10.ns
        val64[0] <= _b0
        val64[3] <= _b0
        val64[63] <= _b0
        res <= val64.reduce(_b00000000,:+)
        !10.ns
    end
end
