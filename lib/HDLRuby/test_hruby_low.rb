######################################################################
##               Program for test the HRbuyLow module.              ##
######################################################################

require "HDLRuby.rb"

require "yaml"

include HDLRuby::Low

$success = true

# print "Creating the type for one bit... "
# begin
#     $bit = Type.new(:bit)
#     if $bit.base == :bit then
#         puts "Ok."
#     else
#         puts "Error: invalid base, got #{$bit.base} but expecting :bit."
#         $success = false
#     end
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
# end

print "\nCreating system types... "
begin
    $systemT0 = SystemT.new("systemT0")
    $systemT1 = SystemT.new("systemT1")
    if $systemT0.name == "systemT0" then
        puts "Ok."
    else
        puts "Error: invalid name, got #{$systemT0.name} but expecting system0."
        $success = false
    end
rescue Exception => e
    puts "Error: unexpected exception raised #{e.inspect}\n"
    $success = false
end

print "\nCreating a one-bit signal type... "
begin
    $sig_bit = SignalT.new("bit",:bit,1)
    if $sig_bit.name != "bit" then
        puts "Error: invalid name: got #{$sig_bit.name} but expecting bit."
        $success = false
    elsif $sig_bit.type != :bit then
        puts "Error: invalid type: got #{$sig_bit.type} but expecting #{$bit}."
        $success = false
    else
        puts "Ok."
    end
rescue Exception => e
    puts "Error: unexpected exception raised #{e.inspect}\n"
    $success = false
end

puts "\nCreating signal instances from the previous signal type..."
$sNames = ["i0", "i1", "i2", "i3", "o0", "o1", "io", "s0", "s1", "s2"]
$signalIs = []
$sNames.each_with_index do |name,i|
    print "  Signal instance #{name}... "
    begin
        $signalIs[i] = SignalI.new($sig_bit,name)
        if $signalIs[i].signalT != $sig_bit then
            puts "Error: invalid signal type, got #{$signalIs[name].signalT} " +
                 " but expecting #{$sig_bit}"
            $success = false
        elsif $signalIs[i].name != name then
            puts "Error: invalid name, got #{$signalIs[i].name} " +
                 " but expecting #{name}"
            $success = false
        else
            puts "Ok."
        end
    rescue Exception => e
        puts "Error: unexpected exception raised #{e.inspect}\n"
        $success = false
    end
end

puts "\nAdding them to $systemT0 as input, output or inout... "
$signalIs.each do |signalI|
    begin
        name = signalI.name
        print "  For signal instance #{name}... "
        if name[0..1] == "io" then
            # Inout
            $systemT0.add_inout(signalI)
        elsif name[0] == "i" then
            # Input
            $systemT0.add_input(signalI)
        elsif name[0] == "o" then
            # Output
            $systemT0.add_output(signalI)
        else
            # Inner
            $systemT0.add_inner(signalI)
        end
        puts "Ok."
    rescue Exception => e
        puts "Error: unexpected exception raised #{e.inspect}\n"
        $success = false
    end
end

print "\nCompleting $systemT1 for further use... "
begin
    $systemT1.add_input(SignalI.new($sig_bit,"i0"))
    $systemT1.add_input(SignalI.new($sig_bit,"i1"))
    $systemT1.add_input(SignalI.new($sig_bit,"i2"))
    $systemT1.add_output(SignalI.new($sig_bit,"o0"))
    $systemT1.add_output(SignalI.new($sig_bit,"o1"))
    $systemT1.add_inout(SignalI.new($sig_bit,"io"))
    puts "Ok."
rescue Exception => e
    puts "Error: unexpected exception raised #{e.inspect}\n"
    $success = false
end

puts "\nInstantiating the systems... "
begin
    $systemI0 = SystemI.new($systemT0,"systemI0")
    $systemI1 = SystemI.new($systemT1,"systemI1")
    $systemI2 = SystemI.new($systemT1,"systemI2")
    if $systemI0.name == "systemI0" then
        puts "Ok."
    else
        puts "Error: invalid name, got #{$systemI0.name} but expecting system0."
    end
rescue Exception => e
    puts "Error: unexpected exception raised #{e.inspect}\n"
    $success = false
