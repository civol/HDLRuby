########################################################################
##            Program for testing the HDLRuby::Low module.            ##
########################################################################

require "HDLRuby.rb"

include HDLRuby::High


$success = true


print "Creating an empty system type... "
begin
    $systemT0 = system :systemT0 
    unless $systemT0 then
        raise "Error: created system type not found."
        $success =false
    end
    if $systemT0.name != :systemT0 then
        raise "Error: invalid system type name, got #{$systemT0.name} but expecting systemT0."
        $success = false
    end
    puts "Ok."
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
end

print "Instantiate it... "
begin
    $systemI0 = $systemT0.instantiate("systemI0")
    puts "Ok."
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
end

print "Creating the unsigned char type (bit[8])... "
begin
    $uchar = type(:uchar) { bit[8] }
    puts "Ok."
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
end

print "Converting systemT0 to a type... "
begin
    $sigT0 = type(:sigT0) { $systemT0.to_type([],[]) }
    puts "Ok."
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
end


print "\nCreating a system type with content (also using the created char type)... "
begin
   $systemT1 = system :systemT1 do |x,y,z|
       bit.input :clk
       systemT0 :my_system
       input :i0, :i1
       output :o0
       uchar.input :i2, :i3
       bit[7..0].output :o1
       {header: bit[4], data: bit[28]}.inner :frame
       union(int: signed[32], uint: bit[32]).inout :value
       sigT0.inner :my_sig

       o0 <= i0 + i1     # Standard connection
       x <= y + z        # Connection of generic parameters
       +:a <= +:b + +:c  # Connection of auto signals

       behavior(i0.posedge) do
           o1 <= i0 * i1
           seq do
               value.int[7..0] <= i2 + i3
           end
           hif i3 > i2 do
               value.int[15..8] <= i3
           end
           helse do
               value.int[15..8] <= i2
           end
       end

       timed do
           clk <= 0
           !10.ns
           clk <= 1
           !10.ns
           clk <= 0
           repeat(1000.ns) do
               !10.ns
               clk <= 1
               !10.ns
               clk <= 0
           end
       end
   end
   unless $systemT1 then
       raise "Error: created system type not found."
       $success =false
   end
   if $systemT1.name != :systemT1 then
       raise "Error: invalid system type name, got #{$systemT0.name} but expecting systemT0."
       $success = false
   end
   puts "Ok."
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
end

