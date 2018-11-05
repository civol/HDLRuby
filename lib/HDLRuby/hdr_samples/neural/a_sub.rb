require "./a.rb"
require "./sigmoid.rb"

system :a_sub, a([32].to_type,proc{|addr| sigmoid(8,4,32,24,addr)}) do
end
