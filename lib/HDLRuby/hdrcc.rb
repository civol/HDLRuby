#!/usr/bin/ruby

require 'fileutils'
require 'HDLRuby'
require 'HDLRuby/hruby_check.rb'
require 'ripper'
require 'HDLRuby/hruby_low2high'
require 'HDLRuby/hruby_low2vhd'
require 'HDLRuby/hruby_low_without_outread'
require 'HDLRuby/hruby_low_with_bool'
require 'HDLRuby/hruby_low_bool2select'
require 'HDLRuby/hruby_low_without_select'
require 'HDLRuby/hruby_low_without_namespace'
require 'HDLRuby/hruby_low_without_bit2vector'
require 'HDLRuby/hruby_low_with_port'
require 'HDLRuby/hruby_low_with_var'
require 'HDLRuby/hruby_low_without_concat'
require 'HDLRuby/hruby_low_cleanup'

require 'HDLRuby/hruby_verilog.rb'

##
# HDLRuby compiler interface program
#####################################

module HDLRuby



    # Class for loading hdr files.
    class HDRLoad

        # TOP_NAME = "__hdr_top_instance__"
        TOP_NAME = "__"

        # The top instance, only accessible after parsing the files.
        attr_reader :top_instance

        # The required files.
        attr_reader :requires

        # Creates a new loader for a +top_system+ system in file +top_file+
        # from directory +dir+ with generic parameters +params+.
        def initialize(top_system,top_file,dir,*params)
            # Sets the top and the looking directory.
            @top_system = top_system.to_s
            @top_file = top_file.to_s
            @dir = dir.to_s
            @params = params

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
        def read(file)
            @texts << File.read(File.join(@dir,file) )
            @checks << Checker.new(@texts[-1],file)
        end

        # Loads all the files from +file+.
        def read_all(file = @top_file)
            # puts "read_all with file=#{file}"
            # Read the file
            read(file)
            # Get its required files.
            requires = @checks[-1].get_all_requires
            requires.each do |file|
                read_all(file) if file != "HDLRuby"
            end
            @requires += requires
            @requires.uniq!
        end

        # Checks the read files.
        def check_all
            @checks.each { |check| check.assign_check }
        end

        # Displays the syntax tree of all the files.
        def show_all(output = $stdout)
            # puts "@checks.size=#{@checks.size}"
            @checks.each { |check| check.show(output) }
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


        # Load the hdlruby structure from an instance of the top module.
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
                    eval(@texts[0],bind,@top_file,1)
                    # No parse error found.
                    raise "Cannot find a top system." unless @top_system
                end
            end
            # Initialize the environment for processing the hdr file.
            bind = TOPLEVEL_BINDING.clone
            eval("require 'HDLRuby'\n\nconfigure_high\n\n",bind)
            # Process it.
            eval(@texts[0],bind,@top_file,1)
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
end



if __FILE__ == $0 then
    require 'optparse'
    # Used standalone, check the files given in the standard input.
    include HDLRuby

    # Process the command line options
    $options = {}
    $optparse = OptionParser.new do |opts|
        opts.banner = "Usage: hdrcc.rb [options] <input file> [<output file>]"
 
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
        opts.on("-t", "--top system", "Specify the top system to process") do|t|
            $options[:top] = t
        end
        opts.on("-p", "--param x,y,z", "Specify the generic parameters") do |p|
            $options[:param] = p
        end
        opts.on_tail("-h", "--help", "Show this message") do
            puts opts
            exit
        end
        opts.separator ""
        opts.separator "Notice:"
        opts.separator "* If no output option is given, simply checks the input file"
        opts.separator "* If no output file is given, the result is given through the standard output."
        opts.separator "* If no top system is given, it will be automatically searched in the input file."
        opts.separator ""
        opts.separator "Examples:"
        opts.separator "* Compile system named `adder` from `adder.rb` input file and generate `adder.yaml` low-level YAML description:"
        opts.separator "   hdrcc.rb --yaml --top adder adder.rb adder.yaml"
        opts.separator "* Compile `adder.rb` input file and generate `adder.vhd` low-level VHDL description:"
        opts.separator "   hdrcc.rb --vhdl adder.rb adder.vhd"
        opts.separator "* Check the validity of `adder.rb` input file:"
        opts.separator "   hdrcc.rb adder.rb"
        opts.separator "* Compile system `adder` whose bit width is generic from `adder_gen.rb` input file to a 16-bit circuit whose low-level Verilog HDL description is dumped to the standard output:"
        opts.separator "   hdrcc -v -t adder --param 16 adder_gen.rb"
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
    if $options[:yaml] then
        $output << $top_instance.to_low.systemT.to_yaml
    elsif $options[:hdr] then
        if $options[:multiple] then
            raise "Multiple files generation mode not supported for HDLRuby output yet."
        end
        # $top_instance.to_low.systemT.each_systemT_deep.reverse_each do |systemT|
        #     $output << systemT.to_high
        # end
        $output << $top_instance.to_low.systemT.to_high
    elsif $options[:verilog] then
        # warn("Verilog HDL output is not available yet... but it will be soon, promise!")
        top_system = $top_instance.to_low.systemT
        # Make description compatible with verilog generation.
        top_system.each_systemT_deep do |systemT|
            systemT.to_upper_space!
            systemT.to_global_systemTs!
            systemT.break_types!
            systemT.with_port!
        end
        # # Verilog generation
        # $output << top_system.to_verilog
        # Generate the Verilog.
        if $options[:multiple] then
            # Get the base name of the input file, it will be used for
            # generating the main name of the multiple result files.
            basename = File.basename($input,File.extname($input))
            basename = $output + "/" + basename
            # File name counter.
            count = 0
            # Prepare the initial name for the main file.
            name = basename + ".v"
            # Multiple files generation mode.
            top_system.each_systemT_deep do |systemT|
                # Generate the name if necessary.
                unless name
                    name = $output + "/" +
                        HDLRuby::Verilog.name_to_verilog(systemT.name) +
                        ".v"
                end
                # Open the file for current systemT
                output = File.open(name,"w")
                # Generate the VHDL code in to.
                output << systemT.to_verilog
                # Close the file.
                output.close
                # Clears the name.
                name = nil
            end
        else
            # Single file generation mode.
            top_system.each_systemT_deep.reverse_each do |systemT|
                $output << systemT.to_verilog
            end
        end
    elsif $options[:vhdl] then
        top_system = $top_instance.to_low.systemT
        # Make description compatible with vhdl generation.
        top_system.each_systemT_deep do |systemT|
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
            basename = File.basename($input,File.extname($input))
            basename = $output + "/" + basename
            # File name counter.
            count = 0
            # Prepare the initial name for the main file.
            name = basename + ".vhd"
            # Multiple files generation mode.
            top_system.each_systemT_deep do |systemT|
                # Generate the name if necessary.
                unless name
                    name = $output + "/" +
                        HDLRuby::Low::Low2VHDL.entity_name(systemT.name) +
                        ".vhd"
                end
                # Open the file for current systemT
                output = File.open(name,"w")
                # Generate the VHDL code in to.
                output << systemT.to_vhdl
                # Close the file.
                output.close
                # Clears the name.
                name = nil
            end
        else
            # Single file generation mode.
            top_system.each_systemT_deep.reverse_each do |systemT|
                $output << systemT.to_vhdl
            end
        end
    end
end
