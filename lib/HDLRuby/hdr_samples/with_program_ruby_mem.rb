
# A benchmark for testing the use of Ruby software code.
system :with_ruby_prog_mem do
    inner :clk, :req, :rwb
    [8].inner :addr, :index, :count, :data

    # This is actually a CPU embedded memory.
    program(:ruby,:mem) do
        actport clk.posedge
        inport  addr: addr
        inport  rwb:  rwb
        inport  din:  count
        outport dout: data
        code "sw_inc_mem.rb"
    end

    # This is real software.
    program(:ruby,:inc_mem) do
        actport req.posedge
        inport  index: index
        code "sw_inc_mem.rb"
    end


    timed do
        clk   <= 0
        addr  <= 0
        index <= 0
        req   <= 0
        count <= 0
        rwb   <= 0
        !10.ns
        req <= 1
        !10.ns
        repeat(10) do
            clk   <= 1
            req   <= 0
            !10.ns
            req   <= 1
            clk   <= 0
            count <= count + 2
            addr  <= addr + 1
            !10.ns
            index <= index + 1
        end
        !10.ns
        addr <= 0
        clk  <= 0
        rwb  <= 1
        repeat(10) do
            !10.ns
            clk  <= 1
            !10.ns
            clk  <= 0
            addr <= addr + 1
        end
    end
end
