# Ruby program for testing SW HDLRuby.

require 'HDLRuby/std/sequencer_sw'

include RubyHDL::High
using RubyHDL::High

[1].inner :clk
clk.value = 0

[32].inner :a,:b,:c,:i
[32].inner :d
bit[32][-4].inner :ar
[32].inner :res0, :res1

some_ruby_value = 1


prog0 = sequencer(clk) do
  a <= 1
  b <= 2
  # c <= ruby { some_ruby_value }
  c <= ruby("some_ruby_value")
  d <= 0
  i <= 0
  # swhile(c<10000000) do
  # 10000000.stimes do
  sfor(0..10000000) do |u|
    c <= a + b + d
    d <= c + 1
    # ar[i%4] <= i
    ar[u%4] <= i
    sif(i<1000) { i <= i + 1 }
    selse { i <= 0 }
    sync
  end
  a[4] <= 1
  b[7..5] <= 5
  res0 <= ar[0]
end

puts "Generating file from prog0 source code..."
File.open("with_sw_hruby_mruby.rb","w") do |f|
  f << prog0.source
end

prog1 = sequencer do
  sloop do
    res1 <= ar[1]
    sync
  end
end

puts "Executing concurrently prog0 and prog1..."

while prog0.alive? do
  prog0.call
  prog1.call
end

puts "a=#{a}"
puts "b=#{b}"
puts "c=#{c}"
puts "d=#{d}"
puts "ar=#{ar}"
puts "ar[1]=#{ar.value[1]}"
puts "res0=#{res0}"
puts "res1=#{res1}"
puts "clk=#{clk}"
