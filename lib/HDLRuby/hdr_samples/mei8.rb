require '../std/fsm.rb'
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

    # # Interrupts.
    # input :iq0, :iq1

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
            # The main computation: s and cf

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
                        vf <= (~x[7] & ~y[7] & z[7]) |
                              (x[7] & y[7] & ~z[7]) }
            # sub
            hwhen(1)  { add.(x ,~y,1,[cf,z])
                        vf <= (~x[7] & y[7] & z[7]) |
                              (x[7] & ~y[7] & ~z[7]) }
            # inc
            hwhen(2)  { add.(x ,0 ,1,[cf,z])
                        vf <= (~x[7] & ~y[7] & z[7]) |
                              (x[7] & y[7] & ~z[7]) }
            # dec
            hwhen(3)  { add.(x ,0xFF ,0,[cf,z])
                        vf <= (~x[7] & ~y[7] & z[7]) |
                              (x[7] & y[7] & ~z[7]) }
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

    [3].inner :dst           # Index of the destination register.
    [8].inner :src00, :src01 # Values of the source registers.
    inner  :branch # Tell if the instruction is a branch.

    # Compute the source register value.
    def getsrc(idx,src)
        src <= mux(idx,a,b,c,d,e,f,g,h)
    end

    # The decoder.
    par do
        # By default, no branch, and destination is a.
        branch <= 0
        dst <= 0
        # And transfer 0.
        alu.(15,0,0)
        # Compute the possible source 2
        getsrc(ir[5..3],src00)
        getsrc(ir[2..0],src01)
        # Depending on the instruction.
        hcase ir[7..6] 
        hwhen _00 do
            # Format 0
            hif(ir[5..3] == ir[2..0]) do
                alu.(15,0,0)
            end
            helse { alu.(15,src00,0) }
            # destination.
            dst <= ir[2..0]
        end
        hwhen _01 do
            # Format 1
            alu.(ir[5..3],a,src01)
            # destination.
            dst <= ir[2..0]
        end
        hwhen _10 do
            # Format 2
            # Computation: 000iiiii
            alu.(7,[_000,ir[4..0]],0)
            # Verify it is a branch.
            branch <= ir[5]
        end
        hwhen _11 do
            # Format 3
            hif ir[5..4] != _11  do
                # Verify it is a branch.
                hif ir[5..3] == _000 do
                    # movh, not a branch.
                    # Computation: iiiaaaaa
                    alu.(7,[ir[2..0],a[4..0]],0)
                end
                helse do
                    # brcc, branch.
                    # Computation: pc + iii 
                    alu.(0,pc, [ ir[2] ]*5 + [ ir[2..0] ])
                    # Destination.
                    branch <= 1
                end
            end
            # Format 4
            helse do 
                # Computation.
                alu.([_1,ir[2..0]],a,0)
                # Special cases of format 4:
                # ld/st cases: g is incremented/decremented
                hif(ir[3..1] == _100)  { alu.(2,g,0) }
                hif(ir[3..1] == _101)  { alu.(3,g,0) }
                # push/pop case: h is decremented/incremented
                hif(ir[3..0] == _1100) { alu.(3,h,0) }
                hif(ir[3..0] == _1101) { alu.(2,h,0) }
                # Destination: depending on the instrution.
                hif(ir[3] == 0)    { dst <= 0 } # a
                helsif(ir[2] == 0) { dst <= 6 } # g
                helse              { dst <= 7 } # h
            end
        end
    end


    # The signals for controlling the io unit.
    inner :io_req, :io_rwb, :io_done, :io_r_done
    [8].inner :io_out # The write buffer.
    [8].inner :io_in  # The read buffer.

    # The io unit.
    fsm(clk.posedge,rst,:async) do
        default       { io_done <= 0; req <= 0; rwb <= 0
                        io_r_done <= 0
                        addr <= 0;
                        dbus  <= _zzzzzzzz
                        io_in <= dbus
                      }
        state(:wait)  { goto(io_req,:start,:wait) }
        state(:start) { req <= 1; rwb <= io_rwb
                        addr <= g
                        hif(~io_rwb) { dbus <= io_out }
                        goto(ack,:end,:start) }
        state(:end)   { io_done <= 1; io_r_done <= io_rwb
                        goto(:wait) }
    end

    inner :calc # Tell if calculation is to be stored.

    [8].inner :npc # Next pc
    inner     :nbr # Tell if must branch next.

    # Writing to registers.
    par(clk.posedge) do
        hif(rst) do
            # In case of hard reset all the resgister of the operative part
            # are to put to 0.
            [a,b,c,d,e,f,g,h,zf,cf,sf,vf,nbr,npc].each do |r|
                r <= 0
            end
        end
        helsif(calc) do
            nbr <= 0; npc <= 0
            # No-branch case.
            hif ~branch do
                # Write to the destination of calculation.
                hcase(dst)
                [a,b,c,d,e,f,g,h].each.with_index do |r,i|
                    hwhen(i) { r <= alu.z }
                end
                # Specific cases
                hif(ir==_11110111) do # xs
                    s <= a
                    a <= s
                end
                # Flags
                zf <= alu.zf
                cf <= alu.cf
                sf <= alu.sf
                vf <= alu.vf
            end
            # Branch case.
            helse do
                hcase ir[6..3]
                # brcc
                hwhen(_1001) { hif(zf) { npc <= alu.z; nbr <= 1 } } # brz
                hwhen(_1010) { hif(cf) { npc <= alu.z; nbr <= 1 } } # brc
                hwhen(_1011) { hif(sf) { npc <= alu.z; nbr <= 1 } } # brs
                hwhen(_1100) { hif(vf) { npc <= alu.z; nbr <= 1 } } # brv
                hwhen(_1101) { npc <= alu.z; nbr <= 1 } # br
                helse        { npc <= alu.z; nbr <= 1 } # jump
            end
        end
        helsif (io_r_done) do
            a <= io_in
        end
    end

    # The control part

    # # Interrupt flags computations.
    # inner :iq_chk, :iq_pos
    # [2..0].inner :iq_msk
    # iq_chk <= (iq0 & s[0]) | (iq1 & s[1]) # External interrupt check
    # iq_pos <= iq1                         # Position of the iq enable to clear

    # The main FSM
    prog.addr <= pc
    fsm(clk.posedge,rst,:async) do
        default      { calc <= 0
                       # prog.addr <= 0
                       io_req <= 0; io_rwb <= 0; io_out <= a
                     }
        # Reset state.
        state(:re)   { }
        sync(:re)    { pc <= 0; ir <= 0 }
        # Standard execution states.
        state(:fe)   { # prog.addr <= pc 
                     }
        sync(:fe)    { ir <= prog.instr
                       pc <= pc + 1
                     }
        state(:ex)   { calc <= 1
                       hif (ir[7..2] == _111110) do
                           io_req <= 1; io_rwb <= ~ir[0]
                       end
                       goto(:fe)
                       # goto(iq_chk,:iq_s,:fe)   # Interrupt / No interrupt
                       goto(branch,:br)
                       goto((ir[7..2] == _111110) & ~io_done,:ld_st) # ld/st
                       goto(ir == _11111110,:ht) # Halt
                       goto(ir == _11111111,:re) # Reset
                     }
        state(:br)   { goto(:fe) }
        sync(:br)    { hif(nbr) { pc <= npc - 1 } }
        # State waiting the end of a load/store.
        state(:ld_st){ io_rwb <= ~ir[0]
                       goto(io_done,:fe,:ld_st)
                       # goto(io_done & iq_chk,:iq_s) # Interrupt / No interrupt
                     } 
        # sync(:ld_st) { hif(io_done) { a <= io_in } }
        # # States handling the interrupts.
        # # Push PC
        # state(:iq_s) { calc <=1; 
        #                io_req <= 1; io_rwb <= 0; io_out <= pc 
        #                alu.(2,f,0)
        #                goto(io_done, :iq_d, :iq_w) }
        # sync(:iq_s)  { f <= alu.z }
        # # Wait the end of the push.
        # state(:iq_w) { goto(io_done, :iq_d, :iq_w) }
        # # Jump to interrupt handler (see async)
        # state(:iq_d) { s[7] <= 1; s[iq_pos] <= 0
        #                goto(:fe) }
        # sync(:iq_d)  { pc <= 196 }
        # # States handling the halt (until rst).
        state(:ht)   { goto(:ht) }
    end
end
