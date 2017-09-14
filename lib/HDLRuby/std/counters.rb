
module HDLRuby::High

##
# Standard HDLRuby::High library: counters
# 
########################################################################

    ## Set a counter to +init+ when +rst+ is 1 and that is decreased according
    #  to the current clock.
    #  When this counter reaches 0, +code+ is executed.
    #  When not within a block, a behavior will be created which is activated
    #  on the rising edge of clk
    def after(init, rst = $rst, clk = $clk, &code)
        counter = High.make_variable(:counter)
        # Are we in a block?
        if High.top_user.is_a?(High::SystemT) then
            # No, create a behavior.
            behavior(clk.posedge) do
                after(init,rst&code)
            end
        else 
            seq do
                inner counter
                ifh rst == 1 do
                    get_inner(counter) <= init
                end
                elsifh get_inner(counter) == 0 do
                    code.call
                end
                elseh do
                    get_inner(counter) <= get_inner(counter) - 1
                end
            end
        end
    end

end