print "Instantiate it... "
begin
    $systemI1 = $systemT1.instantiate("systemI1",Signal.new(:"",$uchar,:inner),Signal.new(:"",$uchar,:inner),Signal.new(:"",$uchar,:inner))
    systemI1Is = $systemI1.each_systemI.to_a
    success = true
    if systemI1Is.size != 1 then
        puts "Error: invalid number of inner system instances, got #{systemI1Is.size} but expecting 1."
        success = false
    elsif systemI1Is[0].name != :my_system then
        puts "Error: invalid inner system instance, got #{systemI1Is[0].name} but expecting my_system."
        success = false
    end
    systemI1Ins = $systemI1.each_input.to_a
    if systemI1Ins.size != 5 then
        puts "Error: invalid number of input signals, got #{systemI1Ins.size} but expecting 5."
        success = false
    elsif systemI1Ins[0].name != :clk then
        puts "Error: invalid input signal, got #{systemI1Ins[0].name} but expecting clk."
        success = false
    elsif systemI1Ins[0].type.name != :bit then
        puts "Error: invalid type for clk, got #{systemI1Ins[0].type.name} but expecting clk."
        success = false
    elsif systemI1Ins[1].name != :i0 then
        puts "Error: invalid input signal, got #{systemI1Ins[0].name} but expecting i0."
        success = false
    elsif systemI1Ins[1].type.name != :void then
        puts "Error: invalid type for i0, got #{systemI1Ins[0].type.name} but expecting void."
        success = false
    elsif systemI1Ins[2].name != :i1 then
        puts "Error: invalid input signal, got #{systemI1Ins[1].name} but expecting i1."
        success = false
    elsif systemI1Ins[3].name != :i2 then
        puts "Error: invalid input signal, got #{systemI1Ins[2].name} but expecting i2."
        success = false
    elsif !systemI1Ins[3].type.is_a?(TypeVector) then
        puts "Error: invalid type for i2, got #{systemI1Ins[0].type.class} but expecting TypeVector."
        success = false
    elsif systemI1Ins[3].type.base.name != :bit then
        puts "Error: invalid base type for i2, got #{systemI1Ins[2].type.base.name} but expecting bit."
        success = false
    elsif systemI1Ins[3].type.range != (7..0) then
        puts "Error: invalid type range for i2, got #{systemI1Ins[2].type.range} but expecting 7..0."
        success = false
    elsif systemI1Ins[4].name != :i3 then
        puts "Error: invalid input signal, got #{systemI1Ins[3].name} but expecting i3."
        success = false
    end

    systemI1Outs = $systemI1.each_output.to_a
    if systemI1Outs.size != 2 then
        puts "Error: invalid number of output signals, got #{systemI1Outs.size} but expecting 2."
        success = false
    elsif systemI1Outs[0].name != :o0 then
        puts "Error: invalid output signal, got #{systemI1Outs[0].name} but expecting o0."
        success = false
    elsif systemI1Outs[1].name != :o1 then
        puts "Error: invalid output signal, got #{systemI1Outs[1].name} but expecting o1."
        success = false
    end

    systemI1Inners = $systemI1.each_inner.to_a
    if systemI1Inners.size != 2 then
        puts "Error: invalid number of inner signals, got #{systemI1Inners.size} but expecting 2."
        success = false
    elsif systemI1Inners[0].name != :frame then
        puts "Error: invalid inner signal, got #{systemI1Inners[0].name} but expecting frame."
        success = false
    elsif !systemI1Inners[0].type.is_a?(TypeStruct) then
        puts "Error: invalid inner type, got #{systemI1Inners[0].type.class} but expecting TypeStruct."
        success = false
    elsif !systemI1Inners[0].type.get_type(:header).is_a?(TypeVector) then
        puts "Error: invalid inner type record for header, got #{systemI1Inners[0].type.get_type(:header).class} but expecting TypeVector."
        success = false
    elsif !systemI1Inners[0].type.get_type(:data).is_a?(TypeVector) then
        puts "Error: invalid inner type record for data, got #{systemI1Inners[0].type.get_type(:data).class} but expecting TypeVector."
        success = false
    elsif systemI1Inners[1].name != :my_sig then
        puts "Error: invalid inner signal, got #{systemI1Inners[1].name} but expecting my_sig."
        success = false
    elsif !systemI1Inners[1].type.is_a?(TypeSystemI) then
        puts "Error: invalid inner type, got #{systemI1Inners[1].type.class} but expecting TypeSystem."
        success = false
    end

    systemI1Inouts = $systemI1.each_inout.to_a
    if systemI1Inouts.size != 1 then
        puts "Error: invalid number of inout signals, got #{systemI1Inouts.size} but expecting 1."
        success = false
    elsif systemI1Inouts[0].name != :value then
        puts "Error: invalid inout signal, got #{systemI1Inouts[0].name} but expecting value."
        success = false
    elsif !systemI1Inouts[0].type.is_a?(TypeUnion) then
        puts "Error: invalid inout type, got #{systemI1Inouts[0].type.class} but expecting TypeUnion."
        success = false
    elsif !systemI1Inouts[0].type.get_type(:uint).is_a?(TypeVector) then
        puts "Error: invalid inout type record for uint, got #{systemI1Inouts[0].type.get_type(:header).class} but expecting TypeVector."
        success = false
    elsif !systemI1Inouts[0].type.get_type(:int).is_a?(TypeVector) then
        puts "Error: invalid inout type record for int, got #{systemI1Inouts[0].type.get_type(:data).class} but expecting TypeVector."
        success = false
    end

    systemI1Connections = $systemI1.each_connection.to_a
    if systemI1Connections.size != 3 then
        puts "Error: invalid number of connections, got #{systemI1Connections.size} but expecting 3."
        success = false
    elsif systemI1Connections[0].left.name != :o0 then
        puts "Error: invalid left for connection, got #{systemI1Connections[0].left.name} but expecting o0."
        success = false
    elsif systemI1Connections[0].right.operator != :+ then
        puts "Error: invalid right operator for connection, got #{systemI1Connections[0].right.operator} but expecting +."
        success = false
    elsif systemI1Connections[0].right.left.name != :i0 then
        puts "Error: invalid right left for connection, got #{systemI1Connections[0].right.left.name} but expecting i0."
        success = false
    elsif systemI1Connections[0].right.right.name != :i1 then
        puts "Error: invalid right right for connection, got #{systemI1Connections[0].right.right.name} but expecting i1."
        success = false
    end

    systemI1Behaviors = $systemI1.each_behavior.to_a
    if systemI1Behaviors.size != 2 then
        puts "Error: invalid number of behaviors, got #{systemI1Behaviors.size} but expecting 2."
        success = false
    end
    systemI1Behavior = systemI1Behaviors[0]
    systemI1Events = systemI1Behavior.each_event.to_a
    if systemI1Events.size != 1 then
        puts "Error: invalid number of events, got #{systemI1Events.size} but expecting 1."
        success = false
    elsif systemI1Events[0].type != :posedge then
        puts "Error: invalid type of event, got #{systemI1Events[0].type} but expecting posedge."
    elsif systemI1Events[0].ref.name != :i0 then
        puts "Error: invalid event reference, got #{systemI1Events[0].ref.name} but expecting i0."
    end
    systemI1Blocks = systemI1Behavior.each_block.to_a
    if systemI1Blocks.size != 1 then
        puts "Error: invalid number of blocks, got #{systemI1Blocks.size} but expecting 1."
        success = false
    end
    systemI1Block = systemI1Blocks[0]
    if systemI1Block.type != :par then
        puts "Error: invalid block type, got #{systemI1Block.type} but expecting par."
        success = false
    end
    systemI1Statements = systemI1Block.each_statement.to_a
    if systemI1Statements.size != 3 then
        puts "Error: invalid number of statements, got #{systemI1Statements.size} but expecting 2."
        success = false
    elsif !systemI1Statements[0].is_a?(Transmit) then
        puts "Error: invalid first statement, got #{systemI1Statements[0].class} but expecting Transmit."
        success = false
    elsif systemI1Statements[0].left.name != :o1 then
        puts "Error: invalid first statement left, got #{systemI1Statements[0].left.name} but expecting o1."
        success = false
    elsif systemI1Statements[0].right.operator != :* then
        puts "Error: invalid first statement right operator, got #{systemI1Statements[0].right.operator} but expecting *."
        success = false
    elsif systemI1Statements[0].right.left.name != :i0 then
        puts "Error: invalid first statement right left, got #{systemI1Statements[0].right.left.name} but expecting i0."
        success = false
    elsif systemI1Statements[0].right.right.name != :i1 then
        puts "Error: invalid first statement right right, got #{systemI1Statements[0].right.left.name} but expecting i1."
        success = false
    elsif !systemI1Statements[2].is_a?(If) then
        puts "Error: invalid third statement, got #{systemI1Statements[2].class} but expecting If."
        success = false
    elsif systemI1Statements[2].condition.operator != :> then
        puts "Error: invalid third statement condition operator, got #{systemI1Statements[2].operator} but expecting <."
        success = false
    elsif !systemI1Statements[2].yes.is_a?(Block) then
        puts "Error: invalid third statement yes, got #{systemI1Statements[2].yes.class} but expecting Block."
        success = false
    elsif !systemI1Statements[2].no.is_a?(Block) then
        puts "Error: invalid third statement no, got #{systemI1Statements[2].no.class} but expecting Block."
        success = false
    end
    systemI1Seq = systemI1Statements[1]
    if !systemI1Seq.is_a?(Block) then
        puts "Error: invalid second statement, got #{systemI1Seq.class} but expecting Block."
        success = false
    elsif systemI1Seq.type != :seq then
        puts "Error: invalid type of block, got #{systemI1Seq.type} but expecting seq."
        success = false
    end
    systemI1SeqStatements = systemI1Seq.each_statement.to_a
    if systemI1SeqStatements.size != 1 then
        puts "Error: invalid number of statements, got #{systemI1Statements.size} but expecting 1."
        success = false
    elsif !systemI1SeqStatements[0].is_a?(Transmit) then
        puts "Error: invalid first statement, got #{systemI1SeqStatements[0].class} but expecting Transmit."
        success = false
    elsif systemI1SeqStatements[0].right.operator != :+ then
        puts "Error: invalid first statement right operator, got #{systemI1SeqStatements[0].right.operator} but expecting +."
        success = false
    elsif !systemI1SeqStatements[0].left.is_a?(RefRange) then
        puts "Error: invalid first statement left reference, got #{systemI1SeqStatements[0].left.class} but expecting RefRange."
        success = false
    elsif systemI1SeqStatements[0].left.range != (7..0) then
        puts "Error: invalid first statement left reference range, got #{systemI1SeqStatements[0].left.range} but expecting 7..0."
        success = false
    elsif !systemI1SeqStatements[0].left.ref.is_a?(RefName) then
        puts "Error: invalid first statement left left reference, got #{systemI1SeqStatements[0].left.ref.class} but expecting RefName."
        success = false
    elsif systemI1SeqStatements[0].left.ref.name != :int then
        puts "Error: invalid first statement left left reference name, got #{systemI1SeqStatements[0].left.ref.name} but expecting int."
        success = false
    elsif systemI1SeqStatements[0].left.ref.ref.name != :value then
        puts "Error: invalid first statement left left left reference name, got #{systemI1SeqStatements[0].left.ref.ref.name} but expecting value."
        success = false
    end

    systemI1Time = systemI1Behaviors[1]
    unless systemI1Time.is_a?(Base::TimeBehavior) then
        puts "Error: invalid behavior class: got #{systemI1Time.class} but expecting TimeBehavior."
        success = false
    end
    systemI1TimeBlks = systemI1Time.each_block.to_a
    unless systemI1TimeBlks.size == 1 then
        puts "Error: invalid number of timed blocks: got #{systemI1TimeBlks.size} but expecting 1."
        success = false
    end
    systemI1TimeStms = systemI1TimeBlks[0].each_statement.to_a
    unless systemI1TimeStms.size == 6 then
        puts "Error: invalid number of timed statements: got #{systemI1TimeStms.size} but expecting 6."
        success = false
    end
    unless systemI1TimeStms[0].is_a?(Transmit) then
        puts "Error: invalid class for first timed statements: got #{systemI1TimeStms[0].class} but expecting Transmit."
        success = false
    end
    unless systemI1TimeStms[1].is_a?(TimeWait) then
        puts "Error: invalid class for second timed statements: got #{systemI1TimeStms[1].class} but expecting TimeDelay."
        success = false
    end
    unless systemI1TimeStms[1].delay.unit == :ns then
        puts "Error: invalid unit for second timed statements: got #{systemI1TimeStms[1].unit} but expecting ns."
        success = false
    end
    unless systemI1TimeStms[1].delay.value == 10 then
        puts "Error: invalid value for second timed statements: got #{systemI1TimeStms[1].value} but expecting 10."
        success = false
    end
    unless systemI1TimeStms[-1].is_a?(TimeRepeat) then
        puts "Error: invalid class for last time statement: got #{systemI1TimeStms[-1].class} but expecting TimeRepeat."
        success = false
    end
    unless systemI1TimeStms[-1].delay.value == 1000 then
        puts "Error: invalid value for second timed statements: got #{systemI1TimeStms[-1].value} but expecting 10."
        success = false
    end
    unless systemI1TimeStms[-1].statement.each_statement.to_a.size == 4 then
        puts "Error: invalid number of statements in the timed repeat: got #{systemI1TimeStms[-1].statement.each_statement.to_a.size} but expecting 4."
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

