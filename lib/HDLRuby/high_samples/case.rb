require 'HDLRuby'

configure_high


# A simple decoder for testing the case statement.
system :decoder do
    [3..0].input :x
    [7..0].output :s

    par do
        hcase(x)
        hwhen(0) { s <= 1 }
        hwhen(1) { s <= 2 }
        hwhen(2) { s <= 4 }
        hwhen(3) { s <= 8 }
        hwhen(4) { s <= 16 }
        hwhen(5) { s <= 32 }
        hwhen(6) { s <= 64 }
        hwhen(7) { s <= 128 }
        helse    { s <= 0 }
    end
end

# Instantiate it for checking.
decoder :decoderI

# Generate the low level representation.
low = decoderI.to_low

# Displays it
puts low.to_yaml
