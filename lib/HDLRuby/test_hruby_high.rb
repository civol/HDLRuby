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
rescue Exception => e
    puts "Error: unexpected exception raised #{e.inspect}\n"
    $success = false
end

print "Instantiate it... "
begin
    $systemI0 = $systemT0.instantiate("systemI0")
    puts "Ok."
rescue Exception => e
    puts "Error: unexpected exception raised #{e.inspect}\n"
    $success = false
end

print "Creating the char type (bit[8])... "
begin
    type(:uchar) { bit[8] }
    puts "Ok."
rescue Exception => e
    puts "Error: unexpected exception raised #{e.inspect}\n"
    $success = false
end

print "Converting systemT0 to a type... "
begin
    type(:sigT0) { $systemT0.to_type }
    puts "Ok."
rescue Exception => e
    puts "Error: unexpected exception raised #{e.inspect}\n"
    $success = false
end


print "\nCreating a system type with content (also using the created char type)... "
begin
   $systemT1 = system :systemT1 do
       systemT0 :my_system
       input :i0, :i1
       output :o0
       uchar.input :i2, :i3
       bit[7..0].output :o1
       {header: bit[4], data: bit[28]}.inner :frame
       union(int: signed[32], uint: bit[32]).inout :value
       sigT0.inner :my_sig
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
rescue Exception => e
    puts "Error: unexpected exception raised #{e.inspect}\n"
    $success = false
end

print "Instantiate it... "
begin
    $systemI1 = $systemT1.instantiate("systemI1")
    systemI1Is = $systemI1.each_systemI.to_a
    if systemI1Is.size != 1 then
        puts "Error: invalid number of inner system instances, got #{systemI1Is.size} but expecting 1."
        $success = false
    elsif systemI1Is[0].name != :my_system then
        puts "Error: invalid inner system instance, got #{systemI1Is[0].name} but expecting my_system."
        $success = false
    end
    systemI1Ins = $systemI1.each_input.to_a
    if systemI1Ins.size != 4 then
        puts "Error: invalid number of input signals, got #{systemI1Ins.size} but expecting 4."
        $success = false
    elsif systemI1Ins[0].name != :i0 then
        puts "Error: invalid input signal, got #{systemI1Ins[0].name} but expecting i0."
        $success = false
    elsif systemI1Ins[0].type.name != :void then
        puts "Error: invalid type for i0, got #{systemI1Ins[0].type.name} but expecting void."
        $success = false
    elsif systemI1Ins[1].name != :i1 then
        puts "Error: invalid input signal, got #{systemI1Ins[1].name} but expecting i1."
        $success = false
    elsif systemI1Ins[2].name != :i2 then
        puts "Error: invalid input signal, got #{systemI1Ins[2].name} but expecting i2."
        $success = false
    elsif !systemI1Ins[2].type.is_a?(TypeVector) then
        puts "Error: invalid type for i2, got #{systemI1Ins[0].type.class} but expecting TypeVector."
        $success = false
    elsif systemI1Ins[2].type.base.name != :bit then
        puts "Error: invalid base type for i2, got #{systemI1Ins[2].type.base.name} but expecting bit."
        $success = false
    elsif systemI1Ins[2].type.range != (7..0) then
        puts "Error: invalid type range for i2, got #{systemI1Ins[2].type.range} but expecting 7..0."
        $success = false
    elsif systemI1Ins[3].name != :i3 then
        puts "Error: invalid input signal, got #{systemI1Ins[3].name} but expecting i3."
        $success = false
    end

    systemI1Outs = $systemI1.each_output.to_a
    if systemI1Outs.size != 2 then
        puts "Error: invalid number of output signals, got #{systemI1Outs.size} but expecting 2."
        $success = false
    elsif systemI1Outs[0].name != :o0 then
        puts "Error: invalid output signal, got #{systemI1Outs[0].name} but expecting o0."
        $success = false
    elsif systemI1Outs[1].name != :o1 then
        puts "Error: invalid output signal, got #{systemI1Outs[1].name} but expecting o1."
        $success = false
    end

    systemI1Inners = $systemI1.each_inner.to_a
    if systemI1Inners.size != 2 then
        puts "Error: invalid number of inner signals, got #{systemI1Inners.size} but expecting 2."
        $success = false
    elsif systemI1Inners[0].name != :frame then
        puts "Error: invalid inner signal, got #{systemI1Inners[0].name} but expecting frame."
        $success = false
    elsif !systemI1Inners[0].type.is_a?(TypeStruct) then
        puts "Error: invalid inner type, got #{systemI1Inners[0].type.class} but expecting TypeStruct."
        $success = false
    elsif !systemI1Inners[0].type.get_type(:header).is_a?(TypeVector) then
        puts "Error: invalid inner type record for header, got #{systemI1Inners[0].type.get_type(:header).class} but expecting TypeVector."
        $success = false
    elsif !systemI1Inners[0].type.get_type(:data).is_a?(TypeVector) then
        puts "Error: invalid inner type record for data, got #{systemI1Inners[0].type.get_type(:data).class} but expecting TypeVector."
        $success = false
    elsif systemI1Inners[1].name != :my_sig then
        puts "Error: invalid inner signal, got #{systemI1Inners[1].name} but expecting my_sig."
        $success = false
    elsif !systemI1Inners[1].type.is_a?(TypeSystem) then
        puts "Error: invalid inner type, got #{systemI1Inners[1].type.class} but expecting TypeSystem."
        $success = false
    elsif systemI1Inners[1].type.systemT != $systemT0 then
        puts "Error: invalid inner type's system, got #{systemI1Inners[1].type.systemT.name} but expecting systemT0."
        $success = false
    end

    systemI1Inouts = $systemI1.each_inout.to_a
    if systemI1Inouts.size != 1 then
        puts "Error: invalid number of inout signals, got #{systemI1Inouts.size} but expecting 1."
        $success = false
    elsif systemI1Inouts[0].name != :value then
        puts "Error: invalid inout signal, got #{systemI1Inouts[0].name} but expecting value."
        $success = false
    elsif !systemI1Inouts[0].type.is_a?(TypeUnion) then
        puts "Error: invalid inout type, got #{systemI1Inouts[0].type.class} but expecting TypeUnion."
        $success = false
    elsif !systemI1Inouts[0].type.get_type(:uint).is_a?(TypeVector) then
        puts "Error: invalid inout type record for uint, got #{systemI1Inouts[0].type.get_type(:header).class} but expecting TypeVector."
        $success = false
    elsif !systemI1Inouts[0].type.get_type(:int).is_a?(TypeVector) then
        puts "Error: invalid inout type record for int, got #{systemI1Inouts[0].type.get_type(:data).class} but expecting TypeVector."
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
