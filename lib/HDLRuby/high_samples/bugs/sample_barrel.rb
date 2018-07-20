require 'HDLRuby'
configure_high

system :barrel do
	[7..0].input :din
	[2..0].input :sft
	[7..0].output :dout
	dout<=din<<sft
end

barrel :barrelI

puts barrelI.to_low.to_yaml