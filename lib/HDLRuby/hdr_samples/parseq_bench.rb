# Check of various par and seq.

# A benchmark for the dff.
system :parseq_bench do
    [4].inner :x0, :x1, :x2, :x3
    [4].inner :y0, :y1, :y2, :y3
    [4].inner :z00, :z01
    [4].inner :z10, :z11
    [4].inner :z20, :z21
    [4].inner :z30, :z31
    [4].inner :u0, :u1, :u2, :u3
    bit[4][-16].constant mem: 16.times.to_a

    par(x0) do
        z00 <= x0 + y0
        z01 <= z00 + 1
        u0 <= mem[z00]
    end

    seq(y1) do
        z10 <= x1 + y1
        z11 <= z10 + 1
        u1 <= mem[z10]
    end

    seq(x2,y2) do
        z20 <= x2 + y2
        z21 <= z20 + 1
        u2 <= mem[z20]
    end

    par do
        bit[4].constant inc: 1
        z30 <= x3 + y3
        z31 <= z30 + inc
        u3 <= mem[z30]
    end


    timed do
        x0 <= 1
        x1 <= 1
        x2 <= 1
        x3 <= 1
        !10.ns
        y0 <= 2
        y1 <= 2
        y2 <= 2
        y3 <= 2
        !10.ns
        x0 <= 3
        x1 <= 3
        x2 <= 3
        x3 <= 3
        y0 <= 4
        y1 <= 4
        y2 <= 4
        y3 <= 4
        !10.ns
    end
end
