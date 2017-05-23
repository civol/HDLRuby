########################################################################
##            Program for testing the HDLRuby::Low module.            ##
########################################################################

require "HDLRuby.rb"
require "HDLRuby/hruby_serializer.rb"

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
    $systemT0 = SystemT.new(:systemT0)
    $systemT1 = SystemT.new(:systemT1)
    if $systemT0.name == :systemT0 then
        puts "Ok."
    else
        puts "Error: invalid name, got #{$systemT0.name} but expecting systemT0."
        $success = false
    end
rescue Exception => e
    puts "Error: unexpected exception raised #{e.inspect}\n"
    $success = false
end

# print "\nCreating a 8-bit signal type... "
# begin
#     $sig_bit = SignalT.new(:bit8,:bit,8)
#     if $sig_bit.name != :bit8 then
#         puts "Error: invalid name: got #{$sig_bit.name} but expecting bit8."
#         $success = false
#     elsif $sig_bit.type != :bit then
#         puts "Error: invalid type: got #{$sig_bit.type} but expecting #{$bit}."
#         $success = false
#     elsif $sig_bit.size != 8 then
#         puts "Error: invalid size: got #{$sig_bit.size} but expecting 8."
#         $success = false
#     else
#         puts "Ok."
#     end
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
# end

print "\nCreating a 8-bit data type... "
begin
    $bit8 = Type.new(:bit8,:bit,8)
    if $bit8.name != :bit8 then
        puts "Error: invalid name: got #{$bit8.name} but expecting bit8."
        $success = false
    elsif $bit8.base != :bit then
        puts "Error: invalid type: got #{$bit8.type} but expecting bit."
        $success = false
    elsif $bit8.size != 8 then
        puts "Error: invalid size: got #{$bit8.size} but expecting 8."
        $success = false
    else
        puts "Ok."
    end
rescue Exception => e
    puts "Error: unexpected exception raised #{e.inspect}\n"
    $success = false
end

# puts "\nCreating signal instances from the previous signal type..."
# $sNames = ["i0", "i1", "i2", "i3", "i4", "i5", "i6", "i7", "clk",
#            "o0", "o1", "o2", "o3", "o4", "o5", "io", "s0", "s1", "s2",
#            ]
# $signalIs = []
# $sNames.each_with_index do |name,i|
#     if i > 0 then
#         print "  Signal instance #{name} (SignalT designated by name)... "
#     else
#         print "  Signal instance #{name}... "
#     end
#     begin
#         if i > 0 then
#             # SignalT directly used.
#             $signalIs[i] = SignalI.new(name,$sig_bit)
#         else
#             # SignalT designated by name.
#             $signalIs[i] = SignalI.new(name,:bit8)
#         end
#         if $signalIs[i].signalT != $sig_bit then
#             puts "Error: invalid signal type, got #{$signalIs[name].signalT} " +
#                  " but expecting #{$sig_bit}"
#             $success = false
#         elsif $signalIs[i].name != name.to_sym then
#             puts "Error: invalid name, got #{$signalIs[i].name} " +
#                  " but expecting #{name}"
#             $success = false
#         else
#             puts "Ok."
#         end
#     rescue Exception => e
#         puts "Error: unexpected exception raised #{e.inspect}\n"
#         $success = false
#     end
# end
puts "\nCreating signals..."
$sNames = ["i0", "i1", "i2", "i3", "i4", "i5", "i6", "i7", "clk",
           "o0", "o1", "o2", "o3", "o4", "o5", "io", "s0", "s1", "s2",
           ]
