require 'std/channel.rb'



##
# Standard HDLRuby::High library: memories encapsulated in channels.
# 
########################################################################


# Synchroneous +n+ ports memories including +size+ words of +typ+ data type,
# synchronized on +clk_e+ events and reset of +rst+ signal.
# +br_rsts+ are reset names on the branches, if not given, a reset input
# is added and connected to rst.
#
# NOTE:
#
# * such memories uses the following signals:
#   - abus_xyz for address bus number xyz
#   - dbus_xyz for data bus number xyz (bidirectional)
#   - cs_xyz for selecting port number xyz
#   - rwb_xyz for indicating whether port xyz is read (1) or written (0)
#
# * The read and write procedure are blocking and require a clock.
#
# * Read and write cannot be simultanous on a given port, and arbitration
#   is assumed to be done outside the channel!
HDLRuby::High::Std.channel(:mem_sync) do |n,typ,size,clk_e,rst,br_rsts = []|
    # Ensure n is an integer.
    n = n.to_i
    # Ensure typ is a type.
    typ = typ.to_type
    # Ensure size in an integer.
    size = size.to_i
    # Compute the address bus width from the size.
    awidth = (size-1).width
    awidth = 1 if awidth == 0
    # Ensure clk_e is an event, if not set it to a positive edge.
    clk_e = clk_e.posedge unless clk_e.is_a?(Event)

    # Declare the signals interfacing the memory.
    n.times do |p|
        # For port number +p+
        # Main signals
        [awidth].inner :"abus_#{p}" # The address bus
        typ.inner      :"dbus_#{p}" # The data bus
        inner          :"cs_#{p}"   # Chip select
        inner          :"rwb_#{p}"  # Read/!Write
    end
    # Declare the memory content.
    typ[-size].inner :mem

    # Defines the ports of the memory as branchs of the channel.
    n.times do |p|
        brancher(p) do
            accesser_inout :"abus_#{p}", :"cs_#{p}", :"rwb_#{p}"
            accesser_inout :"dbus_#{p}"
            if br_rsts[p] then
                rst_name = br_rsts[p].to_sym
            else
                rst_name = rst.name
                accesser_input rst.name
            end

            # Defines the read procedure to port +p+ at address +addr+
            # using +target+ as target of access result.
            reader do |blk,addr,target|
                # Get the interface.
                abus = send(:"abus_#{p}")
                dbus = send(:"dbus_#{p}")
                cs   = send(:"cs_#{p}")
                rwb  = send(:"rwb_#{p}")
                rst  = send(rst_name)
                # Use it to make the access.
                top_block.unshift do
                    hif (rst) do
                        # Reset case
                        cs <= 0
                        abus <= 0
                        rwb <= 0
                    end
                end
                hif(cs == 0) do
                    # Start the access.
                    cs <= 1
                    rwb <= 1
                    abus <= addr
                end; helse do
                    # End the access.
                    target <= dbus
                    cs <= 0
                    # Execute the blk.
                    blk.call if blk
                end
            end

            # Defines the write procedure to port +p+ at address +addr+
            # using +target+ as target of access result.
            writer do |blk,addr,target|
                # Get the interface.
                abus = send(:"abus_#{p}")
                dbus = send(:"dbus_#{p}")
                cs   = send(:"cs_#{p}")
                rwb  = send(:"rwb_#{p}")
                rst  = send(rst_name)
                # Use it to make the access.
                top_block.unshift do
                    hif (rst) do
                        # Reset case
                        cs <= 0
                        abus <= 0
                        rwb <= 0
                    end
                end
                hif(cs == 0) do
                    # Start the access.
                    cs <= 1
                    rwb <= 0
                    abus <= addr
                    dbus <= target
                end; helse do
                    # End the access.
                    abus <= 0
                    cs <= 0
                    rwb <= 0
                    dbus <= "z" * typ.width
                    # Execute the blk.
                    blk.call if blk
                end
            end
        end
    end

    # Manage the accesses
    par(clk_e) do
        # For each port individually: read or no access
        n.times do |p|
            # Get the interface.
            abus = send(:"abus_#{p}")
            dbus = send(:"dbus_#{p}")
            cs   = send(:"cs_#{p}")
            rwb  = send(:"rwb_#{p}")
            # The read accesses
            # Use to manage the memory port.
            hif (cs & rwb) do
                dbus <= mem[abus]
            end
            # The no accesses
            helse { dbus <= "z" * typ.width }
        end
        # For all ports together: write.
        # Priority to the lowest port number.
        n.times do |p|
            # Get the interface.
            abus = send(:"abus_#{p}")
            dbus = send(:"dbus_#{p}")
            cs   = send(:"cs_#{p}")
            rwb  = send(:"rwb_#{p}")
            # The write access.
            if (p == 0) then
                hif(cs & ~rwb) do
                    mem[abus] <= dbus
                end
            else
                helsif(cs & ~rwb) do
                    mem[abus] <= dbus
                end
            end
        end
    end
end


