require 'std/memory.rb'
require 'std/linear.rb'

raise "std/memory.rb is deprecated."

include HDLRuby::High::Std

# Tries for matrix-vector product.





# Sample code for testing the linear library.

system :linear_test do

    # Clock and reset.
    inner :clk,:rst

    # Request and acknoledge signals.
    inner :req
    [8].inner :ack


    # Circuit for testing the scaling.

    # Input memory
    mem_file([8],8,clk,rst, rinc: :rst, winc: :rst).(:mem_scale_in)
    # Output memory
    mem_file([8],8,clk,rst, winc: :rst).(:mem_scale_out)
    # Access ports.
    mem_scale_in.branch(:anum).inner :mem_scale_inP
    mem_scale_inPs = 8.times.map { |i| mem_scale_inP.wrap(i) }
    mem_scale_out.branch(:anum).inner :mem_scale_outP
    mem_scale_outPs = 8.times.map { |i| mem_scale_outP.wrap(i) }

    # Build the scaler.
    scale([8],clk.posedge,req,ack[0],channel_port(3),
          mem_scale_inPs,mem_scale_outPs)


    # Circuit for testing the parallel addition.

    # Input memories
    mem_file([8],8,clk,rst, rinc: :rst, winc: :rst).(:mem_addn_left_in)
    mem_file([8],8,clk,rst, rinc: :rst, winc: :rst).(:mem_addn_right_in)
    # Output memory
    mem_file([8],8,clk,rst, winc: :rst).(:mem_addn_out)
    # Access ports.
    mem_addn_left_in.branch(:anum).inner :mem_addn_left_inP
    mem_addn_left_inPs = 8.times.map { |i| mem_addn_left_inP.wrap(i) }
    mem_addn_right_in.branch(:anum).inner :mem_addn_right_inP
    mem_addn_right_inPs = 8.times.map { |i| mem_addn_right_inP.wrap(i) }
    mem_addn_out.branch(:anum).inner :mem_addn_outP
    mem_addn_outPs = 8.times.map { |i| mem_addn_outP.wrap(i) }

    # Build the adder.
    add_n([8],clk.posedge,ack[0],ack[1],mem_addn_left_inPs,
          mem_addn_right_inPs,mem_addn_outPs)


    # Circuit for testing the parallel multiplication.

    # Input memories
    mem_file([8],8,clk,rst, rinc: :rst, winc: :rst).(:mem_muln_left_in)
    mem_file([8],8,clk,rst, rinc: :rst, winc: :rst).(:mem_muln_right_in)
    # Output memory
    mem_file([8],8,clk,rst, winc: :rst).(:mem_muln_out)
    # Access ports.
    mem_muln_left_in.branch(:anum).inner :mem_muln_left_inP
    mem_muln_left_inPs = 8.times.map { |i| mem_muln_left_inP.wrap(i) }
    mem_muln_right_in.branch(:anum).inner :mem_muln_right_inP
    mem_muln_right_inPs = 8.times.map { |i| mem_muln_right_inP.wrap(i) }
    mem_muln_out.branch(:anum).inner :mem_muln_outP
    mem_muln_outPs = 8.times.map { |i| mem_muln_outP.wrap(i) }

    # Build the multer.
    mul_n([8],clk.posedge,ack[1],ack[2],mem_muln_left_inPs,
          mem_muln_right_inPs,mem_muln_outPs)


    # Circuit for testing the mac
    # Output signal.
    [8].inner :acc

    # Build the mac.
    mac([8],clk.posedge,ack[2],ack[3],channel_port(5), channel_port(6), 
        channel_port(acc))


    # Circuit for testing the parallel mac.
    # Input memory
    mem_file([8],8,clk,rst, winc: :rst).(:mem_macn1_left_in)
    # Output memory
    mem_file([8],8,clk,rst, winc: :rst).(:mem_macn1_out)
    # Access ports.
    mem_macn1_left_in.branch(:anum).inner :mem_macn1_left_inP
    mem_macn1_left_inPs = 8.times.map { |i| mem_macn1_left_inP.wrap(i) }
    mem_macn1_out.branch(:anum).inner :mem_macn1_outP
    mem_macn1_outPs = 8.times.map { |i| mem_macn1_outP.wrap(i) }

    # Build the mac.
    mac_n1([8],clk.posedge,ack[3],ack[4], mem_macn1_left_inPs,
          channel_port(5), mem_macn1_outPs)

    # Circuit for testing the linearun with mac.
    # Input memories
    mem_dual([8],8,clk,rst, rinc: :rst, winc: :rst).(:mem_macrn_left_in)
    mem_dual([8],8,clk,rst, rinc: :rst, winc: :rst).(:mem_macrn_right_in)
    # Access ports.
    mem_macrn_left_in.branch(:rinc).inner :mem_macrn_left_in_readP
    mem_macrn_right_in.branch(:rinc).inner :mem_macrn_right_in_readP
    # Output signal.
    [8].inner :accr

    # Build the linearun mac.
    linearun(8,clk.posedge,ack[4],ack[5]) do |ev,req,ack|
        mac([8],ev,req,ack,mem_macrn_left_in_readP,mem_macrn_right_in_readP, 
            channel_port(accr))
    end


    # The memory initializer.
    # Writing ports
    mem_scale_in.branch(:winc).inner :mem_scale_in_writeP
    mem_addn_left_in.branch(:winc).inner :mem_addn_left_in_writeP
    mem_addn_right_in.branch(:winc).inner :mem_addn_right_in_writeP
    mem_muln_left_in.branch(:winc).inner :mem_muln_left_in_writeP
    mem_muln_right_in.branch(:winc).inner :mem_muln_right_in_writeP
    mem_macn1_left_in.branch(:winc).inner :mem_macn1_left_in_writeP
    mem_macrn_left_in.branch(:winc).inner :mem_macrn_left_in_writeP
    mem_macrn_right_in.branch(:winc).inner :mem_macrn_right_in_writeP
    # Filling index
    [8].inner :idx
    # Filling counter
    [3].inner :cnt
    # Filling value
    [8].inner :val

    # Start flag
    inner :start

    # The execution process
    par(clk.posedge) do
        hif(rst) { cnt <= 0; val <= 0 }
        helse do
            # Step index processing.
            hif(cnt == 7) do
                hif(idx < 8) { idx <= idx + 1 }
            end
            # Memory filling steps.
            hcase(idx)
            hwhen(0) do
                mem_scale_in_writeP.write(val) do
                    cnt <= cnt + 1; val <= val + 1
                end
            end
            hwhen(1) do
                mem_addn_left_in_writeP.write(val) do
                    cnt <= cnt + 1; val <= val + 1
                end
            end
            hwhen(2) do
                mem_addn_right_in_writeP.write(val) do
                    cnt <= cnt + 1; val <= val + 1
                end
            end
            hwhen(3) do
                mem_muln_left_in_writeP.write(val-24) do
                    cnt <= cnt + 1; val <= val + 1
                end
            end
            hwhen(4) do
                mem_muln_right_in_writeP.write(val-24) do
                    cnt <= cnt + 1; val <= val + 1
                end
            end
            hwhen(5) do
                mem_macn1_left_in_writeP.write(val-32) do
                    cnt <= cnt + 1; val <= val + 1
                end
            end
            hwhen(6) do
                mem_macrn_left_in_writeP.write(val-48) do
                    cnt <= cnt + 1; val <= val + 1
                end
            end
            hwhen(7) do
                mem_macrn_right_in_writeP.write(val-48) do
                    cnt <= cnt + 1; val <= val + 1
                end
            end
            # Computation steps.
            helse do
                hif(start) do
                    req <= 1
                    start <= 0
                end
                helse { req <= 0 }
            end
        end
    end


    # The test bench.
    timed do
        req <= 0
        ack <= 0
        clk <= 0
        rst <= 0
        cnt <= 0
        idx <= 0
        val <= 0
        start <= 0
        !10.ns
        clk <= 1
        !10.ns
        # Reset
        clk <= 0
        rst <= 1
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        rst <= 0
        start <= 1
        !10.ns
        # Run
        128.times do
            clk <= 1
            !10.ns
            clk <= 0
            !10.ns
        end
    end
end
