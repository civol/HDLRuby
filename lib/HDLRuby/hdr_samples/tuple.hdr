system :dff do
   input :clk, :rst, :d
   output :q

   par(clk.posedge) { q <= d & ~rst }
end

system :my_system do
   input :clk, :rst
   { sub0: bit, sub1: bit}.inner :sig
   
   dff(:dff0).(clk: clk, rst: rst)
   dff0.d <= sig.sub0
end
