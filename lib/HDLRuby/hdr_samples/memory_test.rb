require 'std/memory.rb'

raise "std/memory.rb is deprecated."

include HDLRuby::High::Std


# Sample code for testing the memory library.

system :memory_test do
    
    # The test step counter.
    [8].inner :step
    # The success counter.
    [4].inner :yay

    # The clock and reset.
    inner :clk, :rst

    # The memory address.
    [3].inner :address
    # The value to write to memories.
    [8].inner :value
    # The general result register.
    [8].inner :result
    # The specific result registers.
    [8].inner :res0, :res1, :res2, :res3, :res4, :res5, :res6, :res7

    # Declares a one-ports synchronous memory.
    mem_sync(1,[8],8,clk.negedge,rst,[:rst]).(:mem_sync_1I)
    # And the corresponding access ports.
    mem_sync_1I.branch(0).inner :mem_sync_1P

    # Declares a dual-edge memory for address-based accesses.
    mem_dual([8],8,clk,rst,raddr: :rst, waddr: :rst).(:mem_dual0I)
    # And the corresponding access ports.
    mem_dual0I.branch(:raddr).inner :mem_dual_raddrP
    mem_dual0I.branch(:waddr).inner :mem_dual_waddrP

    # Declares a second dual-edge memory for incremeted accesses.
    mem_dual([8],8,clk,rst, rinc:  :rst, winc:  :rst).(:mem_dual1I)
    # And the corresponding access ports.
    mem_dual1I.branch(:rinc).inner :mem_dual_rincP
    mem_dual1I.branch(:winc).inner :mem_dual_wincP

    # Declares a thrid dual-edge memory for decremented accesses.
    mem_dual([8],8,clk,rst, rdec:  :rst, wdec:  :rst).(:mem_dual2I)
    # And the corresponding access ports.
    mem_dual2I.branch(:rdec).inner :mem_dual_rdecP
    mem_dual2I.branch(:wdec).inner :mem_dual_wdecP

    # Declares a first register file for address-based accesses.
    mem_file([8],8,clk,rst,raddr: :rst, waddr: :rst).(:mem_file0I)
    # And the corresponding access ports.
    mem_file0I.branch(:raddr).inner :mem_file_raddrP
    mem_file0I.branch(:waddr).inner :mem_file_waddrP

    # Declares a second register file for incremeted accesses.
    mem_file([8],8,clk,rst, rinc:  :rst, winc:  :rst).(:mem_file1I)
    # And the corresponding access ports.
    mem_file1I.branch(:rinc).inner :mem_file_rincP
    mem_file1I.branch(:winc).inner :mem_file_wincP

    # Declares a third register file for decremeted accesses.
    mem_file([8],8,clk,rst, rdec:  :rst, wdec:  :rst).(:mem_file2I)
    # And the corresponding access ports.
    mem_file2I.branch(:rdec).inner :mem_file_rdecP
    mem_file2I.branch(:wdec).inner :mem_file_wdecP

    # Declares a forth register file for num accesses.
    mem_file([8],8,clk,rst, anum:  :rst).(:mem_file3I)
    # And the corresponding access port.
    mem_file3I.branch(:anum).inner :mem_file_anumP

    # Declares a fifth register file for num accesses.
    mem_file([8],8,clk,rst, anum:  :rst).(:mem_file4I)
    # And the corresponding access port: individual accesses.
    mem_file4I.branch(:anum).inner :mem_file_anum1P
    mem_file_fixP = [ mem_file_anum1P.wrap(0), mem_file_anum1P.wrap(1),
                      mem_file_anum1P.wrap(2), mem_file_anum1P.wrap(3),
                      mem_file_anum1P.wrap(4), mem_file_anum1P.wrap(5),
                      mem_file_anum1P.wrap(6), mem_file_anum1P.wrap(7) ]


    # Tests the accesses to the memories.
    par(clk.posedge) do
        # Initial address and value.
        hif(rst) { address <= 0; value <= 0 }

        # Handles the memory accesses.
        hcase(step)
        # Write to mem_sync_1
        hwhen(1) do
            mem_sync_1P.write(address,value) do
                yay <= yay + 1 
                address <= address + 1
                value <= value + 1
            end
        end
        # Read from to mem_sync_1
        hwhen(2) do
            mem_sync_1P.read(address,result) do
                yay <= yay + 1 
                address <= address + 1
            end
        end
        # Write to mem_dual0 with address
        hwhen(3) do
            mem_dual_waddrP.write(address,value) do
                yay <= yay + 1 
                address <= address + 1
                value <= value + 1
            end
        end
        # Read from mem_dual0 with address
        hwhen(4) do
            mem_dual_raddrP.read(address,result) do
                yay <= yay + 1 
                address <= address + 1
            end
        end
        # Write to mem_dual1 with increment
        hwhen(5) do
            mem_dual_wincP.write(value) do
                yay <= yay + 1 
                value <= value + 1
            end
        end
        # Read from mem_dual1 with increment
        hwhen(6) do
            mem_dual_rincP.read(result) do
                yay <= yay + 1 
            end
        end
        # Write to mem_dual2 with decrement
        hwhen(7) do
            mem_dual_wdecP.write(value) do
                yay <= yay + 1 
                value <= value + 1
            end
        end
        # Read from mem_dual1 with decrement
        hwhen(8) do
            mem_dual_rdecP.read(result) do
                yay <= yay + 1 
            end
        end
        # Write to mem_file0 with address
        hwhen(9) do
            mem_file_waddrP.write(address,value) do
                yay <= yay + 1 
                address <= address + 1
                value <= value + 1
            end
        end
        # Read from mem_file0 with address
        hwhen(10) do
            mem_file_raddrP.read(address,result) do
                yay <= yay + 1 
                address <= address + 1
            end
        end
        # Write to mem_file1 with increment
        hwhen(11) do
            mem_file_wincP.write(value) do
                yay <= yay + 1 
                value <= value + 1
            end
        end
        # Read from mem_file1 with increment
        hwhen(12) do
            mem_file_rincP.read(result) do
                yay <= yay + 1 
            end
        end
        # Write to mem_file2 with increment
        hwhen(13) do
            mem_file_wdecP.write(value) do
                yay <= yay + 1 
                value <= value + 1
            end
        end
        # Read from mem_file2 with increment
        hwhen(14) do
            mem_file_rdecP.read(result) do
                yay <= yay + 1 
            end
        end
        # Write to mem_file3 with num access
        hwhen(15) do
            mem_file_anumP.write(0,0)
            mem_file_anumP.write(1,1)
            mem_file_anumP.write(2,2)
            mem_file_anumP.write(3,3)
            mem_file_anumP.write(4,4)
            mem_file_anumP.write(5,5)
            mem_file_anumP.write(6,6)
            mem_file_anumP.write(7,7) do
                yay <= 8
            end
        end
        # Read from mem_file3 with num access
        hwhen(16) do
            mem_file_anumP.read(0,res0)
            mem_file_anumP.read(1,res1)
            mem_file_anumP.read(2,res2)
            mem_file_anumP.read(3,res3)
            mem_file_anumP.read(4,res4)
            mem_file_anumP.read(5,res5)
            mem_file_anumP.read(6,res6)
            mem_file_anumP.read(7,res7) do
                yay <= 8
            end
        end
        # Write to mem_file3 with num access
        hwhen(17) do
            mem_file_fixP[0].write(1)
            mem_file_fixP[1].write(2)
            mem_file_fixP[2].write(4)
            mem_file_fixP[3].write(8)
            mem_file_fixP[4].write(16)
            mem_file_fixP[5].write(32)
            mem_file_fixP[6].write(64)
            mem_file_fixP[7].write(128) do
                yay <= 8
            end
        end
        # Read from mem_file3 with num access
        hwhen(18) do
            mem_file_fixP[0].read(res0)
            mem_file_fixP[1].read(res1)
            mem_file_fixP[2].read(res2)
            mem_file_fixP[3].read(res3)
            mem_file_fixP[4].read(res4)
            mem_file_fixP[5].read(res5)
            mem_file_fixP[6].read(res6)
            mem_file_fixP[7].read(res7) do
                yay <= 8
            end
        end
    end


    timed do
        # Initialize everything.
        clk <= 0
        rst <= 0
        step <= 0
        yay <= 0
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
        step <= 1

        # Testing the synchronous memories.
        256.times do
            !10.ns
            clk <= 1
            !10.ns
            hif(yay==8) do
                step <= step + 1
                yay <= 0
            end
            clk <= 0
        end
    end
end