$signals = []
$sNames.each_with_index do |name,i|
    print "  Signal #{name}... "
    begin
        # SignalT directly used.
        $signals[i] = Signal.new(name,:bit8)
        if $signals[i].name != name.to_sym then
            puts "Error: invalid signal name, got #{$signalIs[i].name} " +
                 " but expecting #{name}"
            $success = false
        elsif $signals[i].type != $bit8 then
            puts "Error: invalid signal type, got #{$signals[i].type} " +
                 " but expecting #{:bit}"
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
# $signalIs.each do |signalI|
#     begin
#         name = signalI.name
#         print "  For signal instance #{name}... "
#         if name[0..1] == "io" then
#             # Inout
#             $systemT0.add_inout(signalI)
#         elsif name[0] == "i" then
#             # Input
#             $systemT0.add_input(signalI)
#         elsif name[0] == "o" then
#             # Output
#             $systemT0.add_output(signalI)
#         elsif name[0] == "s" then
#             # Inner
#             $systemT0.add_inner(signalI)
#         else
#             # Default: input (should be the clock).
#             $systemT0.add_input(signalI)
#         end
#         puts "Ok."
#     rescue Exception => e
#         puts "Error: unexpected exception raised #{e.inspect}\n"
#         $success = false
#     end
# end
$signals.each do |signal|
    begin
        name = signal.name
        print "  For signal instance #{name}... "
        if name[0..1] == "io" then
            # Inout
            $systemT0.add_inout(signal)
        elsif name[0] == "i" then
            # Input
            $systemT0.add_input(signal)
        elsif name[0] == "o" then
            # Output
            $systemT0.add_output(signal)
        elsif name[0] == "s" then
            # Inner
            $systemT0.add_inner(signal)
        else
            # Default: input (should be the clock).
            $systemT0.add_input(signal)
        end
        puts "Ok."
    rescue Exception => e
        puts "Error: unexpected exception raised #{e.inspect}\n"
        $success = false
    end
end

print "\nCompleting $systemT1 for further use... "
# begin
#     $systemT1.add_input(SignalI.new("i0",$sig_bit))
#     $systemT1.add_input(SignalI.new("i1",$sig_bit))
#     $systemT1.add_input(SignalI.new("i2",$sig_bit))
#     $systemT1.add_output(SignalI.new("o0",$sig_bit))
#     $systemT1.add_output(SignalI.new("o1",$sig_bit))
#     $systemT1.add_inout(SignalI.new("io",$sig_bit))
#     puts "Ok."
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
# end
begin
    $systemT1.add_input(Signal.new("i0",:bit8))
    $systemT1.add_input(Signal.new("i1",:bit8))
    $systemT1.add_input(Signal.new("i2",:bit8))
    $systemT1.add_output(Signal.new("o0",:bit8))
    $systemT1.add_output(Signal.new("o1",:bit8))
    $systemT1.add_inout(Signal.new("io",:bit8))
    puts "Ok."
rescue Exception => e
    puts "Error: unexpected exception raised #{e.inspect}\n"
    $success = false
end

puts "\nInstantiating the systems... "
begin
    print "  SystemI 0... "
    $systemI0 = SystemI.new("systemI0",$systemT0)
    success = true
    if $systemI0.name != :systemI0 then
        puts "Error: invalid name, got #{$systemI0.name} but expecting systemI0."
        success = false
    end
    if $systemI0.systemT != $systemT0 then
        puts "Error: invalid system type, got #{$systemI0.systemT.name} but expecting systemT0."
        success = false
    end
    if success then
        puts "Ok."
    else
        $success = false
    end
    print "  SystemI 1... "
    $systemI1 = SystemI.new("systemI1",$systemT1)
    if $systemI1.name != :systemI1 then
        puts "Error: invalid name, got #{$systemI1.name} but expecting systemI1."
        success = false
    end
    if $systemI1.systemT != $systemT1 then
        puts "Error: invalid system type, got #{$systemI1.systemT.name} but expecting systemT1."
        success = false
    end
    if success then
        puts "Ok."
    else
        $success = false
    end
    print "  SystemI 2 (SystemT designated by name)... "
    $systemI2 = SystemI.new("systemI2",:systemT1)
    if $systemI2.systemT != $systemT1 then
        puts "Error: invalid system type, got #{$systemI2.systemT.name} but expecting systemT1."
        success = false
    end
    if success then
        puts "Ok."
    else
        $success = false
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

