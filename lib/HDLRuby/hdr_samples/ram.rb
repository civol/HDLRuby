# Describes an 8-bit data 16-bit address RAM.
system :ram8_16 do
    input :clk, :rwb, :en
    [7..0].input :addr
    [7..0].inout :data

    bit[7..0][2**8].inner :content

    # Memory enabled?
    par(clk.posedge) do
        hif(en) do
            # Read case
            hif(rwb)   { data <= content[addr] }
            helse      { content[addr] <= data }
        end
        helse { data <= _bZZZZZZZZ }
    end
end
