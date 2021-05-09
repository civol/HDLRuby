# Test the execution of multiple timed behaviors
system :multi_timed do
    inner :clk1, :clk2, :rst, :button
    [8].inner :counter1, :counter2 

    # The process controlling counter1.
    par(clk1.posedge) do
        hif(rst) { counter1 <= 0 }
        helsif(button) { counter1 <= counter1 + 1 }
    end

    # The process controlling counter2.
    par(clk2.posedge) do
        hif(rst) { counter2 <= 0 }
        helsif(button) { counter2 <= counter2 + 1 }
    end

    # The process for clk1
    timed do
        50.times do
            clk1 <= 0
            !10.ns
            clk1 <= 1
            !10.ns
        end
    end

    # The process for clk2
    timed do
        80.times do
            clk2 <= 0
            !3.ns
            clk2 <= 1
            !3.ns
        end
    end

    # The control process
    timed do
        rst <= 0
        button <= 0
        !10.ns
        rst <= 1
        !20.ns
        rst <= 0
        !10.ns
        10.times do
            button <= 1
            !20.ns
            button <= 0
            !20.ns
        end
    end
end
