require 'HDLRuby'

configure_high


def hello_out
    puts "hello_out"
end

# A system for testing functions
system :conditionals do
    [15..0].input :x,:y
    [15..0].output :s

    hello_out

    def hello_in
        puts "hello_in"
        s <= x + y
    end

    hello_in
end

hello_out

# Instantiate it for checking.
conditionals :conditionalsI

# Generate the low level representation.
low = conditionalsI.to_low

# Displays it
puts low.to_yaml