# Flexible ROM memory of +size+ elements of +typ+ typ, syncrhonized on +clk+
# (positive and negative edges) and reset on +rst+.
# At each rising edge of +clk+ a read and a write is guaranteed to be
# completed provided they are triggered.
# +br_rsts+ are reset names on the branches, if not given, a reset input
# is added and connected to rst.
# The content of the ROM is passed through +content+ argument.
#
# NOTE:
#
# * such memories uses the following ports:
#   - trig_r: read access trigger  (output)
#   - trig_w: write access trigger (output)
#   - dbus_r: read data bus        (input)
#   - dbus_w: write data bus       (output)
#
# * The following branches are possible (only one read and one write can
#   be used per channel)
#   - raddr:   read by address, this channel adds the following port:
#     abus_r:  read address bus (output)
#   - waddr:   read by address, this channel adds the following port:
#     abus_w:  write address bus (output)
#   - rinc:    read by automatically incremented address.
#   - winc:    write by automatically incremented address.
#   - rdec:    read by automatically decremented address.
#   - wdec:    write by automatically decremented address.
#   - rque:    read in queue mode: automatically incremented address ensuring
#              the read address is always different from the write address.
#   - wque:    write in queue mode: automatically incremented address ensuring
#              the write address is always differnet from the read address.
#
HDLRuby::High::Std.channel(:mem_rom) do |typ,size,clk,rst,content,
    br_rsts = {}|
    # Ensure typ is a type.
    typ = typ.to_type
    # Ensure size in an integer.
    size = size.to_i
    # Compute the address bus width from the size.
    awidth = (size-1).width
    awidth = 1 if awidth == 0
    # Process the table of reset mapping for the branches.
    # Ensures br_srts is a hash.
    br_rsts = br_rsts.to_hash

    # Declare the control signals.
    # Access trigger.
    inner :trig_r
    # Data bus
    typ.inner :dbus_r
    # Address bus (or simply register)
    [awidth].inner :abus_r

    # Declare the ROM with its inner content.
    # typ[-size].constant mem: content.map { |val| val.to_expr }
    typ[-size].constant mem: content

    # Processes handling the memory access.
    par(clk.negedge) do
        dbus_r <= mem[abus_r]
    end

    # The address branches.
    # Read with address
    brancher(:raddr) do
        reader_output :trig_r, :abus_r
        reader_input :dbus_r
        if br_rsts[:raddr] then
            rst_name = br_rsts[:raddr].to_sym
        else
            rst_name = rst.name
            reader_input rst_name
        end

        # Defines the read procedure at address +addr+
        # using +target+ as target of access result.
        reader do |blk,addr,target|
            # By default the read trigger is 0.
            top_block.unshift { trig_r <= 0 }
            # The read procedure.
            rst  = send(rst_name)
            par do
                hif(rst == 0) do
                    # No reset, so can perform the read.
                    hif(trig_r == 1) do
                        # The trigger was previously set, read ok.
                        target <= dbus_r
                        trig_r <= 0
                        blk.call if blk
                    end
                    helse do
                        # Prepare the read.
                        abus_r <= addr
                        trig_r <= 1
                    end
                end
            end
        end
    end

    # The increment branches.
    # Read with increment
    brancher(:rinc) do
        reader_output :trig_r, :abus_r
        reader_input :dbus_r
        if br_rsts[:rinc] then
            rst_name = br_rsts[:rinc].to_sym
        else
            rst_name = rst.name
            reader_input rst_name
        end

        # Defines the read procedure at address +addr+
        # using +target+ as target of access result.
        reader do |blk,target|
            # On reset the read trigger is 0.
            rst  = send(rst_name)
            top_block.unshift do
                # Initialize the address so that the next access is at address 0.
                hif(rst==1) { abus_r <= -1 }
                # Reset so switch of the access trigger.
                trig_r <= 0
            end
            # The read procedure.
        #     par do
        #         hif(rst == 0) do
        #             # No reset, so can perform the read.
        #             hif(trig_r == 1) do
        #                 # The trigger was previously set, read ok.
        #                 target <= dbus_r
        #                 blk.call if blk
        #             end
        #             # Prepare the read.
        #             abus_r <= abus_r + 1
        #             trig_r <= 1
        #         end
        #     end
            # The read procedure.
            par do
                hif(rst == 0) do
                    # No reset, so can perform the read.
                    hif(trig_r == 1) do
                        # The trigger was previously set, read ok.
                        # target <= dbus_r
                        # blk.call if blk
                        seq do
                            # abus_r <= abus_r + 1
                            target <= dbus_r
                            blk.call if blk
                        end
                    end
                    helse do
                        # Prepare the read.
                        # abus_r <= abus_r + 1
                        if 2**size.width != size then
                            abus_r <= mux((abus_r + 1) == size, abus_r + 1, 0)
                        else
                            abus_r <= abus_r + 1
                        end
                        trig_r <= 1
                    end
                end
            end
        end
    end

    # The decrement branches.
    # Read with increment
    brancher(:rdec) do
        reader_output :trig_r, :abus_r
        reader_input :dbus_r
        if br_rsts[:rdec] then
            rst_name = br_rsts[:rdec].to_sym
        else
            rst_name = rst.name
            reader_input rst_name
        end

        # Defines the read procedure at address +addr+
        # using +target+ as target of access result.
        reader do |blk,target|
            # On reset the read trigger is 0.
            rst  = send(rst_name)
            top_block.unshift do
                # Initialize the address so that the next access is at address 0.
                hif(rst==1) { abus_r <= 0 }
                # Reset so switch of the access trigger.
                trig_r <= 0
            end
            # # The read procedure.
            # par do
            #     hif(rst == 0) do
            #         # No reset, so can perform the read.
            #         hif(trig_r == 1) do
            #             # The trigger was previously set, read ok.
            #             target <= dbus_r
            #             blk.call if blk
            #         end
            #         # Prepare the read.
            #         abus_r <= abus_r - 1
            #         trig_r <= 1
            #     end
            # end
            # The read procedure.
            par do
                hif(rst == 0) do
                    # No reset, so can perform the read.
                    hif(trig_r == 1) do
                        # The trigger was previously set, read ok.
                        # target <= dbus_r
                        # blk.call if blk
                        seq do
                            # abus_r <= abus_r - 1
                            target <= dbus_r
                            blk.call if blk
                        end
                    end
                    helse do
                        # Prepare the read.
                        # abus_r <= abus_r - 1
                        if 2**size.width != size then
                            abus_r <= mux(abus_r == 0, abus_r - 1, size - 1)
                        else
                            abus_r <= abus_r - 1
                        end
                        trig_r <= 1
                    end
                end
            end
        end
    end

end





