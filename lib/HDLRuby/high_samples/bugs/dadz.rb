require 'HDLRuby'
configure_high

system :dadz do
	input :clk,:res
	signed[31..0].input :a
	signed[31..0].output :dadz
	signed[63..0].inner :tmp_dadz
	
	par(clk.posedge,res.posedge)do
		hif(res==_1)do
			tmp_dadz<=0
		end 
		helse do
			tmp_dadz<=(_00000001000000000000000000000000-a)*a
		end
	end
	dadz<=tmp_dadz[55..24]
end

dadz :dadzI
puts dadzI.to_low.to_yaml