# A simple 16-bit adder
system :adder do
    [15..0].input :x,:y
    [16..0].output :s

    s <= x + y
end
