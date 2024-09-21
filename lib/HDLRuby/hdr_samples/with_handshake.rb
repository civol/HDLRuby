raise "Deprecated code."

require 'std/handshakes.rb'

include HDLRuby::High::Std


# System using a handshake for summing inputs.
system :hs_adder do
    input :clk
    [8].input :x,:y
    [8].output :z

    inner :read, :write

    include(hs_pipe(clk.posedge,read,write))

    par(clk.posedge) do
        hif(read) do
            z <= x + y
            write <= 1
        end
        hif(ackO) do
            z <= _zzzzzzzz
            write <= 0
        end
    end
end


# System testing handshakes.
system :with_handshake do

    # The clock signal.
    inner :clk
    # The request and acknoledge signals.
    inner :reqI,:ackI,:reqO,:ackO

    # The input and output values.
    [8].inner :x, :y, :z

    # Instantiate the handshake adder.
    hs_adder.(:adderI).(clk: clk, x: x, y: y, z: z,
                        reqI: reqI, ackI: ackI, reqO: reqO, ackO: ackO)

    # Test the handshake adder.
    timed do
        clk  <= 0
        x    <= 0
        y    <= 0
        reqI <= 0
        ackO <= 0
        !10.ns
        clk  <= 1
        !10.ns
        clk  <= 0
        x    <= 1
        y    <= 2
        !10.ns
        clk  <= 1
        !10.ns
        clk  <= 0
        reqI <= 1
        !10.ns
        clk  <= 1
        !10.ns
        clk  <= 0
        reqI <= 0
        !10.ns
        clk  <= 1
        !10.ns
        clk  <= 0
        ackO <= 1
        !10.ns
        clk  <= 1
        !10.ns
        clk  <= 0
        !10.ns
        clk  <= 1
        !10.ns
        clk  <= 0
        !10.ns
        clk  <= 1
        !10.ns
        clk  <= 0
        ackO <= 0
        !10.ns
        clk  <= 0
        x    <= 3
        y    <= 4
        !10.ns
        clk  <= 1
        !10.ns
        clk  <= 0
        reqI <= 1
        !10.ns
        clk  <= 1
        !10.ns
        clk  <= 0
        reqI <= 0
        !10.ns
        clk  <= 1
        !10.ns
        clk  <= 0
        ackO <= 1
        !10.ns
        clk  <= 1
        !10.ns
        clk  <= 0
        ackO <= 0
    end
end