# Flexible dual-edge memory with distinct read and write ports of +size+
# elements of +typ+ typ, syncrhonized on +clk+ (positive and negative edges)
# and reset on +rst+.
# At each rising edge of +clk+ a read and a write is guaranteed to be
# completed provided they are triggered.
# +br_rsts+ are reset names on the branches, if not given, a reset input
# is added and connected to rst.
#
# NOTE:
#
# * such memories uses the following ports:
#   - trig_r: read access trigger  (output)
#   - trig_w: write access trigger (output)
#   - dbus_r: read data bus        (input)
#   - dbus_w: write data bus       (output)
#
# * The following branches are possible (only one read and one write can
#   be used per channel)
#   - raddr:   read by address, this channel adds the following port:
#     abus_r:  read address bus (output)
#   - waddr:   read by address, this channel adds the following port:
#     abus_w:  write address bus (output)
#   - rinc:    read by automatically incremented address.
#   - winc:    write by automatically incremented address.
#   - rdec:    read by automatically decremented address.
#   - wdec:    write by automatically decremented address.
#   - rque:    read in queue mode: automatically incremented address ensuring
#              the read address is always different from the write address.
#   - wque:    write in queue mode: automatically incremented address ensuring
#              the write address is always differnet from the read address.
#
HDLRuby::High::Std.channel(:mem_dual) do |typ,size,clk,rst,br_rsts = {}|
    # Ensure typ is a type.
    typ = typ.to_type
    # Ensure size in an integer.
    size = size.to_i
    # Compute the address bus width from the size.
    awidth = (size-1).width
    awidth = 1 if awidth == 0
    # Process the table of reset mapping for the branches.
    # puts "first br_rsts=#{br_rsts}"
    # if br_rsts.is_a?(Array) then
    #     # It is a list, convert it to a hash with the following order:
    #     # raddr, waddr, rinc, winc, rdec, wdec, rque, wque
    #     # When not specified the reset is +rst+ by default.
    #     # If there is only two entries they will be duplicated and mapped
    #     # as follows:
    #     # [raddr,waddr], [rinc,winc], [rdec,wdec], [rque,wque]
    #     # If there is only one entry it will be duplicated and mapped as
    #     # follows:
    #     # raddr, rinc, rdec, rque
    #     if br_rsts.size == 2 then
    #         br_rsts = br_rsts * 4
    #     elsif br_rsts.size == 1 then
    #         br_rsts = br_rsts * 8
    #     end
    #     br_rsts = { raddr: br_rsts[0], waddr: br_rsts[1],
    #                 rinc:  br_rsts[2], winc:  br_rsts[3],
    #                 rdec:  br_rsts[4], wdec:  br_rsts[5],
    #                 rque:  br_rsts[6], wque:  br_rsts[6] }
    # end
    # unless br_rsts.respond_to?(:[])
    #     raise "Invalid reset mapping description: #{br_rsts}"
    # end
    #
    # Ensures br_srts is a hash.
    br_rsts = br_rsts.to_hash

    # Declare the control signals.
    # Access triggers.
    inner :trig_r, :trig_w
    # Data buses
    typ.inner :dbus_r, :dbus_w
    # Address buses (or simply registers)
    [awidth].inner :abus_r, :abus_w

    # Declare the memory content.
    typ[-size].inner :mem

    # Processes handling the memory access.
    par(clk.negedge) do
        dbus_r <= mem[abus_r]
        hif(trig_w) { mem[abus_w] <= dbus_w }
    end

    # The address branches.
    # Read with address
    brancher(:raddr) do
        reader_output :trig_r, :abus_r
        reader_input :dbus_r
        if br_rsts[:raddr] then
            rst_name = br_rsts[:raddr].to_sym
        else
            rst_name = rst.name
            reader_input rst_name
        end

        # Defines the read procedure at address +addr+
        # using +target+ as target of access result.
        reader do |blk,addr,target|
            # By default the read trigger is 0.
            top_block.unshift { trig_r <= 0 }
            # The read procedure.
            rst  = send(rst_name)
            par do
                hif(rst == 0) do
                    # No reset, so can perform the read.
                    hif(trig_r == 1) do
                        # The trigger was previously set, read ok.
                        target <= dbus_r
                        trig_r <= 0
                        blk.call if blk
                    end
                    helse do
                        # Prepare the read.
                        abus_r <= addr
                        trig_r <= 1
                    end
                end
            end
        end
    end

    # Write with address
    brancher(:waddr) do
        writer_output :trig_w, :abus_w, :dbus_w
        if br_rsts[:waddr] then
            rst_name = br_rsts[:waddr].to_sym
        else
            rst_name = rst.name
            writer_input rst_name
        end
        # puts "br_rsts=#{br_rsts}"
        # puts "rst_name=#{rst_name}"

        # Defines the read procedure at address +addr+
        # using +target+ as target of access result.
        writer do |blk,addr,target|
            # By default the read trigger is 0.
            top_block.unshift { trig_w <= 0 }
            # The write procedure.
            rst  = send(rst_name)
            par do
                hif(rst == 0) do
                    # No reset, so can perform the write.
                    hif(trig_w == 1) do
                        # The trigger was previously set, write ok.
                        blk.call if blk
                    end
                    # Prepare the write.
                    abus_w <= addr
                    trig_w <= 1
                    dbus_w <= target
                end
            end
        end
    end


    # The increment branches.
    # Read with increment
    brancher(:rinc) do
        reader_output :trig_r, :abus_r
        reader_input :dbus_r
        if br_rsts[:rinc] then
            rst_name = br_rsts[:rinc].to_sym
        else
            rst_name = rst.name
            reader_input rst_name
        end

        # Defines the read procedure at address +addr+
        # using +target+ as target of access result.
        reader do |blk,target|
            # On reset the read trigger is 0.
            rst  = send(rst_name)
            top_block.unshift do
                # Initialize the address so that the next access is at address 0.
                hif(rst==1) { abus_r <= -1 }
                # Reset so switch of the access trigger.
                trig_r <= 0
            end
            # The read procedure.
            par do
                hif(rst == 0) do
                    # No reset, so can perform the read.
                    hif(trig_r == 1) do
                        # The trigger was previously set, read ok.
                        # target <= dbus_r
                        # blk.call if blk
                        seq do
                            # abus_r <= abus_r + 1
                            target <= dbus_r
                            blk.call if blk
                        end
                    end
                    helse do
                        # Prepare the read.
                        # abus_r <= abus_r + 1
                        if 2**size.width != size then
                            abus_r <= mux((abus_r + 1) == size, abus_r + 1, 0)
                        else
                            abus_r <= abus_r + 1
                        end
                        trig_r <= 1
                    end
                end
            end
        end
    end

    # Write with address
    brancher(:winc) do
        writer_output :trig_w, :abus_w, :dbus_w
        if br_rsts[:winc] then
            rst_name = br_rsts[:winc].to_sym
        else
            rst_name = rst.name
            writer_input rst_name
        end
        # puts "br_rsts=#{br_rsts}"
        # puts "rst_name=#{rst_name}"

        # Defines the read procedure at address +addr+
        # using +target+ as target of access result.
        writer do |blk,target|
            # On reset the read trigger is 0.
            rst = send(rst_name)
            top_block.unshift do
                # Initialize the address so that the next access is at address 0.
                hif(rst == 1) { abus_w <= -1 }
                # Reset so switch of the access trigger.
                trig_w <= 0
            end
            # The write procedure.
            par do
                hif(rst == 0) do
                    # No reset, so can perform the write.
                    blk.call if blk
                    # Prepare the write.
                    # abus_w <= abus_w + 1
                    if 2**size.width != size then
                        abus_w <= mux((abus_w + 1) == size, abus_w + 1, 0)
                    else
                        abus_w <= abus_w + 1
                    end
                    trig_w <= 1
                    dbus_w <= target
                end
            end
        end
    end


    # The decrement branches.
    # Read with increment
    brancher(:rdec) do
        reader_output :trig_r, :abus_r
        reader_input :dbus_r
        if br_rsts[:rdec] then
            rst_name = br_rsts[:rdec].to_sym
        else
            rst_name = rst.name
            reader_input rst_name
        end

        # Defines the read procedure at address +addr+
        # using +target+ as target of access result.
        reader do |blk,target|
            # On reset the read trigger is 0.
            rst  = send(rst_name)
            top_block.unshift do
                # Initialize the address so that the next access is at address 0.
                hif(rst==1) { abus_r <= 0 }
                # Reset so switch of the access trigger.
                trig_r <= 0
            end
            # # The read procedure.
            # par do
            #     hif(rst == 0) do
            #         # No reset, so can perform the read.
            #         hif(trig_r == 1) do
            #             # The trigger was previously set, read ok.
            #             target <= dbus_r
            #             blk.call if blk
            #         end
            #         # Prepare the read.
            #         abus_r <= abus_r - 1
            #         trig_r <= 1
            #     end
            # end
            # The read procedure.
            par do
                hif(rst == 0) do
                    # No reset, so can perform the read.
                    hif(trig_r == 1) do
                        # The trigger was previously set, read ok.
                        # target <= dbus_r
                        # blk.call if blk
                        seq do
                            # abus_r <= abus_r - 1
                            target <= dbus_r
                            blk.call if blk
                        end
                    end
                    helse do
                        # Prepare the read.
                        # abus_r <= abus_r - 1
                        if 2**size.width != size then
                            abus_r <= mux(abus_r == 0, abus_r - 1, size - 1)
                        else
                            abus_r <= abus_r - 1
                        end
                        trig_r <= 1
                    end
                end
            end
        end
    end

    # Write with address
    brancher(:wdec) do
        writer_output :trig_w, :abus_w, :dbus_w
        if br_rsts[:wdec] then
            rst_name = br_rsts[:wdec].to_sym
        else
            rst_name = rst.name
            writer_input rst_name
        end
        # puts "br_rsts=#{br_rsts}"
        # puts "rst_name=#{rst_name}"

        # Defines the read procedure at address +addr+
        # using +target+ as target of access result.
        writer do |blk,target|
            # On reset the read trigger is 0.
            rst  = send(rst_name)
            top_block.unshift do
                # Initialize the address so that the next access is at address 0.
                hif(rst == 1) { abus_w <= 0 }
                # Reset so switch of the access trigger.
                trig_w <= 0
            end
            # The write procedure.
            par do
                hif(rst == 0) do
                    # No reset, so can perform the write.
                    blk.call if blk
                    # Prepare the write.
                    # abus_w <= abus_w - 1
                    if 2**size.width != size then
                        abus_w <= mux(abus_w == 0, abus_w - 1, size - 1)
                    else
                        abus_w <= abus_w - 1
                    end
                    trig_w <= 1
                    dbus_w <= target
                end
            end
        end
    end

