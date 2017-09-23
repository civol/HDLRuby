module HDLRuby::High::Counter

##
# Standard HDLRuby::High library: counters
# 
########################################################################
    
    ## Sets a counter to +init+ when +rst+ is 1 that is decreased according
    #  to +clk+.
    #  +code+ will be applied on this counter.
    #  When not within a block, a behavior will be created which is
    #  activated on the rising edge of +clk+.
    def with_counter(init, rst = $rst, clk = $clk, &code)
        # Creates the counter
        counter = High.make_variable(:counter)
        # Are we in a block?
        if High.top_user.is_a?(High::SystemT) then
            # No, create a behavior.
            behavior(clk.posedge) do
                with_counter(init,rst,clk,&code)
            end
        else
            code.call(counter)
        end
    end

    
    ## Sets a counter to +init+ when +rst+ is 1 that is decreased according
    #  to +clk+.
    #  As long as this counter does not reach 0, +code+ is executed.
    #  When not within a block, a behavior will be created which is
    #  activated on the rising edge of +clk+.
    def before(init, rest = $rst, clk = $clk, &code)
        with_counter(init,rst,clk) do |counter|
            seq do
                inner counter
                ifh(rst == 1) do
                    get_inner(counter) <= init
                end
                elsifh(get_inner(counter) != 0) do
                    get_inner(counter) <= get_inner(counter) - 1
                    code.call
                end
            end
        end
    end

    ## Sets a counter to +init+ when +rst+ is 1 that is decreased according
    #  to +clk+.
    #  When this counter reaches 0, +code+ is executed.
    #  When not within a block, a behavior will be created which is activated
    #  on the rising edge of +clk+.
    def after(init, rst = $rst, clk = $clk, &code)
        with_counter(init,rst,clk) do |counter|
            seq do
                inner counter
                ifh(rst == 1) do
                    get_inner(counter) <= init
                end
                elsifh(get_inner(counter) == 0) do
                    code.call
                end
                elseh do
                    get_inner(counter) <= get_inner(counter) - 1
                end
            end
        end
    end

end
