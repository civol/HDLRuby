# Script for testing all the samples

for file in *.rb
do
    # Skip the samples starting by "_" (they are WIP)
    if [[ ${file:0:1} == "_" ]] ; then continue; fi
    # A sample to check
    bundle exec ruby "$file" || exit 1
done
