require 'HDLRuby'

configure_high


# A simple 16-bit adder
system :with_change do
    [15..0].input :x,:y
    [16..0].output :s

    behavior x,y do
        s <= x + y
    end
end

# Instantiate it for checking.
with_change :with_changeI

# Generate the low level representation.
low = with_changeI.to_low

# Displays it
puts low.to_yaml
