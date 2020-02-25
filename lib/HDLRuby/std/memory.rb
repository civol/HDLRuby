require 'std/channel.rb'



##
# Standard HDLRuby::High library: memories encapsulated in channels.
# 
########################################################################

# Synchroneous +n+ ports memories including +size+ words of +typ+ data type,
# synchronized on +clk_e+ event.
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
HDLRuby::High::Std.channel(:mem_sync) do |n,typ,size,clk_e|
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
    typ[awidth].inner :mem

    # Sets the reader and writer channel ports (not the memory ports!)
    n.times do |p|
        # For port number +p+
        # Access channel ports.
        accesser_inout :"abus_#{p}", :"cs_#{p}", :"rwb_#{p}"
        accesser_inout :"dbus_#{p}"
    end

    # Defines a command for generating an interface for accessing
    # a specific port.
    command(:port) do |p|
        # Get access to the channel
        obj = self
        # Use a delagator to overload its inout for generating an
        # access to memory port p only.
        Class.new(SimpleDelegator) do
            def inout(name)
                # Get the delegate channel
                obj = __getobj__
                # Generate the channel access port from it
                port = obj.inout(name)
                # Update its read and write method to access only
                # memory port number p.
                read_meth = obj.method(:read)
                port.define_singleton_method(:read) do |address,target,&blk|
                    read_meth.(p,address,target,&blk)
                end
                write_meth = obj.method(:write)
                port.define_singleton_method(:write) do |address,target,&blk|
                    write_meth.(p,address,target,&blk)
                end
            end
        end.new(obj)
    end

    # Defines the access procedure to port +p+ at address +addr+
    # using +target+ as target of access result.
    # If +mode+ is 0 then it is a write otherwise it is a read.
    accesser do |blk,p,mode,addr,target|
        # Ensure p is an integer.
        p = p.to_i
        # Get the interface.
        abus = send(:"abus_#{p}")
        dbus = send(:"dbus_#{p}")
        cs   = send(:"cs_#{p}")
        rwb  = send(:"rwb_#{p}")
        # Use it to make the access.
        hif (cs == 0) do
            # Can access.
            cs <= 1
            rwb <= mode
            abus <= addr
            hif (rwb) { target <= dbus }
            helse     { dbus <= target }
            # Execute the blk.
            blk.call if blk
        end; helse do
            # Cannot access.
            abus <= _z
            cs <= _z
            rwb <= _z
        end
    end

    # Defines the read procedure to port +p+ at address +addr+
    # using +target+ as target of access result.
    reader do |blk,p,addr,target|
        access(p,1,addr,target,&blk)
    end

    # Defines the writer procedure to port +p+ at address +addr+
    # using +target+ as target of access result.
    writer do |blk,p,addr,target|
        access(p,1,addr,target,&blk)
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
            hif (cs & rwb) { dbus <= mem[abus] }
            # The no accesses
            helsif (cs == 0)   { dbus <= _z }
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
                hif(cs & ~rwb)    { mem[abus] <= dbus }
            else
                helsif(cs & ~rwb) { mem[abus] <= dbus }
            end
        end
    end
end
