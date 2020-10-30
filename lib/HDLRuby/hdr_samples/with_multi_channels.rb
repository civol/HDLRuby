require "std/channel.rb"

include HDLRuby::High::Std

# Channel describing a buffered queue storing data of +typ+ type of +depth+,
# synchronized through clk and reset on +rst+.
channel(:queue) do |typ,depth,clk,rst|
    # The inner buffer of the queue.
    typ[-depth].inner :buffer
    # The read and write pointers.
    [depth.width].inner :rptr, :wptr
    # The read and write command signals.
    inner :rcmd, :wcmd
    # The read and write ack signals.
    inner :rack, :wack
    # The ack check deactivator (for synchron accesses).
    inner :hrack, :hwack
    # The read/write data registers.
    typ.inner :rdata, :wdata

    # The process handling the decoupled access to the buffer.
    par(clk.posedge) do
        # rack <= 0
        # wack <= 0
        hif (~rcmd) { rack <= 0 }
        hif (~wcmd) { wack <= 0 }
        hif(rst) { rptr <= 0; wptr <= 0 }
        hif(rcmd & (hrack|~rack) & (rptr != wptr)) do
            rptr <= (rptr + 1) % depth
            rack <= 1
        end
        hif(wcmd & (hwack|~wack) & (((wptr+1) % depth) != rptr)) do
            buffer[wptr] <= wdata
            # buffer[1] <= wdata
            wptr <= (wptr + 1) % depth
            wack <= 1
        end
    end
    par { rdata <= buffer[rptr] }

    reader_output :rcmd, :rptr, :hrack
    reader_input :rdata, :rack

    # The read primitive.
    reader do |blk,target|
        if (cur_behavior.on_event?(clk.posedge,clk.negedge)) then
            # Same clk event, synchrone case: perform a direct access.
            # Now perform the access.
            top_block.unshift do
                rcmd <= 0
                hrack <= 1
            end
            seq do
                rptr <= (rptr + 1) % depth
                target <= rdata
                blk.call if blk
            end
        else
            # Different clk event, perform a decoupled access.
            top_block.unshift do
                rcmd <= 0
                hrack <= 0
                hif(rack) do
                    blk.call if blk
                end
            end
            seq do
                # hif(rack) do
                #     blk.call if blk
                # end
                # helse do
                hif(rack==0) do
                    rcmd <= 1 
                    target <= rdata
                end
            end
        end
    end

    writer_output :wcmd, :wdata, :hwack
    writer_input :wack

    # The write primitive.
    writer do |blk,target|
        if (cur_behavior.on_event?(clk.negedge,clk.posedge)) then
            # Same clk event, synchrone case: perform a direct access.
            top_block.unshift do
                wcmd <= 0
                hwack <= 1
            end
            wcmd <= 1
            wdata <= target
            blk.call if blk
        else
            # Different clk event, asynchrone case: perform a decoupled access.
            top_block.unshift do
                wcmd <= 0
                hwack <= 0
                hif(wack) do
                    blk.call if blk
                end
            end
            seq do
                # hif(wack) do
                #     blk.call if blk
                # end
                # helse 
                hif(wack==0) { wcmd <= 1 }
                wdata <= target
            end
        end
    end
end


# Channel describing a register of +typ+ type.
channel(:register) do |typ|
    # The register.
    typ.inner :buffer

    reader_input :buffer

    # The read primitive.
    reader do |blk,target|
        target <= buffer
        blk.call if blk
    end

    writer_output :buffer

    # The read primitive.
    writer do |blk,target|
        buffer <= target
        blk.call if blk
    end
end



# Channel describing a handshake for transmitting data of +typ+ type, reset
# by +rst+
channel(:handshake) do |typ|
    # The data signal.
    typ.inner :data
    # The request and acknowledge.
    inner :req, :ack

    reader_input :ack, :data
    reader_output :req

    # The read primitive.
    reader do |blk,target|
        top_block.unshift do
            req <= 0
        end
        hif(ack == 0) do
            req <= 1
        end
        helsif(req) do
            target <= data
            req <= 0
            blk.call if blk
        end
    end

    writer_input :req
    writer_output :ack, :data

    # The read primitive.
    writer do |blk,target|
        top_block.unshift do
            ack <= 0
        end
        hif(req) do
            hif(~ack) do
                data <= target
                blk.call if blk
            end
            ack <= 1
        end
    end
end

