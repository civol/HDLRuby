module HDLRuby::High::Std

##
# Standard HDLRuby::High library: clocks
# 
########################################################################
    @@__clocks_rst = nil

    # Initialize the clock generator with +rst+ as reset signal.
    def configure_clocks(rst = nil)
        @@__clocks_rst = rst
    end

    # Create a clock inverted every +times+ occurence of an +event+.
    def make_clock(event, times)
        clock = nil # The resulting clock

        # Enters the current system
        HDLRuby::High.cur_system.open do

            # Ensures times is a value.
            times = times.to_value - 1
            if (times == 0) then
              AnyError.new("Clock multiplier must be >= 2.") 
            end

            # Create the counter.
            # Create the name of the counter.
            name = HDLRuby.uniq_name
            # Declare the counter.
            if @@__clocks_rst then
                # There is a reset, so no need to initialize.
                [times.width].inner(name)
            else
                # There is no reset, so need to initialize.
              [times.width].inner(name => times)
            end
            # Get the signal of the counter.
            counter = get_inner(name)

            # Create the clock.
            # Create the name of the clock.
            name = HDLRuby.uniq_name
            # Declares the clock.
            if @@__clocks_rst then
                # There is a reset, so no need to initialize.
                bit.inner(name)
            else
                # There is no reset, so need to initialize.
                bit.inner(name => times)
            end
            # Get the signal of the clock.
            clock = get_inner(name)
            
            # Control it.
            par(event) do
                if @@__clocks_rst then
                    # There is a reset, handle it.
                    hif(@@__clocks_rst) do
                      counter <= times
                        clock <= 0
                    end
                    helsif(counter.to_expr == 0) do
                        counter <= times 
                        clock   <= ~ clock
                    end
                    helse do
                        counter <= counter - 1
                    end
                else
                    # There is no reset.
                    hif(counter == 0) do
                        counter <= times 
                        clock   <= ~ clock
                    end
                    helse do
                        counter <= counter - 1
                    end
                end
            end
        end
        return clock
    end


# https://referencedesigner.com/tutorials/verilogexamples/verilog_ex_07.php
# 
# module clk_divn #(
# parameter WIDTH = 3,
# parameter N = 5)
#  
# (clk,reset, clk_out);
#  
# input clk;
# input reset;
# output clk_out;
#  
# reg [WIDTH-1:0] pos_count, neg_count;
# wire [WIDTH-1:0] r_nxt;
#  
#  always @(posedge clk)
#  if (reset)
#  pos_count <=0;
#  else if (pos_count ==N-1) pos_count <= 0;
#  else pos_count<= pos_count +1;
#  
#  always @(negedge clk)
#  if (reset)
#  neg_count <=0;
#  else  if (neg_count ==N-1) neg_count <= 0;
#  else neg_count<= neg_count +1; 
#  
# assign clk_out = ((pos_count > (N>>1)) | (neg_count > (N>>1))); 
# endmodule


    # Creates a clock inverted every +times+ occurence of an +event+ and its
    # everted.
    def make_2edge_clock(event,times)
        clock = nil # The resulting clock

        # Enters the current system
        HDLRuby::High.cur_system.open do
            # Ensure times is a value.
            times = times.to_value 
            if (times == 1) then
              AnyError.new("Clock multiplier must be >= 2.") 
            end

            # Create the event counter.
            # Create the name of the counter.
            name = HDLRuby.uniq_name
            # Declare the counter.
            if @@__clocks_rst then
                # There is a reset, so no need to initialize.
                [times.width].inner(name)
            else
                # There is no reset, so need to initialize.
                [times.width].inner(name => 0)
            end
            # Get the signal of the counter.
            counter = get_inner(name)

            # Create the inverted event counter.
            # Create the name of the counter.
            name = HDLRuby.uniq_name
            # Declare the counter.
            if @@__clocks_rst then
                # There is a reset, so no need to initialize.
                [times.width].inner(name)
            else
                # There is no reset, so need to initialize.
              [times.width].inner(name => 0)
            end
            # Get the signal of the counter.
            counter_inv = get_inner(name)

            # Create the clock.
            # Create the name of the clock.
            name = HDLRuby.uniq_name
            # Declare the clock.
            if @@__clocks_rst then
                # There is a reset, so no need to initialize.
                bit.inner(name)
            else
                # There is no reset, so need to initialize.
                bit.inner(name => 0)
            end
            # Get the signal of the clock.
            clock = get_inner(name)

            # Control the even counter.
            par(event) do
                if @@__clocks_rst then
                    hif(@@__clocks_rst)        { counter <= 0 }
                    helsif(counter == times-1) { counter <= 0 }
                    helse                      { counter <= counter + 1 }
                else
                    hif(counter == times-1)     { counter <= 0 }
                    helse                      { counter <= counter + 1 }
                end
            end

            # Control the odd counter.
            par(event.invert) do
                if @@__clocks_rst then
                    hif(@@__clocks_rst)        { counter_inv <= 0 }
                    helsif(counter == times-1) { counter_inv <= 0 }
                    helse                      { counter_inv <= counter_inv + 1 }
                else
                    hif(counter == times-1)     { counter_inv <= 0 }
                    helse                      { counter_inv <= counter_inv + 1 }
                end
            end

            clock <= ((counter > (times/2)) | (counter_inv > (times/2)))
        end
        # Return the clock.
        return clock
    end

end



class HDLRuby::High::Event
    # Enhance the events with multiply operator.

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
