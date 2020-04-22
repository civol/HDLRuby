require "std/fixpoint.rb"

include HDLRuby::High::Std



# System for testing the fixed point library.
system :fix_test do

    # Declare three 4-bit integer part 4-bit fractional part
    bit[3..0,3..0].inner :x,:y,:z

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
    end
end
