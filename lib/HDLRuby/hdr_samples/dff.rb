# A simple D-FF
system :dff do
    input :clk, :rst, :d
    output :q, :qb

    qb <= ~q

    par(clk.posedge) { q <= d & ~rst }
end
