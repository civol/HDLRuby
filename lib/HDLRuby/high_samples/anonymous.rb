require 'HDLRuby'

configure_high


# A 32-bit or made of two 16-bit ones declared with anonymous system.
system :or32 do
    [31..0].input :x,:y
    [32..0].output :s

    instance :or0 do
        [15..0].input :x,:y
        [16..0].output :s

        s <= x | y
    end

    instance :or1 do
        [15..0].input :x,:y
        [16..0].output :s

        s <= x | y
    end

    or0.x <= x[15..0]
    or0.y <= y[15..0]
    s[15..0] <= or0.s[15..0]

    or1.x <= x[31..16]
    or1.y <= y[31..16]
    s[31..16] <= or0.s[31..16]
end

# Instantiate it for checking.
or32 :or32I

# Generate the low level representation.
low = or32I.systemT.to_low

# Displays it
puts low.to_yaml
