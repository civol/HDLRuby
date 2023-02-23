require 'std/sequencer.rb'

include HDLRuby::High::Std

# Checking the usage of sequencers computing a fibbnacci series until 100
# is passed over.
system :my_seqencer do

    inner :clk,:rst
    [32].inner :u, :v,:res

    sequencer(clk,rst) do
        hprint("#0\n")
        u   <= 0
        v   <= 1
        step
        res <= 0
        hprint("#1 res=",res,"\n")
        swhile(v < 100) do
            v <= u + v
            u <= v - u
            hprint("#2 v=",v,"\n")
        end
        res <= v
        hprint("#3 res=",res,"\n")
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
