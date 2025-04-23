require 'std/sequencer.rb'

include HDLRuby::High::Std

# Checking for siulation leaks when using a sequencer.
system :my_seqencer do

    inner :clk,:rst
    [65536].inner :count

    # sequencer(clk.posedge,rst) do
    #   sloop do
    #     # count <= count + 1
    #   end
    # end



    timed do
        clk <= 0
        rst <= 0
        count <= 0
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
        repeat do
            !10.ns
            clk <= ~clk
            hif(count == 0) { count <= 1 }
            hcase(count)
            hwhen(1) { count <= 2 }
            hwhen(2) { count <= 3 }
            hwhen(3) { count <= 4 }
            helse { count <= 5 }
        end
    end
end
