require 'std/loop.rb'

include HDLRuby::High::Std

system :with_loop do

    # The clock and reset
    inner :clk, :rst
    # The running signal.
    inner :run
    # The signal to check for finishing.
    inner :over

    # A counter.
    [4].inner :count

    # The loop
    lp = while_loop(clk, proc {count<=0}, count<15) { count <= count + 1 }

    par(clk.negedge) do
        over <= 0
        hif(run) { lp.run() }
        lp.finish() { over <= 1 }
    end

    timed do
        run <= 0
        clk <= 0
        !10.ns
        clk <= 1
        run <= 1
        !10.ns
        20.times do
            clk <= 0
            !10.ns
            clk <= 1
            !10.ns
        end
    end
end
