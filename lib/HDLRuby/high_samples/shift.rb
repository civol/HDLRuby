require 'HDLRuby'

configure_high


# Describes an 16-bit shift register.
system :shift16 do
    input :clk, :rst, :din
    output :dout

    [15..0].inner :reg

    dout <= reg[15] # The output is the last bit of the register.

    par(clk.posedge) do
        hif(rst) { reg <= 0 }
        helse seq do
            reg[0] <= din
            reg[15..1] <= reg[14..0]
        end 
    end
end

# Instantiate it for checking.
shift16 :shift16I

# Generate the low level representation.
low = shift16I.systemT.to_low

# Displays it
puts low.to_yaml
