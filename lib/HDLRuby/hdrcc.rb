#!/usr/bin/ruby

require 'fileutils'
require 'tempfile'
require 'HDLRuby'
require 'HDLRuby/hruby_check.rb'
# require 'ripper'
require 'HDLRuby/hruby_low2high'
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
                        # puts "Standard files: #{founds}"
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
            # puts "read_all with file=#{file}"
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
            # puts "@checks.size=#{@checks.size}"
            @checks.each { |check| check.show(outfile) }
        end

        # Gets the (first) top system.
        def get_top
            # Get all the systems.
            systems = @checks.reduce([]) {|ar,check| ar + check.get_all_systems}
            # puts "First systems=#{systems}"
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
            # puts "Now systems=#{systems}"
            # Return the first top of the list.
            return systems[-1]
        end


        # Load the HDLRuby structure from an instance of the top module.
        def parse
            # Is there a top system specified yet?
            if @top_system == "" then
                # No, look for it.
                @top_system = get_top
                # puts "@top_system=#{@top_system}"
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


    # Extend the Code class with generation of file for the content.
    class HDLRuby::Low::Code

        ## Creates a file in +path+ containing the content of the code.
        def to_file(path = "")
            self.each_chunk do |chunk|
                # Process the lumps of the chunk.
                # NOTE: for now use the C code generation of Low2C
                content = chunk.to_c
                # Dump to a file.
                if chunk.name != :sim then 
                    # The chunk is to be dumbed to a file.
                    # puts "Outputing chunk:#{HDLRuby::Low::Low2C.obj_name(chunk)}"
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



if __FILE__ == $0 then
    # From hdrcc.rb
    $hdr_dir = File.dirname(__FILE__)
else
    # Form hdrcc
    $hdr_dir = File.dirname(Gem.bin_path("HDLRuby","hdrcc")).chomp("exe") +
        "lib/HDLRuby"
end

require 'optparse'
# Used standalone, check the files given in the standard input.
include HDLRuby

