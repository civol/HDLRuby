module HDLRuby::High::Std

    # Describe a RAM compatibile with BRAM of FPGAs.
    # - 'widthA': address bit width
    # - 'widthD': data bit width
    # - 'size':   the size of the memory.
    system :bram do |widthA, widthD, size = nil|
        # Process size if required.
        size = 2**widthA unless size

        # Declares the io of the ram.
        input :clk, :rwb
        [widthA].input :addr
        [widthD].input :din
        [widthD].output :dout

        bit[widthD][-size].inner mem: [ :"_b#{"0"*widthD}".to_value ] * size

        par(clk.negedge) do
            hif(rwb == 0) { mem[addr] <= din }
            dout <= mem[addr]
        end
    end



    # # Declare the possible commands for the stack.
    # PUSH  = 0   # Pushes the value of input din into the stack.
    # POP   = 1   # Pops din values for the stack. If din is negative, allocates din elements on the stack.
    # READ  = 2   # Read the value address din and output it on dout.
    # WRITE = 3   # Write the value at the top of the stack at address din.

    # # Describe a stack compatible with BRAM of FPGAs.
    # # - 'widthA': address bit width
    # # - 'widthD': data bit width
    # # - 'size'  : the size of the stack
    # #
    # system :bram_stack do |widthA, widthD, size|
    #     # Process size if required.
    #     size = 2**widthA unless size

    #     # Compute the bit width of the stack pointer register.
    #     widthS = (size+1).width

    #     # Declare the inputs and outputs.
    #     input :clk, :rst, :ce
    #     [2].input :cmd
    #     [widthD].input :din
    #     [widthD].output :dout
    #     output :empty, :full

    #     # Declare the BRAM containing the stack data.
    #     inner rwb: 1
    #     [widthA].inner :addr
    #     [widthD].inner :brin, :brout
    #     bram(widthA,widthD,size).(:bramI).(clk,rwb,addr,brin,brout)

    #     # Declare the stack pointer register and the top of stack value.
    #     [widthS].inner sp: size
    #     [widthD].inner :top

    #     # Tells if the stack is empty or full.
    #     empty <= (sp == size)
    #     full  <= (sp == 0)

    #     # The output bus of the stacl is the same as the one of the inner BRAM.
    #     dout <= brout

    #     # The combinatorial process handling the address of the BRAM.
    #     par do
    #         hif(ce) do
    #             hcase(cmd)
    #             hwhen(PUSH)  { addr <= sp }
    #             hwhen(POP)   { addr <= sp }
    #             hwhen(READ)  { addr <= din }
    #             hwhen(WRITE) { addr <= din }
    #         end
    #         helse { addr <= sp }
    #     end

    #     # The clock process handling the access.
    #     par(clk.posedge) do
    #         # By default, read the top of the memory.
    #         rwb <= 1
    #         hif(rst) do
    #             sp <= size
    #         end
    #         helsif(ce) do
    #             # Now depending on the command.
    #             hcase(cmd)
    #             hwhen(PUSH) do
    #                 # Is the stack full?
    #                 hif(~full) do
    #                     # No, can store onto the stack.
    #                     brin <= din
    #                     rwb  <= 0
    #                     # Update the top register.
    #                     top <= din
    #                     # Finally, decrease sp.
    #                     sp <= sp - 1
    #                 end
    #             end
    #             hwhen(POP) do
    #                 # Is the stack empty?
    #                 hif((sp + din).as(bit[widthS]) < size) do
    #                     # No, can increase sp.
    #                     sp <= sp + din
    #                     top <= brout
    #                 end
    #             end
    #             hwhen(READ) do
    #                 # Simple read access.
    #                 # Nothing to do actually.
    #             end
    #             hwhen(WRITE) do
    #                 # Write using the top of the stack as data.
    #                 brin <= top
    #                 rwb  <= 0
    #             end
    #         end
    #     end
    # end



end
