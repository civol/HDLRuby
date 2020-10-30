#!/usr/bin/ruby
# Script for generating the vcd files.

# The configuration scenarii
$scenarii = [
              [:sync,  :register],     # 00
              [:sync,  :handshake],    # 01
              [:sync,  :queue],        # 02
              [:nsync, :register],     # 03
              [:nsync, :handshake],    # 04
              [:nsync, :queue],        # 05
              [:async, :register],     # 06
              [:async, :handshake],    # 07
              [:async, :queue],        # 08
              [:proco, :register],     # 09
              [:proco, :handshake],    # 10
              [:proco, :queue],        # 11
              [:double,:register],     # 12
              [:double,:handshake],    # 13 
              [:double,:queue]         # 14
            ]
(0..11).each do |i|
    `bundle exec ../hdrcc.rb -S --vcd with_multi_channels.rb WithMultiChannelPaper #{i}`
    `mv WithMultiChannelPaper/hruby_simulator.vcd WithMultiChannelPaper/#{i.to_s.to_s.rjust(2,"0")}_#{$scenarii[i][0]}_#{$scenarii[i][1]}.vcd`
end
