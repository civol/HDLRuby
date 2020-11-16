require 'std/channel.rb'
require 'std/connector.rb'

include HDLRuby::High::Std

# Sample for testing the connectors of channels.

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
            hif(~rsync) do
                hif (~rreq) { rack <= 0 }
                hif(rreq & (~rack) & (rptr != wptr)) do
                    rdata <= buffer[rptr]
                    rptr <= (rptr + 1) % depth
                    rack <= 1
                end
            end

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




# Module for testing the connector.
system :with_connectors do
    inner :clk, :rst
    [4].inner :counter, :res_0,:res_1,:res_2,:res_3
    inner :ack_in

    # The input queue.
    queue(bit[4],4,clk,rst).(:in_qu)

    # The first output queue.
    queue(bit[4],4,clk,rst).(:out_qu0)
    queue(bit[4],4,clk,rst).(:out_qu1)
    queue(bit[4],4,clk,rst).(:out_qu2)
    queue(bit[4],4,clk,rst).(:out_qu3)

    # Connect them
    duplicator([4],clk.negedge,in_qu,[out_qu0,out_qu1,out_qu2,out_qu3])

    par(clk.posedge) do
        hif(rst) { counter <= 0 }
        helse do
            counter <= counter + 1
            in_qu.write(counter)  { ack_in <= 1 }
            hif(ack_in) do
                out_qu0.read(res_0)
                out_qu1.read(res_1)
                out_qu2.read(res_2)
                out_qu3.read(res_3)
            end
        end
    end

    timed do
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
        clk <= 1
        !10.ns
        clk <= 0
        rst <= 0
        16.times do
            !10.ns
            clk <= 1
            !10.ns
            clk <= 0
        end
    end
end