# Channel describing a handshake for transmitting data of +typ+ type, reset
# by +rst+
channel(:handshake2) do |typ|
    # The data signal.
    typ.inner :data
    # The request and acknowledge.
    inner :req, :ack
    # The write flag
    inner :wf

    reader_input :ack, :data
    reader_output :req

    # The read primitive.
    reader do |blk,target|
        top_block.unshift do
            req <= 0
            hif(ack & req == 1) do
                target <= data
                req <= 0
                blk.call if blk
            end
        end
        hif(ack == 0) do
            req <= 1
        end
    end

    writer_input :req
    writer_output :ack, :data
    writer_inout :wf

    # The read primitive.
    writer do |blk,target|
        top_block.unshift do
            ack <= 0
            hif(wf & req & ~ack == 1) do
                data <= target
                ack <= 1
                blk.call if blk
            end
            hif(~req) { wf <= 0 }
        end
        hif(~ack) do
            wf <= 1
        end
    end
end


# $mode = :sync
# $mode = :nsync
# $mode = :async
# $mode = :proco  # Producer / Consummer
# $mode = :double # Producer and Consummer with double channels.
# $channel = :register
# $channel = :handshake
# $channel = :queue

# The configuration scenarii
$scenarii = [
              [:sync,  :register],     #  0
              [:sync,  :handshake],    #  1
              [:sync,  :queue],        #  3
              [:nsync, :register],     #  4
              [:nsync, :handshake],    #  5
              [:nsync, :queue],        #  6
              [:async, :register],     #  7
              [:async, :handshake],    #  8
              [:async, :queue],        #  9
              [:proco, :register],     # 10
              [:proco, :handshake],    # 11
              [:proco, :queue],        # 12
              [:double,:register],     # 13
              [:double,:handshake],    # 14
              [:double,:queue]         # 15
            ]

# The configuration
# $mode, $channel = $scenarii[11]
$mode, $channel = $scenarii[ARGV[-1].to_i]
puts "scenario: #{$scenarii[ARGV[-1].to_i]}"

# Testing the queue channel.
system :test_queue do
    inner :clk, :rst, :clk2, :clk3
    [8].inner :idata, :odata, :odata2
    [4].inner :counter

    if $channel == :register then
        register(bit[8]).(:my_ch)
        register(bit[8]).(:my_ch2)
    elsif $channel == :handshake then
        handshake(bit[8],rst).(:my_ch)
        handshake(bit[8],rst).(:my_ch2)
    elsif $channel == :queue then
        queue(bit[8],5,clk,rst).(:my_ch)
        queue(bit[8],5,clk,rst).(:my_ch2)
    end

    ev = $mode == :sync ? clk.posedge : 
         $mode == :nsync ? clk.negedge : clk2.posedge

    if $mode != :proco && $mode != :double then
        # Sync/Neg sync and async tests mode
        par(ev) do
            hif(rst) do
                counter <= 0
                idata <= 0
                # odata <= 0
            end
            helse do
                hif (counter < 4) do
                    my_ch.write(idata) do
                        idata <= idata + 1
                        counter <= counter + 1
                    end
                end
                helsif ((counter > 10) & (counter < 15)) do
                    my_ch.read(odata) do
                        # idata <= idata - odata
                        counter <= counter + 1
                    end
                end
                helse do
                    counter <= counter + 1
                end
            end
        end
    elsif $mode == :proco then
        # Producter/consumer mode
        # Producer
        par(clk2.posedge) do
            hif(rst) do
                idata <= 0
            end
            helse do
                my_ch.write(idata) do
                    idata <= idata + 1
                end
            end
        end
        # Consumer
        par(clk3.posedge) do
            hif(rst) do
                counter <= 0
            end
            helse do
                my_ch.read(odata) do
                    counter <= counter + 1
                end
            end
        end
    else
        # Producer and consumer are commicating through two layers of channels
        par(ev) do
            hif(rst) do
                counter <= 0
                idata <= 0
            end
            helse do
                my_ch.write(idata) do
                    idata <= idata + 1
                end
                my_ch.read(odata) do
                    my_ch2.write(odata)
                end
                my_ch2.read(odata2) do
                    counter <= counter + 1
                end
            end
        end
    end

    timed do
        clk <= 0
        clk2 <= 0
        clk3 <= 0
        rst <= 0
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        rst <= 1
        !3.ns
        clk2 <= 1
        !3.ns
        clk3 <= 0
        !4.ns
        clk <= 1
        !10.ns
        clk <= 0
        !3.ns
        clk2 <= 0
        !3.ns
        clk3 <= 1
        !2.ns
        rst <= 0
        !2.ns
        64.times do
            clk <= 1
            !10.ns
            clk <= 0
            !3.ns
            clk2 <= ~clk2
            !3.ns
            hif (clk2 == 0) { clk3 <= ~ clk3 }
            !4.ns
        end
    end
end

