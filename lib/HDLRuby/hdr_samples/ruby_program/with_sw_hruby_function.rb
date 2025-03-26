require 'HDLRuby/std/sequencer_sw'

include RubyHDL::High
using RubyHDL::High

# Sequencer for testing arithmetic computations.

sdef(:truc) do |m,n|
  sreturn(n+m*2)
end

signed[32].inner :x,:y, :result

my_seq = sequencer do
  x <= 0
  y <= 0
  100.stimes do
    x <= x + 1
    10.times do
      y <= truc(x,y)
    end
  end
  result <= y
end

puts "code=" + my_seq.source

my_seq.()

puts "result=#{result}"
