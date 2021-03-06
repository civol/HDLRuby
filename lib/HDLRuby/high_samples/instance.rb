require 'HDLRuby'

configure_high


# A simple 16-bit or
system :or16 do
    [15..0].input :x,:y
    [16..0].output :s

    s <= x | y
end

# A 32-bit or made of two 16-bit ones.
system :or32 do
    [31..0].input :x,:y
    [32..0].output :s

    or16 :or0

    or0.x <= x[15..0]
    or0.y <= y[15..0]
    s[15..0] <= or0.s[15..0]

    or16(:or1).(x[31..16],y[31..16])

    s[31..16] <= or1.s[31..16]
end

# Instantiate it for checking.
or32 :or32I

# Generate the low level representation.
low = or32I.systemT.to_low

# Displays it
puts low.to_yaml
