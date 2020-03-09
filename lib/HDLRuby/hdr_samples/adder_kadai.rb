system :adder do
    [4].input :a,:b
    [4].output :x
    output :carry

    [x,carry] <= a+b
end
