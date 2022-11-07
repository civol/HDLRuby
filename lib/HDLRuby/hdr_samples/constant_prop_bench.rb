# A simple counter
system :counter do
    input :clk, :rst
    [8].input  :inc
    [8].output :count

    par(clk.posedge) do
        hif(rst) { count <= 0 }
        helse    { count <= count + inc }
    end
end

# A benchmark for the counter using a constant as the inc input.
system :dff_bench do
    inner :clk, :rst
    [8].inner :count
    [8].constant inc: 5

    # counter(:my_counter).(clk,rst,inc,count)
    counter(:my_counter).(clk,rst,5,count)

    # par do
    #     my_counter.inc <= 5
    #     count <= my_counter.count
    # end

    timed do
        clk <= 0
        rst <= 0
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
        !10.ns
        clk <= 0
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        !10.ns
        clk <= 1
        !10.ns
    end
end
