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
    inner :rreq, :wreq
    # The read and write ack signals.
    inner :rack, :wack
    # The read/write data registers.
    typ.inner :rdata, :wdata

    # The flags telling of the channel is synchronized
    inner :rsync, :wsync

    # The process handling the decoupled access to the buffer.
    par(clk.posedge) do
        hif(rst) { rptr <= 0; wptr <= 0 }
        helse do
            # hif(rsync) do
            #     hif(rptr != wptr) do
            #         rdata <= buffer[rptr]
            #     end
            # end
            # helse do
            hif(~rsync) do
                hif (~rreq) { rack <= 0 }
                hif(rreq & (~rack) & (rptr != wptr)) do
                    rdata <= buffer[rptr]
                    rptr <= (rptr + 1) % depth
                    rack <= 1
                end
            end

            # hif(wsync) do
            #     buffer[wptr] <= wdata
            # end
            # helse do
            hif(~wsync) do
                hif (~wreq) { wack <= 0 }
                hif(wreq & (~wack) & (((wptr+1) % depth) != rptr)) do
                    buffer[wptr] <= wdata
                    wptr <= (wptr + 1) % depth
                    wack <= 1
                end
            end
        end
    end

    reader_output :rreq, :rptr, :rsync
    reader_input :rdata, :rack, :wptr, :buffer

    # The read primitive.
    reader do |blk,target|
        if (cur_behavior.on_event?(clk.posedge,clk.negedge)) then
            # Same clk event, synchrone case: perform a direct access.
            # Now perform the access.
            top_block.unshift do
                rsync <= 1
                rreq <= 0
            end
            seq do
                hif(rptr != wptr) do
                    # target <= rdata
                    target <= buffer[rptr]
                    rptr <= (rptr + 1) % depth
                    blk.call if blk
                end
            end
        else
            # Different clk event, perform a decoupled access.
            top_block.unshift do
                rsync <= 0
                rreq <= 0
            end
            par do
                hif (~rack) { rreq <= 1 }
                helsif(rreq) do
                    rreq <= 0
                    target <= rdata
                    blk.call if blk
                end
            end
        end
    end

    writer_output :wreq, :wdata, :wptr, :wsync, :buffer
    writer_input :wack, :rptr

    # The write primitive.
    writer do |blk,target|
        if (cur_behavior.on_event?(clk.negedge,clk.posedge)) then
            # Same clk event, synchrone case: perform a direct access.
            top_block.unshift do
                wsync <= 1
                wreq <= 0
            end
            hif(((wptr+1) % depth) != rptr) do
                # wdata <= target
                buffer[wptr] <= target
                wptr <= (wptr + 1) % depth
                blk.call if blk
            end
        else
            # Different clk event, asynchrone case: perform a decoupled access.
            top_block.unshift do
                wsync <= 0
                wreq <= 0
            end
            seq do
                hif (~wack) do
                    wreq <= 1
                    wdata <= target
                end
                helsif(wreq) do
                    wreq <= 0
                    blk.call if blk
                end
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


# $mode: channel clock, producer clock, consumer clock (n: not clock)
# $channel = :register
# $channel = :handshake
# $channel = :queue

# The configuration scenarii
$scenarii = [
              [:_clk2_clk2,      :register],    #  0
              [:_clk2_nclk2,     :register],    #  1
              [:_clk2_clk3,      :register],    #  2
              [:_clk3_clk2,      :register],    #  3
              [:_clk2_clk2,      :handshake],   #  4
              [:_clk2_nclk2,     :handshake],   #  5
              [:_clk2_clk3,      :handshake],   #  6
              [:_clk3_clk2,      :handshake],   #  7
              [:clk2_clk2_clk2,  :queue],       #  8
              [:clk2_clk2_nclk2, :queue],       #  9
              [:clk1_clk2_clk3,  :queue],       # 10
              [:clk3_clk2_clk1,  :queue],       # 11
              [:clk2_clk3_clk1,  :queue],       # 12
              [:clk2_clk1_clk3,  :queue],       # 13
            ]

# The configuration
# $mode, $channel = $scenarii[11]
$mode, $channel = $scenarii[ARGV[-1].to_i]
puts "scenario: #{$scenarii[ARGV[-1].to_i]}"

# Testing the queue channel.
system :test_queue do
    inner :rst, :clk1, :clk2, :clk3
    [8].inner :idata, :odata, :odata2
    [4].inner :counter


    # Assign the clocks
    mode = $mode.to_s.split("_")
    if ($channel == :queue) then
        clk_que = send(mode[0])
    end
    ev_pro = mode[1][0] == "n" ? 
        send(mode[1][1..-1]).negedge : send(mode[1]).posedge
    ev_con = mode[2][0] == "n" ? 
        send(mode[2][1..-1]).negedge : send(mode[2]).posedge

    # Set up the channel
    if $channel == :register then
        register(bit[8]).(:my_ch)
    elsif $channel == :handshake then
        handshake(bit[8],rst).(:my_ch)
    elsif $channel == :queue then
        queue(bit[8],3,clk_que,rst).(:my_ch)
    end

    # Producter/consumer mode
    # Producer
    par(ev_pro) do
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
    par(ev_con) do
        hif(rst) do
            counter <= 0
        end
        helse do
            my_ch.read(odata) do
                counter <= counter + 1
            end
        end
    end

    timed do
        clk1 <= 0
        clk2 <= 0
        clk3 <= 0
        rst <= 0
        !10.ns
        clk1 <= 1
        !10.ns
        clk1 <= 0
        rst <= 1
        !3.ns
        clk2 <= 1
        !3.ns
        clk3 <= 0
        !4.ns
        clk1 <= 1
        !10.ns
        clk1 <= 0
        !3.ns
        clk2 <= 0
        !3.ns
        clk3 <= 1
        !2.ns
        rst <= 0
        !2.ns
        64.times do
            clk1 <= 1
            !10.ns
            clk1 <= 0
            !3.ns
            clk2 <= ~clk2
            !3.ns
            hif (clk2 == 0) { clk3 <= ~ clk3 }
            !4.ns
        end
    end
end

