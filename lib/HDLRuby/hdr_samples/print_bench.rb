##
# A simple system for testing hw print and strings.
######################################################

system :with_print do
    input  :clk, :rst
    [4].output :counter

    seq(clk.posedge) do
        hif(rst) do
            counter <= 0
        end
        helse do
            counter <= counter + 1
            hprint("In '#{__FILE__}' line #{__LINE__}: ")
            hprint("Counter=", counter, "\n")
        end
    end
end

# A benchmark for the dff.
system :with_print_bench do
    inner :clk, :rst
    [4].inner :counter

    with_print(:my_print).(clk,rst,counter)

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


    cur_system.properties[:pre_driver] = "drivers/hw_print.rb", :hw_print_generator
end
