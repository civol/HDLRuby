require 'HDLRuby'

configure_high

# System with scopes within scopes.
system :scopescope do
    input  :i0,:i1
    output :o0,:o1
    inner  :s0

    sub do
        inner :s0
        sub do
            inner :s0
        end
    end
end

# Instantiate it for checking.
scopescope :scopescopeI

# Generate the low level representation.
low = scopescopeI.to_low

# Displays it
puts low.to_yaml
