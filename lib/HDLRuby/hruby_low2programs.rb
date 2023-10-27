require 'HDLRuby'
require 'HDLRuby/hruby_low_with_bool'
require 'HDLRuby/hruby_low_without_namespace'
require 'HDLRuby/hruby_low_with_var'


module HDLRuby::Low


##
# Converts a HDLRuby::Low description to descriptions of software programs.
#
########################################################################

    ## Provides tools for extracting software from HDLRuby description.
    module Low2Programs

        class SystemT
            ## Extends the SystemT class with extraction of software.

            # Extract the information about the software in the system and put it
            # into +target+ directory.
            def extract_programs(target)
                # Gather the programs descriptions.
                programs = self.scope.each_scope_deep.map do |scope|
                    scope.each_program.to_a
                end
                programs.flatten!
                # Sort the programs by language.
                lang2prog = Hash.new([])
                programs.each { |prog| lang2prog[prog.language] << prog }
                # Copy the programs in the corresponding subdirectories.
                lang2prog.each do |lang,progs|
                    dir = target + "/" + lang
                    Dir.mkdir(dir)
                    progs.each do |prog|
                        prog.each_code  { |code| FileUtils.cp(code,dir) }
                    end
                end
            end
        end


        class Scope
        end

    end
