require 'rubyHDL'

# Ruby program ment to eb executed within HDLRuby hardware.

def echo
    val = RubyHDL.inP
    puts "Echoing: #{val}"
    RubyHDL.outP = val    
end
