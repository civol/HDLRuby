require "rubyHDL.rb"

# Ruby program that simulate a memory: not real software!
MEM = [ 0 ] * 256
def mem
    addr = RubyHDL.addr
    rwb  = RubyHDL.rwb
    din  = RubyHDL.din

    if rwb == 1 then
        dout = MEM[addr & 255]
        # puts "Reading memory at addr=#{addr} dout=#{dout}"
        RubyHDL.dout = dout
    else
        # puts "Writing memory at addr=#{addr} din=#{din}"
        MEM[addr & 255] = din
    end
end




# Ruby program that increments the contents of a memory.


# Access the memory.
def inc_mem
    index = RubyHDL.index
    val  = MEM[index]
    puts "Increasing #{val} at index #{index}..."
    MEM[index] = val + 1
end
