# Test the comparison operators.

# A benchmark for the index access..
system :if_bench do
    [8].inner :x
    [2].inner :r0,:r1,:r2,:r3, :r4
    inner :r5

    par do
        r0 <= x[1..0]
        r1 <= x[3..2]
        r2 <= x[5..4]
        r3 <= x[7..6]
        r4 <= x[-1..-2]
        r5 <= x[-1]
    end

    timed do
        x <= 0
        !10.ns
        x <= 1
        !10.ns
        x <= 2
        !10.ns
        x <= 3
        !10.ns
        x <= 4
        !10.ns
        x <= 5
        !10.ns
        x <= 6
        !10.ns
        x <= 7
        !10.ns
        x <= 8
        !10.ns
        x <= 81
        !10.ns
        x <= 123
        !10.ns
        x <= 0
        !10.ns
        x[7..6] <= 3
        !10.ns
        x[5..4] <= 2
        !10.ns
        x[3..2] <= 1
        !10.ns
    end
end
