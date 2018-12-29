# Simple program for testing the variable generation for HDLRuby::Low objects.
require 'pp'
require 'HDLRuby'
require 'HDLRuby/hruby_low_with_var.rb'
include HDLRuby::Low

# Read a yaml file.
hardwares = HDLRuby::from_yaml(File.read($*[0]))

# Generate the variables.
hardwares[-1].with_var!

# Displays the result
puts hardwares[-1].to_yaml
