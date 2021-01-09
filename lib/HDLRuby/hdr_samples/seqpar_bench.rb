# require "../hruby_low2c.rb"



# A system for testing the execution of par block in seq block.
system :seqpar_bench do

    inner :rst, :clk
    signed[8].inner :a, :b, :c, :d
    signed[8].inner :out

    seq(clk.posedge) do
        hif(rst) do
            a <= 0
            b <= 0
            c <= 0
            d <= 0
        end
        helse do
            a <= a + 1
            b <= a + 2
            par do
                c <= b + 3
                d <= c + 4
            end
            a <= d + 5
        end
    end

    out <= a

    timed do
        clk <= 0
        rst <= 0
        !20.ns
        clk <= 1
        !20.ns
        clk <= 0
        rst <= 1
        !20.ns
        clk <= 1
        !20.ns
        clk <= 0
        rst <= 0
        !20.ns
        clk <= 1
        !20.ns
        clk <= 0
        !20.ns
        clk <= 1
        !20.ns
        clk <= 0
        !20.ns
        clk <= 1
        !20.ns
        clk <= 0
        !20.ns
    end
end
