require "std/fixpoint.rb"

include HDLRuby::High::Std



# System for testing the fixed point library.
system :fix_test do

    # Declare three 4-bit integer part 4-bit fractional part
    bit[3..0,3..0].inner :x,:y,:z
    # Declare three 8-bit integer part 8-bit fractional part
    signed[3..0,3..0].inner :a,:b,:c,:d
    # Declare the comparison results.
    bit.inner :cmpU, :cmpS

    cmpU <= (x >= y)
    cmpS <= (a >= b)


    # Performs calculation between then
    timed do
        # x <= _b00110011 # 3.1875
        x <= 3.1875.to_fix(4)
        y <= _b01000000 # 4
        !10.ns
        z <= x + y
        !10.ns
        z <= x * y
        !10.ns
        z <= z / x
        !10.ns
        a <= _b00010000
        b <= _b00001111
        !10.ns
        c <= a * b
        d <= 0
        !10.ns
        d <= d + c 
        !10.ns
        d <= d / c
        !10.ns
        d <= d / 3.to_fix(4)
        !10.ns
        d <= 1.to_fix(4) - d
        !10.ns
        d <= -d
        !10.ns
        d <= d * 3.to_fix(4)
        !10.ns
        d <= -d
        !10.ns
        a <= -0.375.to_fix(4)
        b <= 1.625.to_fix(4)
        !10.ns
        c <= a * b
        !10.ns
        # a <= _b00010000
        # b <= _b00010101
        a <= _sb0000111x
        b <= _sb1110011x
        !10.ns
        # a <= a & _b11111110
        # b <= b | _b00000001
        a <= a | _b00000001
        b <= b | _b00000001
        !10.ns
        c <= a * b
        !10.ns
        c <= (a+b) * b
    end
end