# Process the command line options
$options = {}
$optparse = OptionParser.new do |opts|
    opts.banner = "Usage: hdrcc.rb [options] <input file> [<output directory or file>]"

    opts.separator ""
    opts.separator "Where:"
    opts.separator "* `options` is a list of options"
    opts.separator "* `<input file>` is the initial file to compile (mandatory)"
    opts.separator "* `<output file>` is the output file"
    opts.separator ""
    opts.separator "Options:"
    
    opts.on("-y", "--yaml", "Output in YAML format") do |y|
        $options[:yaml] = y
    end
    opts.on("-r", "--hdr","Output in HDLRuby format") do |v|
        $options[:hdr] = v
    end
    opts.on("-C", "--clang","Output in C format (simulator)") do |v|
        $options[:clang] = v
        $options[:multiple] = v
    end
    opts.on("--allocate=LOW,HIGH,WORD","Allocate signals to addresses") do |v|
        $options[:allocate] = v
    end
    opts.on("-S", "--sim","Output in C format (simulator)") do |v|
        $options[:clang] = v
        $options[:multiple] = v
        $options[:sim] = v
    end
    opts.on("--vcd", "The simulator will generate a vcd file") do |v|
        $options[:vcd] = v
    end
    opts.on("-v", "--verilog","Output in Verlog HDL format") do |v|
        $options[:verilog] = v
        $options[:multiple] = v
    end
    opts.on("-V", "--vhdl","Output in VHDL format") do |v|
        HDLRuby::Low::Low2VHDL.vhdl08 = false
        $options[:vhdl] = v
        $options[:multiple] = v
        $options[:vhdl08] = false
    end
    opts.on("-A", "--alliance","Output in Alliance-compatible VHDL format") do |v|
        HDLRuby::Low::Low2VHDL.vhdl08 = false
        HDLRuby::Low::Low2VHDL.alliance = true
        $options[:vhdl] = v
        $options[:alliance] = v
        $options[:multiple] = v
        $options[:vhdl08] = false
    end
    opts.on("-U", "--vhdl08","Output in VHDL'08 format") do |v|
        HDLRuby::Low::Low2VHDL.vhdl08 = true
        $options[:vhdl] = v
        $options[:multiple] = v
        $options[:vhdl08] = true
    end
    opts.on("-s", "--syntax","Output the Ruby syntax tree") do |s|
        $options[:syntax] = s
    end
    opts.on("-m", "--multiple", "Produce multiple files for the result.\nThe output name is then interpreted as a directory name.") do |v|
        $options[:multiple] = v
    end
    opts.on("-d", "--directory dir","Specify the base directory for loading the hdr files") do |d|
        $options[:directory] = d
    end
    opts.on("-D", "--debug","Set the HDLRuby debug mode") do |d|
        $options[:debug] = d
    end
    opts.on("-T","--test","Compile the unit tests.") do |t|
        $options[:test] = t
    end
    opts.on("-t", "--top system", "Specify the top system to process") do|t|
        $options[:top] = t
    end
    opts.on("-p", "--param x,y,z", "Specify the generic parameters") do |p|
        $options[:param] = p
    end
    opts.on("--dump","Dump all the properties to yaml files") do |v|
        $options[:dump] = v
        $options[:multiple] = v
    end
    # opts.on_tail("-h", "--help", "Show this message") do
    opts.on("-h", "--help", "Show this message") do
        puts opts
        exit
    end
    opts.separator ""
    opts.separator "Notice:"
    opts.separator "* If no output option is given, simply checks the input file"
    opts.separator "* If no top system is given, it will be automatically searched in the input file."
    opts.separator ""
    opts.separator "Examples:"
    opts.separator "* Compile system named `adder` from `adder.rb` input file and generate `adder.yaml` low-level YAML description:"
    opts.separator "   hdrcc.rb --yaml --top adder adder.rb adder.yaml"
    opts.separator "* Compile `adder.rb` input file and generate low-level VHDL description files in `adder_vhd` directory:"
    opts.separator "   hdrcc.rb --vhdl adder.rb adder_vhd"
    opts.separator "* Check the validity of `adder.rb` input file:"
    opts.separator "   hdrcc.rb adder.rb"
    opts.separator "* Compile system `adder` whose bit width is generic from `adder_gen.rb` input file to a 16-bit circuit whose low-level Verilog HDL description files are put in `adder_gen_v` directory:"
    opts.separator "   hdrcc -v -t adder --param 16 adder_gen.rb adder_gen_v"
    opts.separator "* Compile system `multer` with inputs and output bit width is generic from `multer_gen.rb` input file to a 16x16->32 bit cicruit whose low-level YAML description is saved to output file `multer_gen.yaml`"
    opts.separator "hdrcc -y -t multer -p 16,16,32 multer_gen.rb multer_gen.yaml"

end
$optparse.parse!

# puts "options=#{$options}"

# Check the compatibility of the options
if $options.count {|op| [:yaml,:hdr,:verilog,:vhdl].include?(op) } > 1 then
    warn("Please choose either YAML, HDLRuby, Verilog HDL, or VHDL output.")
    puts $optparse.help()
end

# Get the the input and the output files.
$input,$output = $*
    # Get the top system name if name.
    $top = $options[:top].to_s
unless $top == "" || (/^[_[[:alpha:]]][_\w]*$/ =~ $top) then
    warn("Please provide a valid top system name.")
    exit
end
# Get the generic parameters if any.
$params = $options[:param].to_s.split(",")


if $input == nil then
    warn("Please provide an input file (or consult the help using the --help option.)")
    exit
end

if ($options[:test]) then
    $top = "__test__"
    # Generate the unit test file.
    $test_file = Tempfile.new('tester.rb',Dir.getwd)
    $test_file.write("require 'hruby_unit.rb'\nrequire_relative '#{$input}'\n\n" +
                    "HDLRuby::Unit.test(\"#{$top}\")\n")
    # $test_file.rewind
    # puts $test_file.read
    $test_file.rewind
    # It is the new input file.
    $input = $test_file
end

# Open the output.
if $output then
    if $options[:multiple] then
        # Create a directory if necessary.
        unless File.directory?($output)
            FileUtils.mkdir_p($output)
        end
    else
        # Open the file.
        $output = File.open($output,"w")
    end
