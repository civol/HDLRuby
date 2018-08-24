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
        # from directory +dir+.
        def initialize(top_system,top_file,dir)
            # Sets the top and the looking directory.
            @top_system = top_system.to_s
            @top_file = top_file.to_s
            @dir = dir.to_s

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


        # Load the hdlruby structure from an instance of the top module.
        def parse
            # Initialize the environment for processing the hdr file.
            bind = TOPLEVEL_BINDING.clone
            eval("require 'HDLRuby'\n\nconfigure_high\n\n",bind)
            # Process it.
            eval(@texts[0],bind)
            # Get the resulting instance
            @top_instance = eval("#{@top_system} :#{@top_name}\n#{@top_name}",bind)
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
        opts.banner = "Usage: hdrcc.rb [options] <top system> <input hdr file> [<output file>]"
 
        opts.separator ""
        opts.separator "Notice:"
        opts.separator "* If no option is given, simply checks the input file."
        opts.separator "* If no output file is given, the result is given through the standard output."
        opts.separator ""
        opts.separator "Options:"

        opts.on("-y", "--yaml", "Output in YAML format") do |y|
            options[:yaml] = y
        end
        opts.on("-v", "--verilog","Output in Verlog HDL format") do |v|
            options[:verilog] = v
        end
        opts.on("-d", "--directory","Specify the base directory for loading the hdr files.") do |d|
            options[:directory] = d
        end
        opts.on_tail("-h", "--help", "Show this message") do
            puts opts
            exit
        end
    end
    optparse.parse!

    # Check the compatibility of the options
    if options[:yaml] && options[:verilog] then
        warn("Please choose EITHER yaml OR verilog output.")
        puts optparse.help()
    end
        
    # Get the top system name, and the input and output files.
    top,input,output = $*

    if top == nil || !(/^[_[[:alpha:]]][_\w]*$/ =~ top) then
        warn("Please provide a valid top system name.")
        puts optparse.help()
        exit
    end

    if input == nil then
        warn("Please provide an input hdr file.")
        puts optparse.help()
        exit
    end

    # Load and process the hdr files.
    options[:directory] ||= "./"
    loader = HDRLoad.new(top,input,options[:directory].to_s)
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
