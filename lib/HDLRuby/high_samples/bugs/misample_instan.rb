require 'HDLRuby'
configure_high

#インスタンス化
system :top do
	input   :a,:b
	output  :c,:d
	andgate(:i0).( a: a, b: b, y: d )
	andgate(:i1).( c, a , b )
end

system :andgate do
	input :a,:b
	output :y
	y <= a & b
end

top :topI

puts topI.to_low.to_yaml
