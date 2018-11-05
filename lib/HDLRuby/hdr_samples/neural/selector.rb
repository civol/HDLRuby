##
# Module generating the selector that decides if a neuron is to update or not.
# Params:
# - +skip+: the number of clocks to skip.
system :selector do |skip|
    input :clk, :reset
    output :enable_update

    # The clock counter.
    [Math::log2(skip).ceil].inner :counter

    # The behavior handling the skip counter
    par(clk.posedge) do
        hif(reset == 1) { counter <= 0 }
        helse do
            hif(counter == skip-1) { counter <=0 }
            helse        {counter <= counter + 1 }
        end
    end

    # The behavior handling the update signal
    par(clk.posedge) do
        hif(reset == 1) { enable_update <= 0 }
        helse do
            hif(counter == skip-1) { enable_update <= 1 }
            helse                  { enable_update <= 0 }
        end
    end
end