print "\nCreating a simple generic system with 2 inputs and 2 outputs... "
begin
    $systemT2 = system :systemT2 do |type|
        input :clk
        type.input :i0,:i1
        type.output :o0,:o1
    end
    puts "Ok."
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
end

print "Converting it to a type... "
begin
    $sigT2 = type(:sigT2) { $systemT2.to_type([:i0,:i1],[:o0,:o1]) }
    unless $sigT2.is_a?(TypeSystemT) then
        raise "Invalid type class: got #{$sigT2.class} but expecting TypeSystemT."
    end
    puts "Ok."
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
end

print "Using it in a new system and instantiate the result... "
begin
    $systemT3 = system :systemT3 do
        sigT2.(uchar).input :x,:y
        sigT2.(uchar).output :z
    end
    $systemI3 = $systemT3.instantiate("systemI3")
    systemI3inputs = $systemI3.each_input.to_a
    success = true
    [:i0,:i1,:o0,:o1].each do |name|
        unless systemI3inputs[0].respond_to?(name) then
            puts "Error: systemI3's input does not include #{name} sub signal."
            success = false
        end
    end
    [:i0,:i1].each do |name|
        unless systemI3inputs[0].type.left.get_type(name) then
            puts "Error: systemI3's input type's left side does not include #{name} sub type."
            success = false
        end
    end
    [:o0,:o1].each do |name|
        unless systemI3inputs[0].type.right.get_type(name) then
            puts "Error: systemI3's input type's right side does not include #{name} sub type."
            success = false
        end
    end
    if (success) then
        puts "Ok."
    else
        $success = false
    end
