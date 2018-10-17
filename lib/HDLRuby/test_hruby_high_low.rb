require 'HDLRuby'

configure_high

# Program for testing both HDLRuby::High and HDLRuby::Low


print "Checking creation of an HDLRuby::High system... "
# Create a HDLRuby::High testing system
system :high_test do
    input :clk, :cond
    [15..0].input :x,:y,:z
    [16..0].output :s,:u

    seq(clk.posedge) do
        hif(cond) { s <= x+y }
        u <= x+y+z
    end
end

puts "Ok."

print "Checking its instantiation... "
# Instantiate it for checking.
high_test :high

puts "Ok."

print "Checking its converion to low... "
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
        statement.clone
        puts "Ok."
    end
end

