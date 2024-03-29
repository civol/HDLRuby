require 'std/sequencer.rb'

include HDLRuby::High::Std

# Checking the usage of sequencers:
# - One sequencer computes a fibbnacci series until 100
# - One sequencer computes a fibbnacci series until 1000 with early termination
#   for testing sterminate.
# - One sequencer computes a fibbnacci series until 1000 with ealry break
#   for testing sbreak.
# - One sequence that increase a first counter and the other one every four
#   increases of the first one for testing scontinue.
# - One sequencer computes the square value of each elements of a buffer.
# - One sequencer computes the square value of each elements of a range.
# - One sequencer concatenates the value of a counter with its index.
# - One sequencer puts the sum of two arrays in a third one.
# - One sequencer iterates over two arrays.
# - One sequencer iterates downward.
# - One sequencer checks sub iterators (HDLRuby special).
system :my_seqencer do

    inner :clk,:rst
    [16].inner :u, :v,:res0

    sequencer(clk.posedge,rst) do
        # hprint("#0\n")
        u <= 0
        v <= 1
        step
        res0 <= 0
        # hprint("#1 res0=",res0,"\n")
        swhile(v < 100) do
            v <= u + v
            u <= v - u
            # hprint("#2 v=",v,"\n")
        end
        res0 <= v
        # hprint("#3 res0=",res0,"\n")
    end

    [16].inner :uu, :vv
    sequencer(clk.posedge,rst) do
        # hprint("##0\n")
        uu <= 0
        vv <= 1
        swhile(vv<10000) do
            vv <= uu + vv
            uu <= vv - uu
            step
            # hprint("##1 vv=",vv,"\n")
            sif(vv >= 100) { sterminate }
        end
        # hprint("##2 vv=",vv,"... But should not be here!\n")
    end

    [16].inner :uuu, :vvv, :res00

    sequencer(clk.posedge,rst) do
        # hprint("###0\n")
        res00 <= 0
        steps(3) # Checks 3 steps
        uuu <= 0
        vvv <= 1
        swhile(vvv<10000) do
            vvv <= uuu + vvv
            uuu <= vvv - uuu
            # hprint("##1 vvv=",vvv,"\n")
            sif(vvv >= 100) { sbreak }
            selse { res00 <= res00 + 1 }
        end
        # hprint("##2 res00=",res00,"... and should be here!\n")
    end

    [8].inner :a,:b

    sequencer(clk.posedge,rst) do
        # hprint("=0\n")
        a <= 0
        b <= 0
        sfor(0..19) do
            a <= a + 1
            # hprint("=1 a=",a,"\n")
            sif(a % 4) { scontinue }
            b <= b + 1
            # hprint("=2 b=",b,"\n")
        end
        # hprint("=3 a=",a," b=",b,"\n")
    end


    bit[16][-8].inner buf: 8.times.map {|i| i.to_expr.as(bit[16]) }
    [16].inner :res1
    # [8].inner :idx

    sequencer(clk.posedge,rst) do
        res1 <= 0
        # hprint("$0 res1=",res1,"\n")
        buf.seach do |elem|
            res1 <= elem * elem
            # hprint("$1 elem=",elem," res1=",res1,"\n")
        end
        # hprint("$2 res1=",res1,"\n")
    end

    [32].inner :res2

    sequencer(clk.posedge,rst) do
        res2 <= 0
        # hprint("%0 res2=",res2,"\n")
        (_h00000000.._h00000007).seach do |elem|
            res2 <= elem * elem
            # hprint("%1 elem=",elem," res2=",res2,"\n")
        end
        # hprint("%2 res2=",res2,"\n")
    end

    [32].inner :res3

    sequencer(clk.posedge,rst) do
        res3 <= 0
        # hprint("&0 res3=",res3,"\n")
        5.supto(10).with_index do |elem,idx|
            res3 <= [elem[15..0],idx[15..0]]
            # hprint("&1 elem=",elem," idx=",idx," res3=",res3,"\n")
        end
        # hprint("&2 res3=",res3,"\n")
    end

    bit[8][-8].inner ar0: [_h01,_h02,_h04,_h08, _h10,_h20,_h40,_h80]
    bit[8][-8].inner ar1: [_h01,_h02,_h03,_h04, _h05,_h06,_h07,_h08]
    bit[8][-8].inner :res4

    sequencer(clk.posedge,rst) do
        sfor(ar0) do |elem,idx|
            res4[idx] <= elem + ar1[idx]
        end
        # hprint("res4=",res4,"\n")
    end

    [8].inner :res5

    sequencer(clk.posedge,rst) do
        res5 <= 0
        # hprint("(0 res5=",res5,"\n")
        (ar0.seach + ar1).seach do |elem|
            res5 <= elem
            # hprint("(1 res5=",res5,"\n")
        end
        # hprint("(2 res5=",res5,"\n")
    end


    [32].inner :res6

    sequencer(clk.posedge,rst) do
        res6 <= 0
        # hprint(")0 res6=",res6,"\n")
        10.sdownto(1) do |elem|
            res6 <= elem
            # hprint(")1 res6=",res6,"\n")
        end
        # hprint(")2 res6=",res6,"\n")
    end

    [8].inner :res7,:res8

    sequencer(clk.posedge,rst) do
        res7 <= 0
        res8 <= 0
        ar0.seach_range(0..3) do |elem|
            res7 <= elem
        end
        ar0.seach_range(4..9) do |elem|
            res7 <= elem
        end
        (_h00.._h07).seach_range(1..4) do |elem|
            res8 <= elem
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
