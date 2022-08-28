
# A benchmark for the bit string generation in case of signed values.
system :bstr_bench do
    signed[7..0].inner :val

    timed do
        val <= 0
        !10.ns
        val <= 26
        !10.ns
        val <= -25
        !10.ns
        val <= -32
        !10.ns
    end
end
