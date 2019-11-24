# Describes a simple D-FF
system :dff do
    input :clk,:rst
    input :d
    output :q

    (q <= d & ~rst ).at(clk.posedge)
end


# Describes a 2-bit counter using dff
system :counter2 do
    input :clk,:rst
    output :q

    dff [:dff0, :dff1]
    
    dff0.(clk,rst,~dff0.q)
    dff1.(dff0.q,rst,~dff1.q,q)
end
