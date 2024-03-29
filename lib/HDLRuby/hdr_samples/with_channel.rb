require 'std/channel.rb'

raise "std/channel.rb is deprecated."

include HDLRuby::High::Std

# Implementation of a handshaker channel transmitting generic values
channel(:handshaker) do |typ|
    # The buffer holding the value to transmit
    typ.inner :buf
    # The handshaking lock signals.
    # Each signal is modified one-sided (reader or writer),
    # hence a double lock valid/ready is required.
    inner :read_valid, :read_ready, :write_valid, :write_ready
    # Sets the reader inputs ports.
    reader_input :buf, :read_valid, :read_ready
    # Sets the reader output ports.
    reader_output :write_valid, :write_ready

    # Sets the writer input ports.
    writer_input :write_valid, :write_ready
    # Sets the writer output ports.
    writer_output :buf, :read_valid, :read_ready

    # # Defines the reset command for the channel.
    # command(:reset) do
    #     # Fully locked reader side.
    #     read_valid  <= 0
    #     read_ready  <= 0
    #     # Fully unlocked writer side.
    #     write_valid <= 1
    #     write_ready <= 1
    # end

    # Defines the reader's access procedure.
    reader do |blk,target|
        hif(read_valid) do
            write_valid <= 0
            write_ready <= 0
            hif(read_ready) do
                target <= buf
                write_valid <= 1
                blk.call if blk
            end
        end
        helse { write_ready <= 1 }
    end

    # Defines the writer's access procedure.
    writer do |blk,target|
        hif(write_valid) do
            read_valid <= 0
            read_ready <= 0
            hif(write_ready) do
                buf <= target
                read_valid <= 1
                blk.call if blk
            end
        end
        helse { read_ready <= 1 }
    end
end




# A system writing indefinitely to a channel.
# Checking usage of channel without declaring a port.
system :producer8 do |channel|
    # puts "channel=#{channel}, channel methods=#{channel.methods}"
    # Inputs of the producer: clock and reset.
    input :clk, :rst
    # # Instantiate the channel ports
    # channel.output :ch
    # Inner 8-bit counter for generating values.
    [8].inner :counter

    # The value production process
    par(clk.posedge) do
        hif(rst) { counter <= 0 }
        helse do
            # ch.write(counter) { counter <= counter + 1 }
            channel.write(counter) { counter <= counter + 1 }
        end
    end
end

# A system reading indefinitely from a channel.
system :consummer8 do |channel|
    # Input of the consummer: a clock is enough.
    input :clk
    # Instantiate the channel ports
    channel.input :ch
    # Inner buffer for storing the cunsummed value.
    [8].inner :buf

    # The value consumption process
    par(clk.posedge) do
        ch.read(buf)
    end
end

# A system reading indefinitely from a channel.
# Version without port declaration.
system :consummer16 do |channel|
    # Input of the consummer: a clock is enough.
    input :clk
    # # Instantiate the channel ports
    # channel.input :ch
    # Inner buffer for storing the cunsummed value.
    [16].inner :buf

    # The value consumption process
    par(clk.posedge) do
        # ch.read(buf)
        channel.read(buf)
    end
end


# A system testing the handshaker.
system :hs_test do
    input :clk,:rst

    # Declares two handshakers
    handshaker([8]).(:hs0)
    handshaker([16]).(:hs1)

    # # Sets the reset.
    # par(rst.posedge) { hs.reset }
    
    # For the first handshake

    # Instantiate the producer.
    producer8(hs0).(:producerI).(clk,rst)

    # Instantiate the consummer.
    consummer8(hs0).(:consummerI).(clk)

    # For the second handshaker
    
    # Instantiatethe consummer.
    consummer16(hs1).(:consummer2I).(clk)

    # Produce from within.
    [16].inner :counter

    # hs1.output :port

    par(clk.posedge) do
       hif(rst) { counter <= 0 }
        helse do
            # port.write(counter) { counter <= counter + 1 }
            hs1.write(counter) { counter <= counter + 1 }
        end
    end

end
