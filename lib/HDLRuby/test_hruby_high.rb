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
rescue Exception => e
    puts "Error: unexpected exception raised #{e.inspect}\n"
    $success = false
end


    

if $success then
    puts "\nSuccess."
else
    puts "\nFailure."
end
