require 'HDLRuby'

configure_high

# An adder-suber
system :addsub do
    input  :opr
    [15..0].input :x,:y
    [16..0].output :s

    # The only adder instance.
    instance :add do
        [15..0].input :x,:y
        input :cin
        [16..0].output :s

        s <= x+y+cin
    end

    # Control part for choosing between add and sub.
    hif(opr) { add.(x,~y,1,s) }
    helse    { add.(x,y,0,s) }
end


# Instantiate it for checking.
addsub :addsubI

# Generate the low level representation.
low = addsubI.systemT.to_low

# Displays it
puts low.to_yaml
