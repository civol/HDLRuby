require 'HDLRuby'

configure_high

# Tests the inclusion of other files.

require "./adder.rb"


# Two parallel adders
system :adder16_2 do
    [15..0].input :x0,:y0,:x1,:y1
    [16..0].output :s0,:s1

    adder(:adder0).(x0,y0,s0)
    
    adder(:adder1).(x1,y1,s1)
end

# Instantiate it for checking.
adder16_2 :adder16_2I

# Generate the low level representation.
low = adder16_2I.systemT.to_low

# Displays it
puts low.to_yaml
