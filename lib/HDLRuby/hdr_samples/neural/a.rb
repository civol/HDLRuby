system :a do |typ, activate|
   input :clk, :din
   typ.input :vin # Former addr
   typ.output :dout

   par(clk.posedge) do
       dout <= mux(din == 1, activate.(vin), :"_#{"z"*typ.width}")
   end
end