# rescue Exception => e
#     puts "Error: unexpected exception raised #{e.inspect}\n"
#     $success = false
end

print "\nExtending systemI3 and do a bit of meta programming... "
begin
    $systemI3.open do
        z <= x & y
        block_open do
            def hello(name)
                $hello = "Hello #{name}."
            end
        end
        par do
            hello("everybody")
        end
    end
    success = true
    unless $hello == "Hello everybody." then
        puts "Change of the block classes had no effect."
        success = false
    end
    begin
        system :fake do
            par do
                hello("no one.")
            end
        end.instantiate(:faker)
        puts "The hello method should not be in a general block class."
        success = false
    rescue Exception => e
        unless ( e.is_a?(NoMethodError) and e.message.include?("hello") ) then
            puts "Error: unexpected exception #{e.inspect}."
            success = false
        end
    end
    $systemI3Connections = $systemI3.each_connection.to_a
    unless $systemI3Connections.size == 1 then
        puts "Invalid number of connection: got #{$systemI3Connections.size} but expecting 1."
        success = false
    end
    unless $systemI3Connections[0].right.operator == :& then
        puts "Invalid operator for connection's right: got #{$systemI3Connections[0].right.operator} but expecting &."
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

if $success then
    puts "\nSuccess."
else
    puts "\nFailure."
end
