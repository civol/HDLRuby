# A class for a handshake transmission.

raise "Deprecated code."

class Handshaker

    ## Create a new handshaker for transmitting +type+ data.
    def initialize(type)
        # Sets the date type.
        type = type.to_type
        @type = type
        buffer = read_valid = read_ready = write_valid = write_ready = nil
        HDLRuby::High.cur_system.open do
            # Declares the registers used for the handshake
            # The data buffer.
            buffer = type.inner(HDLRuby.uniq_name)
            # Declares the handshake control singals.
            read_valid  = inner(HDLRuby.uniq_name)
            read_ready  = inner(HDLRuby.uniq_name)
            write_valid = inner(HDLRuby.uniq_name)
            write_ready = inner(HDLRuby.uniq_name)
        end
        @buffer = buffer
        @read_valid  = read_valid
        @read_ready  = read_ready
        @write_valid = write_valid
        @write_ready = write_ready
        # puts "@buffer=#{@buffer}"
        # puts "@read_valid=#{@read_valid}"
    end

    # Generate the reset of the handshaker.
    def reset
        read_valid  = @read_valid
        read_ready  = @read_ready
        write_valid = @write_valid
        write_ready = @write_ready
        HDLRuby::High.cur_system.open do
            par do
                read_valid  <= 0
                read_ready  <= 0
                write_valid <= 1
                write_ready <= 1
            end
        end
    end

    ## Declares the signals used for input from the handshaker and
    # do the connections of the upper SystemI
    def input
        ibuffer = iread_valid = iread_ready = iwrite_valid = iwrite_ready =nil
        type = @type
        buffer = @buffer
        read_valid  = @read_valid 
        read_ready  = @read_ready 
        write_valid = @write_valid 
        write_ready = @write_ready 
        HDLRuby::High.cur_system.open do
            # Declares the input signals
            ibuffer = type.input(HDLRuby.uniq_name)
            iread_valid  = input(HDLRuby.uniq_name)
            iread_ready  = input(HDLRuby.uniq_name)
            iwrite_valid = output(HDLRuby.uniq_name)
            iwrite_ready = output(HDLRuby.uniq_name)
        end
        @ibuffer = ibuffer
        @iread_valid   = iread_valid
        @iread_ready   = iread_ready
        @iwrite_valid  = iwrite_valid
        @iwrite_ready  = iwrite_ready
    end

    ## Declares the signals used for output to the handshaker and
    # do the connections of the upper SystemI
    def output
        obuffer = oread_valid = oread_ready = owrite_valid = owrite_ready =nil
        type = @type
        buffer = @buffer
        read_valid  = @read_valid 
        read_ready  = @read_ready 
        write_valid = @write_valid 
        write_ready = @write_ready 
        HDLRuby::High.cur_system.open do
            obuffer = type.output(HDLRuby.uniq_name)
            oread_valid  = output(HDLRuby.uniq_name)
            oread_ready  = output(HDLRuby.uniq_name)
            owrite_valid = input(HDLRuby.uniq_name)
            owrite_ready = input(HDLRuby.uniq_name)
        end
        @obuffer = obuffer
        @oread_valid   = oread_valid
        @oread_ready   = oread_ready
        @owrite_valid  = owrite_valid
        @owrite_ready  = owrite_ready
    end

    ## Gets the port of the handshaker as a list of signals.
    def get_port
        return [@buffer,@read_valid,@read_ready,@write_valid,@write_ready]
    end
    alias_method :to_a, :get_port

    ## Generates a blocking read.
    def read(target,&blk)
        ibuffer = @ibuffer
        iread_valid  = @iread_valid
        iread_ready  = @iread_ready
        iwrite_valid = @iwrite_valid
        iwrite_ready = @iwrite_ready
        HDLRuby::High.cur_block.open do
            hif(iread_valid) do
                iwrite_valid <= 0
                iwrite_ready <= 0
                hif(iread_ready) do
                    target <= ibuffer
                    iwrite_valid <= 1
                    blk.call if blk
                end
            end
            helse do
                iwrite_ready <= 1
            end
        end
    end

    ## Generates a blocking write.
    def write(target,&blk)
        obuffer = @obuffer
        oread_valid  = @oread_valid
        oread_ready  = @oread_ready
        owrite_valid = @owrite_valid
        owrite_ready = @owrite_ready
        HDLRuby::High.cur_block.open do
            hif(owrite_valid) do
                oread_valid <= 0
                oread_ready <= 0
                hif(owrite_ready) do
                    obuffer <= target
                    oread_valid <= 1
                    blk.call if blk
                end
            end 
            helse do
                oread_ready <= 1
            end
        end
    end
end



# A system generating data and sending them through hadnshake.
# +hs_port+ is the handshaker.
system :hs_producer do |hs_port|
    input :clk
    input :rst
    hs_port.output

    [8].inner :counter

    par(clk.posedge) do
        hif(rst) { counter <= 0 }
        helse do
            hs_port.write(counter) { counter <= counter + 1 }
        end
    end
end

# A system consuming data obtained from a handshaker.
# +hs_port+ is the handshaker.
system :hs_consummer do |hs_port|
    input :clk
    hs_port.input

    [8].inner :value

    par(clk.posedge) do
        hs_port.read(value)
    end
end

# A system testing the producer/consumer.
system :hs_test do
    inner :clk,:rst

    # Declares the handshaker
    hs = Handshaker.new([8])

    # Sets the reset.
    hs.reset.at(rst.posedge)

    # Instantiate the producer.
    hs_producer(hs).(:producer).(clk,rst,*hs)
    # Instantiate the consummer.
    hs_consummer(hs).(:consummer).(clk,*hs)
end



# Idea: core / container / ?
# -> pour SW et reconfigurable.
