require 'HDLRuby'

configure_high


# A simple 16-bit adder
system :add do
    [15..0].input :x,:y
    [16..0].output :s

    s <= x + y
end

# Instantiate it for checking.
add :addI

# Generate the low level representation.
low = addI.to_low

# Displays it
puts low.to_yaml
