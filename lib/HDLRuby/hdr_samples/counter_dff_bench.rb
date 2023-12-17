# A simple D-FF
system :dff do
    input  :clk, :rst, :d
    output :q

    (q <= d & ~rst).at(clk.posedge)
end

# A benchmark for the dff.
system :dff_bench do
    inner :clk, :rst
    inner :d0, :q0, :d1, :q1

    dff(:my_dff0).(clk,rst,d0,q0)
    dff(:my_dff1).(d0,rst,d1,q1)

    d0 <= ~q0
    d1 <= ~q1

    timed do
        clk <= 0
        rst <= 0
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        rst <= 1
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        rst <= 0
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        !10.ns
        clk <= 1
        !10.ns
    end
end
