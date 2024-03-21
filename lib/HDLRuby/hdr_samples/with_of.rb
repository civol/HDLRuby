# Some abstract system.
system :sysA do
    input :clk,:rst
    input :d
    output :q
end

# Some inheriting system.
system :sysH, sysA do
    par(clk.posedge, rst.posedge) do
        hprint("sys1\n")
        q <= d & ~rst
    end
end

# Another system that have nothing to see with the others.
# Some abstract system.
system :sysO do
    input :clk,:rst
    input :d
    output :q

    par(clk.posedge, rst.posedge) do
        hprint("sys1\n")
        q <= d & ~rst
    end
end


# A system for testing inheritance and of?
system :with_of do
    input :clk,:rst
    input :d
    output :q

    # Instantiate the abstract system.
    sysA(:my_dffA).(clk,rst,d,q)

    # Test the of?
    puts "my_dffA.systemT.of?(sysA)=#{my_dffA.systemT.of?(sysA)}"
    puts "my_dffA.systemT.of?(sysH)=#{my_dffA.systemT.of?(sysH)}"
    puts "my_dffA.systemT.of?(sysO)=#{my_dffA.systemT.of?(sysO)}"

    # Instantiate the inheriting system.
    sysH(:my_dffH).(clk,rst,d,q)

    # Test the of?
    puts "my_dffH.systemT.of?(sysH)=#{my_dffH.systemT.of?(sysH)}"
    puts "my_dffH.systemT.of?(sysA)=#{my_dffH.systemT.of?(sysA)}"
    puts "my_dffH.systemT.of?(sysO)=#{my_dffH.systemT.of?(sysO)}"
end
