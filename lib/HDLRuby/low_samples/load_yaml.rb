# Simple program for loading a yaml description of HDLRuby::Low hardware
# and displaying it once again.

require 'HDLRuby'
include HDLRuby::Low

hardwares = HDLRuby::from_yaml(File.read($*[0]))


# Displays it
puts hardwares[-1].to_yaml
