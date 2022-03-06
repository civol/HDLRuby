# Testing HDLRuby unit test.
# require 'std/hruby_unit.rb' 

# Declare multiple simple dff-systems and their corresponding test.

3.times do |i|

    # A simple D-FF
    system :"dff#{i}" do
        input :clk, :rst, :d
        output :q, :qb

        qb <= ~q

        par(clk.posedge) { q <= d & ~rst }
    end

    # Code for testing it.
    Unit.system :"test_dff#{i}" do
        inner :clk, :rst, :d, :q, :qb

        send(:"dff#{i}",:dffI).(clk,rst,d,q,qb)

        test do
            clk <= 0
            rst <= 0
            d   <= 0
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
            d   <= 1
            !10.ns
            clk <= 1
            !10.ns
            clk <= 0
            d   <= 0
            !10.ns
            clk <= 1
            !10.ns
        end
    end
end

