# A system for testing the clock generator.
system :with_clocks do
    inner :clk, :rst
    [8].inner :cnt1, :cnt2, :cnt3, :cnt4, :cnt5
    [8].inner :cnta, :cntb, :cntc, :cntd

    configure_clocks(rst)

    (cnt1 <= cnt1 + 1).at(clk.posedge)
    (cnt2 <= cnt2 + 1).at(clk.posedge*2)
    (cnt3 <= cnt3 + 1).at(clk.posedge*3)
    (cnt4 <= cnt4 + 1).at(clk.posedge*4)
    (cnt5 <= cnt5 + 1).at(clk.posedge*5)

    configure_clocks(nil)

    (cnta <= cnta + 1).at(clk.posedge*2)
    (cntb <= cntb + 1).at(clk.posedge*3)
    (cntc <= cntc + 1).at(clk.posedge*4)
    (cntd <= cntd + 1).at(clk.posedge*5)

    timed do
        clk <= 0
        rst <= 0
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        rst <= 1
        cnt1 <= 0; cnt2 <= 0; cnt3 <= 0; cnt4 <= 0; cnt5 <= 0
        cnta <= 0; cntb <= 0; cntc <= 0; cntd <= 0
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        rst <= 0
        repeat(100) do
            !10.ns
            clk <= ~clk
        end
    end
end
