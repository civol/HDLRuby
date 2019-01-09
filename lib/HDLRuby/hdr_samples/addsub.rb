# An adder-suber
system :addsub do
    [2..0].input  :opr
    [15..0].input :x,:y
    [16..0].output :s

    # The only adder instance.
    instance :adder do
        input :cin
        [15..0].input :x,:y
        [16..0].output :s
        
        s <= x+y+cin
    end

    def add(x,y,cin=0)
        adder.x <= x
        adder.y <= y
        adder.cin <= cin
        adder.s
    end


    # Some computation.
    hcase(opr)
    hwhen(0) { s <= add(0,0) }
    hwhen(1) { s <= add(x,y) }
    hwhen(2) { s <= add(x,~y,1) }
    helse    { s <= add(0,~y,2) }
end
