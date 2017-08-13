########################################################################
##            Program for testing the HDLRuby::Low module.            ##
########################################################################

require "HDLRuby.rb"
require "HDLRuby/hruby_serializer.rb"

include HDLRuby::Low

$success = true

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
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
end


print "\nCreating a bit and a 8-bit data types... "
begin
    $bit = Type.new(:bit)
    $bit8 = TypeVector.new(:bit8,$bit,8)
    if $bit8.name != :bit8 then
        puts "Error: invalid name: got #{$bit8.name} but expecting bit8."
        $success = false
    elsif $bit8.base != $bit then
        puts "Error: invalid type: got #{$bit8.base} but expecting bit."
        $success = false
    elsif $bit8.range != (7..0) then
        puts "Error: invalid range: got #{$bit8.range} but expecting 7..0."
        $success = false
    else
        puts "Ok."
    end
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
end

puts "\nCreating signals..."
$sNames = ["i0", "i1", "i2", "i3", "i4", "i5", "i6", "i7", "clk",
           "o0", "o1", "o2", "o3", "o4", "o5", "io", "s0", "s1", "s2",
           ]
$signals = []
$sNames.each_with_index do |name,i|
    print "  SignalI #{name}... "
    begin
        # SignalT directly used.
        $signals[i] = SignalI.new(name,$bit8)
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
    # rescue Exception => e
    #     puts "Error: unexpected exception raised #{e.inspect}\n"
    #     $success = false
    end
end

puts "\nAdding them to $systemT0 as input, output or inout... "
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
    # rescue Exception => e
    #     puts "Error: unexpected exception raised #{e.inspect}\n"
    #     $success = false
    end
end

print "\nCompleting $systemT1 for further use... "
begin
    $systemT1.add_input(SignalI.new("i0",$bit8))
    $systemT1.add_input(SignalI.new("i1",$bit8))
    $systemT1.add_input(SignalI.new("i2",$bit8))
    $systemT1.add_output(SignalI.new("o0",$bit8))
    $systemT1.add_output(SignalI.new("o1",$bit8))
    $systemT1.add_inout(SignalI.new("io",$bit8))
    puts "Ok."
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
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
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
end
$systemIs = [ $systemI0, $systemI1, $systemI2 ]

puts "\nAdding systems instances to $systemT0... "
begin
    print "  Adding $systemI1... "
    $systemT0.add_systemI($systemI1)
    print "Ok.\n  Adding $systemI2... "
    $systemT0.add_systemI($systemI2)
    puts "Ok."
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
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
    # rescue Exception => e
    #     puts "Error: unexpected exception raised #{e.inspect}\n"
    #     $success = false
    end
end

puts "\nCreating reference-only connections..."
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
    # rescue Exception => e
    #     puts "Error: unexpected exception raised #{e.inspect}\n"
    #     $success = false
    end    
end


puts "\nCreating expressions... "
eNames = [ "i4+i5", "i4&i5", "i6-i7", "i6|i7", "i4+2", "i5&7"]

