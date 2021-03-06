require 'HDLRuby'

configure_high


# A simple 16-bit adder with an error
system :adder do
    [15..0].input :x,:y
    [16..0].output :s

    seq do
       s = x + y
    end
end

# Instantiate it for checking.
adder :adderI

# Generate the low level representation.
low = adderI.systemT.to_low

# Displays it
puts low.to_yaml
