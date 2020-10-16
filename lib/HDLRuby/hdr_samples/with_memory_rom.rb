require 'std/memory.rb'

include HDLRuby::High::Std





# A system testing the rom channel.
system :rorm_test do
    inner :clk,:rst
    [8].inner :value
    inner :addr

    # Declares a 8-bit-data and 1 element rom address synchronous memory
    # on negative edge of clk.
    # mem_rom([8],2,clk,rst,[_00000110,_00000111], rinc: :rst).(:romI)
    mem_rom([8],1,clk,rst,[_00000110], rinc: :rst).(:romI)
    rd = romI.branch(:rinc)

    par(clk.posedge) do
        hif(rst) { addr <= 0 }
        helse do
            rd.read(value)
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
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        rst <= 0
        !10.ns
        10.times do
            clk <= 1
            !10.ns
            clk <= 0
            !10.ns
        end
    end
end
