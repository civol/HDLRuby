# require "../hruby_low2c.rb"

# A generic register with C printing the data to the standard output.
system :register do |size|
    input  :clk, :rst
    [size].input :d
    [size].output :q

    (q <= d & ~rst).at(clk.posedge)

    code clk.posedge, c: [ '
#include <stdio.h>
#include "hruby_sim.h"
#include "hruby_sim_gen.h"

void show() {
    printf("######################## From software q=");
    print_value(',q,');
    printf("\n");
}
        ' ],
        sim: "show"
end

# A benchmark for the register.
system :register_bench do
    [8].inner :d, :clk, :rst
    [8].inner :q

    register(8).(:my_register).(clk,rst,d,q)

    timed do
        clk <= 0
        rst <= 0
        d   <= 0
        !10.ns
        clk <= 1
        rst <= 0
        d   <= 0
        !10.ns
        clk <= 0
        rst <= 1
        d   <= 0
        !10.ns
        clk <= 1
        rst <= 1
        d   <= 0
        !10.ns
        clk <= 0
        rst <= 0
        d   <= 1
        !10.ns
        clk <= 1
        rst <= 0
        d   <= 1
        !10.ns
        clk <= 0
        rst <= 0
        d   <= 2
        !10.ns
        clk <= 1
        rst <= 0
        d   <= 2
        !10.ns
        clk <= 0
        rst <= 0
        d   <= 0
        !10.ns
        clk <= 1
        rst <= 0
        d   <= 255
        !10.ns
        clk <= 0
        rst <= 0
        d   <= 255
        !10.ns
        clk <= 1
        rst <= 0
        d   <= 255
        !10.ns
        clk <= 0
        rst <= 0
        d   <= 0
        !10.ns
        clk <= 1
        rst <= 0
        d   <= 0
        !10.ns
        clk <= 0
        rst <= 0
        d   <= 0
        !10.ns
        clk <= 1
        rst <= 0
        d   <= 0
        !10.ns
    end
end
