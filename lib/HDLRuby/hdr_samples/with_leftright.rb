# A benchmark for the cases where a left value is also a right value
# in a block without sensitivity list.
system :leftright_bench do
    [8].inner :l,:r0,:r1,:lr

    par do
        lr <= r0*2
        l <= [lr[7],lr[6..0]].to_expr + r1
    end

    timed do
        !10.ns
        r0 <= 1
        !10.ns
        r1 <= 2
        !10.ns
        r0 <= 3
        r1 <= 4
        !10.ns
    end
end
