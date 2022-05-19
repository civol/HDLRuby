module HDLRuby::High::Std

##
# Standard HDLRuby::High library: delays
#
########################################################################


    ## Module describing a simple delay using handshake for working.
    #  @param num the number of clock cycles to delay.
    system :delay do |num|
        # Checks and process the number of clock to wait.
        num = num.to_i
        raise "The delay generic argument must be positive: #{num}" if (num < 0)

        input  :clk     # The clock to make the delay on.
        input  :req     # The handshake request.
        output :ack     # The handshake acknoledgment.

        # The process of the delay.
        if (num == 0) then
            # No delay case.
            ack <= req
        else
            # The is a delay.
            inner run: 0             # Tell if the deayl is running.
            [num.width].inner :count # The counter for computing the delay.
            par(clk.posedge) do
                # Is there a request to treat?
                hif(req & ~run) do
                    # Yes, intialize the delay.
                    run <= 1
                    count <= 0
                    ack <= 0
                end
                # No, maybe there is a request in processing.
                helsif(run) do
                    # Yes, increase the counter.
                    count <= count + 1
                    # Check if the delay is reached.
                    hif(count == num-1) do
                        # Yes, tells it and stop the count.
                        ack <= 1
                        run <= 0
                    end
                end
            end
        end
    end



    ## Module describing a pipeline delay (supporting multiple successive delays)
    #  using handshake for working.
    #  @param num the number of clock cycles to delay.
    system :delayp do |num|
        # Checks and process the number of clock to wait.
        num = num.to_i
        raise "The delay generic argument must be positive: #{num}" if (num < 0)

        input  :clk          # The clock to make the delay on.
        input  :req          # The handshake request.
        output :ack          # The handshake acknoledgment.

        if (num==0) then
            # No delay.
            ack <= req
        else
            # There is a delay.

            [num].inner state: 0 # The shift register containing the progression
            # of each requested delay.

            # The acknoledgment is directly the last bit of the state register.
            ack <= state[-1]


            # The process controlling the delay.
            seq(clk.posedge) do
                # Update the state.
                if (num > 1) then
                    state <= state << 1
                else
                    state <= 0
                end
                # Handle the input.
                ( state[0] <= 1 ).hif(req)
            end
        end
    end

end