# Generate an expression from a signal or constant name
def eName2Exp(name)
    # puts "eName2Exp with name=#{name}"
    ref = $refs.find do |ref|
        if ref.ref.respond_to?(:name) then
            ref.ref.name == name.to_sym
        else
            ref.name == name.to_sym
        end
    end
    # puts "ref=#{ref}"
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
        # puts "left=#{left}"
        operator = eName[2].to_sym
        # puts "operator=#{operator}"
        right = eName2Exp(eName[3..-1])
        # puts "right=#{right}"
        expression = Binary.new(operator,left,right)
        $expressions << expression
        success = true
        unless expression.left == left then
            puts "Error: invalid left value, got #{expression.left} but expecting #{left}."
            success = false
        end
        unless expression.right == right then
            puts "Error: invalid right value, got #{expression.right} but expecting #{right}."
            success = false
        end
        unless expression.operator == operator then
            puts "Error: invalid operator, got #{expression.operator} but expecting #{operator}."
            success = false
        end
        all_refs = expression.each_ref_deep.to_a
        # puts "all_refs=#{all_refs}"
        unless all_refs[0] == expression.left then
            puts "Error: invalid first result for each_ref_deep, got #{all_refs[0]} but expecting #{expression.left}."
            success = false
        end
        if expression.right.is_a?(HDLRuby::Base::Ref) then
            unless all_refs[1] == expression.right then
                puts "Error: invalid second result for each_ref_deep, got #{all_refs[1]} but expecting #{expression.right}."
                success = false
            end
        else
            if all_refs.size > 1 then
                puts "Error: too many signals for each_ref_deep, got #{all_refs.size} but expecting 1."
                success = false
            end
        end
        if success then
            unless all_refs.size < 3 then
                puts "Error: too many signals for each_ref_deep, got #{all_refs.size} but expecting 2."
                sucess = false
            end
        end
        if success then
            puts "Ok."
        else
            $success = false
        end
        # Remove the parents for reusing the references (just for test purpose)
        all_refs.each {|ref| ref.parent = nil }
    # rescue Exception => e
    #     puts "Error: unexpected exception raised #{e.inspect}\n"
    #     $success = false
    end
end


print "\nCreating an expression connection... "
begin
    
    ref = $refs[$pNames.index("p0o2")]
    connection = Connection.new(ref,$expressions[0])
    $connections << connection
    puts "Ok."
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
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
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
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
    # rescue Exception => e
    #     puts "Error: unexpected exception raised #{e.inspect}\n"
    #     $success = false
    end
end


print "\nCreating a clock event... "
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
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
end


print "\nCreating a block... "
begin
    $block = Block.new(:seq)
    if $block.mode != :seq then
        puts "Error: invalid block mode, got #{$block.type} but expecting :seq."
        $success = false
    else
        puts "Ok."
    end
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
end

puts "\nAdding statements to $block... "
$statements[0...$statements.size/2].each.with_index do |statement,i|
    begin
        print "  For statement #{i}... "
        $block.add_statement(statement)
        puts "Ok."
    # rescue Exception => e
    #     puts "Error: unexpected exception raised #{e.inspect}\n"
    #     $success = false
    end
end
puts "Checking the added statements... "
$statements[0...$statements.size/2].each.with_index do |statement,i|
    begin
        print "  For statement #{i}... "
        bStatement = $block.each_statement.to_a[i]
        if bStatement != statement then
            puts "Error: invalid statement, got #{bStatement} but expecting #{statement}."
            $success = false
        else
            puts "Ok."
        end
    # rescue Exception => e
    #     puts "Error: unexpected exception raised #{e.inspect}\n"
    #     $success = false
    end
end

print "\nCreating $blockIn, another block... "
begin
    $blockIn = Block.new(:par)
    if $blockIn.mode != :par then
        puts "Error: invalid block mode, got #{$blockIn.type} but expecting :par."
        $success = false
    else
        puts "Ok."
    end
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
end

puts "\nAdding statements to $blockIn... "
$statements[$statements.size/2..-1].each.with_index do |statement,i|
    begin
        print "  For statement #{i+$statements.size/2}... "
        $blockIn.add_statement(statement)
        puts "Ok."
    # rescue Exception => e
    #     puts "Error: unexpected exception raised #{e.inspect}\n"
    #     $success = false
    end
end

puts "\nAdding $blockIn to $block as a statement..."
$block.add_statement($blockIn)

puts "Checking the added statements deeply... "
$statements.each.with_index do |statement,i|
    begin
        print "  For statement #{i}... "
        bStatement = $block.each_statement_deep.to_a[i]
        if bStatement != statement then
            puts "Error: invalid statement, got #{bStatement} but expecting #{statement}."
            $success = false
        else
            puts "Ok."
        end
    # rescue Exception => e
    #     puts "Error: unexpected exception raised #{e.inspect}\n"
    #     $success = false
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
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
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
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
end


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
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
end

