# Test the comparison operators.

# A benchmark for the if statement.
system :if_bench do
    [8].inner :x, :y, :z

    par do
        hif(x == y)   { z <= 1 }
        helsif(x < y) { z <= 2 }
        helse         { z <= 3 }
    end

    timed do
        x <= 0
        y <= 0
        !10.ns
        x <= 1
        !10.ns
        y <= 2
        !10.ns
        x <= 2
        !10.ns
    end
end
