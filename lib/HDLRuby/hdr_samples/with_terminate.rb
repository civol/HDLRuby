
# A benchmark for testing the terminate statement.
system :with_terminate do
    [8].constant cst0: 127
    constant cst1: _b1
    [8].inner sig0: _b10000000
    inner sig1: _b1
    [8].inner :sig2
    [8].inner count: 0

    timed do
        !20.ns
        100.times do
            count <= count + 1
            !20.ns
        end
    end

    timed do
        !10.ns
        sig2  <= cst0 + cst1
        sig0  <= sig0 + sig1
        !10.ns
        sig2 <= sig2 + sig1
        !10.ns
        terminate
        sig0 <= sig0 + sig0
        !10.ns
        sig0 <= sig0 + sig0
        !10.ns
    end
end
