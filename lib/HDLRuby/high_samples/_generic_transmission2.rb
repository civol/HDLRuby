require 'HDLRuby'

configure_high

require 'HDLRuby/std/channel'
include HDLRuby::High::Std

# Some very complex system which sends 8 bit values.
system :systemA do |typ|
    input :clk, :rst
    typ :data
    [7..0].inner :count

    par(clk.posedge) do
        hif data.can_write? do
            # count <= mux(rst == 0, 0, count + 1)
            count <= (rst == 0).mux(0, count + 1) 
            data <= count
        end
    end
end


# Another extremly complex system which recieves 8 bit values.
system :systemB do |typ|
    input :clk
    typ :data
    output :result

    par(clk.posedge) do
        hif data.can_read? do
            result <= mux(data == 0, 0, 1)
        end
    end
end


# A system connecting A to B directly.
system :directAB do
    input :clk, :rst
    output :result

    [7..0].inner :a2b

    systemA(:sysA,[7..0]).(clk: clk, data: a2b, rst: rst)
    systemB(:sysB,[7..0]).(clk: clk, data: a2b, result: result)
end

# Instantiate it for checking.
directAB :directABI

# The type used for the buffered serialized communication.
channel :swriteT do
    [7..0].output :data
    output :ready
    input :ack
end
swriteT.on_write! do |chan,stmnt|
    hif chan.ready == 0 do
        chan.ready <= 1
    end
    helse do
        (chan.ready <= 0).hif(chan.ack == 1)
    end
    stmnt
end
swriteT.can_write! do |chan|
    chan.ack == 1
end
channel :sreadT do
    [7..0].input :data
    input :ready
    output :ack
end
sreadT.on_read! do |chan,ref,stmnt|
    hif chan.ready == 1 & chan.ack == 0 do
        chan.ack <= 1
        ref <= chan.data
    end
    helse do
        ack <= 0
    end
    stmnt
end
sreadT.can_read! do
    ready == 1
end

# A system connecting A to B through a serial interface.
system :serialAB do
    input :clk, :rst
    output :result

    swriteT :swrite    # Channel for serial write
    sreadT  :sread     # Channel for serial read

    inner :sdat        # Serial data line
    inner :ctrl        # Serial control line
    inner :wr_cnt      # Serial write counter
    inner :rd_cnt      # Serial read counter

    # Handle the serial transmission writer side.
    par(clk.posedge) do
        hif (swrite.ready) {
            wr_cnt <= 0
            ctrl <= 1
            swrite.ack <= 0
        }
        helsif (ctrl == 1) {
            wr_scnt <= wr_scnt + 1
            sdat <= swrite.data[wr_scnt]
            hif (swrite.scnt == 7) {
                ctrl <= 0
                swrite.ack <= 1
            }
        }
    end

    # Handle the serial transmission reader side.
    par(clk.negedge) do
        hif (ctrl == 1) do
            rd_scnt <= rd_scnt + 1
            sread.data[rd_scnt] <= sdat
            hif(rd_scnt == 7) do
                sread.ready <= 1
                rd_scnt = 0
            end
        end
        hif(sread.ack) do
            sread.ready <= 0
        end
    end

    systemA(:sysA,bufT).(clk: clk, data: bufA, rst: rst)
    systemB(:sysB,bufT).(clk: clk, data: bufB, result: result)
end


# Instantiate it for checking.
serialAB :serialABI

# Generate the low level representation.
low = serialABI.to_low

# Displays it
puts low.to_yaml
