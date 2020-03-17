require 'HDLRuby'

configure_high

# Describes a system including several value.
system :values do
    [3..0].output :sig

    timed do
        !1.us
        sig <= _1010
        !1.us
        sig <= _b4b1010
        !1.us
        sig <= _bb1001
        !1.us
        sig <= _b1100

        !1.us
        sig <= _u4b1010
        !1.us
        sig <= _ub1001
        !1.us
        sig <= _u1100

        !1.us
        sig <= _s4b1010
        !1.us
        sig <= _sb1001
        !1.us
        sig <= _s1100

        !1.us
        sig <= _b12o0623
        !1.us
        sig <= _bo0623
        !1.us
        sig <= _b12d0923
        !1.us
        sig <= _bd0923
        !1.us
        sig <= _b16h0F2E
        !1.us
        sig <= _bh0F2E

        !1.us
        sig <= _b1ZZX

        !1.us
        sig <= _b8bxxxx

        !1.us
        sig <= _b0110 + _b0110
        !1.us
        sig <= _b0110 - _b0110
        !1.us
        sig <= _b0110 * _b0010
        !1.us
        sig <= _b0110 / _b0010
        !1.us
        sig <= _b0110 % _b0010
    end
end


# Instantiate it for checking.
values :valuesI

# Generate the low level representation.
low = valuesI.systemT.to_low

# Displays it
puts low.to_yaml
