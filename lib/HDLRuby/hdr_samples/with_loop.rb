require 'std/loop.rb'

include HDLRuby::High::Std

system :with_loop do

    # The clock and reset
    inner :clk, :rst
    # The running signals.
    inner :doit0, :doit1
    # The signal to check for finishing.
    inner :over

    # A counter.
    [8].inner :count, :count2

    # The first loop: basic while.
    lp0 = while_loop(clk, proc{count<=0}, count<15) { count <= count + 1 }

    # The second loop: 10 times.
    lp1 = times_loop(clk,10) { count2 <= count2+2 }
    # Control it using doit1 as req and over as ack.
    rst_req_ack(clk.posedge,rst,doit1,over,lp1)

    par(clk.posedge) do
        doit1 <= 0
        hif(rst) do
            lp0.reset()
            # lp1.reset()
            # doit1 <= 0
            count2 <= 0
            over <= 0
        end
        helse do
            hif(doit0) { lp0.run }
            lp0.finish { doit0 <= 0; doit1 <= 1 }# ; lp1.run }
            hif(doit1) { lp1.run; lp0.reset() }
            # lp1.finish { over <= 1; doit1 <= 0 }
            # Second pass for first loop.
            hif(over)  { lp0.run }
        end
    end

    timed do
        clk <= 0
        rst <= 0
        doit0 <= 0
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
        doit0 <= 1
        !10.ns
        clk <= 1
        !10.ns
        64.times do
            clk <= 0
            !10.ns
            clk <= 1
            !10.ns
        end
    end
end
