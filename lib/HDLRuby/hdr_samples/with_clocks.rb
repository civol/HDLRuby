# A system for testing the clock generator.
system :with_clocks do
    inner :clk
    [8].inner :cnt1, :cnt2, :cnt3, :cnt4

    (cnt1 <= cnt1 + 1).at(clk.posedge)
    (cnt2 <= cnt1 + 1).at(clk.posedge*2)
    (cnt3 <= cnt1 + 1).at(clk.posedge*3)
    (cnt4 <= cnt1 + 1).at(clk.posedge*4)

    timed do
        clk <= 0
        cnt1 <= 0; cnt2 <= 0; cnt3 <= 0; cnt4 <= 0
        repeat(100) do
            !10.ns
            clk <= ~clk
        end
    end
end
