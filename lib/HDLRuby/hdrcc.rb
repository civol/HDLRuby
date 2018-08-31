#!/usr/bin/ruby

require 'HDLRuby'
require 'HDLRuby/hruby_check.rb'
require 'ripper'

##
# Library for loading an HDLRuby description in HDR format
###########################################################

module HDLRuby



    # Class for loading hdr files.
    class HDRLoad

        TOP_NAME = "__hdr_top_instance__"

        # The top instance, only accessible after parsing the files.
        attr_reader :top_instance

        # Creates a new loader for a +top_system+ system in file +top_file+
        # from directory +dir+ with generic parameters +params+.
        def initialize(top_system,top_file,dir,*params)
            # Sets the top and the looking directory.
            @top_system = top_system.to_s
            @top_file = top_file.to_s
            @dir = dir.to_s
            @params = params

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
            # Read the file
            read(file)
            # Get its required files.
            requires = @checks[-1].get_all_requires
            requires.each do |file|
                read_all(require) if file != "HDLRuby"
            end
        end

        # Checks the read files.
        def check_all
            @checks.each { |check| check.assign_check }
        end

        # Gets the (first) top system.
        def get_top
            # Get all the systems.
            systems = @checks.reduce([]) {|ar,check| ar + check.get_all_systems}
            # Remove the systems that are instantiated (they cannot be tops)
            @checks.each do |check|
                check.get_all_instances(systems).each do |instante|
                    systems.delete(@check.instance_system(instance))
                end
            end
            # Return the first top of the list.
            return systems[-1]
        end


        # Load the hdlruby structure from an instance of the top module.
        def parse
            # Is there a top system specified yet?
            if @top_system == "" then
                # No, look for it.
                @top_system = get_top
                # Not found? Error.
                raise "Cannot find a top system." unless @top_system
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
                    eval("#{@top_system} :#{@top_name},#{@params.join(",")}\n#{@top_name}",bind)
            end
        end
    end
end



if __FILE__ == $0 then
    require 'optparse'
    # Used standalone, check the files given in the standard input.
    include HDLRuby

    # Process the command line options
    options = {}
    optparse = OptionParser.new do |opts|
        opts.banner = "Usage: hdrcc.rb [options] <input hdr file> [<output file>]"
 
        opts.separator ""
        opts.separator "Where:"
        opts.separator "* `options` is a list of options"
        opts.separator "* `<input hdr file>` is the initial file to compile (mandatory)"
        opts.separator "* `<output file>` is the output file"
        opts.separator ""
        opts.separator "Options:"

        opts.on("-y", "--yaml", "Output in YAML format") do |y|
            options[:yaml] = y
        end
        opts.on("-v", "--verilog","Output in Verlog HDL format") do |v|
            options[:verilog] = v
        end
        opts.on("-d", "--directory","Specify the base directory for loading the hdr files") do |d|
            options[:directory] = d
        end
        opts.on("-t", "--top system", "Specify the top system to process") do|t|
            options[:top] = t
        end
        opts.on("-p", "--param x,y,z", "Specify the generic parameters") do |p|
            options[:param] = p
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
        opts.separator "* Compile system named `adder` from `adder.hdr` input file and generate `adder.yaml` low-level YAML description:"
        opts.separator "   hdrcc.rb --yaml --top adder adder.hdr adder.yaml"
        opts.separator "* Compile `adder.hdr` input file and generate `adder.v` low-level Verilog HDL description:"
        opts.separator "   hdrcc.rb --verilog adder.hdr adder.v"
        opts.separator "* Check the validity of `adder.hrd` input file:"
        opts.separator "   hdrcc.rb adder.hdr"
        opts.separator "* Compile system `adder` whose bit width is generic from `adder_gen.hdr` input file to a 16-bit circuit whose low-level Verilog HDL description is dumped to the standard output:"
        opts.separator "   hdrcc -v -t adder --param 16 adder_gen.hdr"
        opts.separator "* Compile system `multer` with inputs and output bit width is generic from `multer_gen.hdr` input file to a 16x16->32 bit cicruit whose low-level YAML description is saved to output file `multer_gen.yaml`"
        opts.separator "hdrcc -y -t multer -p 16,16,32 multer_gen.hdr multer_gen.yaml"

    end
    optparse.parse!

    # puts "options=#{options}"

    # Check the compatibility of the options
    if options[:yaml] && options[:verilog] then
        warn("Please choose EITHER YAML OR Verilog HDL output.")
        puts optparse.help()
    end

    # Get the the input and the output files.
    input,output = $*
    # Get the top system name if name.
    top = options[:top].to_s
    unless top == "" || (/^[_[[:alpha:]]][_\w]*$/ =~ top) then
        warn("Please provide a valid top system name.")
        exit
    end
    # Get the generic parameters if any.
    params = options[:param].to_s.split(",")


    if input == nil then
        warn("Please provide an input hdr file (or consult the help using the --help option.)")
        exit
    end

    # Load and process the hdr files.
    options[:directory] ||= "./"
    loader = HDRLoad.new(top,input,options[:directory].to_s,*params)
    loader.read_all
    loader.check_all
    top_instance = loader.parse

    # Open the output.
    if output then
        output = File.open(output,"w")
    else
        output = $stdout
    end

    # Generate the result.
    if options[:yaml] then
        output << top_instance.to_low.systemT.to_yaml
    elsif options[:verilog] then
        warn("Verilog HDL output is not available yet... but it will be soon, promise!")
    end
end
