require "./dadz_gen.rb"

system :dadz, dadz_gen(32, proc {|a| (_sh01000000-a)*a }) do
end
