# Test the comparison operators.

# A benchmark for the case statement.
system :case_bench do
    [8].inner :x, :z

    par do
        hcase(x)
        hwhen(0)  { z <= 0 }
        hwhen(1)  { z <= 1 }
        hwhen(2)  { z <= 4 }
        hwhen(3)  { z <= 9 }
        hwhen(4)  { z <= 16 }
        hwhen(5)  { z <= 25 }
        hwhen(6)  { z <= 36 }
        hwhen(7)  { z <= 49 }
        hwhen(8)  { z <= 64 }
        hwhen(9)  { z <= 81 }
        hwhen(10) { z <= 100 }
        hwhen(11) { z <= 121 }
        hwhen(12) { z <= 144 }
        hwhen(13) { z <= 169 }
        hwhen(14) { z <= 196 }
        hwhen(15) { z <= 225 }
        helse    { z <= _zzzzzzzz }
    end

    timed do
        !10.ns
        20.times do |i|
            x <= i
            !10.ns
        end
    end
end
