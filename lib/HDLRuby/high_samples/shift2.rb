require 'HDLRuby'

configure_high


system :dff do
   input :clk, :rst, :d
   output :q, :qb

   qb <= ~q

   (q <= d & ~rst).at(clk.posedge)
end

system :shifter do |n|
   input :i0
   output :o0, :o0b

   # Instantiating n D-FF
   [n].dff :dffIs

   # Interconnect them as a shift register
   dffIs[0..-2].zip(dffIs[1..-1]) do |ff0,ff1|
       ff1.d <= ff0.q 
   end

   # Connects the input and output of the circuit
   dffIs[0].d <= i0
   o0 <= dffIs[-1].q
   o0b <= dffIs[-1].qb
end

# Instantiate it for checking.
shifter :shifterI, 16

# Generate the low level representation.
low = shifterI.to_low

# Displays it
puts low.to_yaml
