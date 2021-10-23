

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
    end
end
