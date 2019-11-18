# A simple counter
system :counter do
    input  :clk, :rst
    input :ctrl
    [8].output :q
    output :c

    [8].inner :qq
    inner :cc

    instance :add do
        [8].input :x,:y
        [9].output :z

        z <= x.as([9]) + y
    end


    par do
        add.(q,0)
        hif(rst) { [cc,qq] <= 0 }
        helse do
            add.(q,1,[cc,qq])
            hif(ctrl == 1) { add.(q,-1,[cc,qq]) }
        end
    end

    par(clk.posedge) do
        q <= qq
        c <= cc
    end

end


# A benchmark for the counter.
system :counter_bench do
    inner :clk, :rst
    inner :ctrl
    [8].inner :q
    inner :c

    counter(:my_counter).(clk,rst,ctrl,q,c)

    timed do
        clk <= 0
        rst <= 0
        ctrl <= 0
        !10.ns
        clk <= 1
        rst <= 0
        !10.ns
        clk <= 0
        rst <= 1
        !10.ns
        clk <= 1
        rst <= 1
        !10.ns
        clk <= 0
        rst <= 0
        !10.ns
        clk <= 1
        rst <= 0
        !10.ns
        10.times do
            clk <= 0
            rst <= 0
            !10.ns
            clk <= 1
            rst <= 0
            !10.ns
        end
        ctrl <= 1
        20.times do
            clk <= 0
            rst <= 0
            !10.ns
            clk <= 1
            rst <= 0
            !10.ns
        end
    end
end
