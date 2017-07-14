require 'HDLRuby'

configure_high

# Some very complex system which sends 8 bit values.
system :systemA do |data|
    input :clk, :rst
    [7..0].output data # Set data as 8-bit output while keeping its properties

    behavior(clk.posedge) do
        ( data <= mux(rst == 0, 0, data + 1) ).hif(data.can_write)
    end
end


# Another extremly complex system which recieves 8 bit values.
system :systemB do |data|
    input :clk
    [7..0].input data # Set data as 8-bit input while keeping its properties
    output :result

    behavior(clk.posedge) do
        ( result <= mux(data == 0, 0, 1) ).hif(data.can_read)
    end
end


# A system connecting A to B directly.
system :directAB do
    input :clk
    output :result

    [7..0].inner :a2b

    systemA(:sysA,a2b).(clk: clk)
    systemB(:sysB,a2b).(clk: clk, result: result)
end

# Instantiate it for checking.
Universe.directAB :directABI


# A system connecting A to B through a serial interface.
system :serialAB do
    input :clk, :rst
    output :result

    [7..0].inner :bufA   # Buffer for serialization on A side
    [2..0].inner :scntA  # Counter for serialization on A side
    [7..0].inner :bufB   # Buffer for serialization on B side
    [2..0].inner :scntB  # Counter for serialization on B side

    inner :sdat          # Serial data line

    # Handle the serial transmission A side.
    behavior(clk.posedge) do
        hif (rst) {
            scntA <= 0
        }
        helse {
            scntA <= scntA + 1
            sdat <= bufA[scntA]
        }
    end

    # Handle the serial transmission B side.
    behavior(clk.negedge) do
        hif rst do
            scntB <= 0
        end ; helse do
            scntB <= scntB + 1
            bufB[scntB] <= sdat
        end
    end

    # Set that bufA can only written when scntA becomes 0
    bufA.can_write = scntA == 7

    # Set that bufB can only read when scntB becomes 0
    bufA.can_read = scntB == 7

    systemA(:sysA,bufA).(clk: clk)
    systemB(:sysB,bufB).(clk: clk)
end


# Instantiate it for checking.
serialAB :serialABI
