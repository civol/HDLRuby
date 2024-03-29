require 'std/memory.rb'
require 'std/linear.rb'
# require 'std/timing.rb'

raise "std/memory.rb is deprecated."

include HDLRuby::High::Std


system :fir do |typ,iChannel,oChannel,coefs|
    input :clk, :rst, :req
    output :ack
    # Declare the input port.
    iChannel.input :iPort
    # Declare the output port.
    oChannel.output :oPort

    # Declares the data registers.
    datas = coefs.map.with_index do |coef,id|
        coef.type.inner :"data_#{id}"
    end

    inner :req2
    

    # Generate the mac pipeline.
    mac_np(typ,clk.posedge,req2,ack, 
          datas.map{|data| channel_port(data) },
          coefs.map{|coef| channel_port(coef) }, oPort)

    # Generate the data transfer through the pipeline.
    par(clk.posedge) do
        req2 <= 0
        hif(rst) { datas.each { |d| d <= 0 } }
        hif(req) do
            iPort.read(datas[0]) do
                # datas.each_cons(2) { |d0,d1| d1 <= d0 }
                datas[1..-1] <= datas[0..-2]
            end
            req2 <= 1
        end
    end
end





system :work do

    inner :clk,:rst,:req,:ack

    # The input memory.
    mem_rom([8],8,clk,rst,
            [_b00000001,_b00000010,_b00000011,_b00000100,
             _b00000101,_b00000110,_b00000111,_b00001000]).(:iMem)
    # The output memory.
    mem_dual([8],8,clk,rst).(:oMem)
    # The coefficients.
    coefs = [_b11001100,_b00110011,_b10101010,_b01010101,
             _b11110000,_b00001111,_b11100011,_b00011100]

    # The filter
    fir([8],iMem.branch(:rinc),oMem.branch(:winc),coefs).(:my_fir).(clk,rst,req,ack)

    # iMem.branch(:rinc).inner :port
    # [8].inner :a
    # par(clk.posedge) do
    #     hif(req) { port.read(a) }
    # end

    timed do
        req <= 0
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
        rst <= 0
        !10.ns
        clk <= 1
        !10.ns
        req <= 1
        clk <= 0
        64.times do
            !10.ns
            clk <= 1
            !10.ns
            clk <= 0
        end
    end
end
