system :dff do
   input :clk, :rst, :d
   output :q

   par(clk.posedge) { q <= d & ~rst }
end

system :my_system do
   input :clk, :rst
   [bit, bit].inner :zig
   
   dff(:dff0).(clk: clk, rst: rst)
   dff(:dff1).(clk: clk, rst: rst)
   dff0.d <= zig[0]
   dff1.d <= zig[1]
end
