# require "../hruby_low2c.rb"

# An 8-bit register with C encrypting.
system :encrypt_register do
    input  :clk, :rst
    [8].input :d
    [8].output :q

    code clk.posedge, c: [ "
#include <stdio.h>
#include \"hruby_sim.h\"
#include \"hruby_sim_gen.h\"

void encrypt() {
    static char keys[] = { 'S', 'e', 'c', 'r', 'e', 't', ' ', '!' };
    static int index  = 0;
    char buf;
    buf = read8(",d,");
    printf(\"######################## From software: encrypting d=%x\\n\",buf);
    buf = buf ^ (keys[index]);
    index = (index + 1) & sizeof(keys)-1;
    printf(\"######################## From software: result =%x\\n\",buf);
    write8(buf,",q,");
    
}
        " ],
        sim: "encrypt"
end

# A benchmark for the register.
system :encrypt_bench do
    [8].inner :d, :clk, :rst
    [8].inner :q

    encrypt_register(:my_register).(clk,rst,d,q)

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
