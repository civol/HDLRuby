system :dff do
   input :clk, :rst, :d
   output :q

   par(clk.posedge) { q <= d & ~rst }
end

system :dff_full do
    output :qb

    include dff

    qb <= ~q
end
