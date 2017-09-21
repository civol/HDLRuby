require 'HDLRuby'

configure_high


# A simple 16-bit comparer
system :comparer do
    [15..0].input :x,:y
    output :s

    s <= (x < y)
end

# Instantiate it for checking.
comparer :comparerI

# Generate the low level representation.
low = comparerI.to_low

# Displays it
puts low.to_yaml
