#!/usr/bin/ruby

require 'fileutils'
require 'tempfile'
require 'HDLRuby'
require 'HDLRuby/hruby_check.rb'
# require 'ripper'
require 'HDLRuby/hruby_low2hdr'
require 'HDLRuby/hruby_low2c'
require 'HDLRuby/hruby_low2vhd'
require 'HDLRuby/hruby_low_fix_types'
# require 'HDLRuby/hruby_low_expand_types' # For now dormant
require 'HDLRuby/hruby_low_without_outread'
require 'HDLRuby/hruby_low_with_bool'
require 'HDLRuby/hruby_low_bool2select'
require 'HDLRuby/hruby_low_without_select'
require 'HDLRuby/hruby_low_without_namespace'
require 'HDLRuby/hruby_low_without_bit2vector'
require 'HDLRuby/hruby_low_with_port'
require 'HDLRuby/hruby_low_with_var'
require 'HDLRuby/hruby_low_without_concat'
require 'HDLRuby/hruby_low_without_connection'
require 'HDLRuby/hruby_low_casts_without_expression'
require 'hruby_low_without_parinseq'
require 'HDLRuby/hruby_low_cleanup'

require 'HDLRuby/hruby_verilog.rb'

require 'HDLRuby/backend/hruby_allocator'
require 'HDLRuby/backend/hruby_c_allocator'

require 'HDLRuby/version.rb'

##
# HDLRuby compiler interface program
#####################################

