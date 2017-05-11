########################################################################
##            Program for testing the HDLRuby::Low module.            ##
########################################################################

require "HDLRuby.rb"

include HDLRuby::High


$success = true


print "Creating an empty system type... "
begin
    system :systemT0
    $systemT0 = SystemT.get(:systemT0)
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

print "\nCreating a system type including a system instance... "
begin
   system :systemT1 do
       systemT0 :my_system
   end
   $systemT1 = SystemT.get(:systemT1)
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
