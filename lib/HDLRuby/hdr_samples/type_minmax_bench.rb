# Test the type method min and max

# A benchmark for the adder.
system :adder_bench do
    [32].inner :x
    signed[32].inner :y

    timed do
        x <= 0
        y <= 0
        !10.ns
        x <= bit[8].max
        y <= signed[8].max
        !10.ns
        x <= bit[8].min
        y <= signed[8].min
        !10.ns
        x <= bit[10].max
        y <= signed[10].max
        !10.ns
        x <= bit[10].min
        y <= signed[10].min
        !10.ns
        x <= bit[16].max
        y <= signed[16].max
        !10.ns
        x <= bit[16].min
        y <= signed[16].min
        !10.ns
        x <= bit[32].max
        y <= signed[32].max
        !10.ns
        x <= bit[32].min
        y <= signed[32].min
        !10.ns
    end
end
