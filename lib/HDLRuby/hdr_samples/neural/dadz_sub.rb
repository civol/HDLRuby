require "./dadz.rb"

system :dadz_sub, dadz(32, proc {|a| (_sh01000000-a)*a }) do
end
