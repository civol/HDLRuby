require 'HDLRuby'
include HDLRuby::High

# System with blocks in blocks.
system :blockblock do
    input  :i0,:i1
    output :o0,:o1
    inner  :s0

    behavior do
        inner :s0
        block do
            inner :s0
        end
    end
end
