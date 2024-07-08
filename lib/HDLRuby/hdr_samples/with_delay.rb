require 'std/delays.rb'

include HDLRuby::High::Std

# System descending for delayp for adding a reset.
system :delayp_rst do |num|
    include(delayp(num))

    input :rst

    par(clk.posedge) do
        hif(rst) { state <= 0 }
    end
end


# System testing delay, delayp and the new delayp_rst.
system :with_delays do
    num = 10

    # The clock and reset signals
    inner :clk,:rst
    # The request signals.
    inner :req, :reqp, :reqp_rst
    # The ack signals.
    inner :ack, :ackp, :ackp_rst

    # Instantiate the delays.
    delay(num).(:delayI).(clk,req,ack)
    delayp(num).(:delaypI).(clk,reqp,ackp)
    delayp_rst(num).(:delaypI_rst).(rst,clk,reqp_rst,ackp_rst)

    # Test the delays.
    timed do
        clk <= 0
        rst <= 0
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        req <= 1
        reqp <= 1
        reqp_rst <= 1
        !10.ns
        clk <= 1
        !10.ns
        req <= 0
        clk <= 0
        rst <= 1
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        rst <= 0
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        reqp <= 0
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        reqp_rst <= 0
        10.times do
            !10.ns
            clk <= 1
            !10.ns
            clk <= 0
        end
    end
end
