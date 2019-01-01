# Simple program for testing the variable generation for HDLRuby::Low objects.
require 'HDLRuby'
require 'HDLRuby/hruby_low2high'
include HDLRuby::Low

# Read a yaml file.
hardwares = HDLRuby::from_yaml(File.read($*[0]))

# Generate the corresponding HDLruby::High code.
puts hardwares[-1].to_high
