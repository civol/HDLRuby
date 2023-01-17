require 'soft/stacks.rb'

include HDLRuby::High::Soft


# A system testing the stack.
system :bram_stach_test do

    widthA = 3
    widthD = 8


    input :clk,:rst,:ce
    [2].inner :cmd
    [widthD].inner  :din,:dout
    inner :empty, :full

    bram_stack(widthA,widthD).(:bramI).(clk,rst,ce,cmd,din,dout,empty,full)

    [widthD].inner :count # Additional counter for the test.

    timed do
        clk <= 0
        ce  <= 0
        rst <= 0
        cmd <= READ
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
        ce  <= 1
        din <= 1
        !10.ns
        clk <= 1
        repeat(9) do
            !10.ns
            clk <= 0
            cmd <= PUSH
            din <= din + 1
            !10.ns
            clk <= 1
        end
        !10.ns
        clk <= 0
        !10.ns
        clk <= 1
        din <= -1
        repeat(8) do
            !10.ns
            clk <= 0
            cmd <= READ
            din <= din + 1
            !10.ns
            clk <= 1
        end
        !10.ns
        clk <= 0
        !10.ns
        clk <= 1
        count <= 0
        repeat(4) do
            !10.ns
            clk <= 0
            din <= 1
            cmd <= POP
            !10.ns
            clk <= 1
            !10.ns
            clk <= 0
            count <= count + 1
            din <= count
            cmd <= PUSH
            !10.ns
            clk <= 1
        end
        !10.ns
        clk <= 0
        !10.ns
        clk <= 1
        repeat(9) do
            !10.ns
            clk <= 0
            din <= 1
            cmd <= POP
            !10.ns
            clk <= 1
        end
        !10.ns
        clk <= 0
        din <= -1
        cmd <= READ
        !10.ns
        clk <= 1
        repeat(8) do
            !10.ns
            clk <= 0
            cmd <= WRITE
            din <= din + 1
            !10.ns
            clk <= 1
        end
        !10.ns
        clk <= 0
        din <= -1
        cmd <= READ
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        din <= -3
        cmd <= POP
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        din <= 31
        cmd <= PUSH
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        din <= 3
        cmd <= POP
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        din <= -1
        cmd <= READ
        !10.ns
        clk <= 1
    end
end
