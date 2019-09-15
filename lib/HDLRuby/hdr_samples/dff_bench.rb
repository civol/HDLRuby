# A simple D-FF
system :dff do
    input  :d, :clk, :rst
    output :q

    (q <= d & ~rst).at(clk.posedge)
end

# A benchmark for the dff.
system :dff_bench do
    inner :d, :clk, :rst
    inner :q

    dff(:my_dff).(d,clk,rst,q)

    timed do
        clk <= 0
        rst <= 0
        d   <= 0
        !10.ns
        clk <= 1
        rst <= 0
        d   <= 0
        !10.ns
        clk <= 0
        rst <= 1
        d   <= 0
        !10.ns
        clk <= 1
        rst <= 1
        d   <= 0
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
        d   <= 1
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
        clk <= 1
        rst <= 0
        d   <= 0
        !10.ns
    end
end
