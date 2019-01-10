require 'HDLRuby'

configure_high

# An adder-suber
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
    hif(opr) { add.(x,~y,1,s) }
    helse    { add.(x,y,0,s) }
end


# Instantiate it for checking.
addsub :addsubI

# Generate the low level representation.
low = addsubI.systemT.to_low

# Displays it
puts low.to_yaml
