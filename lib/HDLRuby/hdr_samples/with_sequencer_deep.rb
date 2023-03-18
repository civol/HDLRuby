require 'std/sequencer.rb'

include HDLRuby::High::Std

# Checking the usage of sequencers with multiple and deep loops.
system :my_seqencer do

    inner :clk,:rst
    [16].inner :u, :v,:res0

    sequencer(clk.posedge,rst) do
        hprint("#0\n")
        u <= 0
        v <= 1
        swhile(v<10) { v <= v + 1 }
        swhile(u<10) { u <= u + 1 }
    end


    timed do
        clk <= 0
        rst <= 0
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        rst <= 1
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        rst <= 0
        !10.ns
        clk <= 1
        repeat(100) do
            !10.ns
            clk <= ~clk
        end
    end
end
