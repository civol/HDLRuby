typedef(:some_struct) do
    { sub2: bit, sub3: bit[2] }
end

system :my_system do
    inner :x
    [3].inner :y
    inner :z
    { sub0: bit, sub1: bit[2]}.inner :sigA
    some_struct.inner :sigB, :sigC
    # { sub4: bit[8], sub5: bit[8] }.to_type[-2].inner :sigs
    { sub4: bit[8][-2], sub5: bit[8][-2] }.inner :sigs

    sigC <= sigA

    par(sigA) { z <= ~z }


    timed do
        # z <= 0
        # x <= 1
        # y <= _b000

        # sigs[0].sub4 <= 1
        # sigs[0].sub5 <= 2
        # sigs[1].sub4 <= 3
        # sigs[1].sub5 <= 4
        sigs.sub4[0] <= 1
        sigs.sub5[0] <= 2
        sigs.sub4[1] <= 3
        sigs.sub5[1] <= 4

        !10.ns
        sigA.sub0 <= 0
        sigA.sub1 <= x
        sigB.sub2 <= 0
        sigB.sub3 <= x
        !10.ns
        sigA.sub0 <= x
        sigA.sub1 <= ~sigB.sub3
        sigB.sub2 <= x
        sigB.sub3 <= ~sigA.sub1
        !10.ns
        sigA <= _b111
        sigB <= _b111
        !10.ns
        sigA <= _b100
        !10.ns
        y <= sigA
        sigB <= sigA
        !10.ns
        sigA <= _b011
        !10.ns
        sigB <= sigA
        !10.ns
        sigB <= sigA + 1
        !10.ns
    end

end