end



# Register file supporting multiple parallel accesses with distinct read and
# write ports of +size+ elements of +typ+ typ, syncrhonized on +clk+ 
# and reset on +rst+.
# At each rising edge of +clk+ a read and a write is guaranteed to be
# completed provided they are triggered.
# +br_rsts+ are reset names on the branches, if not given, a reset input
# is added and connected to rst.
#
# NOTE:
#
# * such memories uses the following arrayes of ports:
#   - dbus_rs: read data buses        (inputs)
#   - dbus_ws: write data buses       (outputs)
#
# * The following branches are possible (only one read and one write can
#   be used per channel)
#   - anum:    access by register number, the number must be a defined value.
#   - raddr:   read by address
#   - waddr:   read by address
#   - rinc:    read by automatically incremented address.
#   - winc:    write by automatically incremented address.
#   - rdec:    read by automatically decremented address.
#   - wdec:    write by automatically decremented address.
#   - rque:    read in queue mode: automatically incremented address ensuring
#              the read address is always different from the write address.
#   - wque:    write in queue mode: automatically incremented address ensuring
#              the write address is always differnet from the read address.
#
HDLRuby::High::Std.channel(:mem_file) do |typ,size,clk,rst,br_rsts = {}|
    # Ensure typ is a type.
    typ = typ.to_type
    # Ensure size in an integer.
    size = size.to_i
    # Process the table of reset mapping for the branches.
    # puts "first br_rsts=#{br_rsts}"
    if br_rsts.is_a?(Array) then
        # It is a list, convert it to a hash with the following order:
        # raddr, waddr, rinc, winc, rdec, wdec, rque, wque
        # If there is only two entries they will be duplicated and mapped
        # as follows:
        # [raddr,waddr], [rinc,winc], [rdec,wdec], [rque,wque]
        # If there is only one entry it will be duplicated and mapped as
        # follows:
        # raddr, rinc, rdec, rque
        if br_rsts.size == 2 then
            br_rsts = br_rsts * 4
        elsif br_rsts.size == 1 then
            br_rsts = br_rsts * 8
        end
        br_rsts = { raddr: br_rsts[0], waddr: br_rsts[1],
                    rinc:  br_rsts[2], winc:  br_rsts[3],
                    rdec:  br_rsts[4], wdec:  br_rsts[5],
                    rque:  br_rsts[6], wque:  br_rsts[6] }
    end
    unless br_rsts.respond_to?(:[])
        raise "Invalid reset mapping description: #{br_rsts}"
    end

    # Declare the registers.
    size.times do |i|
        typ.inner :"reg_#{i}"
    end

    # Defines the ports of the memory as branchs of the channel.
    
    # The number branch (accesser).
    brancher(:anum) do
        size.times { |i| accesser_inout :"reg_#{i}" }

        # Defines the read procedure of register number +num+
        # using +target+ as target of access result.
        reader do |blk,num,target|
            regs = size.times.map {|i| send(:"reg_#{i}") }
            # The read procedure.
            par do
                # No reset, so can perform the read.
                target <= regs[num]
                blk.call if blk
            end
        end

        # Defines the read procedure of register number +num+
        # using +target+ as target of access result.
        writer do |blk,num,target|
            regs = size.times.map {|i| send(:"reg_#{i}") }
            # The write procedure.
            par do
                regs[num] <= target
                blk.call if blk
            end
        end

        # Defines a conversion to array as list of fixed inner accessers.
        define_singleton_method(:inners) do |name|
            # The resulting array.
            chbs = []
            # Declare the fixed inners with uniq names, box them and
            # add the result to the resulting array.
            size.times do |i|
                port = inner HDLRuby.uniq_name
                chbs << port.box(i)
            end
            # Register the array as name.
            HDLRuby::High.space_reg(name) { chbs }
            # Return it.
            return chbs
        end

    end

    
    # The address branches.
    # Read with address
    brancher(:raddr) do
        size.times { |i| reader_input :"reg_#{i}" }
        if br_rsts[:raddr] then
            rst_name = br_rsts[:raddr].to_sym
        else
            rst_name = rst.name
            reader_input rst_name
        end

        # Defines the read procedure at address +addr+
        # using +target+ as target of access result.
        reader do |blk,addr,target|
            regs = size.times.map {|i| send(:"reg_#{i}") }
            # The read procedure.
            rst  = send(rst_name)
            par do
                hif(rst == 0) do
                    # No reset, so can perform the read.
                    hcase(addr)
                    size.times do |i|
                        hwhen(i) { target <= regs[i] }
                    end
                    blk.call if blk
                end
            end
        end
    end

    # Write with address
    brancher(:waddr) do
        size.times { |i| writer_output :"reg_#{i}" }
        if br_rsts[:waddr] then
            rst_name = br_rsts[:waddr].to_sym
        else
            rst_name = rst.name
            writer_input rst_name
        end

        # Defines the writer procedure at address +addr+
        # using +target+ as target of access.
        writer do |blk,addr,target|
            regs = size.times.map {|i| send(:"reg_#{i}") }
            # The writer procedure.
            rst  = send(rst_name)
            par do
                hif(rst == 0) do
                    # No reset, so can perform the read.
                    hcase(addr)
                    size.times do |i|
                        hwhen(i) { regs[i] <= target }
                    end
                    blk.call if blk
                end
            end
        end
    end


    # The increment branches.
    # Read with increment
    brancher(:rinc) do
        size.times { |i| reader_input :"reg_#{i}" }
        if br_rsts[:rinc] then
            rst_name = br_rsts[:rinc].to_sym
        else
            rst_name = rst.name
            reader_input rst_name
        end
        # Declares the address counter.
        awidth = (size-1).width
        awidth = 1 if awidth == 0
        [size.width-1].inner :abus_r
        reader_inout :abus_r

        # Defines the read procedure at address +addr+
        # using +target+ as target of access result.
        reader do |blk,target|
            regs = size.times.map {|i| send(:"reg_#{i}") }
            # On reset the read trigger is 0.
            rst  = send(rst_name)
            top_block.unshift do
                # Initialize the address so that the next access is at address 0.
                hif(rst==1) { abus_r <= 0 }
            end
            # The read procedure.
            par do
                hif(rst == 0) do
                    # No reset, so can perform the read.
                    hcase(abus_r)
                    size.times do |i|
                        hwhen(i) { target <= regs[i] }
                    end
                    blk.call if blk
                    # Prepare the next read.
                    # abus_r <= abus_r + 1
                    if 2**size.width != size then
                        abus_r <= mux((abus_r + 1) == size, abus_r + 1, 0)
                    else
                        abus_r <= abus_r + 1
                    end
                end
            end
        end
    end

    # Write with increment
    brancher(:winc) do
        size.times { |i| writer_output :"reg_#{i}" }
        if br_rsts[:winc] then
            rst_name = br_rsts[:winc].to_sym
        else
            rst_name = rst.name
            writer_input rst_name
        end
        # Declares the address counter.
        [size.width-1].inner :abus_w
        writer_inout :abus_w

        # Defines the write procedure at address +addr+
        # using +target+ as target of access result.
        writer do |blk,target|
            regs = size.times.map {|i| send(:"reg_#{i}") }
            # On reset the read trigger is 0.
            rst  = send(rst_name)
            top_block.unshift do
                # Initialize the address so that the next access is at address 0.
                hif(rst==1) { abus_w <= 0 }
            end
            # The read procedure.
            par do
                hif(rst == 0) do
                    # No reset, so can perform the read.
                    hcase(abus_w)
                    size.times do |i|
                        hwhen(i) { regs[i] <= target }
                    end
                    blk.call if blk
                    # Prepare the next write.
                    # abus_w <= abus_w + 1
                    if 2**size.width != size then
                        abus_w <= mux((abus_w + 1) == size, abus_w + 1, 0)
                    else
                        abus_w <= abus_w + 1
                    end
                end
            end
        end
    end


    # The decrement branches.
    # Read with decrement
    brancher(:rdec) do
        size.times { |i| reader_input :"reg_#{i}" }
        if br_rsts[:rdec] then
            rst_name = br_rsts[:rdec].to_sym
        else
            rst_name = rst.name
            reader_input rst_name
        end
        # Declares the address counter.
        awidth = (size-1).width
        awidth = 1 if awidth == 0
        [size.width-1].inner :abus_r
        reader_inout :abus_r

        # Defines the read procedure at address +addr+
        # using +target+ as target of access result.
        reader do |blk,target|
            regs = size.times.map {|i| send(:"reg_#{i}") }
            # On reset the read trigger is 0.
            rst  = send(rst_name)
            top_block.unshift do
                # Initialize the address so that the next access is at address 0.
                hif(rst==1) { abus_r <= -1 }
            end
            # The read procedure.
            par do
                hif(rst == 0) do
                    # No reset, so can perform the read.
                    hcase(abus_r)
                    size.times do |i|
                        hwhen(i) { target <= regs[i] }
                    end
                    blk.call if blk
                    # Prepare the next read.
                    # abus_r <= abus_r - 1
                    if 2**size.width != size then
                        abus_r <= mux(abus_r == 0, abus_r - 1, size - 1)
                    else
                        abus_r <= abus_r - 1
                    end
                end
            end
        end
    end

    # Write with decrement
    brancher(:wdec) do
        size.times { |i| writer_output :"reg_#{i}" }
        if br_rsts[:wdec] then
            rst_name = br_rsts[:wdec].to_sym
        else
            rst_name = rst.name
            reader_input rst_name
        end
        # Declares the address counter.
        [size.width-1].inner :abus_w
        reader_inout :abus_w

        # Defines the write procedure at address +addr+
        # using +target+ as target of access result.
        writer do |blk,target|
            regs = size.times.map {|i| send(:"reg_#{i}") }
            # On reset the read trigger is 0.
            rst  = send(rst_name)
            top_block.unshift do
                # Initialize the address so that the next access is at address 0.
                hif(rst==1) { abus_w <= -1 }
            end
            # The read procedure.
            par do
                hif(rst == 0) do
                    # No reset, so can perform the read.
                    hcase(abus_w)
                    size.times do |i|
                        hwhen(i) { regs[i] <= target }
                    end
                    blk.call if blk
                    # Prepare the next write.
                    # abus_w <= abus_w - 1
                    if 2**size.width != size then
                        abus_w <= mux(abus_w == 0, abus_w - 1, size - 1)
                    else
                        abus_w <= abus_w - 1
                    end
                end
            end
        end
    end

