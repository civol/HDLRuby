require 'std/sequencer.rb'

include HDLRuby::High::Std

# Checking the creation of sequencers enumerators.
# - The first sequencer checks enumerators on signals.
# - The second sequencer checks enumerators on ranges.
# - The third sequencer checks enumerators on arrays.
# - The fourth sequencer checks custom enumerators.
system :my_seqencer do

    inner :clk,:rst

    bit[8][-8].inner vals: [ _h01, _h02, _h03, _h04, _h10, _h20, _h30, _h40 ]

    [8].inner :res0, :res1

    sequencer(clk.posedge,rst) do
        # hprint("#0\n")
        res0 <= 0
        res1 <= 0
        res0 <= vals.ssum
        res1 <= res0.ssum(_h00)
        # hprint("#1 res0=",res0," res1=",res1,"\n")
    end

    [8].inner :res2, :res3

    sequencer(clk.posedge,rst) do
        # hprint("$0\n")
        res2 <= 0
        res3 <= 0
        res2 <= (1..5).ssum(_h00)
        res3 <= (res3..res2).ssum
        # hprint("$1 res2=",res2," res3=",res3,"\n")
    end

    [8].inner :res4, :res5

    sequencer(clk.posedge,rst) do
        # hprint("!0\n")
        res4 <= 0
        res5 <= 0
        res4 <= [_h01,_h02,_h03,_h04].ssum
        res5 <= [1,2,3,4,5].ssum(_h00)
        # hprint("!1 res4=",res4," res5=",res5,"\n")
    end

    bit[8][-8].inner mem: [ _h01, _h02, _h03, _h04, _h30, _h30, _h30, _h30 ]

    [8].inner :res6, :addr, :data

    data <= mem[addr]

    mem_enum = senumerator(bit[8],8) do |i|
        addr <= i
        step
        data
    end

    sequencer(clk.posedge,rst) do
        # hprint("~0\n")
        res6 <= 0
        res6 <= mem_enum.ssum
        # hprint("~1 res6=",res6,"\n")
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
