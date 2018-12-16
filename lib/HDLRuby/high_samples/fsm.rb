require 'HDLRuby'

configure_high

require 'HDLRuby/std/fsm'
include HDLRuby::High::Std


# Implementation of a fsm.
system :my_fsm do
    input :clk,:rst
    [7..0].input :a, :b
    [7..0].output :z

    fsm :fsmI # Shortcut: fsm(clk,rst).(:fsmI)
    fsmI.for_event { clk.posedge }
    # Shortcut: fsmI.clk = clk
    fsmI.for_reset { rst }
    # Shortcut: fsmI.rst = rst
    fsmI do
        state         { z <= 0 }
        state(:there) { z <= a+b }
        state do
            hif (a>0) { z <= a-b }
            helse { goto(:there) }
        end
    end
end

# Instantiate it for checking.
my_fsm :my_fsmI

# Generate the low level representation.
low = my_fsmI.systemT.to_low

# Displays it
puts low.to_yaml