puts "\nCreating references for further connection of the signals..."
$pNames = ["p0i0", "p0i1", "p0i2", "p0i3", "p0i4", "p0i5", "p0i6", "p0i7",
           "p0o0", "p0o1", "p0o2", "p0o3", "p0o4", "p0o5", "p0io",
           "p0s0", "p0s1", "p0s2", "p0clk",
           "p1i0", "p1i1", "p1i2", "p1o0", "p1o1", "p1io",
           "p1s0", "p1s1", "p1s2",
           "p2i0", "p2i1", "p2i2", "p2o0", "p2o1", "p2io",
           "p2s0", "p2s1", "p2s2"]
$refs = []
$pNames.each_with_index do |name,i|
    print "  Ref #{name}... "
    begin
        # Create the system reference.
        system_ref = RefThis.new
        if name[1] != "0" then
            # Sub system case.
            system_ref = RefName.new(system_ref,"systemI#{name[1]}")
        end
        # Create the signal reference.
        $refs[i] = RefName.new(system_ref,"#{name[2..-1]}")
        if $refs[i].name != name[2..-1].to_sym then
            puts "Error: invalid signal, got #{$refs[i].name} " +
                 " but expecting #{name[2..-1]}"
            $success = false
        else
            puts "Ok."
        end
    rescue Exception => e
        puts "Error: unexpected exception raised #{e.inspect}\n"
        $success = false
    end
end

puts "\nCreating reference-only connections..."
# $cNames = { "p0i0" => ["p1i0"], "p0i1" => ["p1i1"],
#             "p0i2" => ["p2i0"], "p0i3" => ["p2i1"],
#             "p1o0" => ["p0o0"], "p1o1" => ["p2i2"], 
#             "p2o0" => ["p0o1"], "p2o1" => ["p1i2"], 
#             "p0io" => ["p1io", "p1io"]
#           }
# $connections = []
# $cNames.each do |sName,dNames|
#     print "  Connection #{sName} => #{dNames}... "
#     begin
#         connection = Connection.new
#         $connections << connection
#         refs = [ $refs[$pNames.index(sName)] ] + 
#                 dNames.map {|name| $refs[$pNames.index(name)] }
#         refs.each {|ref| connection.add_ref(ref) }
#         success = true
#         connection.each_ref.with_index do |cRef,i|
#             if cRef != refs[i] then
#                 puts "Error: invalid reference, got #{cRef} but expecting #{refs[i]}."
#                 success = false
#             end
#         end
#         if success then
#             puts "Ok."
#         else
#             $success = false
#         end
#     rescue Exception => e
#         puts "Error: unexpected exception raised #{e.inspect}\n"
#         $success = false
#     end    
# end
$cNames = { "p0i0" => "p1i0", "p0i1" => "p1i1",
            "p0i2" => "p2i0", "p0i3" => "p2i1",
            "p1o0" => "p0o0", "p1o1" => "p2i2", 
            "p2o0" => "p0o1", "p2o1" => "p1i2", 
            "p0io" => "p1io"
          }
$connections = []
$cNames.each do |sName,dName|
    print "  Connection #{sName} => #{dName}... "
    begin
        left =  $refs[$pNames.index(sName)]
        right = $refs[$pNames.index(dName)]
        connection = Connection.new(left,right)
        $connections << connection
        success = true
        if connection.left != left then
            puts "Error: invalid reference, got #{connection.keft} but expecting #{left}."
            success = false
        end
        if connection.right != right then
            puts "Error: invalid reference, got #{connection.keft} but expecting #{right}."
            success = false
        end
        if success then
            puts "Ok."
        else
            $success = false
        end
    rescue Exception => e
        puts "Error: unexpected exception raised #{e.inspect}\n"
        $success = false
    end    
end


puts "\nCreating expressions... "
eNames = [ "i4+i5", "i4&i5", "i6-i7", "i6|i7", "i4+2", "i5&7"]

# Generate an expression from a signal or constant name
def eName2Exp(name)
    ref = $refs.find {|ref| ref.name == name }
    unless ref
        return Value.new(:bit8,name.to_i)
    end
    return ref
end

