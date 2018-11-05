system :dadz do |width,derivate|
    input :clk,:res
    signed[width].input :a
    signed[width].output :dadz

    par(clk.posedge) do
        dadz <= mux(res == 1, 0, derivate.(a))
    end
end
