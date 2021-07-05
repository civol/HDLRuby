
# A benchmark for testing the arithmetic with signed values.
system :neg_arith_bench do
    signed[11..0].inner :x,:y,:z
    inner :cmp

    timed do
        x <= 10
        y <= 10
        z <= 0
        !10.ns
        z <= 10 * 10
        cmp <= (10 < 10)
        !10.ns
        z <= x * y
        cmp <= (x < y)
        !10.ns
        x <= 10
        y <= -10
        !10.ns
        z <= 10 * (-10)
        cmp <= (10 < -10)
        !10.ns
        z <= x * y
        cmp <= (x < y)
        !10.ns
        x <= -10
        y <= 10
        !10.ns
        z <= (-10) * 10
        cmp <= (-10 < 10)
        !10.ns
        z <= x * y
        cmp <= (x < y)
        !10.ns
        x <= -10
        y <= -10
        !10.ns
        z <= (-10) * (-10)
        cmp <= (-10 < -10)
        !10.ns
        z <= x * y
        cmp <= (x < y)
        !10.ns
        x <= _000000011010
        y <= _000011111010
        z <= 0
        !10.ns
        z <= x * y
        cmp <= (x < y)
        !10.ns
        x <= _000000011010
        y <= _111111111010
        z <= 0
        !10.ns
        z <= x * y
        cmp <= (x < y)
        !10.ns
    end
end
