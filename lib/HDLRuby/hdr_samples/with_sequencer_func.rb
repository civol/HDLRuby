require 'std/sequencer_func.rb'

include HDLRuby::High::Std


sdef(:fact,16) do |n|
    hprint("n=",n,"\n")
    sif(n > 1) { sreturn(n*fact(n-1)) }
    selse      { sreturn(1) }
end

# Checking the usage of sequencers functions.
system :my_seqencer do

    inner :clk,:rst

    [16].inner :val
    [16].inner :res

    sequencer(clk.posedge,rst) do
        5.stimes do |i|
            val <= i
            res <= fact(val)
        end
    end

    # sequencer(clk.posedge,rst) do
    #     5.stimes do |i|
    #         val <= i
    #         sif(val < 2) { res <= 0 ; step ; res <= 1 }
    #         selse { res <= 3 ; step ; res <= 4 }
    #     end
    # end

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
        repeat(200) do
            !10.ns
            clk <= ~clk
        end
    end
end