end
$systemIs = [ $systemI0, $systemI1, $systemI2 ]

puts "\nAdding systems instances to $systemT0... "
begin
    print "  Adding $systemI1... "
    $systemT0.add_systemI($systemI1)
    print "Ok.\n  Adding $systemI2... "
    $systemT0.add_systemI($systemI2)
    puts "Ok."
rescue Exception => e
    puts "Error: unexpected exception raised #{e.inspect}\n"
    $success = false
end

puts "\nCreating ports for further connection of the signals..."
$pNames = ["p0i0", "p0i1", "p0i2", "p0i3", "p0o0", "p0o1", "p0io",
           "p0s0", "p0s1", "p0s2",
           "p1i0", "p1i1", "p1i2", "p1o0", "p1o1", "p1io",
           "p1s0", "p1s1", "p1s2",
           "p2i0", "p2i1", "p2i2", "p2o0", "p2o1", "p2io",
           "p2s0", "p2s1", "p2s2"]
$ports = []
$pNames.each_with_index do |name,i|
    print "  Port #{name}... "
    begin
        # Create the system port.
        system_port = PortThis.new
        if name[1] != "0" then
            # Sub system case.
            system_port = PortKey.new(system_port,"systemI#{name[1]}")
        end
        # Create the signal port
        $ports[i] = PortKey.new(system_port,"#{name[2..3]}")
        if $ports[i].key != name[2..3].to_sym then
            puts "Error: invalid signal instance, got #{$ports[i].key} " +
                 " but expecting #{name[2..3]}"
            $success = false
        else
            puts "Ok."
        end
    rescue Exception => e
        puts "Error: unexpected exception raised #{e.inspect}\n"
        $success = false
    end
end

puts "\nCreating the connections..."
$cNames = { }


puts "Testing the content of $systemT0... "
begin
    iCount = 0  # Input signal instances counter
    oCount = 0  # Output signal instances counter
    ioCount = 0 # Inout signal instances counter
    puts "  Inputs... "
    $systemT0.each_input.with_index do |input,i|
        print "    Input #{i}... "
        signalI = $signalIs[i]
        iCount += 1
        if input == signalI then
            puts "Ok."
        else
            puts "Error: unexpected input, got #{input} but expecting #{signalI}."
            $success = false
        end
    end
    puts "  Outputs... "
    $systemT0.each_output.with_index do |output,i|
        print "    Output #{i}... "
        signalI = $signalIs[i+iCount]
        oCount += 1
        if output == signalI then
            puts "Ok."
        else
            puts "Error: unexpected output, got #{output} but expecting #{signalI}."
            $success = false
        end
    end
    puts "  Inouts... "
    $systemT0.each_inout.with_index do |inout,i|
        print "    Inout #{i}... "
        signalI = $signalIs[i+iCount+oCount]
        ioCount += 1
        if inout == signalI then
            puts "Ok."
        else
            puts "Error: unexpected output, got #{inout} but expecting #{signalI}."
            $success = false
        end
    end
    puts "  Inners... "
    $systemT0.each_inner.with_index do |inner,i|
        print "    Inner #{i}... "
        signalI = $signalIs[i+iCount+oCount+ioCount]
        if inner == signalI then
            puts "Ok."
        else
            puts "Error: unexpected inner, got #{inner} but expecting #{signalI}."
            $success = false
        end
    end
    puts "  All signal instances... "
    $systemT0.each_signalI.with_index do |any,i|
        print "    SignalI #{i}... "
        signalI = $signalIs[i]
        if any == signalI then
            puts "Ok."
        else
            puts "Error: unexpected signalI, got #{any} but expecting #{signalI}."
            $success = false
        end
    end
    puts "  System instances... "
    $systemT0.each_systemI.with_index do |any,i|
        print "    SystemI #{i}... "
        systemI = $systemIs[i+1]
        if any == systemI then
            puts "Ok."
        else
            puts "Error: unexpected systemI, got #{any} but expecting #{systemI}."
            $success = false
        end
    end
rescue Exception => e
    puts "Error: unexpected exception raised #{e.inspect}\n"
    $success = false
end

    

if $success then
    puts "\nSuccess."
else
    puts "\nFailure."
end


# puts YAML.dump($systemT0)
