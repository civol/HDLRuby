#!/bin/bash
# Script for testing all the samples

# Test general conversions
for file in *.yaml
do
    # Skip the samples starting by "_" (they are WIP)
    if [[ ${file:0:1} == "_" ]] ; then continue; fi
    # A sample to check
    # Load it.
    bundle exec ruby load_yaml.rb "$file" || exit 1
    # Convert it with variables.
    # This conversion allows to check clone and each_node methods.
    bundle exec ruby variable_maker.rb "$file" || exit 1
    # Convert with port wires.
    # This conversion allows to check each_block_deep methods.
    bundle exec ruby port_maker.rb "$file" || exit 1
done

# Test HDLRuby output.
for file in *.yaml
do
    # Skip the samples starting by "_" (they are WIP)
    if [[ ${file:0:1} == "_" ]] ; then continue; fi
    # A sample to check
    bundle exec ruby yaml2hdr.rb "$file" || exit 1
done

# Test he VHDL output.
for file in *.yaml
do
    # Skip the samples starting by "_" (they are WIP)
    if [[ ${file:0:1} == "_" ]] ; then continue; fi
    # Skip the vector.yaml sample since it contains a tuple not supported yet.
    if [[ $file == "vector.yaml" ]] ; then continue; fi
    # Skip the rom.yaml sample since it contains a tuple not supported yet.
    if [[ $file == "rom.yaml" ]] ; then continue; fi
    # A sample to check
    bundle exec ruby yaml2vhd.rb "$file" || exit 1
done

# Tests the cloner.
bundle exec ruby cloner.rb || exit 1
