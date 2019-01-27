require 'HDLRuby'

configure_high

require 'HDLRuby/std/decoder'
include HDLRuby::High::Std

# Implementation of a decoder.
system :my_decoder do
    [7..0].input :a
    [7..0].output :z

    decoder(a) do
        entry("1000uuvv") { z <= u + v }
        entry("101uuuvv") { z <= u - v }
        entry("1100uuvv") { z <= u & v }
        entry("1101uuvv") { z <= u | v }
        entry("1110uuvv") { z <= u ^ v }
        default           { z <= 0     }
    end
end

# Instantiate it for checking.
my_decoder :my_decoderI

# Generate the low level representation.
low = my_decoderI.systemT.to_low

# Displays it
puts low.to_yaml
