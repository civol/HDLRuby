require 'HDLRuby'

configure_high

# Program for testing both HDLRuby::High and HDLRuby::Low


print "Checking creation of an HDLRuby::High system... "
# Create a HDLRuby::High testing system
system :high_test do
    input :clk, :cond0, :cond1
    [15..0].input :x,:y,:z
    [16..0].output :s,:u,:v

    seq(clk.posedge) do
        hif(cond0) { s <= x+y }
        helsif(cond1) { u <= x+y+2 }
        helse { s <= z }
        v <= x*y*_011
    end

    [3..0].output :sig
    timed do
        !1.us
        sig <= _1010
    end
end

puts "Ok."

print "Checking its instantiation... "
# Instantiate it for checking.
high_test :high

puts "Ok."

print "Checking its conversion to low... "
# Generate the low level representation.
low = high.systemT.to_low

puts "Ok."
puts
puts "##############################"
puts "Checking HDLRuby::Low methods."
puts "##############################"
puts
puts "Checking clone."
# Try clone
low.each_behavior do |beh|
    beh.each_statement do |statement|
        print "Cloning statement: #{statement}... "
        copy = statement.clone
        if copy.class == statement.class then
            puts "Ok."
        else
            puts "Invalid clone result: #{statement.class}"
        end
    end
end