$expressions = []
eNames.each do |eName|
    print "  Expression #{eName}... "
    begin
        left = eName2Exp(eName[0..1])
        operator = eName[2].to_sym
        right = eName2Exp(eName[3..-1])
        expression = Binary.new(operator,left,right)
        $expressions << expression
        success = true
        unless expression.left == left then
            raise "Error: invalid left value, got #{expression.left} but expecting #{left}."
            success = false
        end
        unless expression.right == right then
            raise "Error: invalid right value, got #{expression.right} but expecting #{right}."
            success = false
        end
        unless expression.operator == operator then
            raise "Error: invalid operator, got #{expression.operator} but expecting #{operator}."
            success = false
        end
        if success then
            puts "Ok."
        else
            $success = false
        end
    rescue Exception => e
        puts "Error: unexpected exception raised #{e.inspect}\n"
        $success = false
    end
end


print "\nCreating an expression connection... "
# begin
#     connection = Connection.new($expressions[0])
#     $connections << connection
#     ref = $refs[$pNames.index("p0o2")]
#     connection.add_ref(ref)
#     success = true
#     unless connection.expression == $expressions[0] then
#         puts "Error: invalid expression, got #{connection.expression} but expecting #{$expressions[0]}"
#         success = false
#     end
#     refs = connection.each_ref.to_a
#     unless refs.size == 1 then
#         puts "Error: too many references for the connection, got #{refs.size} but expecting 1."
#         success = false
#     end
#     unless refs[0] == ref then
#         puts "Error: invalid reference in connection, got #{refs[0]} but expecting #{ref}."
#         success = false
#     end
#     if success then
#         puts "Ok."
#     else
#         $success = false
#     end
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
# end
begin
    
    ref = $refs[$pNames.index("p0o2")]
    connection = Connection.new(ref,$expressions[0])
    $connections << connection
    puts "Ok."
rescue Exception => e
    puts "Error: unexpected exception raised #{e.inspect}\n"
    $success = false
end


puts "\nAdding connections to $systemT0... "
begin
    $connections.each.with_index do |connection,i|
        key = $cNames.keys[i]
        if key then
            # System connections
            print "  Adding connection #{key} => #{$cNames[key]}... "
        else
            # Expression connections
            print "  Adding expression connection... "
        end
        $systemT0.add_connection(connection)
        puts "Ok."
    end
rescue Exception => e
    puts "Error: unexpected exception raised #{e.inspect}\n"
    $success = false
end


puts "\nCreating statements..."
$stNames = [ ["p0o3", $expressions[1]], ["p0o4", $expressions[2]] ]
$statements = []
$stNames.each do |pName,expression|
    print "  Transmission to #{pName}... "
    begin
        ref = $refs[$pNames.index(pName)]
        statement = Transmit.new(ref,expression)
        $statements << statement
        success = true
        unless statement.left == ref then
            raise "Error: invalid left value, got #{statement.left} but expecting #{ref}."
            success = false
        end
        unless statement.right == expression then
            raise "Error: invalid right value, got #{statement.right} but expecting #{expression}."
            success = false
        end
        if success then
            puts "Ok."
        else
            $success = false
        end
    rescue Exception => e
        puts "Error: unexpected exception raised #{e.inspect}\n"
        $success = false
    end
end


print "\nCreating a clock event... "
# begin
#     signalI = $signalIs.find{|signalI| signalI.name == :clk}
#     $event = Event.new(:posedge,signalI)
#     success = true
#     if $event.type != :posedge then
#         puts "Error: invalid type of event, got #{$event.type} but expecting :posedge."
#         success = false
#     elsif $event.signalI != signalI then
#         puts "Error: invalid signalI, got #{$event.signalI} but expecting #{signalI}."
#         success = false
#     end
#     if success then
#         puts "Ok."
#     else
#         $success = false
#     end
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
# end
begin
    ref = $refs.find{|ref| ref.name == :clk}
    $event = Event.new(:posedge,ref)
    success = true
    if $event.type != :posedge then
        puts "Error: invalid type of event, got #{$event.type} but expecting :posedge."
        success = false
    elsif $event.ref != ref then
        puts "Error: invalid reference, got #{$event.ref} but expecting #{ref}."
        success = false
    end
    if success then
        puts "Ok."
    else
        $success = false
    end
