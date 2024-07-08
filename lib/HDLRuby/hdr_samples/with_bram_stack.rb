require 'soft/stacks.rb'

include HDLRuby::High::Soft


# A system testing the bram-based stack.
system :bram_stach_test do

    size = 8
    widthD = 8


    inner :clk, :rst, :ce
    inner :cmd
    [widthD].inner  :din,:dout
    inner :empty, :full

    bram_stack(widthD,size).(:stack0).(clk,rst,ce,cmd,din,dout,empty,full)

    timed do
        clk <= 0
        rst <= 0
        ce <= 0
        cmd <= PUSH
        din <= 0
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
        din <= 0
        !10.ns
        clk <= 1
        repeat(9) do
            !10.ns
            clk  <= 0
            ce  <= 1
            cmd <= PUSH
            din <= din + 1
            !10.ns
            clk <= 1
        end
        !10.ns
        clk <= 0
        ce <= 0
        !10.ns
        clk <= 1
        repeat(9) do
            !10.ns
            clk  <= 0
            ce   <= 1
            cmd  <= POP
            !10.ns
            clk <= 1
        end
        !10.ns
        clk <= 0
        ce  <= 0
        !10.ns
        clk <= 1
        !10.ns
    end

end
