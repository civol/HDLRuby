#!/usr/bin/ruby

require 'fileutils'


##
# Front-end to the Alliance tool chain for hdrcc vhdl results
##############################################################

if $*.include?("--clean") then
    # Clean mode.
    `rm *.vbe *.vst *.xsc *.ap`
    exit
end

######################################################
# Initialization phase
#
# Process the options.
# For now there should only be the name of the main file.
$input = $*[0]

# Get the extension name, the base name and the path from the main file.
$extname  = File.extname($input)
$basename = File.basename($input,$extname)
$path     = File.dirname($input)
$fullname = $basename + $extname

# Go the the target directory.
Dir.chdir($path)

# Gather the files other than the main to treat.
$subfiles = Dir.foreach("./").select do |name|
    File.extname(name) == $extname && name != $fullname
end
# And the all files to treat.
$allfiles = [$fullname] + $subfiles

# Generate the base names for the sub files.
# $subbases = $subfiles.map {|file|  File.basename(file,$extname) }
# $basename_model = $basename + "_model"
# $subbases =[ $basename_model ] + $subbases
$allbases = $allfiles.map {|file|  File.basename(file,$extname) }

######################################################
# Compiling steps

# Conversion to alliance format.
$allfiles.each do |file|
    cmd = "vasy -Vaop -I vhd #{file}"
    puts cmd
    `#{cmd}`
end

# # Check if there is a model have been generated.
# unless File.file?($basename_model + ".vbe") then
#     # No model, single file case.
#     $subbases = [ $basename ]
# end

# puts "$subbases=#{$subbases}"

# Boolean minimisation.
# $subbases.each do |base|
$allbases.each do |base|
    if File.file?("#{base}.vbe") then
        cmd = "boom -l 3 -d 50 #{base}.vbe"
        puts cmd
        `#{cmd}`
    end
    if File.file?("#{base}_model.vbe") then
        cmd = "boom -l 3 -d 50 #{base}_model.vbe"
        puts cmd
        `#{cmd}`
    end
end

# Structureal description generation.
# $subbases.each do |base|
$allbases.each do |base|
    if File.file?("#{base}.vbe") then
        cmd = "boog #{base}_o #{base} -x 1 -m 2"
        puts cmd
        `#{cmd}`
    end
    if File.file?("#{base}_model.vbe") then
        cmd = "boog #{base}_model_o #{base}_model -x 1 -m 2"
        puts cmd
        `#{cmd}`
    end
end

# Flattening and global optimization.
cmd = "loon #{$basename} #{$basename}_l -x 0 -m 0"
puts cmd
`#{cmd}`

# Placement.
cmd = "ocp #{$basename}_l #{$basename}_p"
puts cmd
`#{cmd}`

# Route.
cmd = "nero -V -G -6 -p #{$basename}_p #{$basename}_l #{$basename}_r"
puts cmd
`#{cmd}`

# Technology mapping.
cmd = "s2r -v #{$basename}_r #{$basename}_core"
puts cmd
`#{cmd}`


## Other tools
#  
#  Simulation:
#  `asimut #{$basename}_l #{$basename}_in #{$basename}_out`
#
#  View simulation result:
#  `xpat -l #{basename}_out`
#
#  View P&R result:
#  `graal`
#
#  Extract netlist:
#  `cougar #{$basename}_r #{$basename}_c`
#
#  Check P&R result:
#  `lvx vst al #{$basename} #{$basename}_c` or
#  `lvx vst vst #{$basename} #{$basename}_c`
#
#  DRC check:
#  `druc #{$basename}_r`
#
#  View techno mapping result:
#  `dreal -l #{$basename}_core`
#
