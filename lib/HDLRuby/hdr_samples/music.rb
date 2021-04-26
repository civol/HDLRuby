# require "std/fixpoint.rb"
# require_relative "activation_function.rb"
require 'std/function_generator.rb'

include HDLRuby::High::Std

system :music do

   input :clk, :rst
   [24].output :sound 
   
   # func_sin = proc { |i| Math.sin(i) }
   # More efficient:
   func_sin = Math.method(:sin)

   # bit[8,8].inner :time
   # signed[2,22].inner :sin_val0
   # signed[2,22].inner :sin_val1
   bit[8].inner :time
   signed[24].inner :sin_val0
   signed[24].inner :sin_val1

   # activation_function(func_sin,signed[2,22],8,8,16).(:func_sin0_generator).(time,sin_val0)
   # activation_function(func_sin,signed[2,22],8,8,16).(:func_sin1_generator).(time/2,sin_val1)
   function_generator(func_sin,bit[8],signed[24],4,-Math::PI..Math::PI,-2..2).(:func_sin0_generator).(time,sin_val0)
   function_generator(func_sin,bit[8],signed[24],4,-Math::PI*2..Math::PI*2,-2..2).(:func_sin1_generator).(time/2,sin_val1)

   # signed[2,22].inner :sound0
   signed[48].inner :sound0

   sound0 <= sin_val0.as(signed[24]) * sin_val1

   sound <= sound0[47..24]

   par(clk.posedge) do
      hif(rst) { time <= 0 }
      helse do
        # time <= time + _0000000000000001
        time <= time + _00000001
      end
   end

end




system :music_test do

    inner :clk,:rst
    [24].inner :sound

    music(:my_music).(clk,rst,sound)

    timed do
        clk <= 0
        rst <= 0
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        rst <= 1
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        rst <= 0
        256.times do
            !10.ns
            clk <= 1
            !10.ns
            clk <= 0
        end
    end
end
