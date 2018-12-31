# Simple program for testing the port wire generation for HDLRuby::Low instances.
require 'pp'
require 'HDLRuby'
require 'HDLRuby/hruby_low_with_port.rb'
include HDLRuby::Low

# Read a yaml file.
hardwares = HDLRuby::from_yaml(File.read($*[0]))

# Generate the variables.
hardwares[-1].with_port!

# Displays the result
puts hardwares[-1].to_yaml
