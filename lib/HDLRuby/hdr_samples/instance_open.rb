system :dff do
   input :clk, :rst, :d
   output :q

   (q <= d & ~rst).at(clk.posedge)
end

system :in_dff do
   input :clk, :rst, :d
   output :q, :qb

   dff :dff0
   dff0.open do
      output :qb
      qb <= ~q
   end

   dff0.clk <= clk
   dff0.rst <= rst
   dff0.d <= d
   q <= dff0.q
   qb <= dff0.qb
end