module HDLRuby



    # Class for loading HDLRuby files.
    class HDRLoad

        # TOP_NAME = "__hdr_top_instance__"
        TOP_NAME = "__"

        # The top instance, only accessible after parsing the files.
        attr_reader :top_instance

        # The required files.
        attr_reader :requires

        # Creates a new loader for a +top_system+ system in file +top_file_name+
        # from directory +dir+ with generic parameters +params+.
        #
        # NOTE: +top_file+ can either be a file or a file name.
        def initialize(top_system,top_file,dir,*params)
            # Sets the top and the looking directory.
            @top_system = top_system.to_s
            # @top_file can either be a file or a string giving the file name.
            if top_file.respond_to?(:path) then
                @top_file = top_file
                @top_file_name = top_file.path
            else
                @top_file = nil
                @top_file_name = top_file.to_s
            end
            @dir = dir.to_s
            @params = params

            # The list of the standard library files to exclude for
            # checking.
            # Get the directory of the HDLRuby and Ruby standard libraries.
            @std_dirs = $LOAD_PATH
            # @std_dirs << File.dirname(__FILE__) + "/std"
            # # Gather the files with their path to std.
            # @std_files = Dir[@std_dir + "/*"]

            # The list of required files.
            @requires = []

            # The list of the code texts (the first one should be the one
            # containing the top system).
            @texts = []

            # The list of the code checkers.
            @checks = []

            # The name of the top instance
            @top_name = TOP_NAME
        end

        # Loads a single +file+.
        #
        # NOTE: +file+ can either be a file or a file name.
        def read(file)
            # Resolve the file.
            if file.respond_to?(:read) then
                found = file
            else
                found = File.join(@dir,file)
                unless File.exist?(found) then
                    founds = Dir.glob(@std_dirs.map do |path|
                        File.join(path,file) 
                    end)
                    if founds.empty? then
                        # No standard file with this name, this is an error.
                        raise "Unknown required file: #{file}."
                    else
                        # A standard file is found, skip it since it does not
                        # need to be read.
                        # show? "Standard files: #{founds}"
                        return false
                    end
                end
            end
            # Load the file.
            @texts << File.read(found)
            if found.respond_to?(:path) then
                @checks << Checker.new(@texts[-1],found.path)
            else
                @checks << Checker.new(@texts[-1])
            end
            return true
        end

        # Loads all the files from +file+.
        def read_all(file = nil)
            unless file then
                if @top_file then
                    file = @top_file
                else
                    file = @top_file_name
                end
            end
            # show? "read_all with file=#{file}"
            # Read the file
            # read(file)
            unless read(file) then
                # The file is to skip.
                return
            end
            # Get its required files.
            requires = @checks[-1].get_all_requires +
                       @checks[-1].get_all_require_relatives
            requires.each do |file|
                read_all(file)
            end
            @requires += requires
            @requires.uniq!
        end

        # Checks the read files.
        def check_all
            @checks.each { |check| check.assign_check }
        end

        # Displays the syntax tree of all the files.
        def show_all(outfile = $stdout)
            # show? "@checks.size=#{@checks.size}"
            @checks.each { |check| check.show(outfile) }
        end

        # Gets the (first) top system.
        def get_top
            # Get all the systems.
            systems = @checks.reduce([]) {|ar,check| ar + check.get_all_systems}
            # show? "First systems=#{systems}"
            # Remove the systems that are instantiated or included
            # (they cannot be tops)
            @checks.each do |check|
                # The instances
                check.get_all_instances(systems).each do |instance|
                    systems.delete(check.get_instance_system(instance))
                end
                # The explicitly included systems
                check.get_all_includes(systems).each do |included|
                    systems.delete(check.get_include_system(included))
                end
                # The system included when declaring (inheritance)
                check.get_all_inherits(systems).each do |inherit|
                    systems -= check.get_inherit_systems(inherit)
                end
            end
            # show? "Now systems=#{systems}"
            # Return the first top of the list.
            return systems[-1]
        end


        # Load the HDLRuby structure from an instance of the top module.
        def parse
            # Is there a top system specified yet?
            if @top_system == "" then
                # No, look for it.
                @top_system = get_top
                # show? "@top_system=#{@top_system}"
                unless @top_system then
                    # Not found? Error.
                    # Maybe it is a parse error, look for it.
                    bind = TOPLEVEL_BINDING.clone
                    eval("require 'HDLRuby'\n\nconfigure_high\n\n",bind)
                    eval(@texts[0],bind,@top_file_name,1)
                    # No parse error found.
                    raise "Cannot find a top system." unless @top_system
                end
            end
            # Initialize the environment for processing the hdr file.
            bind = TOPLEVEL_BINDING.clone
            eval("require 'HDLRuby'\n\nconfigure_high\n\n",bind)
            # Process it.
            eval(@texts[0],bind,@top_file_name,1)
            # Get the resulting instance
            if @params.empty? then
                # There is no generic parameter
                @top_instance = 
                    eval("#{@top_system} :#{@top_name}\n#{@top_name}",bind)
            else
                # There are generic parameters
                @top_instance = 
                    # eval("#{@top_system} :#{@top_name},#{@params.join(",")}\n#{@top_name}",bind)
                    eval("#{@top_system}(#{@params.join(",")}).(:#{@top_name})\n#{@top_name}",bind)
            end
        end
    end


    class HDLRuby::Low::Code
        ## Extends the Code class with generation of file for the content.

        ## Creates a file in +path+ containing the content of the code.
        def to_file(path = "")
            self.each_chunk do |chunk|
                # Process the lumps of the chunk.
                # NOTE: for now use the C code generation of Low2C
                content = chunk.to_c
                # Dump to a file.
                if chunk.name != :sim then 
                    # The chunk is to be dumbed to a file.
                    # show? "Outputing chunk:#{HDLRuby::Low::Low2C.obj_name(chunk)}"
                    outfile = File.open(path + "/" +
                                       HDLRuby::Low::Low2C.obj_name(chunk) + "." +
                                       chunk.name.to_s,"w")
                    outfile << content
                    outfile.close
                end
            end
        end
    end


end

# Locate an executable from cmd.
def which(cmd)
    # Get the possible exetensions (for windows case).
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    # Look for the command within the executable paths.
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each do |ext|
            exe = File.join(path, "#{cmd}#{ext}")
            return exe if File.executable?(exe) && !File.directory?(exe)
        end
    end
    nil
end



if __FILE__ == $0 then
    # From hdrcc.rb
    $hdr_dir = File.dirname(__FILE__)
else
    # Form hdrcc
    $hdr_dir = File.dirname(Gem.bin_path("HDLRuby","hdrcc")).chomp("exe") +
        "lib/HDLRuby"
end


include HDLRuby


