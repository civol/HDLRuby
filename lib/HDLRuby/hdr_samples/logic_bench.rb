
# A benchmark for the logic operations.
system :logic_bench do
    [3].inner :x,:y
    [3].inner :s_not, :s_and, :s_or, :s_xor, :s_nxor
    
    signed[16].inner :a,:b,:shl,:shr

    timed do
        8.times do |i|
            8.times do |j|
                x      <= i
                y      <= j
                s_not  <= ~x
                s_and  <= x & y
                s_or   <= x | y
                s_xor  <= x ^ y
                s_nxor <= (x == y)
                !10.ns
                a      <= i
                b      <= j
                shl    <= (a << b)
                shr    <= (a >> b)
            end
        end
    end
end
