# Sample for testing advanced expressions with fixpoint.

system :with_fixpoint_adv do
    inner :clk,:rst
    signed[8,8].inner :x,:y,:z,:u,:v,:w,:a,:b,:c,:d
    bit.inner :cmp

    cmp <= (x >= y)
    u   <= (x >= y)

    sequencer(clk,rst) do
        hif(5>4) { w <= _hFFFF }
        helse    { w <= _h0000 }
        swhile(w<_h0000) do
            hif(5>6) { w <= _hFFFF }
            helse    { w <= _h0000 }
        end
        5.stimes do
            x <= _h0100
            y <= _hFF34
            a <= _h0100
            b <= _h0100
            c <= _h0100
            step
            x <= x*a
            hif(x>=y) { z <= _hFFFF }
            helse     { z <= _h0000 }
            v <= mux(x>=y,_h0000,_hFFFF)
            hif(10>0) { w <= _hFFFF }
            helse     { w <= _h0000 }
            d <= a*b*c
            step
            x <= _h0000
            x <= x*a
            y <= _hFE68
            hif(x>=y) { z <= _hFFFF }
            helse     { z <= _h0000 }
            v <= mux(x>=y,_h0000,_hFFFF)
            hif(1>20) { w <= _hFFFF }
            helse     { w <= _h0000 }
            a <= _h0200
            d <= a*b*c
            step
            x <= _hFE00
            x <= x*a
            y <= _hFE02
            hif(x>=y) { z <= _hFFFF }
            helse     { z <= _h0000 }
            v <= mux(x>=y,_h0000,_hFFFF)
            b <= _h0200
            d <= a*b*c
        end
    end

    def cstep(n=1)
        n.times do
            clk <= ~clk
            !10.ns
        end
    end

    timed do
        clk <= 0
        rst <= 0
        !10.ns
        cstep(2)
        rst <= 1
        cstep(2)
        rst <= 0
        cstep(40)
    end
    
end