rescue Exception => e
    puts "Error: unexpected exception raised #{e.inspect}\n"
    $success = false
end


print "\nCreating a block... "
begin
    $block = Block.new(:sequential)
    if $block.type != :sequential then
        puts "Error: invalid block type, got #{$block.type} but expecting :sequential."
        $success = false
    else
        puts "Ok."
    end
rescue Exception => e
    puts "Error: unexpected exception raised #{e.inspect}\n"
    $success = false
end

puts "\nAdding statements to $block... "
$statements.each.with_index do |statement,i|
    begin
        print "  For statement #{i}... "
        $block.add_statement(statement)
        puts "Ok."
    rescue Exception => e
        puts "Error: unexpected exception raised #{e.inspect}\n"
        $success = false
    end
end
puts "Checking the added statements... "
$statements.each.with_index do |statement,i|
    begin
        print "  For statement #{i}... "
        bStatement = $block.each_statement.to_a[i]
        if bStatement != statement then
            puts "Error: invalid statement, got #{bStatement} but expecting #{statement}."
            $success = false
        else
            puts "Ok."
        end
    rescue Exception => e
        puts "Error: unexpected exception raised #{e.inspect}\n"
        $success = false
    end
end


print "\nCreating a behavior with $block... "
begin
    $behavior = Behavior.new($block)
    block = $behavior.block
    if block != $block then
        puts "Error: invalid block, got #{block} but expecting #{$block}."
        $sucess = false
    else
        puts "Ok."
    end
rescue Exception => e
    puts "Error: unexpected exception raised #{e.inspect}\n"
    $success = false
end

print "\nAdding an even to $behavior... "
begin
    $behavior.add_event($event)
    pEvent = $behavior.each_event.first
    if pEvent != $event then
        puts "Error: invalid event, got #{pEvent} but expecting #{$event}."
        $sucess = false
    else
        puts "Ok."
    end
rescue Exception => e
    puts "Error: unexpected exception raised #{e.inspect}\n"
    $success = false
end

# print "\nAdding a block to $behavior... "
# begin
#     $behavior.add_block($block)
#     pBlock = $behavior.each_block.first
#     if pBlock != $block then
#         puts "Error: invalid block, got #{pBlock} but expecting #{$block}."
#         $sucess = false
#     else
#         puts "Ok."
#     end
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
# end


print "\nAdding a behavior to $systemT0... "
begin
    $systemT0.add_behavior($behavior)
    sBehavior = $systemT0.each_behavior.first
    if sBehavior != $behavior then
        puts "Error: invalid behavior, got #{sBehavior} but expecting #{$behavior}."
        $sucess = false
    else
        puts "Ok."
    end
rescue Exception => e
    puts "Error: unexpected exception raised #{e.inspect}\n"
    $success = false
end

#################################################################
# Final global test.

