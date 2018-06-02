require 'HDLRuby'
configure_high

#組み合わせ回路
system :led7seg do
	[3..0].input :in0
	[6..0].output :out
	[6..0].inner :out
	
	par do
		hcase(in0)
			hwhen 0 do
				out <= _b7b0111111
			end
			hwhen 1 do
				out <= _b7b0000110
			end
			hwhen 2 do
				out <= _b7b1011011
			end
			hwhen 3 do
				out <= _b7b1001111
			end
			hwhen 4 do
				out <= _b7b1100110
			end
			hwhen 5 do
				out <= _b7b1111101
			end
			hwhen 6 do
				out <= _b7b1111101
			end
			hwhen 7 do
				out <= _b7b0000111
			end
			hwhen 8 do
				out <= _b7b1111111
			end
			hwhen 9 do
				out <= _b7b1100111
			end
			helse do 
				out <= 0
			end
		
		
	end
end

led7seg :led7segI

puts led7segI.to_low.to_yaml
