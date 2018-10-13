system :dff do
   input :clk, :rst, :d
   output :q

   par(clk.posedge) { q <= d & ~rst }
end

system :my_system do
   input :clk, :rst
   [bit, bit].inner :zig
   (bit*2).inner :zag
   
   dff(:dff0).(clk: clk, rst: rst)
   dff(:dff1).(clk: clk, rst: rst)
   dff(:dff2).(clk: clk, rst: rst)
   dff(:dff3).(clk: clk, rst: rst)
   dff0.d <= zig[0]
   dff1.d <= zig[1]
   dff2.d <= zag[0]
   dff3.d <= zag[1]
end
