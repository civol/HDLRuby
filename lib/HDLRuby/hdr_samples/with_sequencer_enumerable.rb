require 'std/sequencer.rb'

include HDLRuby::High::Std

# Checking the usage of sequencer's enumerable capabilities.
# - The first sequencer checks sall?
# - The second sequencer checks sany?
# - The third sequencer checks schain
# - The forth sequencer checks smap
# - The fifth sequencer checks smap with with_index
# - The sixth sequencer checks scompact
# - The seventh sequencer checks scount
# - The eighth sequencer checks scycle
# - The nineth sequencer checks sfind
# - The tenth sequencer checks sdrop and sdrop_while
# - The eleventh sequencer checks seach_cons
# - The twelveth sequencer checks seach_slice
# - The thirteenth sequencer checks sto_a
# - The forteenth sequencer checks sselect
# - The fifteenth sequencer checks sfind_index
# - The sixteenth sequencer checks sfirst
# - The seventeenth sequencer checks sinject
# - The eighteenth sequencer checks smax
# - The nineteenth sequencer checks smax_by
# - The twentieth sequencer checks smax_by
# - The twenty firth sequencer checks smin
# - The twenty second sequencer checks smin_by
# - The twenty third sequencer checks sminmax and sminmax_by
# - The twenty fourth sequencer checks snone?
# - The twenty fifth sequencer checks sone?
# - The twenty sixth sequencer checks sreverse_each
# - The twenty seventh sequencer checks ssort and ssort_by
# - The twenty eighth sequencer checks ssum
# - The twenty nineth sequencer checks stake and stake_while
# - The thirtieth sequencer checks suniq
# - The thirty first sequencer checks szip
system :my_seqencer do

    inner :clk,:rst

    bit[8][-8].inner vals: [ _h00, _h10, _hA5, _h0B, _hFE, _h34, _h5C, _h44 ]

    [16].inner :res0, :res1

    sequencer(clk.posedge,rst) do
        hprint("#0\n")
        res0 <= 0
        res1 <= 0
        step
        res0 <= vals.sall? { |val| val != _h11 }
        res1 <= vals.sall? { |val| val != _h5C }
        hprint("#1 res0=",res0," res1=",res1,"\n")
    end

    [16].inner :res2, :res3

    sequencer(clk.posedge,rst) do
        hprint("$0\n")
        res2 <= 0
        res3 <= 0
        step
        res2 <= vals.sany? { |val| val == _h11 }
        res3 <= vals.sany? { |val| val == _h5C }
        hprint("$1 res2=",res2," res3=",res3,"\n")
    end

    [16].inner :res4

    sequencer(clk.posedge,rst) do
        hprint("!0\n")
        res4 <= 0
        vals.schain(0..10).seach do |elem|
            res4 <= elem
            hprint("!1 res4=",res4,"\n")
        end
        hprint("!2 res4=",res4,"\n")
    end

    [8*8].inner :res5

    sequencer(clk.posedge,rst) do
        hprint("%0\n");
        res5 <= 0
        res5 <= vals.smap { |val| val + 1 }
        hprint("%1 res5=",res5,"\n");
    end

    [8*8].inner :res6

    sequencer(clk.posedge,rst) do
        hprint("&0\n");
        res6 <= 0
        res6 <= vals.smap.with_index { |val,i| val + i }
        hprint("&1 res6=",res6,"\n");
    end

    bit[8][-8].inner vals2: [ _h00, _h10, _h00, _h0B, _hFE, _h00, _h5C, _h00 ]
    [8*8].inner :res7

    sequencer(clk.posedge,rst) do
        hprint("|0\n");
        res7 <= 0
        res7 <= vals2.scompact
        hprint("|1 res7=",res7,"\n");
    end

    [8].inner :res8, :res9, :res10

    sequencer(clk.posedge,rst) do
        hprint("(0\n");
        res8 <= 0
        res9 <= 0
        res10 <= 0
        res8 <= vals2.scount
        res9 <= vals2.scount(_h00)
        res10 <= vals2.scount {|elem| elem > _h10 }
        hprint("(1 res8=",res8," res9=",res9," res10=",res10,"\n");
    end

    [8].inner :res11, :res12

    sequencer(clk.posedge,rst) do
        hprint(")0\n")
        res11 <= 0
        res12 <= 0
        vals.scycle(2) { |elem| res11 <= elem }
        hprint(")1 res11=",res11,"\n")
        vals2.scycle { |elem| res12 <= elem }
        hprint(")2 Should never be here! ... res12=",res12,"\n")
    end

    [8].inner :res13, :res14
    
    sequencer(clk.posedge,rst) do
        hprint("=0\n")
        res13 <= 0
        res14 <= 0
        res13 <= vals.sfind(-1) { |elem| elem > 0 }
        res14 <= vals.sfind(-1) { |elem| elem == _hAA }
        hprint("=1 res13=",res13," res14=",res14,"\n")
    end

    [8*8].inner :res15, :res16
    
    sequencer(clk.posedge,rst) do
        hprint("+0\n")
        res15 <= 0
        res16 <= 0
        res15 <= vals.sdrop(3)
        res16 <= vals.sdrop_while { |elem| elem < _hAA }
        hprint("+1 res15=",res15," res16=",res16,"\n")
    end

    [8].inner :res17
    
    sequencer(clk.posedge,rst) do
        hprint("*0\n")
        res17 <= 0
        vals.seach_cons(3) { |a,b,c| res17 <= a+b+c }
        hprint("*1 res17=",res17,"\n")
    end

    [8].inner :res18
    
    sequencer(clk.posedge,rst) do
        hprint("/0\n")
        res18 <= 0
        vals.seach_slice(3) { |a,b,c| res18 <= a+b+c }
        hprint("/1 res18=",res18,"\n")
    end

    [32*4].inner :res19
    
    sequencer(clk.posedge,rst) do
        hprint("~0\n")
        res19 <= 0
        res19 <= (1..4).seach.sto_a
        hprint("~1 res19=",res19,"\n")
    end

    [8].inner :res21, :res22
    
    sequencer(clk.posedge,rst) do
        hprint(">0\n")
        res21 <= 0
        res22 <= 0
        res21 <= vals.sfind_index(_h0B)
        res22 <= vals.sfind_index { |elem| elem < _hAA }
        hprint(">1 res21=",res21," res22=",res22,"\n")
    end

    [4*8].inner :res23
    
    sequencer(clk.posedge,rst) do
        hprint("<0\n")
        res23 <= 0
        res23 <= vals.sfirst(4)
        hprint("<1 res23=",res23,"\n")
    end

    inner :res24, :res25
    
    sequencer(clk.posedge,rst) do
        hprint("!0\n")
        res24 <= 0
        res25 <= 0
        res24 <= vals.sinclude?(_h0B)
        res25 <= vals.sinclude?(_hAA)
        hprint("!1 res24=",res24," res25=",res25,"\n")
    end

    [8].inner :res26, :res27

    sequencer(clk.posedge,rst) do
        hprint(":0\n")
        res26 <= 0
        res27 <= 0
        res26 <= vals.sinject(1) { |a,b| a+b }
        res27 <= vals.sinject(:+)
        hprint(":1 res26=",res26," res27=",res27,"\n")
    end

    [8].inner :res28
    [8*3].inner :res29

    sequencer(clk.posedge,rst) do
        hprint(";0\n")
        res28 <= 0
        res29 <= 0
        res28 <= vals.smax
        res29 <= vals.smax(3)
        hprint(";1 res28=",res28," res29=",res29,"\n")
    end

    [8].inner :res30
    [8*3].inner :res31

    sequencer(clk.posedge,rst) do
        hprint(",0\n")
        res30 <= 0
        res31 <= 0
        res30 <= vals.smax_by {|e| e.to_signed }
        res31 <= vals.smax_by(3) {|e| e.to_signed }
        hprint(",1 res30=",res30," res31=",res31,"\n")
    end

    [8].inner :res32
    [8*3].inner :res33

    sequencer(clk.posedge,rst) do
        hprint(".0\n")
        res32 <= 0
        res33 <= 0
        res32 <= vals.smin
        res33 <= vals.smin(3)
        hprint(".1 res32=",res32," res33=",res33,"\n")
    end

    [8].inner :res34
    [8*3].inner :res35

    sequencer(clk.posedge,rst) do
        hprint(":0\n")
        res34 <= 0
        res35 <= 0
        res34 <= vals.smin_by {|e| e.to_signed }
        res35 <= vals.smin_by(3) {|e| e.to_signed }
        hprint(":1 res34=",res34," res35=",res35,"\n")
    end

    [16].inner :res36, :res37

    sequencer(clk.posedge,rst) do
        hprint("]0\n")
        res36 <= 0
        res37 <= 0
        res36 <= vals.sminmax
        res37 <= vals.sminmax_by {|e| e.to_signed }
        hprint("]1 res36=",res36," res37=",res37,"\n")
    end

    [8].inner :res38, :res39

    sequencer(clk.posedge,rst) do
        hprint("[0\n")
        res38 <= 0
        res39 <= 0
        step
        res38 <= vals.snone? { |val| val == _h11 }
        res39 <= vals.snone?(_h5C)
        hprint("[1 res38=",res38," res39=",res39,"\n")
    end

    [8].inner :res40, :res41, :res42

    sequencer(clk.posedge,rst) do
        hprint("[0\n")
        res40 <= 0
        res41 <= 0
        res42 <= 0
        step
        res40 <= vals.sone?(_h5C)
        res41 <= vals.sone? { |val| val == _h11 }
        res42 <= vals2.sone? { |val| val == _h00 }
        hprint("[1 res40=",res40," res41=",res41," res42=",res42,"\n")
    end

    [8].inner :res43

    sequencer(clk.posedge,rst) do
        hprint("_0\n")
        res43 <= 0
        step
        (4..10).sreverse_each { |val| res43 <= val }
        hprint("_1 res43=",res43,"\n")
    end

    [8*8].inner :res44, :res45

    sequencer(clk.posedge,rst) do
        hprint("@0\n")
        res44 <= 0
        res45 <= 0
        step
        res44 <= vals.ssort
        res45 <= vals.ssort_by { |val| val.to_signed }
        hprint("@1 res44=",res44," res45=",res45,"\n")
    end

    [8].inner :res46, :res47

    sequencer(clk.posedge,rst) do
        hprint("`0\n")
        res46 <= 0
        res47 <= 0
        step
        res46 <= vals.ssum
        res47 <= vals.ssum { |val| val & _h0F }
        hprint("`1 res46=",res46," res47=",res47,"\n")
    end

    [8*3].inner :res48
    [8*8].inner :res49

    sequencer(clk.posedge,rst) do
        hprint("`0\n")
        res48 <= 0
        res49 <= 0
        step
        res48 <= vals.stake(3)
        res49 <= vals.stake_while { |val| val < _hAA }
        hprint("`1 res48=",res48," res49=",res49,"\n")
    end

    bit[8][-8].inner vals3: [ _hFE, _h10, _hA5, _h10, _hFE, _h34, _h5C, _h10 ]

    [8*8].inner :res50,:res51

    sequencer(clk.posedge,rst) do
        hprint("\"0\n")
        res50 <= 0
        res51 <= 0
        step
        res50 <= vals3.suniq
        res51 <= vals.suniq { |val| val & _h0F }
        hprint("\"1 res50=",res50," res51=",res51,"\n")
    end

    # [8*4*2].inner :res52
    # [8*4].inner :res53
    # [3].inner :idx

    # sequencer(clk.posedge,rst) do
    #     hprint("}0\n")
    #     res52 <= 0
    #     res53 <= 0
    #     idx   <= 0
    #     step
    #     res52 <= vals.szip(1..6)
    #     vals.szip([1]*8) { |a,b| res53[idx] <= a+b; idx <= idx + 1 }
    #     hprint("}1 res52=",res52," res53=",res53,"\n")
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
        repeat(100) do
            !10.ns
            clk <= ~clk
        end
    end
end
