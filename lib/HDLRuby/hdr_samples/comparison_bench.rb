# Test the comparison operators.

# A benchmark for the adder.
system :adder_bench do
    [8].inner :x, :y
    signed[8].inner :u,:v
    inner :ue, :ult, :ule, :ugt, :uge
    inner :se, :slt, :sle, :sgt, :sge

    par do
        ue  <= (x == y)
        ult <= (x < y)
        ule <= (x <= y)
        ugt <= (x > y)
        uge <= (x >= y)

        se  <= (u == v)
        slt <= (u < v)
        sle <= (u <= v)
        sgt <= (u > v)
        sge <= (u >= v)
    end

    timed do
        x <= 0
        y <= 0
        u <= 0
        v <= 0
        !10.ns
        x <= 1
        u <= 1
        !10.ns
        y <= 2
        v <= 2
        !10.ns
        x <= 2
        u <= -2
        !10.ns
    end
end
