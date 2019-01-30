require '../std/fsm.rb'
require '../std/decoder.rb'
include HDLRuby::High::Std

# A simple implementation of the MEI8 processor.
#
# In this implementation, the program is hard coded in an internal ROM

system :mei8 do
    # Clock and reset.
    input :clk, :rst
    # Bus.
    output     :req, :rwb
    [8].output :addr
    [8].inout  :dbus
    input      :ack

    # Interrupts.
    input :iq0, :iq1

    # The rom containing the program.
    instance :prog do
        [7..0].input  :addr
        [7..0].output :instr

        bit[7..0][2**8].constant content: 
            File.readlines("./prog.obj").map {|l| l.split[0].to_i(2)}

        instr <= content[addr]
    end


    # The registers.
    [8].inner :a, :b, :c, :d, :e, :f, :g, :h # Data registers.
    inner :zf, :cf, :sf, :vf                 # Flags
    [8].inner :ir                            # Instruction register.
    [8].inner :pc                            # Program counter.
    [8].inner :s                             # Status register.


    # The ALU 
    instance :alu do
        [4].input  :opr
        [8].input :x,:y
        [8].output :z
        output :zf, :cf, :sf, :vf

        # The only adder instance.
        instance :add do
            [8].input :x,:y
            input :cin
            [9].output :z

            z <= x+y+cin
        end

        # The control part for choosing between 0, add, sub and neg.
        par do
            # Default computations
            cf <= 0
            vf <= 0
            zf <= (z == 0)
            sf <= z[7]
            add.(0,0,0)

            # Depending on the operator
            hcase(opr)
            # add
            hwhen(0)  { add.(x ,y ,0,[cf,z])
                        vf <= (~x[7] & ~y[7] & z[7]) | (x[7] & y[7] & ~z[7]) }
            # sub
            hwhen(1)  { add.(x ,~y,1,[cf,z])
                        vf <= (~x[7] & y[7] & z[7]) | (x[7] & ~y[7] & ~z[7]) }
            # inc
            hwhen(2)  { add.(x ,0 ,1,[cf,z])
                        vf <= (~x[7] & ~y[7] & z[7]) | (x[7] & y[7] & ~z[7]) }
            # dec
            hwhen(3)  { add.(x ,0xFF ,0,[cf,z])
                        vf <= (~x[7] & ~y[7] & z[7]) | (x[7] & y[7] & ~z[7]) }
            # and
            hwhen(4)  { z <= x & y }
            # or
            hwhen(5)  { z <= x | y }
            # xor
            hwhen(6)  { z <= x ^ y }
            # mov
            hwhen(7)  { z <= x }
            # neg
            hwhen(8)  { add.(~x,0 ,1,[cf,z])
                        vf <= (x[7] & ~z[7]) }
            # not
            hwhen(9)  { z <= ~x }
            # shl
            hwhen(10) { z <= x << 1 ; cf <= x[7] }
            # shr
            hwhen(11) { z <= x >> 1 ; cf <= x[0] }
            # sar
            hwhen(12) { z <= [x[7], x[7..1] ] ; cf <= x[0] }
            helse     { z <= 0 }
        end
    end

    # Signals relative to the decoder
    
    [3].inner :dst           # Index of the destination register.
    [8].inner :src0, :src1   # Values of the source registers.
    inner  :branch  # Tells if the instruction is a branch.
    inner  :cc      # Tells if a branch condition is met.
    inner  :wr, :wf # Tells the computation result is to write to a gpr/flag.
    inner  :ld      # Tells if the instruction is a load.
    inner  :st      # Tells if the instruction is a store.

    inner :iq_calc  # Tells some the interrupt unit is preempting calculation.

    # Compute the source register value.
    def getsrc(idx,src)
        src <= mux(idx,a,b,c,d,e,f,g,h)
    end

    # The decoder.
    par do
        # By default, no branch, no load, no store, write to gpr but not to
        # flags and destination is a.
        branch <= 0; ld <= 0; st <= 0; wr <= 1; wf <= 0
        dst <= 0
        # And transfer 0.
        alu.(15,0,0)
        # Compute the possible source 2
        getsrc(ir[5..3],src0)
        getsrc(ir[2..0],src1)
        # Compute the branch condition.
        cc <= mux(ir[5..3],1,zf,cf,sf,vf,~zf,0)
        # Is it an interrupt?
        hif (iq_calc) { alu.(2,h,0) }
        # No, do normal decoding.
        helse do
            # Depending on the instruction.
            decoder(ir) do
                # Format 0
                entry("00000000") { wr <= 0 }             # nop
                entry("00sssddd") { 
                     hif (s == d) { alu.(15,0,0) }        # mov 0,d
                     helse        { alu.(7,src0) }        # mov s,d
                                    dst <= ir[2..0] }
                # Format 1
                entry("01ooosss") { wf <= 1
                                    alu.(o,a,src1) }      # alu s
                # Format 1 extended.
                entry("10000sss") { wr <= 0; wf <= 1
                                    alu.(1,src1) }        # cp s
                entry("10001ddd") { ld <= 1; dst <= d }   # ld s
                entry("10010sss") { st <= 1; wr <= 0 }    # st s
                entry("10011sss") { branch <= 1
                                    alu.(7,src1) }        # jr s
                # Format 2
                entry("1010iiii") { alu.(7,[_0000,i]) }   # movl i
                entry("1011iiii") { alu.(7,[i,a[3..0]]) } # movh i
                # Format 4
                entry("11110110") { branch <= 1
                                    alu.(7,0xFC)  }       # trap
                entry("11110ooo") { alu.([_1,o],a) }      # alu ( / xs)
                entry("111110ds") { st <= s; ld <= ~s
                                    alu.([_1,d],g)
                                    dst <= 6 }            # ++--ld / ++--st
                entry("1111110i") { branch <= i
                                    st <= ~i; ld <= i
                                    alu.([_1,~i],h)
                                    dst <= 7 }            # push / pop pc
                # Format 3
                entry("11cccsii") { branch <= cc; wr <= 0
                                    alu.(0,pc,[s]*6+[i]) }# br c i
                # halt / reset: treated in main fsm
            end
        end
    end


    # The signals for controlling the io unit.
    inner :io_req, :io_rwb, :io_done, :io_r_done
    [8].inner :io_out # The write buffer.
    [8].inner :io_in  # The read buffer.
    [8].inner :data

    # The io unit.
    fsm(clk.posedge,rst,:async) do
        default       { io_done <= 0; req <= 0; rwb <= 0
                        io_r_done <= 0
                        addr <= 0;
                        hif(io_rwb) { dbus <= _zzzzzzzz }
                        helse       { dbus <= io_out }
                        io_in <= dbus
                      }
        reset(:sync)  { data <= 0; }
        state(:wait)  { goto(io_req,:start,:wait) }
        state(:start) { req <= 1; rwb <= io_rwb
                        addr <= g
                        goto(ack,:end,:start) }
        sync(:start)  { data <= io_in }
        state(:end)   { io_done <= 1; io_r_done <= io_rwb
                        goto(:wait) }
    end

    inner :calc # Tell if calculation is to be stored.

    [8].inner :npc # Next pc
    inner     :nbr # Tell if must branch next.

    inner     :init # Tell CPU is in initialization

    # Writing to registers.
    par(clk.posedge) do
        nbr <= 0; npc <= 0 # By default no branch to schedule.
        hif(rst) do
            # In case of hard reset all the resgister of the operative part
            # are to put to 0.
            [a,b,c,d,e,f,g,h,zf,cf,sf,vf,nbr,npc,s].each do |r|
                r <= 0
            end
        end
        helsif(init) { s <= _00000011 }
        helsif(iq_calc) do
            s[7] <= 1
            hif(iq1) { s[1] <= 0 }
            helse    { s[0] <= 0 }
            h <= alu.z
        end
        helsif(calc) do
            # Write to the destination gpr.
            hif wr do
                hcase(dst)
                [a,b,c,d,e,f,g,h].each.with_index do |r,i|
                    hwhen(i) { r <= alu.z }
                end
            end
            hif wf do
                # Write the the flags.
                zf <= alu.zf; cf <= alu.cf; sf <= alu.sf; vf <= alu.vf
            end
            # Specific cases
            hif(ir == _11110111) do # xs
                s <= a
                a <= s
            end
            hif(ir == _11110110) do # trap
                s[7] <= 1
            end
            hif(branch) { npc <= alu.z; nbr <= 1 }
        end
        helsif (io_r_done) do
            a <= data
        end
    end

    # The control part

    # Interrupt flags computations.
    inner :iq_chk

    # Buses permanent connections.
    prog.addr <= pc

    # The main FSM
    fsm(clk.posedge,rst,:async) do
        default      { calc <= 0
                       io_req <= 0; io_rwb <= 1; io_out <= a
                       iq_calc <= 0; init <= 0
                     }
        reset(:sync) { pc <= 0; ir <= 0; iq_chk <= 0 }
        # Reset state.
        state(:re)   { init <= 1 }
        sync(:re)    { pc <= 0; ir <= 0
                       iq_chk <= 0
                     }
        # Standard execution states.
        state(:fe)   { }
        sync(:fe)    { ir <= prog.instr
                       pc <= pc + 1
                       iq_chk <= (iq0 & s[0]) | (iq1 & s[1]) # External interrupt check
                     }
        state(:ex)   { calc <= 1
                       hif (ld | st) { io_req <= 1; io_rwb <= ld }
                       goto(:fe)
                       goto(iq_chk,:iq_s,:fe)   # Interrupt / No interrupt
                       goto(branch,:br)
                       goto((ld | st) & ~io_done,:ld_st) # ld/st
                       goto(ir == _11111110,:ht) # Halt
                       goto(ir == _11111111,:re) # Reset
                     }
        state(:br)   { goto(iq_chk,:iq_s,:fe) # Interrupt / No interrupt
                     }
        sync(:br)    { hif(nbr) { pc <= npc - 1 } }
        # State waiting the end of a load/store.
        state(:ld_st){ io_rwb <= ld
                       goto(:fe)
                       goto(~io_done,:ld_st)
                       goto(io_done & iq_chk,:iq_s) # Interrupt / No interrupt
                     } 
        # States handling the interrupts.
        # Push PC
        state(:iq_s) { iq_calc <= 1; 
                       io_req <= 1; io_rwb <= 0; io_out <= pc 
                       goto(io_done, :iq_d, :iq_s) 
                     }
        # Jump to interrupt handler.
        state(:iq_d) { goto(:fe) }
        sync(:iq_d)  { pc <= 0xF8 }
        # States handling the halt (until rst).
        state(:ht)   { goto(iq_chk,:iq_s,:ht) # Interrupt / No interrupt
                     }
        sync(:ht)    { iq_chk <= (iq0 & s[0]) | (iq1 & s[1]) # External interrupt check
                     }
    end
end
