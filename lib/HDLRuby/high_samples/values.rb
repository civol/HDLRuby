require 'HDLRuby'

configure_high

# Describes a system including several value.
system :values do
    output :sig

    timed do
        !1.us
        sig <= b4b1010
        !1.us
        sig <= bb1001
        !1.us
        sig <= b1100

        !1.us
        sig <= u4b1010
        !1.us
        sig <= ub1001
        !1.us
        sig <= u1100

        !1.us
        sig <= s4b1010
        !1.us
        sig <= sb1001
        !1.us
        sig <= s1100

        !1.us
        sig <= b12o0623
        !1.us
        sig <= bo0623
        !1.us
        sig <= b12d0923
        !1.us
        sig <= bd0923
        !1.us
        sig <= b16h0F2E
        !1.us
        sig <= bh0F2E
    end
end


# Instantiate it for checking.
values :valuesI
