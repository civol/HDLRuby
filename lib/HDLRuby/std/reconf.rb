module HDLRuby::High::Std

##
# Standard HDLRuby::High library: reconfigurable components.
# 
########################################################################
    
    ## Describes a high-level reconfigurable component type.
    class ReconfT

        # The name of the reconfigurable component type.
        attr_reader :name

        # Creates a new reconfigurable type with +name+ built whose
        # instances are created from +ruby_block+.
        def initialize(name,&ruby_block)
            # Checks and sets the name.
            @name = name.to_sym
            # Sets the block for instantiating a channel.
            @ruby_block = ruby_block
            # Sets the instantiation procedure.
            obj = self
            HDLRuby::High.space_reg(@name) do |*args|
                obj.instantiate(*args)
            end
        end

        ## Intantiates a reconfigurable component.
        def instantiate(*args)
            obj = self
            # No argument, so not an instantiation but actually
            # an access to the channel type.
            return obj if args.empty?
            # Process the case of generic channel.
            if @ruby_block.arity > 0 then
                # Actually the arguments are generic arguments,
                # generates a new channel type with these arguments
                # fixed.
                ruby_block = @ruby_block
                return ReconfT.new(:"") do
                    HDLRuby::High.top_user.instance_exec(*args,&ruby_block)
                end
            end
            # Generates the reconfigurable components.
            args.each do |nameI|
                # puts "for #{nameI} ruby_block=#{@ruby_block}"
                reconfI = ReconfI.new(name,&@ruby_block)
                HDLRuby::High.space_reg(nameI) { reconfI }
                reconfI
            end
        end

        alias_method :call, :instantiate
    end


    ## Creates a new reconfigurable component type named +name+ whose
    #  instances are creating executing +ruby_block+.
    def reconf(name,&ruby_block)
        # puts "reconf with ruby_block=#{ruby_block}"
        return ReconfT.new(name,&ruby_block)
    end




    ## 
    # Describes a high-level reconfigurable component instance.
    class ReconfI
        # include HDLRuby::High::HScope_missing
        include HDLRuby::High::Hmissing

        # The name of the reconfigurable component instance.
        attr_reader :name

        # The namespace associated with the current execution when
        # building a reconfigurable component, its reader or its writer.
        attr_reader :namespace

        # The instance representing the reconfigurable component.
        attr_reader :instance

        ## Creates a new reconfigurable component instance with +name+ built
        #  from +ruby_block+.
        def initialize(name,&ruby_block)
            # Check and set the name
            @name = name.to_sym

            # Sets the block for building:
            @ruby_block = ruby_block

            # Create the namespace for building the reconfigurable component.
            @namespace = Namespace.new(self)
            # # Make it give access to the internal of the class.
            # @namespace.add_method(:each_input, &method(:each_input))

            # Initialize the set of systems that can be used for this
            # component.
            @systemTs = []

            # Initialize the interface of the component.
            @inputs  = []
            @outputs = []
            @inouts  = []

            # Initialize the switch procedure to nil: it must be defined.
            @switcher_proc = nil
            # Initialize the reconfiguration index: it is defined when
            # building the reconfigurable object.
            @index = nil

            # Gives access to the reconfigurable component by registering
            # its name.
            obj = self
            HDLRuby::High.space_reg(@name) { obj }
        end

        ## Builds the reconfigurable component with systems types from
        #  +systems+
        def build(*systemTs)
            # Checks and sets the first system.
            if systemTs.empty? then
                raise "No system given for reconfiguble component: #{name}"
            end

            unless systemTs[0].is_a?(SystemT) then
                raise "Invalid object for a systemT: #{systems[0].class}"
            end
            # Set the default main systemT as the first one.
            @main = self.add_system(systemTs[0])

            # Sets the interface from the first system
            expanded = @main.expand(:"")
            expanded.each_input  {|sig| @inputs  << sig.clone }
            expanded.each_output {|sig| @outputs << sig.clone }
            expanded.each_inout  {|sig| @inouts  << sig.clone }

            # Add the other systems.
            systemTs[1..-1].each { |systemT| self.add_system(systemT) }

            # Generate the name and the size of the reconfiguration index
            # signal.
            index_name = HDLRuby.uniq_name
            index_size = systemTs.size.width
            index_ref  = nil # The reference to the signal, will be set
                             # in the context of the current system.

            # Builds the reconfigurable component.
            ruby_block = @ruby_block
            HDLRuby::High.space_push(@namespace)
            HDLRuby::High.top_user.instance_eval do
                # Generate the index
                index_ref = [index_size].inner(index_name)
            end
            HDLRuby::High.top_user.instance_eval(&ruby_block)
            HDLRuby::High.space_pop
            
            # Set the index signal.
            @index = index_ref

            # Builds the system instance.
            # Creates its name.
            name = HDLRuby.uniq_name
            # Make the instantiation of the main system.
            @instance = @main.instantiate(name)
            # Adds the other possible systems.
            @systemTs.each do |systemT|
                unless systemT == @main
                    systemT = systemT.expand(systemT.name.to_s + ":rT")
                    @instance.add_systemT(systemT)
                end
            end
        end
        alias_method :call, :build

        # The methods for defining the reconfigurable component.
        
        ## Adds system +systemT+.
        def add_system(systemT)
            # Checks the system.
            unless systemT.is_a?(SystemT) then
                raise "Invalid object for a systemT: #{systemT.class}"
            end
           
            # Expand the system to add to know the inputs.
            expanded = systemT.expand(:"")

            # Check its interface if it is not the firs system.
            unless @systemTs.empty? then
                expanded.each_input.with_index do |sig,idx|
                    unless sig.eql?(@inputs[idx]) then
                        raise "Invalid input signal ##{idx} for system " +
                            "#{systemT.name} got #{sig} but "+
                            "expecting: #{@inputs[idx]}"
                    end
                end
                expanded.each_output.with_index do |sig,idx|
                    unless sig.eql?(@outputs[idx]) then
                        raise "Invalid output signal ##{idx} for system " +
                            "#{systemT.name} got #{sig} but "+
                            "expecting: #{@outputs[idx]}"
                    end
                end
                expanded.each_inout.with_index do |sig,idx|
                    unless sig.eql?(@inouts[idx]) then
                        raise "Invalid inout signal ##{idx} for system " +
                            "#{systemT.name} got #{sig} but "+
                            "expecting: #{@inouts[idx]}"
                    end
                end
            end

            # Add the system (not the expanded version!)
            @systemTs << systemT
            systemT
        end

        ## Sets and adds a new main system to be +systemT+.
        def set_main(systemT)
            # puts "set_main with systemT=#{systemT.name}"
            # Add the system if not already present.
            # NOTE: also checks the system.
            systemT = self.add_system(systemT)
            # Set the system to be a main.
            @main = systemT
        end

        ## Iterates on the input signals.
        #
        # Returns an enumerator if no ruby block is given.
        def each_input(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_input) unless ruby_block
            # A ruby block? Apply it on each input signal instance.
            @inputs.each(&ruby_block)
        end

        ## Iterates on the output signals.
        #
        # Returns an enumerator if no ruby block is given.
        def each_output(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_output) unless ruby_block
            # A ruby block? Apply it on each output signal instance.
            @outputs.each(&ruby_block)
        end

        ## Iterates on the inout signals.
        #
        # Returns an enumerator if no ruby block is given.
        def each_inout(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_inout) unless ruby_block
            # A ruby block? Apply it on each inout signal instance.
            @inouts.each(&ruby_block)
        end

        ## Defines the switching command to be +ruby_block+.
        def switcher(&ruby_block)
            @switcher_proc = ruby_block
        end
        
        ## Defines new command +name+ to execute +ruby_block+ for the
        #  channel.
        def command(name,&ruby_block)
            # Ensures name is a symbol.
            name = name.to_sym
            # Sets the new command.
            self.define_singleton_method(name) do
                # Executes the command in the right environment.
                HDLRuby::High.space_push(@namespace)
                res = HDLRuby::High.top_user.instance_exec(&ruby_block)
                HDLRuby::High.space_pop
                res
            end
        end
        
        # For accessing and controlling the reconfiguration state.
        
        ## Gives access to the signal giving the current reconfiguration
        #  index.
        def index
            return @index
        end

        ## Generate the switching code to configuration number +idx+,
        #  and executing the code generated by +ruby_block+ when the
        #  switch is completed.
        def switch(idx,&ruby_block)
            switcher_proc = @switcher_proc
            index = @index
            inputs = @inputs
            outputs = @outputs
            inouts = @inouts
            systemTs = @systemTs
            # Execute the code generating the reader in context.
            HDLRuby::High.space_push(@namespace)
            HDLRuby::High.cur_block.open do
                instance_exec(idx,ruby_block,&switcher_proc)
            end
            HDLRuby::High.space_pop
        end
    end
end





