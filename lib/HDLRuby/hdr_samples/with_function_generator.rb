require 'std/function_generator.rb'

include HDLRuby::High::Std

# System for testing the function generator standard library.
system :with_function_generator do
    # signed[8].inner :x
    # signed[32].inner :y
    bit[8].inner :x
    signed[8].inner :y

    # function_generator(Math.method(:sin).to_proc,
    #                    signed[8],signed[32],4,-Math::PI..Math::PI,-2..2).
    function_generator(Math.method(:sin).to_proc,
                       bit[8],signed[8],4,-Math::PI..Math::PI,-2..2).
    (:my_sin).(x,y)

    timed do
        # (-128..127).each do |i|
        (0..255).each do |i|
            x <= i
            !10.ns
        end
    end
end
