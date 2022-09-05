# A simple D-FF
system :dff do
    input  :d, :clk, :rst
    output :q

    (q <= d & ~rst).at(clk.posedge)
end

# A benchmark for the dff.
system :dff_bench do
    inner :d0, :d1, :clk, :rst
    inner :q0, :q1

    dff(:my_dff0).(d0,clk,rst,q0)
    dff(:my_dff1).(d1,clk,rst,q1)

    timed do
        clk <= 0
        rst <= 0
        d0  <= _z
        d1  <= _z
        !10.ns
        clk <= 1
        rst <= 0
        d0  <= _z
        d1  <= _z
        !10.ns
        clk <= 0
        rst <= 1
        d0  <= _z
        d1  <= _z
        !10.ns
        clk <= 1
        rst <= 1
        d0  <= _z
        d1  <= _z
        !10.ns
        clk <= 0
        rst <= 0
        d0  <= 1
        d1  <= 0
        !10.ns
        clk <= 1
        rst <= 0
        d0  <= 1
        d1  <= 0
        !10.ns
        clk <= 0
        rst <= 0
        d0  <= 1
        d1  <= 1
        !10.ns
        clk <= 1
        rst <= 0
        d0  <= 1
        d1  <= 1
        !10.ns
        clk <= 0
        rst <= 0
        d0  <= 0
        d1  <= 1
        !10.ns
        clk <= 1
        rst <= 0
        d0  <= 0
        d1  <= 1
        !10.ns
        clk <= 0
        rst <= 0
        d0  <= 0
        d1  <= 0
        !10.ns
        clk <= 1
        rst <= 0
        d0  <= 0
        d1  <= 0
        !10.ns
    end
end
