require "std/fixpoint.rb"

include HDLRuby::High::Std



# System for testing the fixed point library.
system :fix_test do

    # Declare three 4-bit integer part 4-bit fractional part
    bit[3..0,3..0].inner :x,:y,:z
    # Declare three 8-bit integer part 8-bit fractional part
    signed[3..0,3..0].inner :a,:b,:c,:d

    # Performs calculation between then
    timed do
        # x <= _00110011 # 3.1875
        x <= 3.1875.to_fix(4)
        y <= _01000000 # 4
        !10.ns
        z <= x + y
        !10.ns
        z <= x * y
        !10.ns
        z <= z / x
        !10.ns
        a <= _00010000
        b <= _00001111
        !10.ns
        c <= a * b
        d <= 0
        !10.ns
        d <= d + c 
        !10.ns
        a <= -0.375.to_fix(4)
        b <= 1.625.to_fix(4)
        !10.ns
        c <= a * b
        !10.ns
        # a <= _00010000
        # b <= _00010101
        a <= _0000111x
        b <= _1110011x
        !10.ns
        # a <= a & _11111110
        # b <= b | _00000001
        a <= a | _00000001
        b <= b | _00000001
        !10.ns
        c <= a * b
        !10.ns
    end
end
