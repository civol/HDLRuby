require 'std/bram.rb'

include HDLRuby::High::Std


# A system testing the memory.
system :bram_test do

    widthA = 16
    widthD = 8


    input :clk,:rwb
    [widthA].inner :addr
    [widthD].inner  :din,:dout

    bram(widthA,widthD).(:bramI).(clk,rwb,addr,din,dout)

    timed do
        clk  <= 0
        rwb  <= 0
        addr <= 0
        din  <= 0
        !10.ns
        clk  <= 1
        !10.ns
        rwb <= 0
        repeat(16) do
            clk <= 0
            !10.ns
            clk <= 1
            addr <= addr + 1
            din <= din + 1
            !10.ns
        end
        rwb <= 1
        repeat(16) do
            clk <= 0
            !10.ns
            clk <= 1
            addr <= addr-1
            !10.ns
        end
    end
end
