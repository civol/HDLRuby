
system :four2eight do
    [4].input :four
    output :o0, :o1, :o2, :o3, :o4, :o5, :o6, :o7

    o0 <= four[0]; o1 <= four[1]; o2 <= four[2]; o3 <= four[3]
    o4 <= four[0]; o5 <= four[1]; o6 <= four[2]; o7 <= four[3]
end

system :four2sixfour do
    [4].input :four
    output :o00, :o01, :o02, :o03, :o04, :o05, :o06, :o07,
           :o08, :o09, :o0A, :o0B, :o0C, :o0D, :o0E, :o0F,
           :o10, :o11, :o12, :o13, :o14, :o15, :o16, :o17,
           :o18, :o19, :o1A, :o1B, :o1C, :o1D, :o1E, :o1F,
           :o20, :o21, :o22, :o23, :o24, :o25, :o26, :o27,
           :o28, :o29, :o2A, :o2B, :o2C, :o2D, :o2E, :o2F,
           :o30, :o31, :o32, :o33, :o34, :o35, :o36, :o37,
           :o38, :o39, :o3A, :o3B, :o3C, :o3D, :o3E, :o3F


    o00 <= four[0]; o01 <= four[1]; o02 <= four[2]; o03 <= four[3]
    o04 <= four[0]; o05 <= four[1]; o06 <= four[2]; o07 <= four[3]
    o08 <= four[0]; o09 <= four[1]; o0A <= four[2]; o0B <= four[3]
    o0C <= four[0]; o0D <= four[1]; o0E <= four[2]; o0F <= four[3]
    o10 <= four[0]; o11 <= four[1]; o12 <= four[2]; o13 <= four[3]
    o14 <= four[0]; o15 <= four[1]; o16 <= four[2]; o17 <= four[3]
    o18 <= four[0]; o19 <= four[1]; o1A <= four[2]; o1B <= four[3]
    o1C <= four[0]; o1D <= four[1]; o1E <= four[2]; o1F <= four[3]
    o20 <= four[0]; o21 <= four[1]; o22 <= four[2]; o23 <= four[3]
    o24 <= four[0]; o25 <= four[1]; o26 <= four[2]; o27 <= four[3]
    o28 <= four[0]; o29 <= four[1]; o2A <= four[2]; o2B <= four[3]
    o2C <= four[0]; o2D <= four[1]; o2E <= four[2]; o2F <= four[3]
    o30 <= four[0]; o31 <= four[1]; o32 <= four[2]; o33 <= four[3]
    o34 <= four[0]; o35 <= four[1]; o36 <= four[2]; o37 <= four[3]
    o38 <= four[0]; o39 <= four[1]; o3A <= four[2]; o3B <= four[3]
    o3C <= four[0]; o3D <= four[1]; o3E <= four[2]; o3F <= four[3]
end



# A benchmark for testing some enumarable properties of expression (to_a).
system :with_to_a_bench do
    [4].inner :four
    [8].inner :val, :res, :eight
    [64].inner :val64, :res64, :sixfour

    vals = val.to_a
    val64s = val64.to_a

    four2eight(:my_four2eight).(four,*(eight.to_a.reverse))
    four2sixfour(:my_four2sixfour).(four,*(sixfour.to_a.reverse))

    timed do
        val <= _b01101010
        res <= vals.reverse
        !10.ns
        val64 <= _b0110101001101010011010100110101001101010011010100110101001101010
        res64 <= val64s.reverse
        !10.ns
        val <= _b00000000
        val64 <= _b0000000000000000000000000000000000000000000000000000000000000000
        !10.ns
        vals.each.with_index do |v,i|
            v <= (i/2) & _b1
        end
        res <= val
        !10.ns
        val64s.each.with_index do |v,i|
            v <= (i/2) & _b1
        end
        res64 <= val64
        !10.ns
        val <= _b01010011
        !10.ns
        8.times do |i|
            val64s[i] <= val[i]
            val64s[i+32] <= val[i]
            val64s[i+56] <= val[i]
        end
        res64 <= val64
        !10.ns
        four <= _b0000
        !10.ns
        four <= _b0001
        !10.ns
        four <= _b1100
        !10.ns
    end
end
