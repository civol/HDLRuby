system :dff do
   input :clk, :rst, :d
   output :q

   (q <= d & ~rst).at(clk.posedge)
end

system :in_dff do
   input :clk, :rst, :d
   output :q

   dff :dff0
   dff0.open do
      output :qb
      qb <= ~q
   end
end
