# Test the comparison operators.

# A benchmark for the index access..
system :if_bench do
    [8].inner :x
    inner :b0,:b1,:b2,:b3,:b4,:b5,:b6,:b7

    par do
        b0 <= x[0]
        b1 <= x[1]
        b2 <= x[2]
        b3 <= x[3]
        b4 <= x[4]
        b5 <= x[5]
        b6 <= x[6]
        b7 <= x[7]
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
        x[7] <= 1
        !10.ns
        x[6] <= 1
        !10.ns
    end
end
