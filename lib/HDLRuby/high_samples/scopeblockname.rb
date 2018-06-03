require 'HDLRuby'

configure_high


# A system with named scopes and blocks.
system :with_names do
    [15..0].input  :x, :y, :z
    [16..0].output :u, :v

    sub :me do
        inner :a
        a <= x + y
    end

    par do
        inner :a
        a <= me.a * z

        sub :myself do
            inner :a
            a <= y - z
        end
        u <= a * myself.a
    end

    v <= me.a - z
end

# Instantiate it for checking.
with_names :with_namesI

# Generate the low level representation.
low = with_namesI.to_low

# Displays it
puts low.to_yaml
