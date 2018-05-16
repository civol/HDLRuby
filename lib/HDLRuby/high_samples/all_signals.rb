require 'HDLRuby'

configure_high


# A simple 16-bit adder
system :adder do
    [15..0].input :x,:y
    [16..0].output :s

    s <= x + y

    cur_system.open do
        puts "Inputs: ", cur_system.get_all_inputs
        puts "Outputs: ", cur_system.get_all_outputs
        puts "InOuts: ", cur_system.get_all_inouts
        puts "Signals: ", cur_system.get_all_signals
    end
end


# Instantiate it for checking.
adder :adderI
# 
# # Generate the low level representation.
# low = adderI.to_low
# 
# # Displays it
# puts low.to_yaml
