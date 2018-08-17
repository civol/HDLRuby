require 'HDLRuby'

configure_high

# Describes an 8-bit data 16-bit address RAM.
system :ram8_16 do
    input :rwb, :en
    [15..0].input :addr
    [7..0].inout :data

    bit[7..0][2**16].inner :content

    # Reading the memory
    data <= mux(en && rwb, content[addr], _bhZZ)
    # Writing the memory
    ( content[addr] <= data ).hif(en && ~rwb)
end

# Instantiate it for checking.
ram8_16 :ram8_16I


# Generate the low level representation.
low = ram8_16I.systemT.to_low

# Displays it
puts low.to_yaml
