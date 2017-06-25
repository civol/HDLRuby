require 'HDLRuby'
include HDLRuby::High

# Describes an 16-bit shift register.
system :shift16 do
    input :clk, :rst, :din
    output :dout

    [15..0].inner :reg

    dout <= reg[15] # The output is the last bit of the register.

    behavior(clk.posedge) do
        hif(rst) { reg <= 0 }
        helse seq do
            reg[0] <= din
            reg <= reg[14..0]
        end 
    end
end

# Instantiate it for checking.
Universe.shift16 :shift16I
