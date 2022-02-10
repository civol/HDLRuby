
# A benchmark for testing the initialization of signals.
system :with_init do
    [8].constant cst0: 127
    constant cst1: _1
    [8].inner sig0: _10000000
    inner sig1: _1
    [8].inner :sig2

    timed do
        !10.ns
        sig2  <= cst0 + cst1
        sig0  <= sig0 + sig1
        !10.ns
        sig2 <= sig2 + sig1
        !10.ns
    end
end
