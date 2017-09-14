# Simple program for loading a yaml description of HDLRuby::Low hardware.

require 'HDLRuby'
include HDLRuby::Low

hardwares = HDLRuby::from_yaml(File.read($*[0]))
