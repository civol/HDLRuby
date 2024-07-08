

# A benchmark for testing conversion of strings to values.
system :with_str2value_bench do
    [8].inner :val
    [64].inner :val64

    timed do
        val <= "01010011".to_value
        !10.ns
        val64 <= ("01010011" * 8).to_value
        !10.ns
    end
end
