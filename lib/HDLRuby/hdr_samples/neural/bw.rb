##
# Module generating a neuron bias or weight.
# Params:
# - +typ+: the data type of the neural signals.
# - +init_bw+: initial value of the bias/weight.
system :bw do |typ,init_bw|
    # The control signals.
    input :clk, :reset    # Clock and reset
    input :select_initial # Initialization of the bias/weight
    input :select_update  # Update of the bias/weight

    # Update of the bias/weight
    typ.input :dbw
    # Output of the bias/weight
    typ.output :bwo

    # Behavior controlling the bias/weight
    par(clk.posedge) do
        hif(reset == 1) { bwo <= 0 }
        helsif(select_initial == 1) { bwo <= init_bw }
        helsif(select_update == 1)  { bwo <= bwo+dbw }
    end
end
