# A simple 16-bit adder
system :adder do
    [15..0].input :x,:y
    [16..0].output :s

    s <= x + y
end

# A benchmark for the adder.
system :adder_bench do
    [15..0].inner :x,:y
    [16..0].inner :s

    adder(:my_adder).(x,y,s)

    timed do
        x <= 0
        y <= 0
        !10.ns
        x <= 1
        y <= _zzzzzzzzzzzzzzzz
        !10.ns
        x <= 2
        y <= 1
        !10.ns
    end
end
