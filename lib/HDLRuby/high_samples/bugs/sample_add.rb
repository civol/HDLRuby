require 'HDLRuby'
configure_high

# 加算　HDLRuby
system :adder do

	[15..0].input :ina,:inb
	[16..0].output :result
	
	result <=  ina + inb
end


adder :addI

puts addI.to_low.to_yaml
