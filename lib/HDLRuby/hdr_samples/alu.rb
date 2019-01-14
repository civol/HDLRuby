# A simple ALU
system :alu do
    [4].input  :opr
    [16].input :x,:y
    [16].output :s
    output :zf, :cf, :sf, :vf

    # The only adder instance.
    instance :add do
        [16].input :x,:y
        input :cin
        [17].output :s
        
        s <= x+y+cin
    end

    # The control part for choosing between 0, add, sub and neg.
    par do
        # The main computation: s and cf
        # Default connections
        cf <= 0
        vf <= 0
        add.(0,0,0)
        # Depending on the operator
        hcase(opr)
        hwhen(1) { s <= x }
        hwhen(2) { s <= y }
        hwhen(3) { add.(x ,y ,0,[cf,s])
                   vf <= (~x[15] & ~y[15] & s[15]) | (x[15] & y[15] & ~s[15]) }
        hwhen(4) { add.(x ,~y,1,[cf,s])
                   vf <= (~x[15] & y[15] & s[15]) | (x[15] & ~y[15] & ~s[15]) }
        hwhen(5) { add.(0 ,~y,1,[cf,s])
                   vf <= (~y[15] & s[15]) }
        hwhen(6) { add.(~x,0 ,1,[cf,s])
                   vf <= (x[15] & ~s[15]) }
        hwhen(7) { s <= x & y }
        hwhen(8) { s <= x | y }
        hwhen(9) { s <= x ^ y }
        hwhen(10){ s <= ~x }
        hwhen(11){ s <= ~y }
        helse    { s <= 0 }

        # The remaining flags.
        zf <= (s == 0)
        sf <= s[15]
    end
end
