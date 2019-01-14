require '../std/fsm.rb'

include HDLRuby::High::Std

# Implementation of a fsm.
system :my_fsm do
    input :clk,:rst
    [7..0].input :a, :b
    [7..0].output :z

    # fsm :fsmI 
    # fsmI.for_event { clk.posedge }
    # # Shortcut: fsmI.for_event(clk)
    # fsmI.for_reset { rst }
    # # Shortcut: fsmI.for_reset(rst)
    # fsmI do
    #     state         { z <= 0 }
    #     state(:there) { z <= a+b }
    #     state do
    #         hif (a>0) { z <= a-b }
    #         helse { goto(:there) }
    #     end
    # end
    # Other alternative:
    fsm(clk.posedge,rst) do
        reset         { z <= 0 }
        state         { z <= a+b }
        state(:there) do
            hif (z!=0) { z <= a-b }
            goto(z==0,:end,:there)
        end
        state(:end)   { goto(:end) }
    end
end
