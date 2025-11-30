# Sample for testing SVG generation.

system :somemodule do
  [8].input :x, :y
  [8].output :z
  [8].inner :tmp

  tmp <= x + y

  z <= tmp * 2
end


system :show_components do
  input :clk
  [8].input :x0, :y0, :x1, :y1, :x2, :y2, :x3, :y3
  [8].output :z0, :z1, :z2

  [8].inner :sig
  bit[8][-8].inner :mem


  somemodule(:instance).(x0,y0,z0)

  sig[6..0] <= x3[6..0] & y3[6..0]
  sig[7] <= x3[7] & y3[7]

  seq do
    z1 <= x1 | y1 | mem[sig]
  end

  par(clk.posedge) do
    z2 <= x2 - y2
  end

end

