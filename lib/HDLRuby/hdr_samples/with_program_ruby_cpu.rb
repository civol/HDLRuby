
# A benchmark for testing the use of Ruby software code.
system :with_ruby_prog_cpu do
    ## The processor interface signals.

    inner :sim              # The signal configuring the simulation.

    inner :clk, :rst
    inner :br, :bg, :rwb
    [16].inner :addr
    [8].inner  :dout #, :din
    inner :req, :ack

    [8].inner :key_reg      # Memory-mapped register containing the latest key.

    ## The configuration parameters.
    [9].inner :hSIZE, :hSTART, :hEND  # Display horizontal size and borders.
    [8].inner :vSIZE, :vSTART, :vEND  # Display vertical size and borders.
    [8].inner :rxCYCLE              # Time for transmitting one bit with the UART
    [16].inner :vADDR, :kADDR         # The display and keyboard start addresses 

    program(:ruby,:configure) do
        actport sim.posedge
        outport hSIZE: hSIZE, hSTART: hSTART, hEND: hEND
        outport vSIZE: vSIZE, vSTART: vSTART, vEND: vEND
        outport rxCYCLE: rxCYCLE
        outport vADDR: vADDR, kADDR: kADDR
        code "ruby_program/sw_cpu_terminal.rb"
    end

    ## The processor model.

    # This is the bus part of the CPU.
    program(:ruby,:cpu_bus) do
        actport clk.posedge
        inport  br:   br      # Bus request
        outport bg:   bg      # Bus granted
        inport  ain:  addr
        inport  aout: addr
        inport  rwb:  rwb
        # inport  din:  din
        outport dout: dout

        inport key_reg: key_reg

        code "ruby_program/sw_cpu_terminal.rb"
    end

    # This is the reset part of the CPU.
    program(:ruby, :cpu_rst) do
        actport rst.posedge
        code "ruby_program/sw_cpu_terminal.rb"
    end

    # This is the interrupt part of the CPU.
    program(:ruby,:cpu_irq) do
        actport req.posedge
        outport ack:   ack
        code "ruby_program/sw_cpu_terminal.rb"
    end


    ## Simplistic circuitry that generates a monochrome video signal
    #  For a 320x200 screen with 512-320 pixels horizontal blank and 
    #  256-200 lines vertical blank and centered screen.
    #  The memory bus is requested at the begining of a line, and if it is
    #  not granted on time the pixels are skipped.

    [1].inner :vclk_count
    inner :vclk
    [9].inner :hcount
    [8].inner :vcount
    [16].inner :vaddr
    inner :hblank, :vblank
    [8].inner :pixel

    # Generate the video clock: every 4 cycles (for not too long simulation).
    # NOTE: requires reset to last two cycles or more.
    seq(clk.posedge) do
        hif(rst) { vclk_count <= 0; vclk <=0 }
        helse do
            vclk_count <= vclk_count + 1
            hif(vclk_count == 1) { vclk <= ~vclk }
        end
    end

    # Generates the signal.
    seq(vclk.posedge,rst.posedge) do
        hif(rst) do
            hcount <= 0; vcount <= 0
            hblank <= 0; vblank <= 0
            vaddr <= vADDR
            pixel <= 0
        end
        helse do
            hif((hcount >= hSIZE + hSTART) | (hcount < hSTART)) { hblank <= 1 }
            hif((vcount >= vSIZE + vSTART) | (vcount < vSTART)) { vblank <= 1 }
            hif((hcount < hSIZE+hSTART) & (vcount < vSIZE+vSTART) & (vcount >= vSTART)) { br <= 1 } #; rwb <= 1 }
            helse { br <= 0} #; rwb <= 0 }
            hif((hcount >= hSTART) & (hcount < hSIZE+hSTART) &
                (vcount >= vSTART) & (vcount < vSIZE+vSTART)) do
                hblank <= 0; vblank <= 0
                hif(bg) { pixel <= dout }
                vaddr <= vaddr + 1
            end
            hcount <= hcount + 1
            hif(hcount >= hSIZE+hSTART+hEND) do
                hcount <= 0
                vcount <= vcount + 1
                hif (vcount >= vSIZE+vSTART+vEND) do
                    vcount <= 0
                    vaddr  <= vADDR
                end
            end
        end
    end

    # Connect to the memory as well as the keyboard register.
    rwb  <= mux(bg, _b0, _b1)
    # addr <= mux(bg, kADDR, vaddr)
    addr <= mux(bg, _hzz, vaddr)

    # # Connect the key register.
    # din <= mux(~bg, _hzz, key_reg)

    # This is the monitor simulator.
    program(:ruby,:monitor) do
        actport vclk.negedge
        inport vblank: vblank, hblank: hblank, pixel: pixel
        code "ruby_program/sw_cpu_terminal.rb"
    end


    ## Simplisitic circuitry that receives bytes from a UART and write them
    #  into a memory-map register before raising an interrupt.
    #  Only 8-bit values, and no parity.

    # The clock signal generation of the keyboard device
    [2].inner :uclk_count 
    inner     :uclk, :urst

    # Generate the UART chip clock: every 8 cycles (for not too long
    # simulation).
    seq(clk.posedge) do
        hif(rst) { uclk_count <= 0; uclk <= 0; urst <= 1 }
        helse do
            uclk_count <= uclk_count + 1
            hif(uclk_count == 1) { uclk <= ~uclk }
            hif(uclk_count == 0) { urst <= 0 }
        end
    end

    # The UART signals.
    inner :rx

    # This is the UART keyboard simulator.
    program(:ruby,:keyboard) do
        actport uclk.negedge
        outport rx: rx
        code "ruby_program/sw_cpu_terminal.rb"
    end

    # The signals for getting key values from UART
    [2].inner :rx_bit_count # The received bit count.
    [8].inner :rx_bits      # The rx bit buffer (a shift register).

    # The sequencer receiving the keyboard data and writing the to a
    # memory-mapped register.
    sequencer(uclk.posedge,urst) do
        sloop do
            # At first no interrupt and nothing received yet.
            req          <= 0
            rx_bit_count <= 0
            rx_bits      <= 0
            key_reg      <= 0

            # Wait for a start bit: falling edge of rx.
            swhile(rx != 0)
            # Now can get the 8 bits.
            8.stimes do
                # Wait one Rx cycle.
                rxCYCLE.stimes;
                # Get one bit.
                rx_bits <= [rx_bits[6..0],rx]
            end
            # All is done, wait end of transmission.
            swhile(rx == 0)
            # Save the received value.
            key_reg <= rx_bits
            # And wait the computer is ready to receive an interrupt
            # and the BUS is not used by the video chip.
            swhile((ack == 1) | (rwb == 1) )
            # Now raise an interrupt.
            req <= 1
            # Wait for its process to start.
            swhile(ack != 0)
        end
    end




    ## The simulation part.

    timed do
        clk   <= 0
        rst   <= 0
        sim   <= 0
        !10.ns
        sim <= 1
        !10.ns
        sim <= 0
        repeat(5) do
          !10.ns
          clk <= 1
          !10.ns
          clk <= 0
        end
        rst <= 1
        repeat(5) do
          !10.ns
          clk <= 1
          !10.ns
          clk <= 0
        end
        rst <= 0
        repeat(10_000_000) do
          !10.ns
          clk <= 1
          !10.ns
          clk <= 0
        end
    end
end
