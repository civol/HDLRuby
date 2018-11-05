##
# Module generating a neuron sum.
# Params:
# - +typ+:  the data type of the neural signals.
# - +ary+:  the arity of the neuron.
# - +sopP+: the sum of product function.
system :z do |typ,ary,sopP|
    # The control signals.
    input :clk, :reset    # Clock and reset

    # The inputs of the neuron.
    ins = []
    wgs = []
    ary.times do |i|
        # The input values
        ins << typ.input(:"x#{i}")
    end
    ary.times do |i|
        # The weights
        wgs << typ.input(:"w#{i}")
    end
    # The bias
    typ.input :bias

    # The sum output
    typ.output :z

    # Behavior controlling the bias/weight
    par(clk.posedge) do
        hif(reset == 1) { z <= 0 }
        helse           { z <= sopP.(ins + [1],wgs + [bias]) }
    end
end
