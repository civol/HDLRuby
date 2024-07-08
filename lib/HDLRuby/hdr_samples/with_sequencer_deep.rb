require 'std/sequencer.rb'

include HDLRuby::High::Std

# Checking the usage of sequencers with multiple and deep loops.
# Also checks empty loops and loops controlled from the outside.
system :my_seqencer do

    inner :clk,:rst,:req

    [16].inner :u, :v

    sequencer(clk,rst) do
        hprint("#0\n")
        u <= 0
        v <= 1
        swhile(v<10) { v <= v + 1 }
        hprint("#1\n")
        swhile(u<10) { u <= u + 1 }
        hprint("#2\n")
    end

    [16].inner :x, :y

    sequencer(clk,rst) do
        hprint("!0\n")
        x <= 1
        y <= 0
        swhile(x<20) do
            hprint("!1\n")
            x <= x + 4
            swhile(y<x) { y <= y + 1 }
        end
        hprint("!2\n")
    end

    [16].inner :z

    sequencer(clk,rst) do
        hprint("$0\n")
        z <= 10
        swhile(x==0)
        z <= 0
        hprint("$1\n")
        swhile(x<10)
        z <= 1
        hprint("$2\n")
    end

    [16].inner :w

    sequencer(clk,rst) do
        hprint(":0\n")
        w <= 0
        sloop do
            swhile(req == 1) { w <= 1 }
            w <= w + 1
        end
    end


    timed do
        clk <= 0
        rst <= 0
        req <= 0
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
        req <= 1
        !10.ns
        clk <= 1
        repeat(10) do
            !10.ns
            clk <= ~clk
        end
        !10.ns
        req <= 0
        clk <= ~clk
        repeat(60) do
            !10.ns
            clk <= ~clk
        end
    end
end
