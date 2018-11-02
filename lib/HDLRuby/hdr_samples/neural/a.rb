system :a_gen do |a_width, d_width, activate|
   input :clk, :din
   [a_width].input :vin # Former addr
   signed[d_width].output :dout
   
   par(clk.posedge) do
       dout <= mux(din == 1, activate.(vin), _s32hzzzz)
   end
end
