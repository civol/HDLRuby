require 'HDLRuby/backend/allocator'

## A generic CPU description
class CPU

    ## Allocator assotiated with the bus of the CPU
    attr_reader :allocator

    ## The clock.
    attr_reader :clk
    ## The reset.
    attr_reader :rst

    ## The address bus
    attr_reader :abus
    ## The data bus
    attr_reader :dbus
    ## The read/!write selection
    attr_reader :rwb
    ## The request
    attr_reader :req
    ## The acknowledge
    attr_reader :ack

    ## Creates a new generic CPU whose data bus is +dwidth+ bit wide,
    #  address bus is +awidth+ bit wide, clock is +clk+, reset +rst+.
    def initialize(dwidth,awidth,clk,rst)
        # Check and set the word and address bus widths
        awidth = awidth.to_i
        dwidth = dwidth.to_i
        @awidth = awidth
        @dwidth = dwidth
        # Check and set the signals.
        @clk = clk.to_ref
        @rst = rst.to_ref
        # The allocator of the CPU
        @allocator = Allocator.new(0..(2**@addr),@data)

        # Declare the address and data buses and the
        # rwb/req/ack control signals
        abus,dbus    = nil,nil
        rwb,req,ack  = nil,nil,nil
        # Declares the data and address bus.
        HDLRuby::High.cur_system.open do
            abus = [awidth].input(HDLRuby.uniq_name)
            dbus = [dwidth].input(HDLRuby.uniq_name)
            rwb  = input(HDLRuby.uniq_name)
            req  = input(HDLRuby.uniq_name)
            ack  = output(HDLRuby.uniq_name)
        end
        @abus,@dbus    = abus,dbus
        @rwb,@req,@ack = rwb,req,ack
    end

    ## Connect signal +sig+ to the bus allocating an address to access it.
    def connect(sig)
        # Allocates the signal in the address space.
        @allocator.allocate(sig)
    end

    ## Generates the bus controller.
    def controller
        clk,rst,req,ack = @clk,@rst,@req,@ack
        abus,dbus,rwb   = @abus,@dbus,@rwb
        allocator       = @allocator
        HDLRuby::High.cur_system.open do
            par(clk) do
                # Bus controller
                hcase(abus)
                hif(req) do
                    ack <= 1
                    allocator.each do |sig,addr|
                        hwhen(addr) do
                            hif(rwb) { dbus <= sig }
                            helse    { sig <= dbus }
                        end
                    end
                end
                helse do
                    ack <= 0
                end
            end
        end

        ## Generates a read of sig executing +ruby_block+ on the result.
        def read(sig,&ruby_block)
            addr = @allocator.get(sig)
            hif(ack == 0) do
                @abus <= addr
                @rwb <= 1
                @req <= 1
            helse
                @req <= 0
                ruby_block.call(@dbus)
            end
        end

        ## Generates a write +val+ to +sig+ executing +ruby_block+
        #  in case of success.
        def write(val,sig,&ruby_block)
            addr = @allocator.get(sig)
            hif(ack == 0) do
                @abus <= addr
                @dbus <= val
                @rwb <= 0
                @req <= 1
            helse
                @req <= 0
                ruby_block.call
            end
        end
    end
end


# Simulates an 8-bit data 8-bit address CPU
class CPUSimu < CPU
    # Read and write are overwritten, save them before.
    alias_method :hw_read, :read
    alias_method :hw_write, :write


    ## Creates a new CPU simulator.
    def initialize(clk,rst)
        super(8,8,clk,rst)

        # The read and write control signals.
        @read_action  = inner(HDLRuby.uniq_name)
        @write_action = inner(HDLRuby.uniq_name)
        @value        = [8].inner(HDLRuby.uniq_name)

        # The CPU simulator code.
        this = self
        read_action,write_action = @read_action, @write_action
        value = @value
        par(this.posedge) do
            hif(this.rst) do
                read_action <= 0
                write_action <= 0
            end
            helse do
                hif(read_action) do
                    this.hw_read(this.target,value) do
                        read_action <= 0
                    end
                end
                helsif(write_action) do
                    this.hw_write(this.target,write_value) do
                        write_action <= 0
                    end
                end
            end
        end

        # The runtime code.
        code c: [
"unsigned char mem_read(unsigned char addr) {
    unsigned char res;
    write8(1,",@read_action,");
    wait_cond8(0,",@read_action,");
    return read8(",@value,");
}

void mem_write(unsigned char val, unsigned char addr) {
    unsigned char res;
    write8(1,",@write_action,");
    write8(val,",@value,");
    wait_cond8(0,",@write_action,");
}
"], h:
"extern unsigned char mem_read(unsigned char addr);
extern void mem_write(unsigned char val, unsigned char addr);
"
    end



    ## Generates a read of signal +sig+.
    def read(code,sig)
        # Generate the resulting SW access.
        return ["mem_read(",code,"0x#{self.allocator.get(sig).to_s(16)})"]
    end

    ## Generates a write of +val+ to signal +sig+.
    def write(val,sig)
        # Generate the resulting SW access.
        return ["mem_write(,",code,",#{val},#{self.allocator.get(sig).to_s(16)})"]
    end
end






# An 8-bit register with C encrypting.
system :encrypt_register do |cpu|
    input  :clk, :rst
    [8].input :d
    [8].output :q

    my_cpy = cpu.new(clk,rst)

    my_cpu.connect(d)
    my_cpu.connect(q)
    my_cpu.controller

    code clk.posedge, c: [ "
#include <stdio.h>
#include \"hruby_sim.h\"
#include \"hruby_sim_gen.h\"

void encrypt() {
    static char keys[] = { 'S', 'e', 'c', 'r', 'e', 't', ' ', '!' };
    static int index  = 0;
    char buf;
    buf = ",my_cpu.read(self,d),";
    printf(\"######################## From software: encrypting d=%x\\n\",buf);
    buf = buf ^ (keys[index]);
    index = (index + 1) & sizeof(keys)-1;
    printf(\"######################## From software: result =%x\\n\",buf);
    ",my_cpu.write(self,"buf",q),";
    
}
        " ],
        sim: "encrypt"
end

# A benchmark for the register.
system :encrypt_bench do
    [8].inner :d, :clk, :rst
    [8].inner :q

    encrypt_register(:my_register).(clk,rst,d,q)

    timed do
        clk <= 0
        rst <= 0
        d   <= 0
        !10.ns
        clk <= 1
        rst <= 0
        d   <= 0
        !10.ns
        clk <= 0
        rst <= 1
        d   <= 0
        !10.ns
        clk <= 1
        rst <= 1
        d   <= 0
        !10.ns
        clk <= 0
        rst <= 0
        d   <= 1
        !10.ns
        clk <= 1
        rst <= 0
        d   <= 1
        !10.ns
        clk <= 0
        rst <= 0
        d   <= 2
        !10.ns
        clk <= 1
        rst <= 0
        d   <= 2
        !10.ns
        clk <= 0
        rst <= 0
        d   <= 0
        !10.ns
        clk <= 1
        rst <= 0
        d   <= 255
        !10.ns
        clk <= 0
        rst <= 0
        d   <= 255
        !10.ns
        clk <= 1
        rst <= 0
        d   <= 255
        !10.ns
        clk <= 0
        rst <= 0
        d   <= 0
        !10.ns
        clk <= 1
        rst <= 0
        d   <= 0
        !10.ns
        clk <= 0
        rst <= 0
        d   <= 0
        !10.ns
        clk <= 1
        rst <= 0
        d   <= 0
        !10.ns
    end
end