# Displays the help
def hdr_help
  puts %{Interactive HDLRuby
  Usage:
  - Getting this help: hdr_help
  - Compiling a module: hdr_make(<module name>[, <parameters>])
  - Generating Verilog code from a compiled module: hdr_verilog
  - Generating VHDL code from a compiled module:    hdr_vhdl
  - Generating HDLRuby code from a compiled module: hdr_hdr
  - Generating YAML code from a compiled module:    hdr_yaml
  - Simulating the compiled module:                 hdr_sim
  - Simulating the compiled module with VCD output: hdr_sim_vcd
  - Simulating the compiled module with no output:  hdr_sim_mute

  Note: the folder for output files is HDLRubyWorkspace}
end

# Error handling.
def hdr_error(mess)
  puts "Error: #{mess}"
  hdr_help
end


def hdr_test
    $top = "__test__"
    tests = $options[:test]
    if tests then
        tests = tests.to_s.split(",")
        tests.map! {|test| ":\"#{test}\"" }
        tests = ", #{tests.join(",")}"
    else
        tests = ""
    end
    # Generate the unit test file.
    $test_file = Tempfile.new('tester.rb',Dir.getwd)
    $test_file.write("require 'std/hruby_unit.rb'\nrequire_relative '#{$input}'\n\n" +
                     "HDLRuby::Unit.test(:\"#{$top}\"#{tests})\n")
    # $test_file.rewind
    # show? $test_file.read
    # exit
    $test_file.rewind
    # It is the new input file.
    $input = $test_file
end

# Sets the options.
$options = {}

# Sets the default input name.
$input = "top_system"

# Open the output.
$output = "HDLRubyWorkspace"

# Fix the y bug
undef y

# Display the initial help.
hdr_help

def hdr_output(output = $output)
    # Create a directory if necessary.
    unless File.directory?($output)
        FileUtils.mkdir_p($output)
    end
end

hdr_output

# Read some files.
def hdr_load(input)
    # loader = HDRLoad.new($top,input,"./",*params)
    # loader.read_all
    # loader.check_all
    # # Not debug mode, use the error management.
    # error_manager(loader.requires + [input]) { top_instance = loader.parse }
    # $top_system = top_instance.to_low.systemT
    # $top_intance = nil # Free as much memory as possible.
    load(input)
end


# Process a system for generation.
def hdr_make(sys,*params)
    if sys.is_a?(SystemI) then
        $top_system_high = sys.systemT
        $top_system = sys.to_low.systemT
    elsif params.empty? then
        $top_system_high = sys.(HDLRuby.uniq_name).systemT
        $top_system = sys.(HDLRuby.uniq_name).to_low.systemT
    else
        $top_system_high = sys.(*params).(HDLRuby.uniq_name).systemT
        $top_system = sys.(*params).(HDLRuby.uniq_name).to_low.systemT
    end
end

$non_hdlruby = []

def hdr_code
    # Gather the non-HDLRuby code.
    $top_system.each_systemT_deep do |systemT|
        systemT.scope.each_scope_deep do |scope|
            scope.each_code do |code|
                non_hdlruby << code
            end
        end
    end
    # Generates its code.
    $non_hdlruby.each {|code| code.to_file($output) }
end


def hdr_yaml
  unless $top_system
    hdr_error("Need to compile a system first.")
  else
    puts $top_system.to_yaml
  end
end

def hdr_hdr
 unless $top_system
   hdr_error("Need to compile a system first.")
 else
   puts $top_system.to_hdr
 end
end

