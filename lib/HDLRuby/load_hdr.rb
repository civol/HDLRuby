require 'HDLRuby'

configure_high


# A simple 16-bit adder
system :adder do
    [15..0].input :x,:y
    [16..0].output :s

    s <= x + y

    s = "tot"

    S = "TT"
end

# Instantiate it for checking.
adder :adderI

# Generate the low level representation.
low = adderI.systemT.to_low

# Displays it
puts low.to_yaml
