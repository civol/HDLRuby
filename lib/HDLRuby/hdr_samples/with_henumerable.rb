require 'std/sequencer.rb'

include HDLRuby::High::Std

# Checking the usage of hardware enumerable capabilities.
# - The first check is for hall?
# - The second check is for hany?
# - The third check is for hchain
# - The forth check is for hmap
# - The fifth check is for hmap with hwith_index
# - The sixth check is for hcompact
# - The seventh checks is for hcount
# - The eighth check is for hcycle
# - The nineth check is for hfind
# - The tenth check is for hdrop and hdrop_while
# - The eleventh check is for heach_cons
# - The twelveth check is for heach_slice
# - The thirteenth check is for hto_a
# - The forteenth check is for hselect
# - The fifteenth check is for hfind_index
# - The sixteenth check is for hfirst
# - The seventeenth check is for hinject
# - The eighteenth check is for hmax
# - The nineteenth check is for hmax_by
# - The twentieth check is for hmax_by
# - The twenty firth check is for hmin
# - The twenty second check is for hmin_by
# - The twenty third check is for hminmax and hminmax_by
# - The twenty fourth check is for hnone?
# - The twenty fifth check is for hone?
# - The twenty sixth check is for hreverse_each
# - The twenty seventh check is for hsort and hsort_by
# - The twenty eighth check is for hsum
# - The twenty nineth check is for htake and htake_while
# - The thirtieth check is for suniq
# - The thirty first check is for hzip
#
# - The remaing checks the enumerators apply on values directly.
#
 
