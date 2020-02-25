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
        hif(rst) { address <= 0 }
        helse do
            memP.read(address,value) do
                value <= value + 1
                memP.write(address,value) { address <= address + 1 }
            end
        end
    end
end



# A system testing the memory.
system :mem_test do
    input :clk,:rst

    # Declares a dual-port 8-bit data and address synchronous memory
    # on negative edge of clk.
    mem_sync(2,[8],256,clk.negedge).(:memI)

    # Instantiate the producer to access port 1 of the memory.
    periph(memI.port(1)).(:periphI).(clk,rst)

    # Inner 8-bit counter for generating addresses.
    [8].inner :address
    # Inner 8-bit counter for generating values.
    [8].inner :value

    # Access the memory.
    par(clk.posedge) do
        hif(rst) { address <= 255; value <= 128 }
        helse do
            memI.write(0,address,value) { address <= address - 1 }
        end
    end

end
