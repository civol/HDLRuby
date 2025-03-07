# Ruby program for testing SW HDLRuby.

# require 'HDLRuby/std/sequencer_sw'

# include RubyHDL::High
# using RubyHDL::High

system :test_with_sw_ruby do

  [32].inner :a,:b,:c,:i
  [32].inner :d, :e
  bit[32][-4].inner :ar
  [32].inner :res0, :res1

  inner :clk,:start


  sequencer(clk,start) do
    a <= 1
    b <= 2
    c <= 0
    d <= 0
    i <= 0
    e <= 0
    # swhile(c<10000000) do
    10000000.stimes do
      c <= a + b + d
      d <= c + 1
      ar[i%4] <= i
      i <= i + 1
    end
    a[4] <= 1
    b[7..5] <= 5
    res0 <= ar[0]
    e <= 1
  end


  sequencer(clk,start) do
    sloop do
      res1 <= ar[1]
    end
  end


  timed do
    clk <= 0
    start <= 0
    !10.ns
    clk <= 1
    !10.ns
    clk <= 0
    start <= 1
    !10.ns
    clk <= 1
    !10.ns
    clk <= 0
    start <= 0
    !10.ns
    clk <= 1
    !10.ns
    repeat(100000000) do
      clk <= ~clk
      !10.ns
      hif(e == 1) do
        hprint("c=",c,"\n")
        hprint("res0=",res0,"\n")
        hprint("res1=",res1,"\n")
        terminate
      end
    end
  end

end