# def hdr_sim
#     $top_system.each_systemT_deep do |systemT|
#         HDLRuby.show "seq2seq step..."
#         # Coverts the par blocks in seq blocks to seq blocks to match
#         # the simulation engine.
#         systemT.par_in_seq2seq!
#         HDLRuby.show Time.now
#         HDLRuby.show "connections_to_behaviors step..."
#         # Converts the connections to behaviors.
#         systemT.connections_to_behaviors!
#         HDLRuby.show Time.now
#         # Break the RefConcat.
#         HDLRuby.show "concat_assigns step..."
#         systemT.break_concat_assigns! 
#         HDLRuby.show Time.now
#         # Explicits the types.
#         HDLRuby.show "explicit_types step..."
#         systemT.explicit_types!
#         HDLRuby.show Time.now
#     end
#     # Generate the C.
#     # Get the base name of the input file, it will be used for
#     # generating the main name of the multiple result files.
#     $basename = File.basename($input,File.extname($input))
#     $basename = $output + "/" + $basename
#     # Multiple files generation mode.
#     # Generate the h file.
#     $hname = $output + "/hruby_sim_gen.h"
#     $hnames = [ File.basename($hname) ]
#     $outfile = File.open($hname,"w")
#     # Adds the generated globals
#     $top_system.each_systemT_deep do |systemT|
#         systemT.to_ch($outfile)
#         # # # Close the file.
#         # # output.close
#         # # # Clears the name.
#         # # hname = nil
#     end
#     # Adds the globals from the non-HDLRuby code
#     $non_hdlruby.each do |code|
#         code.each_chunk do |chunk|
#             if chunk.name == :sim then
#                 $outfile << "extern "
#                 $outfile << HDLRuby::Low::Low2C.prototype(chunk.to_c(""))
#             end
#         end
#     end
#     $outfile.close
# 
#     # Prepare the initial name for the main file.
#     $name = $basename + ".c"
#     # Generate the code for it.
#     $main = File.open($name,"w")
# 
#     # Select the vizualizer depending on the options.
#     init_visualizer = $options[:vcd] ? "init_vcd_visualizer" :
#         "init_default_visualizer"
# 
#     # Gather the system to generate and sort them in the right order
#     # to ensure references are generated before being used.
#     # Base: reverse order of the tree.
#     # Then, multiple configuration of a system instance must be
#     # reverversed so that the base configuration is generated first.
#     c_systems = $top_system.each_systemT_deep_ref
#     # Generate the code of the main function.
#     # HDLRuby start code
#     $main << HDLRuby::Low::Low2C.main("hruby_simulator",
#                                       init_visualizer,
#                                       $top_system,
#                                       c_systems,
#                                       $hnames)
#     $main.close
# 
#     $top_system.each_systemT_deep do |systemT|
#         # For the c file.
#         name = $output + "/" +
#             HDLRuby::Low::Low2C.c_name(systemT.name) +
#             ".c"
#         # show? "for systemT=#{systemT.name} generating: #{name}"
#         # Open the file for current systemT
#         outfile = File.open(name,"w")
#         # Generate the C code in to.
#         # outfile << systemT.to_c(0,*$hnames)
#         systemT.to_c(outfile,0,*$hnames)
#         # Close the file.
#         outfile.close
#         # Clears the name.
#         name = nil
#     end
# 
#     # Simulation mode, compile and exectute.
#     # Path of the simulator core files.
#     $simdir = $hdr_dir + "/sim/"
#     # Generate and execute the simulation commands.
#     # Kernel.system("cp -n #{simdir}* #{$output}/; cd #{$output}/ ; make -s ; ./hruby_simulator")
#     Dir.entries($simdir).each do |filename| 
#         if !File.directory?(filename) && /\.[ch]$/ === filename then
#             FileUtils.cp($simdir + "/" + filename,$output)
#         end
#     end
#     Dir.chdir($output)
#     # Find the compiler.
#     cc_cmd = which('cc')
#     unless cc_cmd then
#         cc_cmd = which('gcc')
#     end
#     unless cc_cmd then
#         raise "Could not find any compiler, please compile by hand as follows:\n" +
#             "   In folder #{$output} execute:\n" +
#             "     <my compiler> -o hruby_simulator *.c -lpthread\n" +
#             "   Then execute:\n   hruby_simulator"
#     end
#     # Use it.
#     Kernel.system("#{cc_cmd} -o3 -o hruby_simulator *.c -lpthread")
#     Kernel.system("./hruby_simulator")
#     Dir.chdir("..")
# end

def hdr_sim(mode = nil)
  unless $top_system_high
    hdr_error("Need to compile a system first.")
    return
  end
  HDLRuby.show "Building the hybrid C-Ruby-level simulator..."
  # C-Ruby-level simulation.
  require 'HDLRuby/hruby_rcsim.rb'
  # Merge the included from the top system.
  $top_system_high.merge_included!
  # Process par in seq.
  $top_system_high.par_in_seq2seq!
  # Generate the C data structures.
  $top_system_high.to_rcsim
  HDLRuby.show "Executing the hybrid C-Ruby-level simulator..."
  HDLRuby::High.rcsim($top_system_high,"hruby_simulator",$output,
                     ((mode == :mute) && 1) || ((mode == :vcd) && 2) || 0)
  HDLRuby.show "End of hybrid C-Ruby-level simulation..."
