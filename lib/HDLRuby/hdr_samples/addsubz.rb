# An extended adder-suber
system :addsubz do
    [1..0].input  :opr
    [15..0].input :x,:y
    [16..0].output :s

    # The only adder instance.
    instance :add do
        [15..0].input :x,:y
        input :cin
        [16..0].output :s
        
        s <= x+y+cin
    end

    # The control part for choosing between 0, add, sub and neg.
    hcase(opr)
    hwhen(0) { add.(0,0,0,s) }
    hwhen(1) { add.(x,y,0,s) }
    hwhen(2) { add.(x,~y,1,s) }
    helse    { add.(0,~y,1,s) }
end
