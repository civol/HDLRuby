require 'HDLRuby'
configure_high

system :updown_cnt do

	input    :ck,:res,:down
	[3..0].output  :q
	[3..0].inner  :q
	
	hif (res) do
		q<=b4h0
	end
	helsif(down) do
		q<=q-b4h1	
	end
	helse do
		q<=q+b4h1
	end
end

updown_cnt :updown_cntI
puts updown_cntI.to_low.to_yaml
