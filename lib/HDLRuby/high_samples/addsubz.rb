require 'HDLRuby'

configure_high

# An extended adder-suber
system :addsub do
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


    # Some computation.
    hcase(opr)
    hwhen(0) { add.(0,0,0,s) }
    hwhen(1) { add.(x,y,0,s) }
    hwhen(2) { add.(x,~y,1,s) }
    helse    { add.(0,~y,1,s) }
end


# Instantiate it for checking.
addsub :addsubI

# Generate the low level representation.
low = addsubI.systemT.to_low

# Displays it
puts low.to_yaml
