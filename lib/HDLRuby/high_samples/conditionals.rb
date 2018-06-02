require 'HDLRuby'

configure_high


# A system for testing conditionals
system :conditionals do
    [15..0].input :x,:y
    output :s

    par do
        hif x <= y do
            s <= 0
        end
        helse do
            s <= 1
        end
    end

end

# Instantiate it for checking.
conditionals :conditionalsI

# Generate the low level representation.
low = conditionalsI.to_low

# Displays it
puts low.to_yaml
