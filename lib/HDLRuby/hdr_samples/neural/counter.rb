##
# Module generating the sample counter.
# Params:
# - +num+: the number of samples.
system :counter do |typ,num|
    # The input control signals.
    input :clk, :reset
    # The output counter.
    typ.output :out

    par(clk.posedge) do
        hif(reset == 1) { out <= 0 }
        helsif(out == num-1) { out <= 0 }
        helse { out <= out+1 }
    end
end
