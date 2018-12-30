#!/bin/bash
# Script for testing all the samples

for file in *.yaml
do
    # Skip the samples starting by "_" (they are WIP)
    if [[ ${file:0:1} == "_" ]] ; then continue; fi
    # A sample to check
    # Load it.
    bundle exec ruby load_yaml.rb "$file" || exit 1
    # Convert it with variables.
    # This conversion allows to check clone and several each methods.
    bundle exec ruby variable_maker.rb "$file" || exit 1
done

# Tests the cloner.
bundle exec ruby cloner.rb || exit 1
