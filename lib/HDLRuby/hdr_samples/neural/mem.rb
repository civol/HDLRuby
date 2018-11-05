##
# Module generating a lookup table memory.
# Params:
# - +inT+:  the data type of the input (address).
# - +outT+: the data type of the output (data).
# - +ar+:   the contents of the memory as an array.
system :mem do |inT,outT,ar|
    # The control signals.
    input :clk # Clock
    input :din # Read enable

    # The interface signals.
    inT.input   :addr  # Address
    outT.output :data  # Data

    # The memory.
    outT[ar.size].inner :contents

    # Fills the memory (static)
    # ar.each.with_index do |val,i|
    #     contents[i] <= val
    # end
    contents <= ar

    # Handle the access to the memory.
    par(clk.posedge) do
        hif(din == 1) { data <= contents[addr] }
        helse         { data <= :"_#{"z"*outT.width}" }
    end
end
