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
            # By default the read trigger is 0.
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
                    abus_r <= abus_r + 1
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
            # By default the read trigger is 0.
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
                    abus_w <= abus_w + 1
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
            # By default the read trigger is 0.
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
                    abus_r <= abus_r - 1
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
            # By default the read trigger is 0.
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
        [size.width-1].inner :abus_r
        reader_inout :abus_r

        # Defines the read procedure at address +addr+
        # using +target+ as target of access result.
        reader do |blk,target|
            regs = size.times.map {|i| send(:"reg_#{i}") }
            # By default the read trigger is 0.
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
                    abus_r <= abus_r + 1
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
            reader_input rst_name
        end
        # Declares the address counter.
        [size.width-1].inner :abus_w
        reader_inout :abus_w

        # Defines the write procedure at address +addr+
        # using +target+ as target of access result.
        writer do |blk,target|
            regs = size.times.map {|i| send(:"reg_#{i}") }
            # By default the read trigger is 0.
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
                    abus_w <= abus_w + 1
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
        [size.width-1].inner :abus_r
        reader_inout :abus_r

        # Defines the read procedure at address +addr+
        # using +target+ as target of access result.
        reader do |blk,target|
            regs = size.times.map {|i| send(:"reg_#{i}") }
            # By default the read trigger is 0.
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
                    abus_r <= abus_r - 1
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
            # By default the read trigger is 0.
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
                    abus_w <= abus_w - 1
                end
            end
        end
    end

end
