# Simple program for testing the cloning of HDLRuby::Low objects.
require 'pp'
require 'HDLRuby'
include HDLRuby::Low


# Creates a transmit statement.
left = RefIndex.new(Bit, RefName.new(Bit,RefThis.new,:s), Value.new(Bit,1) )
rleft = Unary.new(Bit, :-@, RefName.new(Bit,RefThis.new,:x) )
rright = RefName.new(Bit, RefThis.new, :y)
right = Binary.new(Bit, :+, rleft, rright)
trans = Transmit.new(left, right)

# Convert it to yaml.
expected_yaml = trans.to_yaml

# Clone it.
copy = trans.clone

# Convert it to yaml and compare with the expected yaml result.
puts "Differences:"
pp expected_yaml.split(//) - copy.to_yaml.split(//)
