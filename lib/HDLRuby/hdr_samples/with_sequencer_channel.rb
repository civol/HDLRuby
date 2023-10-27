require 'std/sequencer.rb'

include HDLRuby::High::Std

# Checking the usage of sequencers' channels.
system :my_seqencer do

    inner :clk,:rst,filled: 0
    bit[16][-16].inner :mem
    [16].inner :res0, :res1, :res2, :res3

    ch_read = schannel(bit[16],16) do |i|
        mem[i]
    end

    ch_write = schannel(bit[16],16) do |i,val|
        mem[i] <= val
    end

    sequencer(clk.posedge,rst) do
        16.stimes { |i| ch_write.snext!(i) }
        filled <= 1
        16.stimes do |i| 
            res0 <= ch_read.snext 
            res1 <= ch_read[15-i]
        end
    end

    sequencer(clk.posedge,rst) do
        swhile(~filled);
        16.stimes do |i| 
            res2 <= ch_read.snext 
            res3 <= ch_read[15-i]
        end
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
