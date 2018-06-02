require 'HDLRuby'

configure_high

# System with blocks in blocks.
system :blockblock do
    input  :i0,:i1
    output :o0,:o1
    inner  :s0

    par do
        inner :s0
        sub do
            inner :s0
        end
    end
end

# Instantiate it for checking.
blockblock :blockblockI

# Generate the low level representation.
low = blockblockI.to_low

# Displays it
puts low.to_yaml