else
    if $option[:multiple] then
        raise "Need a target directory in multiple files generation mode."
    end
    $output = $stdout
end

# Load and process the hdr files.
$options[:directory] ||= "./"
$loader = HDRLoad.new($top,$input,$options[:directory].to_s,*$params)
$loader.read_all
$loader.check_all

# Remove the test file if any, it is not needed any longer.
if $test_file then
    $test_file.close
    $test_file.unlink 
end

if $options[:syntax] then
    if $options[:multiple] then
        raise "Multiple files generation mode not supported for syntax tree output."
    end
    $output << $loader.show_all
    exit
end

if $options[:debug] then
    # Debug mode, no error management.
    $top_instance = $loader.parse
else
    # Not debug mode, use the error management.
    error_manager($loader.requires + [$input]) { $top_instance = $loader.parse }
end

# Generate the result.
# Get the top systemT.
$top_system = $top_instance.to_low.systemT

# Gather the non-HDLRuby code.
$non_hdlruby = []
$top_system.each_systemT_deep do |systemT|
    systemT.scope.each_scope_deep do |scope|
        scope.each_code do |code|
            $non_hdlruby << code
        end
    end
end
# Applies the allocators if required.
$allocate_range = $options[:allocate]
if $allocate_range then
    # Get the allocation characteristics.
    $allocate_range = $allocate_range.split(",")
    $allocate_range = [$allocate_range[0]..$allocate_range[1],
                       $allocate_range[2]].compact
    # Create the allocator.
    $allocator = HDLRuby::Low::Allocator.new(*$allocate_range)
    $non_hdlruby.each do |code|
        # Try the C allocator.
        code.c_code_allocate($allocator)
    end
end
# Generates its code.
$non_hdlruby.each {|code| code.to_file($output) }

# The HDLRuby code
if $options[:yaml] then
    if $options[:multiple] then
        raise "Multiple files generation mode not supported for YAML output yet."
    end
    # $output << $top_instance.to_low.systemT.to_yaml
    $output << $top_system.to_yaml
elsif $options[:hdr] then
    if $options[:multiple] then
        raise "Multiple files generation mode not supported for HDLRuby output yet."
    end
    # $top_system.each_systemT_deep.reverse_each do |systemT|
    #     $output << systemT.to_high
    # end
    # $output << $top_instance.to_low.systemT.to_high
    $output << $top_system.to_high
