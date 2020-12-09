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

    # First tester.
    [4].inner :counter
    [4*4].inner :res
    inner :ack_in, :ack_out
    inner :dup_req, :dup_ack

    # The input queue.
    queue(bit[4],4,clk,rst).(:in_qu)

    # The middle queues.
    mid_qus = 4.times.map do |i|
        queue(bit[4],4,clk,rst).(:"mid_qu#{i}")
    end

    # The output queue.
    queue(bit[4*4],4,clk,rst).(:out_qu)

    # Connect the input queue to the middle queues.
    duplicator(bit[4],clk.negedge,in_qu,mid_qus,dup_req,dup_ack)

    # Connect the middle queues to the output queue.
    merger([bit[4]]*4,clk.negedge,mid_qus,out_qu)


    # Second tester.
    [4].inner :counterb
    [4].inner :resb
    inner :ack_inb0, :ack_inb1, :ack_outb

    # The input queues.
    queue(bit[4],4,clk,rst).(:in_qub0)
    queue(bit[4],4,clk,rst).(:in_qub1)

    # The output queue.
    queue(bit[4],4,clk,rst).(:out_qub)

    # Connect then with a serializer.
    serializer(bit[4],clk.negedge,[in_qub0,in_qub1],out_qub)

    # # Slow version, always work
    # par(clk.posedge) do
    #     ack_in <= 0
    #     ack_out <= 1
    #     hif(rst) { counter <= 0 }
    #     helse do
    #         hif(ack_out) do
    #             ack_out <= 0
    #             in_qu.write(counter)  do
    #                 ack_in <= 1
    #                 counter <= counter + 1
    #             end
    #         end
    #         hif(ack_in) do
    #             mid_qu0.read(res_0)
    #             mid_qu1.read(res_1)
    #             mid_qu2.read(res_2)
    #             mid_qu3.read(res_3) { ack_out <= 1 }
    #         end
    #     end
    # end

    # Fast version but assumes connected channels are blocking
    par(clk.posedge) do
        ack_in <= 0
        ack_inb0 <= 0
        ack_inb1 <= 0
        hif(rst) { counter <= 0; counterb <= 0 }
        helse do
            in_qu.write(counter)  do
                ack_in <= 1
                counter <= counter + 1
            end
            hif(ack_in) do
                out_qu.read(res)
            end
            hif(~ack_inb0) do
                in_qub0.write(counterb) do
                    ack_inb0 <= 1
                    counterb <= counterb + 1
                end
            end
            helse do
                in_qub1.write(counterb) do
                    ack_inb1 <= 1
                    counterb <= counterb + 1
                end
            end
            hif(ack_inb0 | ack_inb1) do
                out_qub.read(resb)
            end
        end
    end

    timed do
        clk <= 0
        rst <= 0
        dup_req <= 0
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
        4.times do
            !10.ns
            clk <= 1
            !10.ns
            clk <= 0
        end
        dup_req <= 1
        16.times do
            !10.ns
            clk <= 1
            !10.ns
            clk <= 0
        end
    end
end
