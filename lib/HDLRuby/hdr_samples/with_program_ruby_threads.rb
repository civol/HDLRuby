
# A benchmark for testing the use of Ruby software code.
system :with_ruby_thread do
    inner :clk, :rst, :req, :ack
    [8].inner :count

    program(:ruby,:boot) do
        actport rst.negedge
        inport  din: count
        outport ack: ack
        code "ruby_program/sw_log.rb"
    end

    program(:ruby,:log) do
        actport req.posedge
        code "ruby_program/sw_log.rb"
    end

    par(ack.posedge) { count <= count + 1 }


    timed do
        clk <= 0
        rst <= 0
        count <= 0
        req <= 0
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
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        !10.ns
        repeat(100) do
            clk <= 1
            req <= 1
            !10.ns
            clk <= 0
            !10.ns
            clk <= 1
            req <= 0
            !10.ns
            clk <= 0
            !10.ns
        end

    end
end
