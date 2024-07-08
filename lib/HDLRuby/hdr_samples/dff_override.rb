# A simple D-FF with overridable part.
system :dff do
    input  :d, :clk, :rst
    output :q

    sub(:process) do
        (q <= d & ~rst).at(clk.posedge)
    end
end

# A new dff overriding process.
system :dff_neg, dff do
    sub(:process) do
        (q <= d & ~rst).at(clk.negedge)
    end
end

# A benchmark for the dff.
system :dff_bench do
    inner :d, :clk, :rst
    inner :q

    dff_neg(:my_dff).(d,clk,rst,q)
    # dff(:my_dff).(d,clk,rst,q)

    timed do
        clk <= 1
        rst <= 0
        d   <= _z
        !10.ns
        clk <= 0
        rst <= 0
        d   <= _z
        !10.ns
        clk <= 1
        rst <= 1
        d   <= _z
        !10.ns
        clk <= 0
        rst <= 1
        d   <= _z
        !10.ns
        clk <= 1
        rst <= 0
        d   <= 1
        !10.ns
        clk <= 0
        rst <= 0
        d   <= 1
        !10.ns
        clk <= 1
        rst <= 0
        d   <= 1
        !10.ns
        clk <= 0
        rst <= 0
        d   <= 1
        !10.ns
        clk <= 1
        rst <= 0
        d   <= 0
        !10.ns
        clk <= 0
        rst <= 0
        d   <= 0
        !10.ns
        clk <= 1
        rst <= 0
        d   <= 0
        !10.ns
        clk <= 0
        rst <= 0
        d   <= 0
        !10.ns
    end
end