end

def hdr_sim_vcd
  hdr_sim(:vcd)
end

def hdr_sim_mute
  hdr_sim(:mute)
end

def hdr_verilog
  unless $top_system
    hdr_error("Need to compile a system first.")
    return
  end
  # Make description compatible with verilog generation.
  $top_system.each_systemT_deep do |systemT|
    # HDLRuby.show "casts_without_expression! step..."
    # systemT.casts_without_expression!
    # HDLRuby.show Time.now
    HDLRuby.show "to_upper_space! step..."
    systemT.to_upper_space!
    HDLRuby.show Time.now
  end
  HDLRuby.show "to_global_space! step (global)..."
  $top_system.to_global_systemTs!
  HDLRuby.show Time.now
  $top_system.each_systemT_deep do |systemT|
    ## systemT.break_types!
    ## systemT.expand_types!
    HDLRuby.show "par_in_seq2seq! step..."
    systemT.par_in_seq2seq!
    HDLRuby.show Time.now
    HDLRuby.show "initial_concat_to_timed! step..."
    systemT.initial_concat_to_timed!
    HDLRuby.show Time.now
    HDLRuby.show "with_port! step..."
    systemT.with_port!
    HDLRuby.show Time.now
  end
  # # Verilog generation
  # $output << top_system.to_verilog
  # Generate the Verilog.
  # Get the base name of the input file, it will be used for
  # generating the main name of the multiple result files.
  $basename = File.basename($input,File.extname($input))
  $basename = $output + "/" + $basename
  # # File name counter.
  # $namecount = 0
  # Prepare the initial name for the main file.
  $name = $basename + ".v"
  # Multiple files generation mode.
  $top_system.each_systemT_deep do |systemT|
    # Generate the name if necessary.
    unless $name
      $name = $output + "/" +
        HDLRuby::Verilog.name_to_verilog(systemT.name) +
        ".v"
    end
    # Open the file for current systemT
    outfile = File.open($name,"w")
    # Generate the Verilog code in to.
    outfile << systemT.to_verilog
    # Close the file.
    outfile.close
    # Clears the name.
    $name = nil
  end
end

def hdr_vhdl
  unless $top_system
    hdr_error("Need to compile a system first.")
    return
  end
  # top_system = $top_instance.to_low.systemT
  # top_system = $top_system
  # Make description compatible with vhdl generation.
  $top_system.each_systemT_deep do |systemT|
    systemT.outread2inner!            unless $options[:vhdl08] || $options[:alliance]
    systemT.with_boolean!
    systemT.boolean_in_assign2select! unless $options[:alliance]
    systemT.bit2vector2inner!         unless $options[:vhdl08] || $options[:alliance]
    systemT.select2case!              # if     $options[:alliance]
    systemT.break_concat_assigns!     # if     $options[:alliance]
    systemT.to_upper_space!
    systemT.to_global_systemTs!
    systemT.break_types!
    systemT.with_port!
    systemT.with_var!
    systemT.cleanup!
  end
  # Generate the vhdl.
  # Get the base name of the input file, it will be used for
  # generating the main name of the multiple result files.
  $basename = File.basename($input,File.extname($input))
  $basename = $output + "/" + $basename
  # # File name counter.
  # $namecount = 0
  # Prepare the initial name for the main file.
  $name = $basename + ".vhd"
  # Multiple files generation mode.
  $top_system.each_systemT_deep do |systemT|
    # Generate the name if necessary.
    unless $name
      $name = $output + "/" +
        HDLRuby::Low::Low2VHDL.entity_name(systemT.name) +
        ".vhd"
    end
    # Open the file for current systemT
    outfile = File.open($name,"w")
    # Generate the VHDL code in to.
    outfile << systemT.to_vhdl
    # Close the file.
    outfile.close
    # Clears the name.
    $name = nil
  end
end


configure_high


require 'std/std.rb'
include HDLRuby::High::Std
