# A simple generic adder
system :adder do |w|
    [(w-1)..0].input :x,:y
    [w..0].output :s

    s <= x.as(bit[w+1]) + y
end


# Testing the generic adder.
system :adder_bench do
    width = 4
    [width].inner :x,:y
    [width+1].inner :z

    adder(width).(:my_adder).(x,y,z)

    timed do
        x <= 0
        y <= 0
        !10.ns
        x <= 1
        !10.ns
        y <= 1
        !10.ns
        x <= 15
        !10.ns
    end
end
