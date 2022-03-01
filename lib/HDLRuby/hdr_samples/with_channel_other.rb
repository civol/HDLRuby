require 'std/channel.rb'
require 'std/hruby_unit.rb'

include HDLRuby::High::Std

# A clocked handshake channel for testing purpuse.
channel(:handshake) do |typ,clk|
    inner has_data: 0
    inner :set_data
    inner :get_data
    typ.inner :data, :data_val

    writer_input :has_data
    writer_output :set_data, :data_val
    reader_input :has_data, :data
    reader_output :get_data

    par(clk.negedge) do
        hif(set_data) do
            data <= data_val
            has_data <= 1
        end
        helsif(get_data) do
            has_data <= 0
        end
    end

    # The writer.
    writer do |blk,target|
        hif(~has_data) do
            set_data <= 1
            data_val <= target
            blk.call if blk
        end
        helse { set_data <= 0 }
    end

    # The reader
    reader do |blk,target|
        hif(has_data) do
            target <= data
            get_data <= 1
            blk.call if blk
        end
        helse { get_data <= 0 }
    end
end



# A system writing indefinitely to a channel.
# Checking usage of channel without declaring a port.
system :producer8 do |channel|
    # Inputs of the producer: clock and reset.
    input :clk, :rst
    # Inner 8-bit counter for generating values.
    [8].inner :counter

    # The value production process
    par(clk.posedge) do
        hif(rst) { counter <= 0 }
        helse do
            channel.write(counter) { counter <= counter + 1 }
        end
    end
end

# A system reading indefinitely from a channel.
system :consummer8 do |channel|
    # Input of the consummer: a clock is enough.
    input :clk
    # # Instantiate the channel ports
    # channel.input :ch
    # Inner buffer for storing the cunsummed value.
    [8].inner :buf

    # The value consumption process
    par(clk.posedge) do
        channel.read(buf)
    end
end


# A system testing the handshaker.
Unit.system :hs_test do
    inner :clk,:rst

    # Declares two handshakers
    handshake(bit[8],clk).(:hs)

    # For the first handshake

    # Instantiate the producer.
    producer8(hs).(:producerI).(clk,rst)

    # Instantiate the consummer.
    consummer8(hs).(:consummerI).(clk)

    test do
        clk <= 0
        rst <= 0
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        rst <= 1
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        !10.ns
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        rst <= 0
        !10.ns
        clk <= 1
        !10.ns
        10.times do
            clk <= 0
            !10.ns
            clk <= 1
            !10.ns
        end
    end

end
