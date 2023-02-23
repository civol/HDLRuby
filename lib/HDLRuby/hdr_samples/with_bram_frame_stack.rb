require 'soft/stacks.rb'

include HDLRuby::High::Soft


# A system testing the bram-based stack.
system :bram_stach_test do

    widthD = 8
    size = 1024
    depth = 16


    input :clk, :rst, :ce
    [2].inner :cmd
    { frame: bit[depth.width], offset: bit[size.width] }.inner :loc
    [size.width].inner :frame_size
    [widthD].inner  :din,:dout
    inner :empty, :full

    bram_frame_stack(widthD,size,depth).(:stack0).(clk,rst,ce,cmd,loc,din,dout,empty,full)

    timed do
        clk <= 0
        rst <= 0
        ce <= 0
        cmd <= READ
        loc.frame  <= 0
        loc.offset <= 0
        frame_size <= 0
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
        !10.ns
        clk <= 1
        repeat(9) do
            !10.ns
            clk  <= 0
            ce  <= 1
            cmd <= PUSH
            frame_size <= frame_size + 16
            loc.offset <= frame_size
            !10.ns
            clk <= 1
            !10.ns
            clk <= 0
            cmd <= WRITE
            din <= 5
            loc.frame <= 0
            loc.offset <= 1
            !10.ns
            clk <= 1
            !10.ns
            clk <= 0
            cmd <= READ
            loc.frame <= 0
            loc.offset <= 1
            !10.ns
            clk <= 1
            !10.ns
            clk <= 0
            cmd <= WRITE
            din <= 55
            loc.frame <= 1
            loc.offset <= 14
            !10.ns
            clk <= 1
            !10.ns
            clk <= 0
            cmd <= READ
            loc.frame <= 1
            loc.offset <= 14
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
