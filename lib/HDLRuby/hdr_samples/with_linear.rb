require 'std/memory.rb'
require 'std/linear.rb'

include HDLRuby::High::Std

# Tries for matrix-vector product.





# Testing.
system :testmat do

    inner :clk,:rst, :req

    # Input memories
    # mem_dual([8],256,clk,rst, rinc: :rst,winc: :rst).(:memL0)
    # The first memory is 4-bank for testing purpose.
    mem_bank([8],4,256/4,clk,rst, rinc: :rst,winc: :rst).(:memL0)
    # The others are standard dual-edge memories.
    mem_dual([8],256,clk,rst, rinc: :rst,winc: :rst).(:memL1)
    mem_dual([8],256,clk,rst, rinc: :rst,winc: :rst).(:memR)
    # Access ports.
    memL0.branch(:rinc).inner :readL0
    memL1.branch(:rinc).inner :readL1
    memR.branch(:rinc).inner :readR

    # Prepares the left and acc arrays.
    lefts = [readL0, readL1]

    # Accumulators memory.
    mem_file([8],2,clk,rst,rinc: :rst).(:memAcc)
    memAcc.branch(:anum).inner :accs
    accs_out = [accs.wrap(0), accs.wrap(1)]

    # Layer 0 ack.
    inner :ack0
    
    # Instantiate the matrix product.
    mac_n1([8],clk,req,ack0,lefts,readR,accs_out)

    # Translation.
    # Translation memory.
    mem_file([8],2,clk,rst,winc: :rst).(:memT)
    # Tarnslation result
    mem_file([8],2,clk,rst,rinc: :rst).(:memF)
    # Access ports.
    memT.branch(:anum).inner :readT
    memF.branch(:anum).inner :writeF
    regRs = [ readT.wrap(0), readT.wrap(1) ]
    regLs = [ accs.wrap(0), accs.wrap(1) ]
    regs =  [ writeF.wrap(0), writeF.wrap(1) ]

    # Translater ack.
    inner :ackT

    # Instantiate the translater.
    add_n([8],clk,ack0,ackT,regLs,regRs,regs)



    # Second layer.
    # Input memories.
    mem_dual([8],2,clk,rst, rinc: :rst,winc: :rst).(:mem2L0)
    # Access ports.
    mem2L0.branch(:rinc).inner :read2L0
    # memAcc.branch(:rinc).inner :accsR
    memF.branch(:rinc).inner :readF

    # Second layer ack.
    inner :ack1

    # Result.
    [8].inner :res

    sub do
        # Instantiate the second matrix product.
        # mac([8],clk,req,read2L0,accsR,res)
        mac([8],clk,ackT,ack1,read2L0,readF,channel_port(res))
    end



    # The memory initializer.
    memL0.branch(:winc).inner :writeL0
    memL1.branch(:winc).inner :writeL1
    memR.branch(:winc).inner :writeR
    memT.branch(:winc).inner :writeT
    mem2L0.branch(:winc).inner :write2L0
    inner :fill, :fill2
    [8].inner :val
    par(clk.posedge) do
        hif(fill) do
            writeL0.write(val)
            writeL1.write(val+1)
            writeR.write(val+1)
        end
        hif(fill2) do
            write2L0.write(val+2)
            writeT.write(val+2)
        end
    end

    timed do
        req <= 0
        clk <= 0
        rst <= 0
        fill <= 0
        fill2 <= 0
        val  <= 0
        !10.ns
        # Reset the memories.
        rst <= 1
        !10.ns
        clk <= 1
        !10.ns
        # Fill the memories.
        # First layer
        clk <= 0
        rst <= 0
        fill <= 1
        !10.ns
        256.times do |i|
            clk <= 1
            !10.ns
            clk <= 0
            val <= val + 1
            !10.ns
        end
        fill <= 0
        clk <= 1
        !10.ns
        # Second layer
        clk <= 0
        rst <= 0
        fill2 <= 1
        !10.ns
        2.times do |i|
            clk <= 1
            !10.ns
            clk <= 0
            val <= val + 1
            !10.ns
        end
        fill2 <= 0
        clk <= 1
        !10.ns
        clk <= 0
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        !10.ns
        # Launch the computation
        clk <= 0
        req <= 1
        !10.ns
        300.times do
            clk <= 1
            !10.ns
            clk <= 0
            !10.ns
        end
    end
end
