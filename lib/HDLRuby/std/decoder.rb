module HDLRuby::High::Std

    ##
    # Standard HDLRuby::High library: decoder generator.
    # 
    ########################################################################


    ## 
    # Describes a high-level decoder type.
    class DecoderT
        include HDLRuby::High::HScope_missing

        # The description of a decoding field.
        class Field
            attr_accessor :range, :content
        end

        # The entry class
        class Entry
            attr_accessor :id_fields, # The fields for identifying the entry 
                          :var_fields,# The fields for getting variables
                          :code    # The code to execute when the entry matches
        end

        # The name of the decoder type.
        attr_reader :name

        # The namespace associated with the decoder
        attr_reader :namespace

        # The default code if any.
        attr_reader :default_code


        # Creates a new decoder type with +name+.
        def initialize(name)
            # Check and set the name
            @name = name.to_sym

            # Initialize the internals of the decoder.


            # Initialize the environment for building the decoder.

            # The main entries.
            @entries = []

            # The default code to execute when no entry match.
            @default_code = nil

            # Creates the namespace to execute the fsm block in.
            @namespace = Namespace.new(self)

            # Generates the function for setting up the decoder
            # provided there is a name.
            obj = self # For using the right self within the proc
            HDLRuby::High.space_reg(@name) do |expr,&ruby_block|
                if ruby_block then
                    # Builds the decoder.
                    obj.build(expr,&ruby_block)
                else
                    # Return the fsm as is.
                    return obj
                end
            end unless name.empty?

        end

        ## builds the decoder on expression +expr+ by executing +ruby_block+.
        def build(expr,&ruby_block)
            # Use local variable for accessing the attribute since they will
            # be hidden when opening the sytem.
            entries = @entries
            namespace = @namespace
            this   = self
            return_value = nil

            HDLRuby::High.space_push(namespace)
            # Execute the instantiation block
            return_value =HDLRuby::High.top_user.instance_exec(&ruby_block)

            # Create the decoder code

            # The process
            par do
                # Depending on the type of entry.
                test = :hif # Which command to use for testing
                # (first: hif, then heslif)
                entries.each do |entry|
                    # Build the predicate for checking the entry.
                    entry_predicate = entry.id_fields.map do |field|
                        expr[field.range] == field.content
                    end.reduce(:&)

                    send(test,entry_predicate) do
                        # Sets the local variables.
                        entry.var_fields.each do |field|
                            this.
                                define_singleton_method(field.content) do
                                expr[field.range]
                            end
                        end
                        # Generate the content of the entry.
                        entry.code.call
                    end
                    test = :helsif # Now use helsif for the alternative.
                end
                # Adds the default code if any.
                if default_code then
                    helse(&default_code)
                end
            end

            HDLRuby::High.space_pop

            return return_value
        end


        ## The interface for building the decoder


        # Declares a new entry with +format+ and executing +ruby_block+.
        def entry(format, &ruby_block)
            # puts "entry with format=#{format}"
            # Create the resulting entry
            result = Entry.new
            result.code = ruby_block
            # Process the format.
            format = format.to_s
            width = format.size
            # For that purpose create the regular expression used to process it.
            prs = "([0-1]+)|(a+)|(b+)|(c+)|(d+)|(e+)|(g+)|(h+)|(i+)|(j+)|(k+)|(l+)|(m+)|(n+)|(o+)|(p+)|(q+)|(r+)|(s+)|(t+)|(u+)|(v+)|(w+)|(x+)|(y+)|(z+)"
            # Check if the format is compatible with it.
            unless format =~ Regexp.new("^(#{prs})+$") then
                raise AnyError("Invalid format for a field: #{format}")
            end
            # Split the format in fields.
            format = format.split(Regexp.new(prs)).select {|str| !str.empty?}
            # puts "format=#{format}"
            # Fills the entry with each field of the format.
            result.id_fields = []
            result.var_fields = []
            pos = width-1
            format.each do |str|
                # puts "str=#{str}"
                # Create a new field and compute its range.
                field = Field.new
                field.range = pos..(pos-str.size+1)
                # Build its content, and add the field.
                # Depends on wether it is an id or a variable field?
                if str =~ /[0-1]+/ then
                    # Id field.
                    # Build its type.
                    type = TypeVector.new(:"",bit,
                                          field.range.first-field.range.last..0)
                    # Build the content as a value.
                    field.content = Value.new(type,str)
                    # Add the field.
                    result.id_fields << field
                else
                    # Variable field.
                    # Build the content as a single-character symbol.
                    field.content = str[0].to_sym
                    # Add the field.
                    result.var_fields << field
                end
                # Update the position.
                pos = pos-str.size
            end
            # Add it to the list of entries.
            @entries << result
            # Return it.
            return result
        end

        # Declares the default code to execute when no format maches.
        def default(&ruby_block)
            @default_code = ruby_block
        end
    end




    ## Declare a new decoder.
    #  The arguments can be any of (but in this order):
    #
    #  - +name+:: name.
    #  - +expr+:: the expression to decode.
    #
    #  If provided, +ruby_block+ the fsm is directly instantiated with it.
    def decoder(*args, &ruby_block)
        # Sets the name if any
        unless args[0].respond_to?(:to_expr) then
            name = args.shift.to_sym
        else
            name = :""
        end
        # Create the decoder.
        decoderI = DecoderT.new(name)

        # Is there a ruby block?
        if ruby_block then
            # Yes, generate the decoder.
            decoderI.build(*args,&ruby_block)
        else
            # No return the decoder structure for later generation.
            return decoderI
        end
    end

end
