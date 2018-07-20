require 'HDLRuby'
configure_high

system :z2 do

	input :clk,:reset
	signed[31..0].input :k1,:k2
	signed[31..0].input :w2_1,:w2_2
	signed[31..0].input :b2
	signed[7..0].output :z2

	signed[63..0].inner :net1,:net2
	signed[31..0].inner :z2_tmp
	
	par(clk.posedge)do
		hif(reset==1)do	
			net1<=0
			net2<=0
			z2_tmp<=0
		end
		helse do
			net1<=k1*w2_1
			net2<=k2*w2_2
			z2_tmp<=net1[55..24]+net2[55..24] + b2
		end
	end
	
	z2<=z2_tmp[27..20]
end
z2 :z2I

puts z2I.to_low.to_yaml		