module HDLRuby::High::Std

##
# Standard HDLRuby::High library: clocks
# 
########################################################################


    # Initialize the clock generator with +rst+ as reset signal.
    def configure_clocks(rst = $rst)
        @@__clocks_rst = rst
    end

    # Create a clock inverted every +times+ occurence of an +event+.
    def make_clock(event, times)
        clock = nil # The resulting clock

        # Enters the current system
        HDLRuby::High.cur_system.open do

            # Ensures times is a value.
            times = times.to_value

            # Create the counter.
            # Create the name of the counter.
            name = HDLRuby.uniq_name
            # Declare the counter.
            [times.width].inner(name)
            # Get the signal of the counter.
            counter = get_inner(name)

            # Create the clock.
            # Create the name of the clock.
            name = HDLRuby.uniq_name
            # Declares the clock.
            bit.inner(name)
            # Get the signal of the clock.
            clock = get_inner(name)
            
            # Control it.
            par(event) do
                hif(@@__clocks_rst) do
                    counter.to_ref <= times.to_expr
                    clock.to_ref <= 0
                end
                helsif(counter.to_expr == 0) do
                    counter.to_ref <= times.to_expr 
                    clock.to_ref <= ~ clock.to_expr
                end
                helse do
                    counter.to_ref <= counter.to_expr + 1
                end
            end
        end
        return clock
    end

    # module clk_div3(clk,reset, clk_out);

    #     input clk;
    #     input reset;
    #     output clk_out;

    #     reg [1:0] pos_count, neg_count;
    #     wire [1:0] r_nxt;

    #     always @(posedge clk)
    #     if (reset)
    #         pos_count <=0;
    #     else if (pos_count ==2) pos_count <= 0;
    #     else pos_count<= pos_count +1;

    #     always @(negedge clk)
    #     if (reset)
    #         neg_count <=0;
    #     else  if (neg_count ==2) neg_count <= 0;
    #     else neg_count<= neg_count +1;

    #     assign clk_out = ((pos_count == 2) | (neg_count == 2));
    # endmodule

    # Creates a clock inverted every +times+ occurence of an +event+ and its
    # everted.
    def make_2edge_clock(event,times)
        clock = nil # The resulting clock

        # Enters the current system
        HDLRuby::High.cur_system.open do
            # Ensure times is a value.
            times = times.to_value

            # Create the event counter.
            # Create the name of the counter.
            name = HDLRuby.uniq_name
            # Declare the counter.
            [times.width].inner(name)
            # Get the signal of the counter.
            counter = get_inner(name)

            # Create the inverted event counter.
            # Create the name of the counter.
            name = HDLRuby.uniq_name
            # Declare the counter.
            [times.width].inner(name)
            # Get the signal of the counter.
            counter_inv = get_inner(name)

            # Create the clock.
            # Create the name of the clock.
            name = HDLRuby.uniq_name
            # Declare the clock.
            bit.inner(name)
            # Get the signal of the clock.
            clock = get_inner(name)

            # Control the event counter
            par(event) do
                hif(@@__clocks_rst | counter.to_expr == 0) do
                    counter.to_ref <= times.to_expr/2 + 1
                end
            end
            # Control the inverteed event counter
            par(event.invert) do
                hif(@@__clocks_rst | counter_inv.to_expr == 0) do
                    counter_inv.to_ref <= times.to_expr/2 + 1
                end
            end
            # Compute the clock.
            clock.to_ref <= (counter.to_expr == times.to_expr/2 + 1) |
                (counter_inv.to_expr == times.to_expr/2 + 1)
        end
        # Return it.
        return clock
    end
end


# Enhnace the events with multiply operator.
class HDLRuby::High::Event

    # Creates a new event activated every +times+ occurences of the 
    # current event.
    def *(times)
        # The event must be an edge
        unless (self.type == :posedge or self.type == :negedge) then
            raise "Only posedge or negedge events can be multiplied."
        end
        # +times+ must be a value.
        times = times.to_value
        # Creates the clock for the new event.
        clock = nil
        # There are two cases: times is even or times is odd.
        if times.even? then
            # Even case: make a clock inverted every times/2 occurance of
            # current event.
            clock = HDLRuby::High::Std::make_clock(self,times/2)
        else
            # Odd case: make a clock raised every times occurance using
            # both event and inverted event
            clock = HDLRuby::High::Std::make_2edge_clock(self,times)
        end
        # Use the clock to create the new event.
        return clock.posedge
    end
end
