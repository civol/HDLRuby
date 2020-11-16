#!/usr/bin/ruby
# Script for generating the vcd files.

# The configuration scenarii
$scenarii = [
              [:_clk2_clk2,      :register],    #  0
              [:_clk2_nclk2,     :register],    #  1
              [:_clk2_clk3,      :register],    #  2
              [:_clk3_clk2,      :register],    #  3
              [:_clk2_clk2,      :handshake],   #  4
              [:_clk2_nclk2,     :handshake],   #  5
              [:_clk2_clk3,      :handshake],   #  6
              [:_clk3_clk2,      :handshake],   #  7
              [:clk2_clk2_clk2,  :queue],       #  8
              [:clk2_clk2_nclk2, :queue],       #  9
              [:clk1_clk2_clk3,  :queue],       # 10
              [:clk3_clk2_clk1,  :queue],       # 11
              [:clk2_clk3_clk1,  :queue],       # 12
              [:clk2_clk1_clk3,  :queue],       # 13
            ]
$scenarii.each_with_index do |scenarii,i|
    puts "scenario: [#{i}] #{scenarii}"
    `bundle exec ../hdrcc.rb -S --vcd with_multi_channels.rb WithMultiChannelPaper #{i}`
    `mv WithMultiChannelPaper/hruby_simulator.vcd WithMultiChannelPaper/#{i.to_s.to_s.rjust(2,"0")}_#{scenarii[0]}_#{scenarii[1]}.vcd`
end
