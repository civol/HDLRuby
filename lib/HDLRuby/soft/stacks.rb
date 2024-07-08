require 'std/bram'

module HDLRuby::High::Soft


    # Declare the possible commands for the stack.
    PUSH  = 0   # Pushes the value of input din into the stack.
    POP   = 1   # Pops din values for the stack. If din is negative, allocates din elements on the stack.
    READ  = 2   # Read the value address din and output it on dout.
    WRITE = 3   # Write the value at the top of the stack at address din.





    # Describe a stack based on a BRAM (compatible with FPGA's)
    # - 'widthD': data bit width
    # - 'size'  : the size of the stack
    system :bram_stack do |widthD, size|
        # Compute the address width.
        widthA = (size-1).width

        # Compute the bit width of the stack pointer register.
        widthS = (size+1).width

        # Declare the inputs and outputs.
        input :clk, :rst, :ce
        input :cmd
        [widthD].input  :din
        [widthD].output :dout
        output  :empty, :full

        # Declare the BRAM containing the stack data.
        inner rwb: 1
        [widthA].inner :addr
        [widthD].inner :brin, :brout
        bram(widthA,widthD).(:bramI).(clk,rwb,addr,brin,brout)

        # Declare the stack pointer register and the top of stack value.
        [widthS].inner sp: size
        [widthD].inner :top

        # Tells if the stack is empty or full.
        empty <= (sp == size)
        full  <= (sp == 0)

        # The output bus is the top of the stack.
        dout <= top

        # The clock process handling the access.
        seq(clk.posedge) do
            # By default, read before the top of the memory.
            rwb <= 1
            hif(rst) do
                # sp is set to size (stack empty).
                sp <= size
                top <= 0
            end
            helsif(ce) do
                # Now depending on the command.
                hcase(cmd)
                hwhen(PUSH) do
                    # Is the stack full?
                    hif(~full) do
                        # No, can push onto the stack.
                        # Update the top register.
                        top <= din
                        # Update the bram.
                        brin <= din
                        rwb  <= 0
                        # Finally, decrease sp.
                        sp <= sp - 1
                        # The address is the top of the stack
                        addr <= sp
                    end
                end
                hwhen(POP) do
                    # Is the stack empty?
                    hif(~empty) do
                        # No, can pop from the stack.
                        # Update the top register.
                        top <= brout
                        # Finally, increase sp.
                        sp <= sp + 1
                    end
                end
            end
            hif(~ce | cmd != PUSH) do
                # By default the address is the top of the stack + 1
                addr <= sp + 1
            end
        end
        
    end


    # Describe a frame stack based on a BRAM (compatible with FPGA's)
    # - 'widthD': data bit width
    # - 'size'  : the size of the stack
    # - 'depth' : the maximum number of frames.
    system :bram_frame_stack do |widthD, size, depth|
        # Compute the address width.
        widthA = (size-1).width

        # Compute the bit width of the frame pointers.
        widthF = (size+1).width

        # compute the bit width of the frame stack pointer.
        widthS = (depth+1).width

        # Create the type used for accessing the frame stack.
        typedef(:locT) { { frame: bit[widthS], offset: bit[widthF] } }

        # Declare the inputs and outputs.
        input :clk, :rst, :ce
        [2].input :cmd
        locT.input :loc
        [widthD].input  :din
        [widthD].output :dout
        output  :empty, :full

        # Declare the frame index stac pointer.
        [widthS].inner :sp

        # Declare the frame index table.
        bit[widthF][-depth].inner :indexes

        # Declare the BRAM containing the frames data.
        inner rwb: 1
        [widthA].inner :addr
        [widthD].inner :brin, :brout
        bram(widthA,widthD).(:bramI).(clk,rwb,addr,brin,brout)

        # Tells if the stack is empty or full.
        empty <= (sp == depth)
        full  <= (sp == 0)

        # The input data is always the input of the bram.
        brin <= din

        # The output is always the output of the bram.
        dout <= brout

        # The clock process handling the access.
        seq(clk.posedge) do
            # By default, read before the top of the memory.
            rwb <= 1
            hif(rst) do
                # sp is set to depth (stack empty).
                sp <= depth
            end
            helsif(ce) do
                # Now depending on the command.
                hcase(cmd)
                hwhen(PUSH) do
                    # Is the stack full or is the frame to push empty? 
                    hif(~(full | loc.offset == 0)) do
                        # No, we can proceed.
                        # Decrease sp.
                        sp <= sp - 1
                        # Adds the frame.
                        hif(~empty) do
                            indexes[sp] <= loc.offset + indexes[sp+1]
                        end
                        helse do
                            indexes[sp] <= loc.offset
                        end
                    end
                end
                hwhen(POP) do
                    # Is the stack empty?
                    hif(~empty) do
                        # No, can pop a frame from the stack.
                        # Increase sp.
                        sp <= sp + 1
                    end
                end
                hwhen(READ) do
                    # Read access, is the frame valid?
                    cur_frame = sp+loc.frame
                    hif (~(empty | cur_frame >= depth)) do
                        # The frame is valid. Is the offset valid?
                        addr_calc = indexes[cur_frame] - loc.offset - 1
                        hif ((cur_frame < depth-1) & 
                             (addr_calc > indexes[cur_frame+1])) do
                            # Not the first frame and the address is valid.
                            addr <= addr_calc
                        end
                        helsif ((cur_frame == depth-1) &
                            (addr_calc + 1 > 0)) do
                            # The first frame and the address is valid.
                            addr <= addr_calc
                        end
                    end
                end
                hwhen(WRITE) do
                    # Write access, is the frame valid?
                    cur_frame = sp+loc.frame
                    hif (~(empty | cur_frame >= depth)) do
                        # The frame is valid. Is the offset valid?
                        addr_calc = indexes[cur_frame] - loc.offset - 1
                        hif ((cur_frame < depth-1) & 
                             (addr_calc > indexes[cur_frame+1])) do
                            # Not the first frame and the address is valid.
                            addr <= addr_calc
                            rwb  <= 0
                        end
                        helsif ((cur_frame == depth-1) &
                            (addr_calc + 1 > 0)) do
                            # The first frame and the address is valid.
                            addr <= addr_calc
                            rwb  <= 0
                        end
                    end
                end
            end
        end
    end
end
