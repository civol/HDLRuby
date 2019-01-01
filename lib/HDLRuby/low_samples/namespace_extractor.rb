# Simple program for testing the extraction of declares from sub namespaces.
require 'pp'
require 'HDLRuby'
require 'HDLRuby/hruby_low_without_namespace.rb'
require 'HDLRuby/hruby_low2high.rb'
include HDLRuby::Low

$hdr = $*[0] == "-hdr" ? true : false

$*.shift if $hdr

# Read a yaml file.
hardwares = HDLRuby::from_yaml(File.read($*[0]))

# Generate the variables.
hardwares[-1].to_upper_space!

# Displays the result
if $hdr then
    puts hardwares[-1].to_high
else
    puts hardwares[-1].to_yaml
end
