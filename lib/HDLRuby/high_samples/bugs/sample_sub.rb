require 'HDLRuby'
configure_high

system :sub do

	[15..0].input :ina,:inb
	[16..0].output :result
	
	result <= ina - inb
end

sub :subI

puts subI.to_low.to_yaml