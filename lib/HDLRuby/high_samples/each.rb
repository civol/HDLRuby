require 'HDLRuby'

configure_high


# A simple test of using each on signals.
system :with_each do
    [15..0].input :x
    [15..0].output :s
    [15..0].inout :y

    x.each.with_index do |b,i|
        s[i] <= b
    end

    y.each_cons(2) do |b0,b1|
        b0 <= b1
    end
end

# Instantiate it for checking.
with_each :with_eachI

# Generate the low level representation.
low = with_eachI.systemT.to_low

# Displays it
puts low.to_yaml
