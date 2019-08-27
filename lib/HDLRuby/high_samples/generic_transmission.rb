require 'HDLRuby'

configure_high

require 'HDLRuby/std/fsm'
require 'HDLRuby/std/channel'
include HDLRuby::High::Std

# Some very complex system which sends 8 bit values.
system :systemA do |ch|
    input :clk, :rst
    [7..0].inner :count
    ch.output :tx

    par(clk) do
        tx.put? do
            count <= (rst == 0).mux(0, count + 1) 
            tx.put <= count
        end
    end
end

# Alternative implementation without clock.
system :systemAnc do |ch|
    input :rst
    [7..0].inner :count
    ch.output :tx

    tx.put? do
        count <= (rst == 0).mux(0, count + 1) 
        tx.put <= count
    end
end

# Another extremly complex system which recieves 8 bit values.
system :systemB do |ch|
    input :clk
    output :result
    ch.input :rx

    par(clk) do
        rx.get? do
            result <= mux(rx.get == 0, 0, 1)
        end
    end
end


# Alternative implementation without clock.
system :systemBnc do |ch|
    output :result
    ch.input :rx

    rx.get? do
        result <= mux(rx.get == 0, 0, 1)
    end
end

# A system connecting A to B directly.
system :directAB do
    input :clk, :rst
    output :result

    [7..0].inner :a2b

    systemA([7..0]).(:sysA).(clk: clk, rst: rst, tx: a2b)
    systemB([7..0]).(:sysB).(clk: clk, result: result, rx: a2b)
end

# A system connecting Anc to Bnc directly.
system :directABnc do
    input :clk, :rst
    output :result

    [7..0].inner :a2b
    a2b.define_method(:get?,&blk) { par(clk.posedge,&blk) }
    a2b.define_method(:put?,&blk) { par(clk.posedge,&blk) }

    systemA(a2b).(:sysA).(data: a2b, rst: rst, tx: a2b)
    systemB(a2b).(:sysB).(data: a2b, result: result, rx: a2b)
end


# Instantiate it for checking.
directAB :directABI




# A system connecting A to B through a serial interface.
system :serialAB do
    input :clk, :rst
    output :result

    inner :sdat              # Serial data line
    # inner :rdy, :ack         # Serial control lines
    # inner[4..0] :wr_cnt      # Serial write counter
    # inner[4..0] :rd_cnt      # Serial read counter

    { buf: [8], wr_cnt: [5], rdy: bit }.inner  :atb
    atb.define_method(:put?,&blk) do
        hif(wr_cnt==0) { blk.call; rdy <= 1 }
        helsif(wr_cnt==8) { rdy <= 0 }
    end
    atb.define_method(:put) { buf }

    { buf: [8], rd_cnt: [5], ack: bit }.inner  :bfa
    bfa.define_method(:get?,&blk) do
        hif(rd_cnt==8) { blk.call; ack <= 1 }
        helsif(rd_cnt==0) {ack <= 0 }
    end
    bfa.define_method(:put) { buf }

    # Handle the serial transmission writer side.
    par(clk.posedge) do
        hif(rdy == 1 && wr_cnt < 8) do
            sdat <= atb.buf[wr_cnt]
            wr_cnt <= wr_cnt + 1
        end
        helsif(rdy==0) { wr_cnt <= 0 }
    end

    # Handle the serial transmission reader side.
    par(clk.negedge) do
        hif(ack == 1 && rd_cnt > 0) do
            bfa.buf[rd_cnt-1] <= sdat
            rd_cnt <= rd_cnt - 1
        end
        helsif(ack==0) { rd_cnt <= 8 }
    end

    systemA(atb).(:sysA).(data: a2b, rst: rst, tx: atb)
    systemB(bfa).(:sysB).(data: a2b, result: result, rx: bfa)
end


# Instantiate it for checking.
serialAB :serialABI

# Generate the low level representation.
low = serialABI.to_low

# Displays it
puts low.to_yaml
