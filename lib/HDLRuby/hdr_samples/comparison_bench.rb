# Test the comparison operators.

# A benchmark for the comparators.
system :comparison_bench do
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

    [128].inner :xL
    [96].inner :yL
    signed[128].inner :uL
    signed[96].inner :vL
    inner :ueL, :ultL, :uleL, :ugtL, :ugeL
    inner :seL, :sltL, :sleL, :sgtL, :sgeL

    par do
        ueL  <= (xL == yL)
        ultL <= (xL < yL)
        uleL <= (xL <= yL)
        ugtL <= (xL > yL)
        ugeL <= (xL >= yL)

        seL  <= (uL == vL)
        sltL <= (uL < vL)
        sleL <= (uL <= vL)
        sgtL <= (uL > vL)
        sgeL <= (uL >= vL)
    end

    [8].inner :xND
    [96].inner :yND
    signed[8].inner :uND
    signed[128].inner :vND
    inner :ueND, :ultND, :uleND, :ugtND, :ugeND
    inner :seND, :sltND, :sleND, :sgtND, :sgeND

    par do
        ueND  <= (xND == yND)
        ultND <= (xND < yND)
        uleND <= (xND <= yND)
        ugtND <= (xND > yND)
        ugeND <= (xND >= yND)

        seND  <= (uND == vND)
        sltND <= (uND < vND)
        sleND <= (uND <= vND)
        sgtND <= (uND > vND)
        sgeND <= (uND >= vND)
    end


    timed do
        x <= 0
        y <= 0
        u <= 0
        v <= 0
        xL <= 0
        yL <= 0
        uL <= 0
        vL <= 0
        xND <= 0
        yND <= 0
        uND <= 0
        vND <= 0
        !10.ns
        x <= 1
        u <= 1
        xL <= 2**80 - 1
        uL <= 2**80 - 1
        xND <= 1
        uND <= 1
        !10.ns
        y <= 2
        v <= 2
        yL <= 2**81 - 1
        vL <= 2**81 - 1
        yND <= 2
        vND <= 2
        !10.ns
        x <= 3
        u <= 3
        xL <= 2**81 + 2**80 - 1
        uL <= 2**81 + 2**80 - 1
        xND <= 3
        uND <= 3
        !10.ns
        x <= 2
        u <= -2
        xL <= 2**81 - 1
        uL <= -2**81 + 1
        xND <= 2
        uND <= -2
        !10.ns
    end
end