elsif $options[:clang] then
    # top_system = $top_instance.to_low.systemT
    # top_system = $top_system
    # Preprocess the HW description for valid C generation.
    $top_system.each_systemT_deep do |systemT|
        # Coverts the par blocks in seq blocks to seq blocks to match
        # the simulation engine.
        systemT.par_in_seq2seq!
        # Converts the connections to behaviors.
        systemT.connections_to_behaviors!
        # Break the RefConcat.
        systemT.break_concat_assigns! 
        # Explicits the types.
        systemT.explicit_types!
    end
    # Generate the C.
    if $options[:multiple] then
        # Get the base name of the input file, it will be used for
        # generating the main name of the multiple result files.
        $basename = File.basename($input,File.extname($input))
        $basename = $output + "/" + $basename
        # # File name counter.
        # $namecount = 0

        # # Converts the connections to behaviors (C generation does not
        # # support connections).
        # top_system.each_systemT_deep do |systemT|
        #     systemT.connections_to_behaviors!
        # end

        # Multiple files generation mode.
        # Generate the h file.
        $hname = $output + "/hruby_sim_gen.h"
        $hnames = [ File.basename($hname) ]
        $outfile = File.open($hname,"w")
        # Adds the generated globals
        $top_system.each_systemT_deep do |systemT|
            # For the h file.
            # hname = $output + "/" +
            #     HDLRuby::Low::Low2C.c_name(systemT.name) +
            #     ".h"
            # hnames << File.basename(hname)
            # # Open the file for current systemT
            # output = File.open(hname,"w")
            # Generate the H code in to.
            $outfile << systemT.to_ch
            # # Close the file.
            # output.close
            # # Clears the name.
            # hname = nil
        end
        # Adds the globals from the non-HDLRuby code
        $non_hdlruby.each do |code|
            code.each_chunk do |chunk|
                if chunk.name == :sim then
                    $outfile << "extern " + 
                        HDLRuby::Low::Low2C.prototype(chunk.to_c)
                end
            end
        end
        $outfile.close

        # Prepare the initial name for the main file.
        $name = $basename + ".c"
        # Generate the code for it.
        $main = File.open($name,"w")

        # Select the vizualizer depending on the options.
        init_visualizer = $options[:vcd] ? "init_vcd_visualizer" :
                                           "init_default_visualizer"

        # Generate the code of the main function.
        # HDLRuby start code
        $main << HDLRuby::Low::Low2C.main("hruby_simulator",
                                         init_visualizer,
                                         $top_system,
                                         $top_system.each_systemT_deep.to_a.reverse,$hnames)
        $main.close

        $top_system.each_systemT_deep do |systemT|
            # For the c file.
            name = $output + "/" +
                HDLRuby::Low::Low2C.c_name(systemT.name) +
                ".c"
            # Open the file for current systemT
            outfile = File.open(name,"w")
            # Generate the C code in to.
            outfile << systemT.to_c(0,*$hnames)
            # Close the file.
            outfile.close
            # Clears the name.
            name = nil
        end
    else
        # Single file generation mode.
        $top_system.each_systemT_deep.reverse_each do |systemT|
            $output << systemT.to_ch
            $output << systemT.to_c
        end
        # Adds the main code.
        $output << HDLRuby::Low::Low2C.main(top_system,
                                            *top_system.each_systemT_deep.to_a)
    end
    if $options[:sim] then
        # Simulation mode, compile and exectute.
        # Path of the simulator core files.
        # simdir = File.dirname(__FILE__) + "/sim/"
        $simdir = $hdr_dir + "/sim/"
        # Generate and execute the simulation commands.
        # Kernel.system("cp -n #{simdir}* #{$output}/; cd #{$output}/ ; make -s ; ./hruby_simulator")
        Dir.entries($simdir).each do |filename| 
            if !File.directory?(filename) && /\.[ch]$/ === filename then
                FileUtils.cp($simdir + "/" + filename,$output)
            end
        end
        Dir.chdir($output)
        # Kernel.system("make -s")
        Kernel.system("cc -o3 -o hruby_simulator *.c -lpthread")
        Kernel.system("./hruby_simulator")
    end
elsif $options[:verilog] then
    # warn("Verilog HDL output is not available yet... but it will be soon, promise!")
    # top_system = $top_instance.to_low.systemT
    # top_system = $top_system
    # Make description compatible with verilog generation.
    $top_system.each_systemT_deep do |systemT|
        systemT.casts_without_expression!
        systemT.to_upper_space!
        systemT.to_global_systemTs!
        # systemT.break_types!
        # systemT.expand_types!
        systemT.par_in_seq2seq!
        systemT.initial_concat_to_timed!
        systemT.with_port!
    end
    # # Verilog generation
    # $output << top_system.to_verilog
    # Generate the Verilog.
    if $options[:multiple] then
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
    else
        # Single file generation mode.
        top_system.each_systemT_deep.reverse_each do |systemT|
            $output << systemT.to_verilog
        end
    end
elsif $options[:vhdl] then
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
    if $options[:multiple] then
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
    else
        # Single file generation mode.
        $top_system.each_systemT_deep.reverse_each do |systemT|
            $output << systemT.to_vhdl
        end
    end
end

# Apply the post drivers if any.
Hdecorator.each_with_property(:post_driver) do |obj, value|
    # Load the driver.
    require_relative(value[0].to_s)
    # Execute it.
    send(value[1].to_sym,obj,$output)
end

# Dump the properties
if $options[:dump] then
    # Decorate with the parent ids.
    Hdecorator.decorate_parent_id
    
    # Generate the directory for the properties
    property_dir = $output + "/properties"
    unless File.directory?(property_dir)
        FileUtils.mkdir_p(property_dir)
    end

    # Dump to one file per key
    Properties.each_key do |key|
        File.open(property_dir + "/#{key}.yaml", "w") do |f|
            Hdecorator.dump(key,f)
        end
    end
    
end
