require 'HDLRuby'

configure_high

# Definition of the word type.
[15..0].typedef(:word)


# A simple adder using previously defined type word
system :adder do
    word.input :x,:y
    word.output :s

    s <= x + y
end

# Instantiate it for checking.
adder :adderI

# Generate the low level representation.
low = adderI.to_low

# Displays it
puts low.to_yaml
