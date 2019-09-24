require '../std/fsm.rb'
require '../std/decoder.rb'
include HDLRuby::High::Std

# A simple implementation of the MEI8 processor.
#
# In this implementation, the program is hard-coded in an internal ROM
system :mei8 do |prog_file = "./prog.obj"|
    # Clock and reset.
    input :clk, :rst
    # Bus.
    output     :req, :rwb
    [8].output :addr
    [8].inout  :dbus
    input      :ack
    # Interrupts.
    input :iq0, :iq1
    # The signals for controlling the io unit.
    inner :io_req, :io_rwb, :io_done # Request, read/not write, done.
    inner :io_r_done                 # Read done.
    [8].inner :io_out,:io_in         # The write and read inner buses.
    [8].inner :data                  # The read buffer.

    # The rom containing the program.
    instance :prog do
        [7..0].input  :addr          # The address bus
        [7..0].output :instr         # The instruction bus
        bit[7..0][-256].constant content: # The content of the memory
            File.readlines(prog_file).map {|l| l.split[0].to_i(2)}
        instr <= content[addr]       # The access procedure
    end

    # The registers.
    [8].inner :a, :b, :c, :d, :e, :f, :g, :h # General purpose registers
    inner     :zf, :cf, :sf, :vf             # Flags
    [8].inner :ir                            # Instruction register
    [8].inner :pc                            # Program counter
    [8].inner :s                             # Status register

    # The ALU 
    instance :alu do
        [4].input  :opr                      # The operator bus
        [8].input  :x,:y                     # The input buses
        [8].output :z                        # The output bus
        output :zf, :cf, :sf, :vf            # The flag signals

        # The only adder instance.
        instance :add do
            [8].input :x,:y                  # The input buses
            input :cin                       # The input carry
            [9].output :z                    # The output bus (including
                                             # the output carry)
            z <= x.as([9])+y+cin
        end

        # The control part for choosing between 0, add, sub and neg.
        par do
            # Default computations
            cf <= 0; vf <= 0; zf <= (z == 0); sf <= z[7]
            add.(0,0,0)
            # Depending on the operator
            hcase(opr)
            hwhen(0)  { add.(x ,y ,0,[cf,z])                 # add
                        vf <= (~x[7] & ~y[7] & z[7]) | (x[7] & y[7] & ~z[7]) }
            hwhen(1)  { add.(x ,~y,1,[cf,z])                 # sub
                        vf <= (~x[7] & y[7] & z[7]) | (x[7] & ~y[7] & ~z[7]) }
            hwhen(2)  { add.(x ,0 ,1,[cf,z])                 # inc
                        vf <= (~x[7] & ~y[7] & z[7]) | (x[7] & y[7] & ~z[7]) }
            hwhen(3)  { add.(x ,0xFF ,0,[cf,z])              # dec
                        vf <= (~x[7] & ~y[7] & z[7]) | (x[7] & y[7] & ~z[7]) }
            hwhen(4)  { z <= x & y }                         # and
            hwhen(5)  { z <= x | y }                         # or
            hwhen(6)  { z <= x ^ y }                         # xor
            hwhen(7)  { z <= x }                             # mov
            hwhen(8)  { add.(~x,0 ,1,[cf,z])                 # neg
                        vf <= (x[7] & ~z[7]) }
            hwhen(9)  { z <= ~x }                            # not
            hwhen(10) { z <= x << 1 ; cf <= x[7] }           # shl
            hwhen(11) { z <= x >> 1 ; cf <= x[0] }           # shr
            hwhen(12) { z <= [x[7], x[7..1] ] ; cf <= x[0] } # sar
            helse     { z <= 0 }                             # zero
        end
    end

    # Signals relative to the decoder
    [3].inner :dst           # Index of the destination register.
    [8].inner :src0, :src1   # Values of the source registers.
    inner :branch  # Tells if the instruction is a branch.
    inner :cc      # Tells if a branch condition is met.
    inner :wr, :wf # Tells the computation result is to write to a gpr/flag.
    inner :ld, :st # Tells if the instruction is a load/store.
    inner :iq_calc # Tells if the interrupt unit is preempting calculation.

    # The decoder.
    par do
        # By default, no branch, no load, no store, write to gpr but not to
        # flags and destination is a and output value is a
        branch <= 0; ld <= 0; st <= 0; wr <= 1; wf <= 0; dst <= 0; io_out <= a
        # And transfer 0.
        alu.(15,0,0)
        # Compute the possible sources
        src0 <= mux(ir[5..3],a,b,c,d,e,f,g,h)
        src1 <= mux(ir[2..0],a,b,c,d,e,f,g,h)
        # Compute the branch condition.
        cc <= mux(ir[5..3],1,zf,cf,sf,vf,~zf,0)
        # Is it an interrupt?
        hif (iq_calc) { alu.(2,h,0) }
        # No, do a normal decoding of the instruction in ir.
        helse do 
            decoder(ir) do
                # Format 0
                entry("00000000") { wr <= 0 }             # nop
                entry("00xxxyyy") { 
                     hif (x == y) { alu.(15,0,0) }        # mov 0,y
                     helse        { alu.(7,src0) }        # mov x,y
                                    dst <= y }
                # Format 1
                entry("01oooyyy") { wf <= 1
                                    # Destination is also y in case of inc/dec
                                    hif (ir[6..4] == _101) { dst <= y }
                                    alu.(o,a,src1) }      # binary alu
                # Format 1 extended.
                entry("10000yyy") { wr <= 0; wf <= 1
                                    alu.(1,a,src1) }      # cp y
                entry("10001yyy") { ld <= 1; dst <= y }   # ld y
                entry("10010yyy") { st <= 1; wr <= 0      # st y
                    [a,b,c,d,e,f,g,h].hcase(y) {|r| io_out <= r } }
                entry("10011yyy") { branch <= 1           # jr y, must inc y
                                    alu.(2,src1) }        # since pc-1 is used
                # Format 2
                entry("1010iiii") { alu.(7,[_0000,i]) }   # movl i
                entry("1011iiii") { alu.(7,[i,a[3..0]]) } # movh i
                # Format 4
                entry("11110110") { branch <= 1           # trap
                                    alu.(7,0xFC)  }       
                entry("11110ooo") { wf <= 1; alu.([_1,o],a) } # unary alu
                entry("111110os") { st <= s; ld <= ~s     # ++--ld / ++--st
                                    alu.([_1,o],g); dst <= 6 }
                entry("1111110i") { branch <= i
                                    st <= ~i; ld <= i
                                    alu.([_1,~i],h)
                                    dst <= 7; io_out <= pc } # push / pop pc
                # Format 3
                entry("11cccsii") { branch <= cc; wr <= 0
                                    alu.(0,pc,[s]*6+[i]) }# br c i
                # xs / halt / reset: treated without decoding
            end
        end
    end

    # The io unit.
    fsm(clk.posedge,rst,:async) do
        default       { io_done <= 0; req <= 0; rwb <= 0; addr <= 0
                        io_r_done <= 0
                        # Default handling of the 3-state data bus
                        hif(io_rwb) { dbus <= _zzzzzzzz }
                        helse       { dbus <= io_out }
                        io_in <= dbus }
        reset(:sync)  { data <= 0; }
        state(:wait)  { goto(io_req,:start,:wait) }        # Waiting for an IO
        state(:start) { req <= 1; rwb <= io_rwb; addr <= g # Start an IO
                        goto(ack,:end,:start) }   # Wait exteral ack to end IO
        sync(:start)  { data <= io_in }
        state(:end)   { io_done <= 1; io_r_done <= io_rwb  # End IO 
                        goto(:wait) }
    end

    inner :calc    # Tell if calculation is to be writen back to a register.
    inner :init    # Tell CPU is in initialization mode (soft reset).

    [8].inner :npc # Next pc
    inner     :nbr # Tell if must branch next.

    # Write back unit: handles the writing to registers.
    par(clk.posedge) do
        nbr <= 0; npc <= 0 # By default no branch to schedule.
        hif(rst) do
            # In case of hard reset all the registers of the operative part
            # are to put to 0.
            [a,b,c,d,e,f,g,h,zf,cf,sf,vf,nbr,npc,s].each { |r| r <= 0 }
        end
        # Ensures a is 0 and enable interrupts when starting.
        helsif(init) { a<= 0; s <= _00000011; } 
        helsif(iq_calc) do
            s[7] <= 1
            hif(iq1) { s[1] <= 0 }
            helse    { s[0] <= 0 }
            h <= alu.z
        end
        helsif(calc) do
            hif wr do # Write to the destination gpr.
                [a,b,c,d,e,f,g,h].hcase(dst) { |r| r <= alu.z }
            end
            hif wf do # Write the the flags.
                zf <= alu.zf; cf <= alu.cf; sf <= alu.sf; vf <= alu.vf
            end
            # Specific cases
            hif(ir == _11110111) { s <= a; a <= s } # xs
            hif(ir == _11110110) { s[7] <= 1 }      # trap
            hif(branch) { npc <= alu.z; nbr <= 1 }  # Branch
        end
        # Write memory read result to a register if any.
        helsif (io_r_done) do
            hif(branch) { npc <= data; nbr <= 1 }   # pop case  
            helsif(ir[7..3] == _10001) do           # ld case
                [a,b,c,d,e,f,g,h].hcase(dst) {|r| r <= data }
            end
            helse { a <= data }                     # ld++-- case
        end
    end

    prog.addr <= pc # Buses permanent connections.

    inner :iq_chk # Interrupt check buffer.

    # The main FSM
    fsm(clk.posedge,rst,:async) do
        default      { init <= 0; calc <= 0; io_req <= 0; io_rwb <= 1
                       iq_calc <= 0 }
        reset(:sync) { pc <= 0; ir <= 0; iq_chk <= 0 }        # Hard reset
        # Soft reset state.
        state(:re)   { init <= 1 }
        sync(:re)    { pc <= 0; ir <= 0; iq_chk <= 0 } 
        # Standard execution states.
        state(:fe)   { }
        sync(:fe)    { ir <= prog.instr; pc <= pc + 1          # Standard fetch
                       iq_chk <= (iq0 & s[0]) | (iq1 & s[1]) } # Check interrupt
        state(:ex)   { calc <= 1                  # Activate the write back unit
                       hif(ld|st) { io_req <= 1; io_rwb <= ld } # Prepare IO unit if ld or st
                       goto(:fe)                  # By default execution is over
                       goto(iq_chk,:iq_s)         # Interrupt / No interrupt
                       goto(branch,:br)           # Branch instruction
                       goto((ld|st) & ~io_done,:ld_st) # ld/st instruction
                       goto(ir == _11111110,:ht)       # Halt instruction
                       goto(ir == _11111111,:re) }     # Reset instruction
        # Branch state.
        state(:br)   { goto(iq_chk,:iq_s,:fe) }   # Interrupt / No interrupt
        sync(:br)    { hif(nbr) { pc <= npc-1 } } # Next pc is the branch target
        # State waiting the end of a load/store.
        state(:ld_st){ io_rwb <= ld           # Tell IO unit if read or write
                       goto(branch,:br,:fe)   # In case of pop, branch after ld
                       goto(~io_done,:ld_st)  # ld/et not finished yet
                       goto(io_done & iq_chk,:iq_s)}# Interrupt / No interrupt
        # States handling the interrupts.
        # Push PC
        state(:iq_s) { iq_calc <= 1; 
                       io_req <= 1; io_rwb <= 0; # io_out <= pc 
                       goto(io_done, :iq_d, :iq_s) }
        # Jump to interrupt handler.
        state(:iq_d) { goto(:fe) }
        sync(:iq_d)  { pc <= 0xF8 }
        # State handling the halt (until a reset or an interrupt).
        state(:ht)   { goto(iq_chk,:iq_s,:ht) }  # Interrupt / No interrupt
        sync(:ht)    { iq_chk <= (iq0 & s[0]) | (iq1 & s[1]) }
    end
end
