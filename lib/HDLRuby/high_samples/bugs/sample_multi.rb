require 'HDLRuby'
configure_high

system :deconder do
	
	[7..0].input :address
	[1..0].output :ce
	
	# bit[1..0].inner :ce
	
	ce[0]<= (address[7..0]==_b8h0)
	ce[1]<= (address[7..0]==_b8h1)
	
end

deconder :deconderI

puts deconderI.to_low.to_yaml
