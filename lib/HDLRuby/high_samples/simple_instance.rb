require 'HDLRuby'

configure_high

# Simple test of instantiation.


system :io do
    input :i
    output :o

    i <= o
end

system :with_io do
    input :i
    output :o

    io(:ioI).(i: i, o: o)
end



# Instantiate it for checking.
with_io :with_ioI

# Generate the low level representation.
low = with_ioI.to_low

# Displays it
puts low.to_yaml
