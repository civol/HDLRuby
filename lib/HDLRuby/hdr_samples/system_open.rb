system :dff do
   input :clk, :rst, :d
   output :q

   (q <= d & ~rst).at(clk.posedge)
end

dff.open do
   output :qb
   qb <= ~q
end
