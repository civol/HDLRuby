# Test the comparison operators.

# A benchmark for the case statement.
system :if_bench do
    [8].inner :x, :y

    par do
        hcase(x)
        hwhen(0) { y <= _10000000 }
        hwhen(1) { y <= _10000001 }
        hwhen(2) { y <= _10000010 }
        hwhen(3) { y <= _10000011 }
        helse    { y <= _00000000 }
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
    end
end
