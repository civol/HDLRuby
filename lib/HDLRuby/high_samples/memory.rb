require 'HDLRuby'

configure_high

# Describes an 8-bit data 16-bit address memory.
system :mem8_16 do
    input :clk, :rwb
    [15..0].input :addr
    [7..0].inout :data

    bit[7..0][2**16].inner :content
    
    par(clk.posedge) do
        hif(rwb) { data <= content[addr] }
        helse    { content[addr] <= data }
    end
end

# Instantiate it for checking.
mem8_16 :mem8_16I


# Describes a 16-bit memory made of 8-bit memories.
system :mem16_16 do
    input :clk, :rwb
    [15..0].input :addr
    [15..0].inout :data

    mem8_16(:memL).(clk: clk, rwb: rwb, addr: addr, data: data[7..0])
    mem8_16(:memH).(clk: clk, rwb: rwb, addr: addr, data: data[15..8])
end

# Instantiate it for checking.
mem16_16 :mem16_16I


# Describes a 16-bit memory made of 8-bit memories the long way.
system :mem16_16_long do
    input :clk, :rwb
    [15..0].input :addr
    [15..0].inout :data

    mem8_16 [:memL, :memH]

    memL.clk  <= clk
    memL.rwb  <= rwb
    memL.addr <= addr
    memL.data <= data[7..0]

    memH.clk  <= clk
    memH.rwb  <= rwb
    memH.addr <= addr
    memH.data <= data[15..8]
end

# Instantiate it for checking.
mem16_16_long :mem16_16_longI

# Generate the low level representation.
# low = mem16_16I.to_low
low = mem16_16_longI.systemT.to_low

# Displays it
puts low.to_yaml
