module HDLRuby::High::Std

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
        # Are we in a block?
        if HDLRuby::High.top_user.is_a?(HDLRuby::High::SystemT) then
            # No, create a behavior.
            behavior(clk.posedge) do
                with_counter(init,rst,clk,&code)
            end
        else
            # Ensure init is a value.
            init = init.to_value
            # Creates the counter
            # counter = HDLRuby::High::SignalI.new(HDLRuby::High.uniq_name,
            #                           TypeVector.new(:"",bit,init.width),
            #                           :inner)
            # Create the name of the counter.
            name = HDLRuby::High.uniq_name
            # Declare the counter.
            [init.width].inner(name)
            # Get the signal of the counter.
            counter = HDLRuby::High.cur_block.get_inner(name)
            # Apply the code on the counter.
            # code.call(counter)
            instance_exec(counter,&code)
        end
    end

    
    ## Sets a counter to +init+ when +rst+ is 1 that is decreased according
    #  to +clk+.
    #  As long as this counter does not reach 0, +code+ is executed.
    #  When not within a block, a behavior will be created which is
    #  activated on the rising edge of +clk+.
    def before(init, rst = $rst, clk = $clk, &code)
        with_counter(init,rst,clk) do |counter|
            seq do
                hif(rst.to_expr == 1) do
                    counter.to_ref <= init.to_expr
                end
                helsif(counter.to_expr != 0) do
                    counter.to_ref <= counter.to_expr - 1
                    # code.call
                    instance_eval(&code)
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
                hif(rst.to_expr == 1) do
                    counter.to_ref <= init.to_expr
                end
                helsif(counter.to_expr == 0) do
                    # code.call
                    instance_eval(&code)
                end
                helse do
                    counter.to_ref <= counter.to_expr - 1
                end
            end
        end
    end

end