end




# Multi-bank memory combining several dual-edge memories of +nbanks+ banks
# of +size+ elements of +typ+ typ, syncrhonized on +clk+ (positive and
# negative edges) and reset on +rst+.
# at each rising edge of +clk+ a read and a write is guaranteed to be
# completed provided they are triggered.
# +br_rsts+ are reset names on the branches, if not given, a reset input
# is added and connected to rst.
#
# NOTE:
#
# * such memories uses the following ports:
#   - trig_r: read access trigger  (output)
#   - trig_w: write access trigger (output)
#   - dbus_r: read data bus        (input)
#   - dbus_w: write data bus       (output)
#
# * The following branches are possible (only one read and one write can
#   be used per channel)
#   - raddr:   read by address, this channel adds the following port:
#     abus_r:  read address bus (output)
#   - waddr:   read by address, this channel adds the following port:
#     abus_w:  write address bus (output)
#   - rinc:    read by automatically incremented address.
#   - winc:    write by automatically incremented address.
#   - rdec:    read by automatically decremented address.
#   - wdec:    write by automatically decremented address.
#   - rque:    read in queue mode: automatically incremented address ensuring
#              the read address is always different from the write address.
#   - wque:    write in queue mode: automatically incremented address ensuring
#              the write address is always differnet from the read address.
HDLRuby::High::Std.channel(:mem_bank) do |typ,nbanks,size,clk,rst,br_rsts = {}|
    # Ensure typ is a type.
    typ = typ.to_type
    # Ensure size in an integer.
    size = size.to_i
    # Compute the address bus width from the size.
    awidth = (size*nbanks-1).width
    awidth = 1 if awidth == 0
    awidth_b = (size-1).width # Bank width
    awidth_b = 1 if awidth_b == 0
    # Ensures br_srts is a hash.
    br_rsts = br_rsts.to_hash

    # The global buses and control signals.
    [awidth].inner :abus_r, :abus_w
    typ.inner :dbus_r, :dbus_w
    inner :trig_r, :trig_w

    # For each bank.
    nbanks.times do |id|
        # Declare the control signals.
        # Access triggers.
        inner :"trig_r_#{id}", :"trig_w_#{id}"
        # Data buses
        typ.inner :"dbus_r_#{id}", :"dbus_w_#{id}"
        # Address buses (or simply registers)
        [awidth_b].inner :"abus_r_#{id}", :"abus_w_#{id}"

        # Declare the memory content.
        typ[-size].inner :"mem_#{id}"

        # Processes handling the memory access.
        par(clk.negedge) do
            send(:"dbus_r_#{id}") <= send(:"mem_#{id}")[send(:"abus_r_#{id}")]
            hif(trig_w & ((abus_w % nbanks) == id)) do
                send(:"mem_#{id}")[send(:"abus_w_#{id}")] <= dbus_w
            end
            helsif(send(:"trig_w_#{id}")) do
                send(:"mem_#{id}")[send(:"abus_w_#{id}")] <= send(:"dbus_w_#{id}")
            end
        end
    end
    # Interconnect the buses and triggers
    nbanks.times do |id|
        send(:"abus_r_#{id}") <= abus_r / nbanks
        send(:"abus_w_#{id}") <= abus_w / nbanks
    end
    par do
        # By default triggers are off.
        nbanks.times do |id|
            send(:"trig_w_#{id}") <= 0
            send(:"trig_r_#{id}") <= 0
        end
        # Set the read address bus and trigger if required.
        hcase(abus_r % nbanks)
        nbanks.times do |id|
            hwhen(id) do
                dbus_r <= send(:"dbus_r_#{id}")
                send(:"trig_r_#{id}") <= trig_r
            end
        end
    end


    # The address branches.
    # Read with address
    brancher(:raddr) do
        reader_output :trig_r, :abus_r
        reader_input :dbus_r
        if br_rsts[:raddr] then
            rst_name = br_rsts[:raddr].to_sym
        else
            rst_name = rst.name
            reader_input rst_name
        end

        # Defines the read procedure at address +addr+
        # using +target+ as target of access result.
        reader do |blk,addr,target|
            # By default the read trigger is 0.
            top_block.unshift { trig_r <= 0 }
            # The read procedure.
            rst  = send(rst_name)
            par do
                hif(rst == 0) do
                    # No reset, so can perform the read.
                    hif(trig_r == 1) do
                        # The trigger was previously set, read ok.
                        target <= dbus_r
                        trig_r <= 0
                        blk.call if blk
                    end
                    helse do
                        # Prepare the read.
                        abus_r <= addr
                        trig_r <= 1
                    end
                end
            end
        end
    end

    # Write with address
    brancher(:waddr) do
        writer_output :trig_w, :abus_w, :dbus_w
        if br_rsts[:waddr] then
            rst_name = br_rsts[:waddr].to_sym
        else
            rst_name = rst.name
            writer_input rst_name
        end
        # puts "br_rsts=#{br_rsts}"
        # puts "rst_name=#{rst_name}"

        # Defines the read procedure at address +addr+
        # using +target+ as target of access result.
        writer do |blk,addr,target|
            # By default the read trigger is 0.
            top_block.unshift { trig_w <= 0 }
            # The write procedure.
            rst  = send(rst_name)
            par do
                hif(rst == 0) do
                    # No reset, so can perform the write.
                    hif(trig_w == 1) do
                        # The trigger was previously set, write ok.
                        blk.call if blk
                    end
                    # Prepare the write.
                    abus_w <= addr
                    trig_w <= 1
                    dbus_w <= target
                end
            end
        end
    end

    # The increment branches.
    # Read with increment
    brancher(:rinc) do
        reader_output :trig_r, :abus_r
        reader_input :dbus_r
        if br_rsts[:rinc] then
            rst_name = br_rsts[:rinc].to_sym
        else
            rst_name = rst.name
            reader_input rst_name
        end

        # Defines the read procedure at address +addr+
        # using +target+ as target of access result.
        reader do |blk,target|
            # On reset the read trigger is 0.
            rst  = send(rst_name)
            top_block.unshift do
                # Initialize the address so that the next access is at address 0.
                hif(rst==1) { abus_r <= -1 }
                # Reset so switch of the access trigger.
                trig_r <= 0
            end
            # The read procedure.
            par do
                hif(rst == 0) do
                    # No reset, so can perform the read.
                    hif(trig_r == 1) do
                        # The trigger was previously set, read ok.
                        target <= dbus_r
                        blk.call if blk
                    end
                    # Prepare the read.
                    # abus_r <= abus_r + 1
                    if 2**size.width != size then
                        abus_r <= mux((abus_r + 1) == size, abus_r + 1, 0)
                    else
                        abus_r <= abus_r + 1
                    end
                    trig_r <= 1
                end
            end
        end
    end

    # Write with address
    brancher(:winc) do
        writer_output :trig_w, :abus_w, :dbus_w
        if br_rsts[:winc] then
            rst_name = br_rsts[:winc].to_sym
        else
            rst_name = rst.name
            writer_input rst_name
        end
        # puts "br_rsts=#{br_rsts}"
        # puts "rst_name=#{rst_name}"

        # Defines the read procedure at address +addr+
        # using +target+ as target of access result.
        writer do |blk,target|
            # On reset the read trigger is 0.
            rst  = send(rst_name)
            top_block.unshift do
                # Initialize the address so that the next access is at address 0.
                hif(rst == 1) { abus_w <= -1 }
                # Reset so switch of the access trigger.
                trig_w <= 0
            end
            # The write procedure.
            par do
                hif(rst == 0) do
                    # No reset, so can perform the write.
                    blk.call if blk
                    # Prepare the write.
                    # abus_w <= abus_w + 1
                    if 2**size.width != size then
                        abus_w <= mux((abus_w + 1) == size, abus_w + 1, 0)
                    else
                        abus_w <= abus_w + 1
                    end
                    trig_w <= 1
                    dbus_w <= target
                end
            end
        end
    end

    # The decrement branches.
    # Read with increment
    brancher(:rdec) do
        reader_output :trig_r, :abus_r
        reader_input :dbus_r
        if br_rsts[:rdec] then
            rst_name = br_rsts[:rdec].to_sym
        else
            rst_name = rst.name
            reader_input rst_name
        end

        # Defines the read procedure at address +addr+
        # using +target+ as target of access result.
        reader do |blk,target|
            # On reset the read trigger is 0.
            rst  = send(rst_name)
            top_block.unshift do
                # Initialize the address so that the next access is at address 0.
                hif(rst==1) { abus_r <= 0 }
                # Reset so switch of the access trigger.
                trig_r <= 0
            end
            # The read procedure.
            par do
                hif(rst == 0) do
                    # No reset, so can perform the read.
                    hif(trig_r == 1) do
                        # The trigger was previously set, read ok.
                        target <= dbus_r
                        blk.call if blk
                    end
                    # Prepare the read.
                    # abus_r <= abus_r - 1
                    if 2**size.width != size then
                        abus_r <= mux(abus_r == 0, abus_r - 1, size - 1)
                    else
                        abus_r <= abus_r - 1
                    end
                    trig_r <= 1
                end
            end
        end
    end

    # Write with address
    brancher(:wdec) do
        writer_output :trig_w, :abus_w, :dbus_w
        if br_rsts[:wdec] then
            rst_name = br_rsts[:wdec].to_sym
        else
            rst_name = rst.name
            writer_input rst_name
        end
        # puts "br_rsts=#{br_rsts}"
        # puts "rst_name=#{rst_name}"

        # Defines the read procedure at address +addr+
        # using +target+ as target of access result.
        writer do |blk,target|
            # On reset the read trigger is 0.
            rst  = send(rst_name)
            top_block.unshift do
                # Initialize the address so that the next access is at address 0.
                hif(rst == 1) { abus_w <= 0 }
                # Reset so switch of the access trigger.
                trig_w <= 0
            end
            # The write procedure.
            par do
                hif(rst == 0) do
                    # No reset, so can perform the write.
                    blk.call if blk
                    # Prepare the write.
                    abus_w <= abus_w - 1
                    if 2**size.width != size then
                        abus_w <= mux(abus_w == 0, abus_w - 1, size - 1)
                    else
                        abus_w <= abus_w - 1
                    end
                    trig_w <= 1
                    dbus_w <= target
                end
            end
        end
    end


    # Declare the branchers for accessing directly the banks.
    nbanks.times do |id|
        # Read with address.
        brancher(:"raddr_#{id}") do
            reader_output :"trig_r_#{id}", :"abus_r_#{id}"
            reader_input :"dbus_r_#{id}"
            if br_rsts[:"raddr_#{id}"] then
                rst_name = br_rsts[:"raddr_#{id}"].to_sym
            else
                rst_name = rst.name
                reader_input rst_name
            end

            # Defines the read procedure at address +addr+
            # using +target+ as target of access result.
            reader do |blk,addr,target|
                # By default the read trigger is 0.
                top_block.unshift { send(:"trig_r_#{id}") <= 0 }
                # The read procedure.
                rst  = send(rst_name)
                par do
                    hif(rst == 0) do
                        # No reset, so can perform the read.
                        hif(send(:"trig_r_#{id}") == 1) do
                            # The trigger was previously set, read ok.
                            target <= send(:"dbus_r_#{id}")
                            send(:"trig_r_#{id}") <= 0
                            blk.call if blk
                        end
                        helse do
                            # Prepare the read.
                            send(:"abus_r_#{id}") <= addr
                            send(:"trig_r_#{id}") <= 1
                        end
                    end
                end
            end
        end

        # Write with address
        brancher(:"waddr_#{id}") do
            writer_output :"trig_w_#{id}", :"abus_w_#{id}", :"dbus_w_#{id}"
            if br_rsts[:"waddr_#{id}"] then
                rst_name = br_rsts[:"waddr_#{id}"].to_sym
            else
                rst_name = rst.name
                writer_input rst_name
            end

            # Defines the read procedure at address +addr+
            # using +target+ as target of access result.
            writer do |blk,addr,target|
                # By default the read trigger is 0.
                top_block.unshift { send(:"trig_w_#{id}") <= 0 }
                # The write procedure.
                rst  = send(rst_name)
                par do
                    hif(rst == 0) do
                        # No reset, so can perform the write.
                        hif(send(:"trig_w_#{id}") == 1) do
                            # The trigger was previously set, write ok.
                            blk.call if blk
                        end
                        # Prepare the write.
                        send(:"abus_w_#{id}") <= addr
                        send(:"trig_w_#{id}") <= 1
                        send(:"dbus_w_#{id}") <= target
                    end
                end
            end
        end

        # The increment branches.
        # Read with increment
        brancher(:"rinc_#{id}") do
            reader_output :"trig_r_#{id}", :"abus_r_#{id}"
            reader_input :"dbus_r_#{id}"
            if br_rsts[:"rinc_#{id}"] then
                rst_name = br_rsts[:"rinc_#{id}"].to_sym
            else
                rst_name = rst.name
                reader_input rst_name
            end

            # Defines the read procedure at address +addr+
            # using +target+ as target of access result.
            reader do |blk,target|
                # On reset the read trigger is 0.
                rst  = send(rst_name)
                top_block.unshift do
                    # Initialize the address so that the next access is at address 0.
                    hif(rst==1) { send(:"abus_r_#{id}") <= -1 }
                    # Reset so switch of the access trigger.
                    send(:"trig_r_#{id}") <= 0
                end
                # The read procedure.
                par do
                    hif(rst == 0) do
                        # No reset, so can perform the read.
                        hif(send(:"trig_r_#{id}") == 1) do
                            # The trigger was previously set, read ok.
                            target <= send(:"dbus_r_#{id}")
                            blk.call if blk
                        end
                        # Prepare the read.
                        send(:"abus_r_#{id}") <= send(:"abus_r_#{id}") + 1
                        send(:"trig_r_#{id}") <= 1
                    end
                end
            end
        end

        # Write with address
        brancher(:"winc_#{id}") do
            writer_output :"trig_w_#{id}", :"abus_w_#{id}", :"dbus_w_#{id}"
            if br_rsts[:"winc_#{id}"] then
                rst_name = br_rsts[:"winc_#{id}"].to_sym
            else
                rst_name = rst.name
                writer_input rst_name
            end

            # Defines the read procedure at address +addr+
            # using +target+ as target of access result.
            writer do |blk,target|
                # On reset the read trigger is 0.
                rst  = send(rst_name)
                top_block.unshift do
                    # Initialize the address so that the next access is at address 0.
                    hif(rst == 1) { send(:"abus_w_#{id}") <= -1 }
                    # Reset so switch of the access trigger.
                    send(:"trig_w_#{id}") <= 0
                end
                # The write procedure.
                par do
                    hif(rst == 0) do
                        # No reset, so can perform the write.
                        blk.call if blk
                        # Prepare the write.
                        send(:"abus_w_#{id}") <= send(:"abus_w_#{id}") + 1
                        send(:"trig_w_#{id}") <= 1
                        send(:"dbus_w_#{id}") <= target
                    end
                end
            end
        end

        # The decrement branches.
        # Read with increment
        brancher(:"rdec_#{id}") do
            reader_output :"trig_r_#{id}", :"abus_r_#{id}"
            reader_input :"dbus_r_#{id}"
            if br_rsts[:"rdec_#{id}"] then
                rst_name = br_rsts[:"rdec_#{id}"].to_sym
            else
                rst_name = rst.name
                reader_input rst_name
            end

            # Defines the read procedure at address +addr+
            # using +target+ as target of access result.
            reader do |blk,target|
                # On reset the read trigger is 0.
                rst  = send(rst_name)
                top_block.unshift do
                    # Initialize the address so that the next access is at address 0.
                    hif(rst==1) { send(:"abus_r_#{id}") <= 0 }
                    # Reset so switch of the access trigger.
                    send(:"trig_r_#{id}") <= 0
                end
                # The read procedure.
                par do
                    hif(rst == 0) do
                        # No reset, so can perform the read.
                        hif(send(:"trig_r_#{id}") == 1) do
                            # The trigger was previously set, read ok.
                            target <= send(:"dbus_r_#{id}")
                            blk.call if blk
                        end
                        # Prepare the read.
                        send(:"abus_r_#{id}") <= send(:"abus_r_#{id}") - 1
                        send(:"trig_r_#{id}") <= 1
                    end
                end
            end
        end

        # Write with address
        brancher(:"wdec_#{id}") do
            writer_output :"trig_w_#{id}", :"abus_w_#{id}", :"dbus_w_#{id}"
            if br_rsts[:"wdec_#{id}"] then
                rst_name = br_rsts[:"wdec_#{id}"].to_sym
            else
                rst_name = rst.name
                writer_input rst_name
            end

            # Defines the read procedure at address +addr+
            # using +target+ as target of access result.
            writer do |blk,target|
                # On reset the read trigger is 0.
                rst  = send(rst_name)
                top_block.unshift do
                    # Initialize the address so that the next access is at address 0.
                    hif(rst == 1) { send(:"abus_w_#{id}") <= 0 }
                    # Reset so switch of the access trigger.
                    trig_w <= 0
                end
                # The write procedure.
                par do
                    hif(rst == 0) do
                        # No reset, so can perform the write.
                        blk.call if blk
                        # Prepare the write.
                        send(:"abus_w_#{id}") <= send(:"abus_w_#{id}") - 1
                        send(:"trig_w_#{id}") <= 1
                        send(:"dbus_w_#{id}") <= target
                    end
                end
            end
        end
    end

