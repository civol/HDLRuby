# A simple generic adder
system :adder do |w|
    [(w-1)..0].input :x,:y
    [w..0].output :s

    s <= x + y
end