system :henmerable_checks do

    inner :clk,:rst

    bit[8][-8].inner vals: [ _h00, _h10, _hA5, _h0B, _hFE, _h34, _h5C, _h44 ]
    rvals = 8.times.to_a.reverse

    [16].inner :res0, :res1, :res2, :res3

    res0 <= vals.hall? { |val| val != _h11 }
    res1 <= vals.hall? { |val| val != _h5C }

    par(clk.posedge) do
      # hprint("#0\n")
      res2 <= rvals.hall? { |val| val.to_expr != 11 }
      res3 <= rvals.hall? { |val| val.to_expr != 4 }
      # hprint("#1 res0=",res0," res1=",res1," res2=",res2," res3=",res3,"\n")
    end

    [16].inner :res4, :res5, :res6, :res7

    res4 <= vals.hany? { |val| val == _h11 }
    res5 <= vals.hany? { |val| val == _h5C }

    par(clk.posedge) do
        # hprint("$0\n")
        res6 <= rvals.hany? { |val| val == 11 }
        res7 <= rvals.hany? { |val| val == 4 }
        # hprint("#1 res4=",res4," res5=",res5," res6=",res6," res7=",res7,"\n")
    end

    [16].inner :res8, :res9, :res10, :res11

    res8 <= vals.hchain(0..10).hany? { |val| val.as(bit[8]) == _h11 }
    res9 <= vals.hchain(0..10).hany? { |val| val.as(bit[8]) == _h05 }

    par(clk.posedge) do
      # hprint("!0\n")
      res10 <= rvals.hchain(vals).hany? { |val| val.as(bit[8]) == _h11 }
      res11 <= rvals.hchain(vals).hany? { |val| val.as(bit[8]) == _h04 }
    end

    bit[8][-8].inner :res12, :res13

    res12 <= vals.hmap { |val| val + 1 }

    par(clk.posedge) do
      # hprint("%0\n");
      res13 <= vals.hmap { |val| val + 1 }
    end

    bit[8][-8].inner :res14, :res15

    res14 <= vals.hmap.hwith_index { |val,i| val + i }

    par(clk.posedge) do
      # hprint("&0\n");
      res15 <= vals.hmap.hwith_index { |val,i| val + i }
    end

    bit[8][-8].inner vals2: [ _h00, _h10, _h00, _h0B, _hFE, _h00, _h5C, _h00 ]
    # bit[8][-8].inner :res16, :res17

    # res16 <= vals2.hcompact

    # sequencer(clk.posedge,rst) do
    #   # hprint("|0\n");
    #   res17 <= vals2.hcompact
    # end

    [8].inner :res18, :res19, :res20

    res18 <= vals2.hcount
    res19 <= vals2.hcount(_h00)

    par(clk.posedge) do
      # hprint("(0\n");
      res20 <= vals2.hcount {|elem| elem > _h10 }
    end

    # [8].inner :res21, :res22

    # vals.hcycle(2) { |elem| res21 <= elem }

    # par(clk.posedge) do
    #   # hprint(")0\n")
    #   vals2.hcycle { |elem| res22 <= elem }
    # end

    [8].inner :res23, :res24

    res23 <= vals.hfind(proc {-1}) { |elem| elem > _h00 }

    par(clk.posedge) do
      # hprint("=0\n")
      res24 <= vals.hfind(proc {-1}) { |elem| elem == _hAA }
    end

    bit[8][-8].inner :res25 #, :res26
    
    res25 <= vals.hdrop(3)

    # par(clk.posedge) do
    #   # hprint("+0\n")
    #   res26 <= vals.hdrop_while { |elem| elem < _hAA }
    # end

    bit[8][-8].inner :res27

    par(clk.posedge) do
      # hprint("*0\n")
      vals.heach_cons(3).hwith_index { |(a,b,c),i| res27[i] <= a+b+c }
    end

    bit[8][-8].inner :res28
    
    par(clk.posedge) do
      # hprint("/0\n")
      vals.heach_slice(3).hwith_index do |(a,b,c),i| 
        if c then
          res28[i] <= a+b+c
        elsif b then
          res28[i] <= a+b
        else
          res28[i] <= a
        end
      end
    end

    bit[32][-4].inner :res29
    
    par(clk.posedge) do
      # hprint("~0\n")
      res29 <= (_h00000001.._h00000004).heach.hto_a
    end

    [8].inner :res30, :res31, :res31x

    res30 <= vals.hfind_index(_h0B)
    
    par(clk.posedge) do
      # hprint(">0\n")
      res31 <= vals.hfind_index { |elem| elem < _hAA }
      res31x <= vals.hfind_index { |elem| elem == _hAA }
    end

    bit[8][-4].inner :res32
    
    par(clk.posedge) do
      # hprint("<0\n")
      res32 <= vals.hfirst(4)
    end

    inner :res33, :res34

    res33 <= vals.hinclude?(_h0B)
    
    par(clk.posedge) do
      # hprint("!0\n")
      res34 <= vals.hinclude?(_hAA)
    end

    [8].inner :res35, :res36

    res35 <= vals.hinject(_h01) { |a,b| a+b }

    par(clk.posedge) do
      # hprint(":0\n")
      res36 <= vals.(:+)
    end

    [8].inner :res37
    bit[8][-3].inner :res38

    res37 <= vals.hmax

    par(clk.posedge) do
      # hprint(";0\n")
      # res38 <= vals.hmax(3)
      res38 <= vals.hmax(1)
    end

    [8].inner :res39
    # bit[8][-3].inner :res40
    [8].inner :res40

    res39 <= vals.hmax_by {|e| e.to_signed }

    par(clk.posedge) do
      # hprint(",0\n")
      # res40 <= vals.hmax_by(3) {|e| e.to_signed }
      res40 <= vals.hmax_by(1) {|e| e.to_signed }
    end

    [8].inner :res41
    bit[8][-3].inner :res42

    res41 <= vals.hmin

    par(clk.posedge) do
      # hprint(".0\n")
      # res42 <= vals.hmin(3)
      res42 <= vals.hmin(1)
    end

    [8].inner :res43
    bit[8][-3].inner :res44

    res43 <= vals.hmin_by {|e| e.to_signed }

    par(clk.posedge) do
      # hprint(":0\n")
      # res44 <= vals.hmin_by(3) {|e| e.to_signed }
      res44 <= vals.hmin_by(1) {|e| e.to_signed }
    end

    [16].inner :res45, :res46

    res45 <= vals.hminmax

    par(clk.posedge) do
      # hprint("]0\n")
      res46 <= vals.hminmax_by {|e| e.to_signed }
    end

    [8].inner :res47, :res48

    res47 <= vals.hnone? { |val| val == _h11 }

    par(clk.posedge) do
      # hprint("[0\n")
      res48 <= vals.hnone?(_h5C)
    end

    [8].inner :res49, :res50, :res51

    res49 <= vals.hone?(_h5C)

    par(clk.posedge) do
      # hprint("[0\n")
      res50 <= vals.hone? { |val| val == _h11 }
      res51 <= vals2.hone? { |val| val == _h00 }
    end

    bit[8][-6].inner :res52

    par(clk.posedge) do
        # hprint("_0\n")
      (5..10).hreverse_each.hwith_index { |val,i| res52[i] <= val }
    end

    bit[8][-10].inner :res53X, :res54X
    bit[8][-8].inner :res53, :res54
    bit[8][-10].inner valsX: [ _h00, _h10, _hA5, _h0B, _hFE, _h34, _h5C, _h44, _h01, _h82 ]

    res53  <= vals.hsort
    res54  <= vals.hsort_by { |val| val.to_signed }

    seq(clk.posedge) do
      # hprint("@0\n")
      res53X <= valsX.hsort
      res54X <= valsX.hsort_by(_h7F) { |val| val.to_signed }
    end

    [8].inner :res55, :res56

    res55 <= vals.hsum

    par(clk.posedge) do
      # hprint("`0\n")
      res56 <= vals.hsum { |val| val & _h0F }
    end

    bit[8][-3].inner :res57
    # bit[8][-8].inner :res58

    res57 <= vals.htake(3)

    # par(clk.posedge) do
    #   # hprint("`0\n")
    #   res58 <= vals.htake_while { |val| val < _hAA }
    # end

    bit[8][-8].inner vals3: [ _hFE, _h10, _hA5, _h10, _hFE, _h34, _h5C, _h10 ]

    # bit[8][-8].inner :res59,:res60

    # res59 <= vals3.huniq

    # # par(clk.posedge) do
    # #   # hprint("~0\n")
    # #   res60 <= vals.huniq { |val| val & _h0F }
    # # end

    bit[8][-8].inner :res61
    bit[8][-8].inner :res62

    res61 <= vals.hzip((1..6).to_a.map {|i| i.to_expr.as(bit[8]) })

    par(clk.posedge) do
      # hprint("}0\n")
      vals.hzip([_h12]*8).each_with_index { |(a,b),i| res62[i] <= a+b }
    end

    # Test enumerators of values.
    inner :res63, :res64, :res65

    res63 <= _b0101011.(:|)
    res64 <= _b0101011.(:^)
    res65 <= _b0101011.(:&)

    [8].inner :res66

    res66 <= [_h01, _h02, _h03, _h04].(:+)


    # Test signal declarations within iterator block.
    vals.heach do |v,i|
      inner :sig
      sig <= v[0]
    end

    [_h0001, _h0002, _h0003].heach.hwith_index do |v,i|
      [16].inner :sig
      sig <= v + i
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
        repeat(500) do
            !10.ns
            clk <= ~clk
        end
    end
end
