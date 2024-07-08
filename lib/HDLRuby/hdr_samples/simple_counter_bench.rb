# A benchmark for very simple counters.
# Also test the use of ~ on the clock.
system :counter_bench do
    inner :clk, :rst
    [3].inner :counter
    [4].inner :counter2

    par(clk.posedge) do
        hif(rst) { counter <= 0 }
        helse    { counter <= counter + 1 }
    end

    par(clk.posedge) do
        hif(rst) { counter2 <= 0 }
        helse    { counter2 <= counter2 + 1 }
    end


    timed do
        clk <= 0
        rst <= 0
        !10.ns
        clk <= 1
        rst <= 0
        !10.ns
        clk <= ~clk
        rst <= 1
        !10.ns
        clk <= ~clk
        !10.ns
        clk <= ~clk
        rst <= 0
        !10.ns
        clk <= ~clk
        !10.ns
        10.times do
            clk <= ~clk
            !10.ns
            clk <= ~clk
            !10.ns
        end
    end
end
