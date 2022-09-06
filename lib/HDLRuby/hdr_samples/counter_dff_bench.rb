# A simple D-FF
system :dff do
    input  :clk, :d
    output q: 0

    (q <= d).at(clk.posedge)
end

# A benchmark for the dff.
system :dff_bench do
    inner :clk
    inner :d0, :q0, :d1, :q1

    dff(:my_dff0).(clk,d0,q0)
    dff(:my_dff1).(d0,d1,q1)

    d0 <= ~q0
    d1 <= ~q1

    timed do
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
