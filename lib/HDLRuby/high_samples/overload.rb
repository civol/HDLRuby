require 'HDLRuby'

configure_high


# A 16-bit type with overloaded addition (saturated addition).
[15..0].typedef(:sat16)
sat16.define_operator(:+) do |left,right|
    [16..0].inner :res
    [15..0].inner :tmp
    seq do
        tmp <= left
        res <= tmp + right
        hif (res[16]) { res <= 0xFFFF }
    end
    res
end

# A simple 16-bit adder
system :adder do
    sat16.input :x,:y
    [15..0].output :s

    s <= x + y
end

# Instantiate it for checking.
adder :adderI

# Generate the low level representation.
low = adderI.systemT.to_low

# Displays it
puts low.to_yaml