end

# HDLRuby::High::Std.channel(:mem_bank) do |typ,nbanks,size,clk,rst,br_rsts = {}|
#     # Ensure typ is a type.
#     typ = typ.to_type
#     # Ensure nbank is an integer.
#     nbanks = nbanks.to_i
#     # Ensure size in an integer.
#     size = size.to_i
#     # Compute the address bus width from the size.
#     awidth = (size-1).width
#     # # Process the table of reset mapping for the branches.
#     # # puts "first br_rsts=#{br_rsts}"
#     # if br_rsts.is_a?(Array) then
#     #     # It is a list, convert it to a hash with the following order:
#     #     # raddr, waddr, rinc, winc, rdec, wdec, rque, wque
#     #     # If there is only two entries they will be duplicated and mapped
#     #     # as follows:
#     #     # [raddr,waddr], [rinc,winc], [rdec,wdec], [rque,wque]
#     #     # If there is only one entry it will be duplicated and mapped as
#     #     # follows:
#     #     # raddr, rinc, rdec, rque
#     #     if br_rsts.size == 2 then
#     #         br_rsts = br_rsts * 4
#     #     elsif br_rsts.size == 1 then
#     #         br_rsts = br_rsts * 8
#     #     end
#     #     br_rsts = { raddr: br_rsts[0], waddr: br_rsts[1],
#     #                 rinc:  br_rsts[2], winc:  br_rsts[3],
#     #                 rdec:  br_rsts[4], wdec:  br_rsts[5],
#     #                 rque:  br_rsts[6], wque:  br_rsts[6] }
#     # end
#     # unless br_rsts.respond_to?(:[])
#     #     raise "Invalid reset mapping description: #{br_rsts}"
#     # end
#     # Ensures br_rsts is a hash.
#     br_rsts = br_rsts.to_hash
# 
#     # Declares the banks.
#     banks = nbanks.times.map do |id|
#         # Extract the resets corresponding to the bank.
#         cur_br_rsts = {}
#         br_rsts.each do |k,v| 
#             num = k.to_s[/\d+$/]
#             if num && num.to_i == id then
#                 cur_br_rsts[k.to_s.chomp[num]] = v
#             end
#         end
#         # Declare the bank.
#         mem_dual(typ,size,clk,rst, cur_br_rsts).(HDLRuby.uniq_name)
#     end
# 
#     # Declare the branchers for accessing directly the banks.
#     banks.each_with_index do |bank,id|
#         brancher(id,bank)
#     end
# 
#     # Generate the gobal access to the memory.
#  
#     # The address branches.
#     # Read with address
#     brancher(:raddr) do
#         # Create the read branch for each bank.
#         bank_brs = banks.map do |bank|
#             bank.branch(:raddr).inner HDLRuby.uniq_name
#         end
#         # Defines the read procedure at address +addr+
#         # using +target+ as target of access result.
#         reader do |blk,addr,target|
#             # Select the bank depending on the address.
#             hcase(addr / nbanks)
#             nbanks.times do |i|
#                 hwhen(i) do
#                     bank_brs[i].read(addr % nbanks,target,&blk)
#                 end
#             end
#         end
#     end
#     # Write with address
#     brancher(:waddr) do
#         # Create the write branch for each bank.
#         bank_brs = banks.map do |bank|
#             bank.branch(:waddr).inner HDLRuby.uniq_name
#         end
#         # Defines the read procedure at address +addr+
#         # using +target+ as target of access result.
#         writer do |blk,addr,target|
#             # Select the bank depending on the address.
#             hcase(addr / nbanks)
#             nbanks.times do |i|
#                 hwhen(i) do
#                     bank_brs[i].write(addr % nbanks,target,&blk)
#                 end
#             end
#         end
#     end
# 
# 
#     # Address buses (or simply registers) for increment/decrement accesses
#     [awidth].inner :abus_r, :abus_w
# 
#     # The increment branches.
#     # Read with increment
#     brancher(:rinc) do
#         reader_output :abus_r
#         if br_rsts[:rinc] then
#             rst_name = br_rsts[:rinc].to_sym
#         else
#             rst_name = rst.name
#             reader_input rst_name
#         end
#         # Create the write branch for each bank.
#         bank_brs = banks.map do |bank|
#             bank.branch(:raddr).inner HDLRuby.uniq_name
#         end
# 
#         # Defines the read procedure at address +addr+
#         # using +target+ as target of access result.
#         reader do |blk,target|
#             # On reset the read trigger is 0.
#             rst  = send(rst_name)
#             top_block.unshift do
#                 # Initialize the address so that the next access is at address 0.
#                 hif(rst==1) { abus_r <= 0 }
#             end
#             # Select the bank depending on the address.
#             hcase(abus_r / nbanks)
#             nbanks.times do |i|
#                 hwhen(i) do
#                     bank_brs[i].read(abus_r % nbanks,target) do
#                         abus_r <= abus_r + 1 
#                         blk.call
#                     end
#                 end
#             end
#         end
#     end
#     # Write with increment
#     brancher(:winc) do
#         reader_output :abus_w
#         if br_rsts[:winc] then
#             rst_name = br_rsts[:winc].to_sym
#         else
#             rst_name = rst.name
#             writer_input rst_name
#         end
#         # Create the write branch for each bank.
#         bank_brs = banks.map do |bank|
#             bank.branch(:waddr).inner HDLRuby.uniq_name
#         end
# 
#         # Defines the read procedure at address +addr+
#         # using +target+ as target of access result.
#         writer do |blk,target|
#             # On reset the read trigger is 0.
#             rst  = send(rst_name)
#             top_block.unshift do
#                 # Initialize the address so that the next access is at address 0.
#                 hif(rst==1) { abus_w <= 0 }
#             end
#             # Select the bank depending on the address.
#             hcase(abus_w / nbanks)
#             nbanks.times do |i|
#                 hwhen(i) do
#                     bank_brs[i].read(abus_w % nbanks,target) do
#                         abus_w <= abus_w + 1 
#                         blk.call
#                     end
#                 end
#             end
#         end
#     end
# 
#     # The decrement branches.
#     # Read with decrement
#     brancher(:rdec) do
#         reader_output :abus_r
#         if br_rsts[:rdec] then
#             rst_name = br_rsts[:rdec].to_sym
#         else
#             rst_name = rst.name
#             reader_input rst_name
#         end
# 
#         # Defines the read procedure at address +addr+
#         # using +target+ as target of access result.
#         reader do |blk,target|
#             # On reset the read trigger is 0.
#             rst  = send(rst_name)
#             top_block.unshift do
#                 # Initialize the address so that the next access is at address 0.
#                 hif(rst==1) { abus_r <= 0 }
#             end
#             # Select the bank depending on the address.
#             hcase(abus_r / nbanks)
#             nbanks.times do |i|
#                 hwhen(i) do
#                     banks[i].read(abus_r % nbanks,target) do
#                         abus_r <= abus_r + 1 
#                         blk.call
#                     end
#                 end
#             end
#         end
#     end
#     # Write with decrement
#     brancher(:wdec) do
#         reader_output :abus_w
#         if br_rsts[:wdec] then
#             rst_name = br_rsts[:wdec].to_sym
#         else
#             rst_name = rst.name
#             writer_input rst_name
#         end
# 
#         # Defines the read procedure at address +addr+
#         # using +target+ as target of access result.
#         writer do |blk,target|
#             # On reset the read trigger is 0.
#             rst  = send(rst_name)
#             top_block.unshift do
#                 # Initialize the address so that the next access is at address 0.
#                 hif(rst==1) { abus_w <= 0 }
#             end
#             # Select the bank depending on the address.
#             hcase(abus_w / nbanks)
#             nbanks.times do |i|
#                 hwhen(i) do
#                     banks[i].read(abus_w % nbanks,target) do
#                         abus_w <= abus_w + 1 
#                         blk.call
#                     end
#                 end
#             end
#         end
#     end
# 
# end