puts "\nTesting the content of $systemT0... "
begin
    iCount = 0  # Input signal instances counter
    oCount = 0  # Output signal instances counter
    ioCount = 0 # Inout signal instances counter
    # puts "  Inputs... "
    # $systemT0.each_input.with_index do |input,i|
    #     print "    Input #{i}... "
    #     signalI = $signalIs[i]
    #     iCount += 1
    #     if input == signalI then
    #         puts "Ok."
    #     else
    #         puts "Error: unexpected input, got #{input} but expecting #{signalI}."
    #         $success = false
    #     end
    # end
    # puts "  Inputs by name... "
    # $signalIs.each do |input|
    #     if /i[0-9]/.match(input.name) then
    #         print "    Input #{input.name}... "
    #         signalI = $systemT0.get_input(input.name)
    #         if input == signalI then
    #             puts "Ok."
    #         else
    #             puts "Error: unexpected input, got #{signalI} but expecting #{input}."
    #             $success = false
    #         end
    #     end
    # end
    puts "  Inputs... "
    $systemT0.each_input.with_index do |input,i|
        print "    Input #{i}... "
        signal = $signals[i]
        iCount += 1
        if input == signal then
            puts "Ok."
        else
            puts "Error: unexpected input, got #{input} but expecting #{signal}."
            $success = false
        end
    end
    puts "  Inputs by name... "
    $signals.each do |input|
        if /i[0-9]/.match(input.name) then
            print "    Input #{input.name}... "
            signal = $systemT0.get_input(input.name)
            if input == signal then
                puts "Ok."
            else
                puts "Error: unexpected input, got #{signal} but expecting #{input}."
                $success = false
            end
        end
    end

    # puts "  Outputs... "
    # $systemT0.each_output.with_index do |output,i|
    #     print "    Output #{i}... "
    #     signalI = $signalIs[i+iCount]
    #     oCount += 1
    #     if output == signalI then
    #         puts "Ok."
    #     else
    #         puts "Error: unexpected output, got #{output} but expecting #{signalI}."
    #         $success = false
    #     end
    # end
    # puts "  Outputs by name... "
    # $signalIs.each do |output|
    #     if /o[0-9]/.match(output.name) then
    #         print "    Output #{output.name}... "
    #         signalI = $systemT0.get_output(output.name)
    #         if output == signalI then
    #             puts "Ok."
    #         else
    #             puts "Error: unexpected output, got #{signalI} but expecting #{output}."
    #             $success = false
    #         end
    #     end
    # end
    puts "  Outputs... "
    $systemT0.each_output.with_index do |output,i|
        print "    Output #{i}... "
        signal = $signals[i+iCount]
        oCount += 1
        if output == signal then
            puts "Ok."
        else
            puts "Error: unexpected output, got #{output} but expecting #{signal}."
            $success = false
        end
    end
    puts "  Outputs by name... "
    $signals.each do |output|
        if /o[0-9]/.match(output.name) then
            print "    Output #{output.name}... "
            signal = $systemT0.get_output(output.name)
            if output == signal then
                puts "Ok."
            else
                puts "Error: unexpected output, got #{signal} but expecting #{output}."
                $success = false
            end
        end
    end

    # puts "  Inouts... "
    # $systemT0.each_inout.with_index do |inout,i|
    #     print "    Inout #{i}... "
    #     signalI = $signalIs[i+iCount+oCount]
    #     ioCount += 1
    #     if inout == signalI then
    #         puts "Ok."
    #     else
    #         puts "Error: unexpected output, got #{inout} but expecting #{signalI}."
    #         $success = false
    #     end
    # end
    # puts "  Inouts by name... "
    # $signalIs.each do |inout|
    #     if /io/.match(inout.name) then
    #         print "    Inout #{inout.name}... "
    #         signalI = $systemT0.get_inout(inout.name)
    #         if inout == signalI then
    #             puts "Ok."
    #         else
    #             puts "Error: unexpected inout, got #{signalI} but expecting #{inout}."
    #             $success = false
    #         end
    #     end
    # end
    puts "  Inouts... "
    $systemT0.each_inout.with_index do |inout,i|
        print "    Inout #{i}... "
        signal = $signals[i+iCount+oCount]
        ioCount += 1
        if inout == signal then
            puts "Ok."
        else
            puts "Error: unexpected output, got #{inout} but expecting #{signal}."
            $success = false
        end
    end
    puts "  Inouts by name... "
    $signals.each do |inout|
        if /io/.match(inout.name) then
            print "    Inout #{inout.name}... "
            signal = $systemT0.get_inout(inout.name)
            if inout == signal then
                puts "Ok."
            else
                puts "Error: unexpected inout, got #{signal} but expecting #{inout}."
                $success = false
            end
        end
    end

    # puts "  Inners... "
    # $systemT0.each_inner.with_index do |inner,i|
    #     print "    Inner #{i}... "
    #     signalI = $signalIs[i+iCount+oCount+ioCount]
    #     if inner == signalI then
    #         puts "Ok."
    #     else
    #         puts "Error: unexpected inner, got #{inner} but expecting #{signalI}."
    #         $success = false
    #     end
    # end
    # puts "  Inners by name... "
    # $signalIs.each do |inner|
    #     if /s[0-9]/.match(inner.name) then
    #         print "    Inner #{inner.name}... "
    #         signalI = $systemT0.get_inner(inner.name)
    #         if inner == signalI then
    #             puts "Ok."
    #         else
    #             puts "Error: unexpected inner, got #{signalI} but expecting #{inner}."
    #             $success = false
    #         end
    #     end
    # end
    puts "  Inners... "
    $systemT0.each_inner.with_index do |inner,i|
        print "    Inner #{i}... "
        signal = $signals[i+iCount+oCount+ioCount]
        if inner == signal then
            puts "Ok."
        else
            puts "Error: unexpected inner, got #{inner} but expecting #{signal}."
            $success = false
        end
    end
    puts "  Inners by name... "
    $signals.each do |inner|
        if /s[0-9]/.match(inner.name) then
            print "    Inner #{inner.name}... "
            signal = $systemT0.get_inner(inner.name)
            if inner == signal then
                puts "Ok."
            else
                puts "Error: unexpected inner, got #{signal} but expecting #{inner}."
                $success = false
            end
        end
    end

    # puts "  All signal instances... "
    # $systemT0.each_signalI.with_index do |any,i|
    #     print "    SignalI #{i}... "
    #     signalI = $signalIs[i]
    #     if any == signalI then
    #         puts "Ok."
    #     else
    #         puts "Error: unexpected signalI, got #{any} but expecting #{signalI}."
    #         $success = false
    #     end
    # end
    # puts "  All signal instances by name... "
    # $signalIs.each do |signal|
    #     print "    SignalI #{signal.name}... "
    #     signalI = $systemT0.get_signalI(signal.name)
    #     if signal == signalI then
    #         puts "Ok."
    #     else
    #         puts "Error: unexpected signalI, got #{signalI} but expecting #{signal}."
    #         $success = false
    #     end
    # end
    puts "  All signal instances... "
    $systemT0.each_signal.with_index do |any,i|
        print "    SignalI #{i}... "
        signal = $signals[i]
        if any == signal then
            puts "Ok."
        else
            puts "Error: unexpected signal, got #{any} but expecting #{signal}."
            $success = false
        end
    end
    puts "  All signal instances by name... "
    $signals.each do |signal|
        print "    Signal #{signal.name}... "
        signal = $systemT0.get_signal(signal.name)
        if signal == signal then
            puts "Ok."
        else
            puts "Error: unexpected signal, got #{signal} but expecting #{signal}."
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
    puts "  System instances by name... "
    $systemIs[1..-1].each do |system|
        print "    SystemI #{system.name}... "
        systemI = $systemT0.get_systemI(system.name)
        if system == systemI then
            puts "Ok."
        else
            puts "Error: unexpected systemI, got #{systemI} but expecting #{system}."
            $success = false
        end
    end

    puts "  Connections... "
    $systemT0.each_connection.with_index do |connection,i|
        print "    Connection #{i}... "
        if connection == $connections[i] then
            puts "Ok."
        else
            puts "Error: unexpected systemI, got #{connection} but expecting #{$connections[i]}."
            $success = false
        end
    end
rescue Exception => e
    puts "Error: unexpected exception raised #{e.inspect}\n"
    $success = false
end


# Now testing the conversion to YAML.

print "\n\nConverting $systemT0 to a YAML string... "
begin
    $yaml_str = $systemT0.to_yaml
    puts "Ok."
rescue Exception => e
    puts "Error: unexpected exception raised #{e.inspect}\n"
    $success = false
end
puts "YAML result:", $yaml_str

print "\n\n Regenerating the objects from the YAML string... "
begin
    $systemTx = HDLRuby.from_yaml($yaml_str)[-1]
    $yaml_str2 = $systemTx.to_yaml
    puts "YAML result2:", $yaml_str2
    if ($yaml_str != $yaml_str2) then
        puts "Error: the regenerated system type is different from the original one."
        strs = $yaml_str.each_line
        $yaml_str2.each_line.with_index do |line2,i|
            line = strs.next
            if line2 != line then
                print "  line ##{i} differs.\n    Got #{line2}    But #{line}"
            end
        end
        $success = false
    end
    puts "Ok."
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
end


    

if $success then
    puts "\nSuccess."
else
    puts "\nFailure."
end


# puts YAML.dump($systemT0)
