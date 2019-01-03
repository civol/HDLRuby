# Simple program for testing the variable generation for HDLRuby::Low objects.
require 'HDLRuby'
require 'HDLRuby/hruby_low2vhd'
require 'HDLRuby/hruby_low_without_namespace'
require 'HDLRuby/hruby_low_with_port'
require 'HDLRuby/hruby_low_with_var'
include HDLRuby::Low

# Read a yaml file.
hardwares = HDLRuby::from_yaml(File.read($*[0]))
hardware = hardwares[-1]

# Generate the corresponding VHDL code.
hardware.to_upper_space!
hardware.with_port!
hardware.with_var!
puts hardware.to_vhdl
