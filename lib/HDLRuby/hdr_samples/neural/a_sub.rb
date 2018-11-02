require "./a_gen.rb"
require "./sigmoid_gen.rb"

system :a, a_gen(8,32,proc{|addr| sigmoid_gen(8,4,32,24,addr)}) do
end
