# Sample HDLRuby instantiating a Verilog HDL-described adder (adder.v)

require_verilog "adder8.v"

system :verilog_bench do
  [8].inner a,b,c

  # Instantiate the adder.
  adder8(:my_adder8).(a,b,c)

  # Testing it.
  timed do
    a <= 0
    b <= 0
    repeat(100) do
      repeat(100) do
        !10.ns
        b <= b + 1
      end
      a <= a + 1
    end
  end
  !10.ns
end