#################################################################
# Final global test.

puts "\nTesting the content of $systemT0... "
begin
    iCount = 0  # Input signal instances counter
    oCount = 0  # Output signal instances counter
    ioCount = 0 # Inout signal instances counter
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

    puts "  All signals... "
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
        print "    SignalI #{signal.name}... "
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

    print "  All signals including system instance signal ones... "
    signals_deep = $systemT0.each_signal_deep.to_a
    exp_signals = $systemT0.each_signal.to_a + $systemI1.each_signal.to_a +
                  $systemI2.each_signal.to_a
    signals_deep.sort_by! { |signal| signal.to_s }
    exp_signals.sort_by! { |signal| signal.to_s }
    if signals_deep == exp_signals then
        puts "Ok."
    else
        puts "Error: did not get the right signals with :each_signal_deep."
        $success = false
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

    # puts $systemT0.each_signal.to_a.size

    puts "  Reference path... "
    $systemT0.each_connection.with_index do |connection,i|
        unless connection.right.is_a?(HDLRuby::Base::Ref) then
            # Skip connections to expression since they are not defined through
            # $cNames
            next
        end
        # Get the path.
        path = connection.left.path_each
        print "    left path[#{i}]=#{path.to_a}... "
        signal_p = $systemT0.get_signal(path)
        # And test from the refernce directly (must be identical).
        signal_r = $systemT0.get_signal(connection.left)
        print "signal #{signal_p.name}... "
        exp_left_str = $cNames.keys[i]
        case exp_left_str[1]
        when "0" then
            exp_left = $systemT0.get_signal(exp_left_str[2..-1])
        when "1" then
            exp_left = $systemI1.systemT.get_signal(exp_left_str[2..-1])
        when "2" then
            exp_left = $systemI2.systemT.get_signal(exp_left_str[2..-1])
        else
            raise "Test-internal error: could not find signal for #{exp_left_str}."
        end
        success = true
        if exp_left != signal_p then
            puts "Error: invalid signal from path #{path}, got #{signal_p.name} but expecting #{exp_left.name}."
            success = false
        end
        if exp_left != signal_r then
            puts "Error: invalid signal from reference #{path}, got #{signal_r.name} but expecting #{exp_left.name}."
            success = false
        end
        if success then
            puts "Ok."
        else
            $success = false
        end
    end
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
end


# Now testing the conversion to YAML.

print "\n\nConverting $systemT0 to a YAML string... "
begin
    $yaml_str = $systemT0.to_yaml
    puts "Ok."
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
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

# Checking low samples
print "Testing the low sample adder.yaml... "
$adder_str = File.read("./low_samples/adder.yaml")
$adder = HDLRuby.from_yaml($adder_str)[-1]
unless $adder.is_a?(SystemT) then
    puts "Error: invalid class for a system: #{$adder.class}"
    $success = false
end
$adder_inputs = $adder.each_input.to_a
unless $adder_inputs.size == 2 then
    puts "Error: invalid number of inputs, expecting 2 but got: #{$adder_inputs.size}"
    $success = false
end
unless $adder_inputs[0].name == :x then
    puts "Error: invalid name for first input, expecting x but got: #{$adder_inputs[0].name}"
    $success = false
end
unless $adder_inputs[0].type.is_a?(TypeVector) then
    puts "Error: invalid type for first input, expecting TypeVector but got: #{$adder_inputs[0].type.class}"
    $success = false
end
unless $adder_inputs[1].name == :y then
    puts "Error: invalid name for second input, expecting y but got: #{$adder_inputs[1].name}"
    $success = false
end
unless $adder_inputs[1].type.is_a?(TypeVector) then
    puts "Error: invalid type for first input, expecting TypeVector but got: #{$adder_inputs[1].type.class}"
    $success = false
end

puts "Ok." if $success


    

if $success then
    puts "\nSuccess."
else
    puts "\nFailure."
end


# puts YAML.dump($systemT0)
