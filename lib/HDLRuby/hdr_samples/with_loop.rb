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

    par(clk.posedge) do
        # over <= 0
        hif(doit0) { lp0.run }
        lp0.finish { doit0 <= 0; doit1 <= 1 }
        hif(doit1) { lp1.run }
        lp1.finish { over <= 1; doit1 <= 0 }
        # Second pass.
        hif(over)  { lp0.run }
    end

    timed do
        doit0 <= 0
        clk <= 0
        count2 <= 0
        over <= 0
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        !10.ns
        clk <= 1
        doit0 <= 1
        !10.ns
        64.times do
            clk <= 0
            !10.ns
            clk <= 1
            !10.ns
        end
    end
end
