require 'std/memory.rb'

include HDLRuby::High::Std




# A system accessing a memory.
system :periph do |mem|
    # Inputs of the peripheral: clock and reset.
    input :clk, :rst

    # Inner 8-bit counter for generating addresses.
    [8].inner :address
    # Inner 8-bit counter for generating values.
    [8].inner :value
    # The memory port.
    mem.inout :memP


    # The value production process
    par(clk.posedge) do
        hif(rst) do
            address <= 0
        end
        memP.read(address,value) do
            value <= value + 1
            memP.write(address,value) { address <= address + 1 }
        end
    end
end

# A system producing data and writing it to a memory.
system :producer do |mem|
    # Clock and reset.
    input :clk, :rst
    # The memory port.
    mem.output :memP

    # Inner 8-bit counter for generating addresses and values
    [8].inner :count

    # The value production process.
    par(clk.posedge) do
        hif(rst) { count <= 0 }
        helse do
            memP.write(count,count) { count <= count + 1 }
        end
    end
end

# A system consuming data from a memory.
system :consumer do |mem|
    # Clock and reset.
    input :clk, :rst
    # The accumumated consumed data list.
    [8].output :sum
    # The memory port.
    mem.input :memP

    # Inner 8-bit counter for generating addresses and values
    [8].inner :count
    # Memory access result.
    [8].inner :res

    # The value production process.
    par(clk.posedge) do
        hif(rst) do
            count <= 255
            sum <= 0
        end
        helse do
            memP.read(count,res) do
                count <= count + 1
                sum <= sum + res
            end
        end
    end
end



# A system testing the memory.
system :mem_test do
    input :clk,:rst

    # Declares a dual-port 8-bit data and address synchronous memory
    # on negative edge of clk.
    mem_sync(2,[8],256,clk.negedge,rst,[:rst,:rst]).(:memI)

    # Instantiate the producer to access port 1 of the memory.
    periph(memI.branch(1)).(:periphI).(clk,rst)
    # periph(memI).(:periphI).(clk,rst)
    memI.branch(0).inner :mem0

    # Inner 8-bit counter for generating addresses.
    [8].inner :address
    # Inner 8-bit counter for generating values.
    [8].inner :value

    # Access the memory.
    par(clk.posedge) do
        hif(rst) do
            address <= 255; value <= 128
        end
        # memI.write(0,address,value) { address <= address - 1 }
        mem0.write(address,value) { address <= address - 1 }
    end


    [8].inner :sum0, :sum1

    # Declares a dual edge 8-bit data and address memory.
    mem_dual([8],256,clk,rst, raddr: :rst,waddr: :rst).(:memDI)

    # Instantiate the producer to access port waddr of the memory.
    producer(memDI.branch(:waddr)).(:producerI0).(clk,rst)

    # Instantiate the producer to access port raddr of the memory.
    consumer(memDI.branch(:raddr)).(:consumerI0).(clk,rst,sum0)


    # Declares a 4-bank 8-bit data and address memory.
    mem_bank([8],4,256/4,clk,rst, raddr: :rst, waddr: :rst).(:memBI)

    # Instantiate the producer to access port waddr of the memory.
    producer(memBI.branch(:waddr)).(:producerI1).(clk,rst)

    # Instantiate the producer to access port raddr of the memory.
    consumer(memBI.branch(:raddr)).(:consumerI1).(clk,rst,sum1)


end
