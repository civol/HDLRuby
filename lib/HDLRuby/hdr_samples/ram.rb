# Describes an 8-bit data 16-bit address RAM.
system :ram8_16 do
    input :clk, :rwb, :en
    [7..0].input :addr
    [7..0].inout :data

    [7..0].inner :data_in

    bit[7..0][2**8].inner :content

    data <= mux(en & rwb, _bzzzzzzzz, content[addr])
    data_in <= data

    par(clk.posedge) do
        hif(en & ~rwb) do
            content[addr] <= data_in
        end
    end
end
