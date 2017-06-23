##
# Library for describing the basic structures of the hardware component.
#
# NOTE: not meant do be used directly, please @see HDLRuby::High and
# @see HDLRuby::Low
########################################################################
module HDLRuby::Base

    ## 
    # Describes system type.
    class SystemT

        # The name of the system.
        attr_reader :name

        # Creates a new system type named +name+.
        def initialize(name)
            # Set the name as a symbol.
            @name = name.to_sym
            # Initialize the signal instance lists.
            @inputs = {}
            @outputs = {}
            @inouts = {}
            @inners = {}
            # Initialize the system instances list.
            @systemIs = {}
            # Initialize the connections list.
            @connections = []
            # Initialize the behaviors lists.
            @behaviors = []
        end

        # Handling the system instances.

        # Adds system instance +systemI+.
        def add_systemI(systemI)
            # Checks and add the systemI.
            unless systemI.is_a?(SystemI)
                raise "Invalid class for a system instance: #{systemI.class}"
            end
            if @systemIs.has_key?(systemI.name) then
                raise "SystemI #{systemI.name} already present."
            end
            @systemIs[systemI.name] = systemI
        end

        # Iterates over the system instances.
        #
        # Returns an enumerator if no ruby block is given.
        def each_systemI(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_systemI) unless ruby_block
            # A block? Apply it on each system instance.
            @systemIs.each_value(&ruby_block)
        end

        # Gets a system instance by +name+.
        def get_systemI(name)
            return @systemIs[name]
        end

        # Deletes system instance systemI.
        def delete_systemI(systemI)
            @systemIs.delete(systemI.name)
        end

        # Handling the signals.
        
        # Adds input signal +signal+.
        def add_input(signal)
            # print "add_input with signal: #{signal.name}\n"
            # Checks and add the signal.
            unless signal.is_a?(Signal)
                raise "Invalid class for a signal instance: #{signal.class}"
            end
            if @inputs.has_key?(signal.name) then
                raise "Signal #{signal.name} already present."
            end
            @inputs[signal.name] = signal
        end

        # Adds output  signal +signal+.
        def add_output(signal)
            # Checks and add the signal.
            unless signal.is_a?(Signal)
                raise "Invalid class for a signal instance: #{signal.class}"
            end
            if @outputs.has_key?(signal.name) then
                raise "Signal #{signal.name} already present."
            end
            @outputs[signal.name] = signal
        end

        # Adds inout signal +signal+.
        def add_inout(signal)
            # Checks and add the signal.
            unless signal.is_a?(Signal)
                raise "Invalid class for a signal instance: #{signal.class}"
            end
            if @inouts.has_key?(signal.name) then
                raise "Signal #{signal.name} already present."
            end
            @inouts[signal.name] = signal
        end

        # Adds inner signal +signal+.
        def add_inner(signal)
            # Checks and add the signal.
            unless signal.is_a?(Signal)
                raise "Invalid class for a signal instance: #{signal.class}"
            end
            if @inners.has_key?(signal.name) then
                raise "Signal #{signal.name} already present."
            end
            @inners[signal.name] = signal
        end

        # Iterates over the input signals.
        #
        # Returns an enumerator if no ruby block is given.
        def each_input(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_input) unless ruby_block
            # A block? Apply it on each input signal instance.
            @inputs.each_value(&ruby_block)
        end

        # Iterates over the output signals.
        #
        # Returns an enumerator if no ruby block is given.
        def each_output(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_output) unless ruby_block
            # A block? Apply it on each output signal instance.
            @outputs.each_value(&ruby_block)
        end

        # Iterates over the inout signals.
        #
        # Returns an enumerator if no ruby block is given.
        def each_inout(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_inout) unless ruby_block
            # A block? Apply it on each inout signal instance.
            @inouts.each_value(&ruby_block)
        end

        # Iterates over the inner signals.
        #
        # Returns an enumerator if no ruby block is given.
        def each_inner(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_inner) unless ruby_block
            # A block? Apply it on each inner signal instance.
            @inners.each_value(&ruby_block)
        end

        # Iterates over all the signals (input, output, inout, inner).
        #
        # Returns an enumerator if no ruby block is given.
        def each_signal(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_signal) unless ruby_block
            # A block? Apply it on each signal instance.
            @inputs.each_value(&ruby_block)
            @outputs.each_value(&ruby_block)
            @inouts.each_value(&ruby_block)
            @inners.each_value(&ruby_block)
        end

        # Iterates over all the signals of the system type and its system
        # instances.
        def each_signal_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_signal_deep) unless ruby_block
            # A block?
            # First iterate over the current system type's signals.
            self.each_signal(&ruby_block)
            # Then recurse on the system instances.
            self.each_systemI do |systemI|
                systemI.each_signal_deep(&ruby_block)
            end
        end

        ## Gets an input signal by +name+.
        def get_input(name)
            return @inputs[name.to_sym]
        end

        ## Gets an output signal by +name+.
        def get_output(name)
            return @outputs[name.to_sym]
        end

        ## Gets an inout signal by +name+.
        def get_inout(name)
            return @inouts[name.to_sym]
        end

        ## Gets an inner signal by +name+.
        def get_inner(name)
            return @inners[name.to_sym]
        end

        ## Gets a signal by +path+.
        #
        #  NOTE: +path+ can also be a single name or a reference object.
        def get_signal(path)
            path = path.path_each if path.respond_to?(:path_each) # Ref case.
            if path.respond_to?(:each) then
                # Path is iterable: look for the first name.
                path = path.each
                name = path.each.next
                # Maybe it is a system instance.
                systemI = self.get_systemI(name)
                if systemI then
                    # Yes, look for the remaining of the path into the
                    # corresponding system type.
                    return systemI.systemT.get_signal(path)
                else
                    # Maybe it is a signal name.
                    return self.get_signal(name)
                end
            else
                # Path is a single name, look for the signal in the system's
                # Try in the inputs.
                signal = get_input(path)
                return signal if signal
                # Try in the outputs.
                signal = get_output(path)
                return signal if signal
                # Try in the inouts.
                signal = get_inout(path)
                return signal if signal
                # Not found yet, look into the inners.
                return get_inner(path)
            end
        end

        # Deletes input +signal+.
        def delete_input(signal)
            @inputs.delete(signal.name)
        end

        # Deletes output +signal+.
        def delete_output(signal)
            @outputs.delete(signal.name)
        end

        # Deletes inout +signal+.
        def delete_inout(signal)
            @inouts.delete(signal.name)
        end

        # Deletes inner +signal+.
        def delete_inner(signal)
            @inners.delete(signal.name)
        end

        # Handling the connections.

        # Adds a +connection+.
        def add_connection(connection)
            unless connection.is_a?(Connection)
                raise "Invalid class for a connection: #{connection.class}"
            end
            @connections << connection
            connection
        end

        # Iterates over the connections.
        #
        # Returns an enumerator if no ruby block is given.
        def each_connection(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_connection) unless ruby_block
            # A block? Apply it on each connection.
            @connections.each(&ruby_block)
        end

        # Deletes +connection+.
        def delete_connection(connection)
            @connections.delete(connection)
        end

        # Iterates over all the connections of the system type and its system
        # instances.
        def each_connection_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_connection_deep) unless ruby_block
            # A block?
            # First iterate over current system type's connection.
            self.each_connection(&ruby_block)
            # Then recurse on the system instances.
            self.each_systemI do |systemI|
                systemI.each_connection_deep(&ruby_block)
            end
        end

        # Handling the behaviors.

        # Adds a +behavior+.
        def add_behavior(behavior)
            unless behavior.is_a?(Behavior)
                raise "Invalid class for a behavior: #{behavior.class}"
            end
            @behaviors << behavior
            behavior
        end

        # Iterates over the behaviors.
        #
        # Returns an enumerator if no ruby block is given.
        def each_behavior(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_behavior) unless ruby_block
            # A block? Apply it on each behavior.
            @behaviors.each(&ruby_block)
        end

        # Iterates over all the behaviors of the system type and its system
        # instances.
        def each_behavior_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_behavior_deep) unless ruby_block
            # A block?
            # First iterate over current system type's behavior.
            self.each_behavior(&ruby_block)
            # Then recurse on the system instances.
            self.each_systemI do |systemI|
                systemI.each_behavior_deep(&ruby_block)
            end
        end

        # Deletes +behavior+.
        def delete_behavior(behavior)
            @behaviors.delete(behavior)
        end

        # Iterates over all the blocks of the system type and its system
        # instances.
        def each_block_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block_deep) unless ruby_block
            # A block?
            # First apply it on the current's block.
            ruby_block.call(self)
            # Then apply it on each behavior's block deeply.
            self.each_behavior_deep do |behavior|
                behavior.block.each_block_deep(&ruby_block)
            end
        end

        # Iterates over all the stamements of the system type and its system
        # instances.
        def each_statement_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_statement_deep) unless ruby_block
            # A ruby block?
            # Apply it on each block deeply.
            self.each_block_deep do |block|
                block.each_statement_deep(&ruby_block)
            end
        end

        # Iterates over all the statements and connections of the system type
        # and its system instances.
        def each_arrow_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_arrow_deep) unless ruby_block
            # A block?
            # First, apply it on each connection.
            self.each_connection do |connection|
                ruby_block.call(connection)
            end
            # Then recurse over its blocks.
            self.each_behavior do |behavior|
                behavior.each_block_deep(&ruby_block)
            end
            # Finally recurse on its system instances.
            self.each_systemI do |systemI|
                systemI.each_arrow_deep(&ruby_block)
            end
        end

        # Iterates over all the object executed when a specific event is
        # activated (they include the behaviors and the connections).
        #
        # NOTE: the arguments of the ruby block are the object and an enumerator
        # over the set of events it is sensitive to.
        def each_sensitive_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_sensitive_deep) unless ruby_block
            # A block?
            # First iterate over the current system type's connections.
            self.each_connection do |connection|
                ruby_block.call(connection,
                                connection.each_ref_deep.lazy.map do |ref|
                    Event.new(:change,ref)
                end)
            end
            # First iterate over the current system type's behaviors.
            self.each_behavior do |behavior|
                ruby_block.call(behavior,behavior.each_event)
            end
            # Then recurse on the system instances.
            self.each_systemI do |systemI|
                systemI.each_sensitive_deep(&ruby_block)
            end
        end

    end

    
    ##
    # Describes a data type.
    class Type
        # The name of the type
        attr_reader :name

        # Creates a new type named +name+.
        def initialize(name)
            # Check and set the name.
            @name = name.to_sym
        end
    end



    ##
    # Describes a behavior.
    class Behavior

        # # Creates a new behavior.
        # def initialize
        #     # Initialize the sensitivity list.
        #     @events = []
        #     # Initialize the block list.
        #     @blocks = []
        # end

        # The block executed by the behavior.
        attr_reader :block

        # Creates a new behavior executing +block+.
        def initialize(block)
            # Initialize the sensitivity list.
            @events = []
            # Check and set the block.
            unless block.is_a?(Block)
                raise "Invalid class for a block: #{block.class}."
            end
            # Time blocks are only supported in Time Behaviors.
            if block.is_a?(TimeBlock)
                raise "Timed blocks are not supported in common behaviors."
            end
            @block = block
        end

        # Handle the sensitivity list.

        # Adds an +event+ to the sensitivity list.
        def add_event(event)
            unless event.is_a?(Event)
                raise "Invalid class for a event: #{event.class}"
            end
            @events << event
            event
        end

        # Iterates over the events of the sensitivity list.
        #
        # Returns an enumerator if no ruby block is given.
        def each_event(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_event) unless ruby_block
            # A block? Apply it on each event.
            @events.each(&ruby_block)
        end

        # # Handle the blocks.

        # # Adds a +block+.
        # #
        # # NOTE: TimeBlock is not supported unless for TimeBehavior objects.
        # def add_block(block)
        #     unless block.is_a?(Block)
        #         raise "Invalid class for a block: #{block.class}"
        #     end
        #     if block.is_a?(TimeBlock)
        #         raise "Timed blocks are not supported in common behaviors."
        #     end
        #     @blocks << block
        #     block
        # end

        # # Iterates over the blocks.
        # #
        # # Returns an enumerator if no ruby block is given.
        # def each_block(&ruby_block)
        #     # No ruby block? Return an enumerator.
        #     return to_enum(:each_block) unless ruby_block
        #     # A block? Apply it on each block.
        #     @blocks.each(&ruby_block)
        # end
    end


    ##
    # Describes a timed behavior.
    #
    # NOTE: 
    # * this is the only kind of behavior that can include time statements. 
    # * this kind of behavior is not synthesizable!
    class TimeBehavior < Behavior
        # Creates a new time behavior executing +block+.
        def initialize(block)
            # Initialize the sensitivity list.
            @events = []
            # Check and set the block.
            unless block.is_a?(Block)
                raise "Invalid class for a block: #{block.class}."
            end
            # Time blocks are supported here.
            @block = block
        end

        # Time behavior do not have other event than time, so deactivate
        # the relevant methods.
        def add_event(event)
            raise "Time behaviors do not have any sensitivity list."
        end

        # # Handle the blocks.

        # # Adds a +block+.
        # # 
        # # NOTE: TimeBlock is supported.
        # def add_block(block)
        #     unless block.is_a?(Block)
        #         raise "Invalid class for a block: #{block.class}"
        #     end
        #     @blocks << block
        #     block
        # end
    end


    ## 
    # Describes an event.
    class Event
        # The type of event.
        attr_reader :type

        # The reference of the event.
        attr_reader :ref

        # Creates a new +type+ sort of event on signal refered by +ref+.
        def initialize(type,ref)
            # Check and set the type.
            @type = type.to_sym
            # Check and set the reference.
            unless ref.is_a?(Ref)
                raise "Invalid class for a reference: #{ref.class}"
            end
            @ref = ref
        end
    end


    ##
    # Describes a signal.
    class Signal
        
        # The name of the signal
        attr_reader :name

        # The type of the signal
        attr_reader :type

        # Creates a new signal named +name+ typed as +type+.
        def initialize(name,type)
            # Check and set the name.
            @name = name.to_sym
            # Check and set the type.
            if type.is_a?(Type) then
                @type = type
            else
                raise "Invalid class for a type: #{type.class}."
            end
        end
    end


    ## 
    # Describes a system instance.
    class SystemI
        # The name of the instance if any.
        attr_reader :name

        # The instantiated system.
        attr_reader :systemT

        # Creates a new system instance of system type +systemT+ named +name+.
        def initialize(name, systemT)
            # Set the name as a symbol.
            @name = name.to_sym
            # Check and set the systemT.
            if !systemT.is_a?(SystemT) then
                raise "Invalid class for a system type: #{systemT.class}"
            end
            @systemT = systemT
        end

        # Delegate inner accesses to the system type.
        extend Forwardable
        
        # @!method each_input
        #   @see SystemT#each_input
        # @!method each_output
        #   @see SystemT#each_output
        # @!method each_inout
        #   @see SystemT#each_inout
        # @!method each_inner
        #   @see SystemT#each_inner
        # @!method each_signal
        #   @see SystemT#each_signal
        # @!method get_input
        #   @see SystemT#get_input
        # @!method get_output
        #   @see SystemT#get_output
        # @!method get_inout
        #   @see SystemT#get_inout
        # @!method get_inner
        #   @see SystemT#get_inner
        # @!method get_signal
        #   @see SystemT#get_signal
        # @!method each_signal
        #   @see SystemT#each_signal
        # @!method each_signal_deep
        #   @see SystemT#each_signal_deep
        # @!method each_systemI
        #   @see SystemT#each_systemI
        # @!method get_systemI
        #   @see SystemT#get_systemI
        # @!method each_statement_deep
        #   @see SystemT#each_statement_deep
        # @!method each_connection
        #   @see SystemT#each_connection
        # @!method each_connection_deep
        #   @see SystemT#each_connection_deep
        # @!method each_arrow_deep
        #   @see SystemT#each_arrow_deep
        # @!method each_behavior
        #   @see SystemT#each_behavior
        # @!method each_behavior_deep
        #   @see SystemT#each_behavior_deep
        # @!method each_block_deep
        #   @see SystemT#each_block_deep
        # @!method each_sensitive_deep
        #   @see SystemT#each_sensitive_deep
        def_delegators :@systemT,
                       :each_input, :each_output, :each_inout, :each_inner,
                       :each_signal, :each_signal_deep,
                       :get_input, :get_output, :get_inout, :get_inner,
                       :get_signal,
                       :each_systemI, :get_systemI,
                       :each_connection, :each_connection_deep,
                       :each_statement_deep, :each_arrow_deep,
                       :each_behavior, :each_behavior_deep, :each_block_deep,
                       :each_sensitive_deep
    end



    ## 
    # Describes a statement.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Statement
    end


    # ##
    # # Describes a declare statement.
    # class Declare < Statement
    #     # The declared signal instance.
    #     attr_reader :signal

    #     # Creates a new statement declaring +signal+.
    #     def initialize(signal)
    #         # Check and set the declared signal instance.
    #         unless signal.is_a?(Signal)
    #             raise "Invalid class for declaring a signal: #{signal.class}"
    #         end
    #         @signal = signal
    #     end
    # end


    ## 
    # Decribes a transmission statement.
    class Transmit < Statement
        
        # The left reference.
        attr_reader :left
        
        # The right expression.
        attr_reader :right

        # Creates a new transmission from a +right+ expression to a +left+
        # reference.
        def initialize(left,right)
            # Check and set the left reference.
            unless left.is_a?(Ref)
                raise "Invalid class for a reference (left value): #{left.class}"
            end
            @left = left
            # Check and set the right expression.
            unless right.is_a?(Expression)
                raise "Invalid class for an expression (right value): #{right.class}"
            end
            @right = right
        end

        # Iterates over the expression children if any.
        def each_child(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_child) unless ruby_block
            # A block? Apply it on the children.
            ruby_block.call(@left)
            ruby_block.call(@right)
        end
    end


    ## 
    # Describes an if statement.
    class If < Statement
        # The condition
        attr_reader :condition

        # The yes and no statements
        attr_reader :yes, :no

        # Creates a new if statement with a +condition+ and a +yes+ and +no+
        # blocks.
        def initialize(condition, yes, no = nil)
            # Check and set the condition.
            unless condition.is_a?(Expression)
                raise "Invalid class for a condition: #{condition.class}"
            end
            @condition = condition
            # Check and set the yes statement.
            unless yes.is_a?(Statement)
                raise "Invalid class for a statement: #{yes.class}"
            end
            @yes = yes
            # Check and set the yes statement.
            if no and !no.is_a?(Statement)
                raise "Invalid class for a statement: #{no.class}"
            end
            @no = no
        end

        # Sets the no block.
        #
        # No can only be set once.
        def no=(no)
            if @no != nil then
                raise "No already set in if statement."
            end
            # Check and set the yes statement.
            unless no.is_a?(Statement)
                raise "Invalid class for a statement: #{no.class}"
            end
            @no = no
        end

        # Iterates over all the blocks contained in the current block.
        def each_block_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block_deep) unless ruby_block
            # A block?
            # Apply it on the yes and the no blocks.
            self.yes.each_block_deep(&ruby_block)
            self.no.each_block_deep(&ruby_block)
        end
    end


    ## 
    # Describes a case statement.
    class Case < Statement
        # The tested value
        attr_reader :value

        # Creates a new case statement whose excution flow is decided from
        # +value+.
        def initialize(value)
            # Check and set the value.
            unless value.is_a?(Expression)
                raise "Invalid class for a value: #{value.class}"
            end
            @value = value
            # Initialize the match cases.
            @whens = []
        end

        # Adds a possible +match+ for the case's value that lead to the 
        # execution of +statement+.
        def add_when(match,statement)
            # Checks and sets the match.
            unless match.is_a?(Expression)
                raise "Invalid class for a case match: #{match.class}"
            end
            # Checks and sets the statement.
            unless statement.is_a?(Statement)
                raise "Invalid class for a statement: #{statement.class}"
            end
            @whens << [match,block]
            [match,block]
        end

        # Iterates over the match cases.
        #
        # Returns an enumerator if no ruby block is given.
        def each_when(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_when) unless ruby_block
            # A block? Apply it on each when case.
            @whens.each(&ruby_block)
        end

        # Iterates over all the blocks contained in the current block.
        def each_block_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block_deep) unless ruby_block
            # A block?
            # Apply it on each when's block.
            self.each_when do |value,block|
                block.each_block_deep(&ruby_block)
            end
        end
    end


    ##
    # Describes a delay: not synthesizable.
    class Delay
        # The time unit.
        attr_reader :unit

        # The time value.
        attr_reader :value

        # Creates a new delay of +value+ +unit+ of time.
        def initialize(value,unit)
            # Check and set the value.
            unless value.is_a?(Numeric)
                raise "Invalid class for a delay value: #{value.class}."
            end
            @value = value
            # Check and set the unit.
            @unit = unit.to_sym
        end
    end


    ## 
    # Describes a wait statement: not synthesizable!
    class TimeWait < Statement
        # The delay to wait.
        attr_reader :delay

        # Creates a new statement waiting +delay+.
        def initialize(delay)
            # Check and set the delay.
            unless delay.is_a?(Delay)
                raise "Invalid class for a delay: #{delay.class}."
            end
            @delay = delay
        end

    end


    ## 
    # Describes a timed loop statement: not synthesizable!
    class TimeRepeat < Statement
        # The delay until the loop is repeated
        attr_reader :delay

        # The statement to execute.
        attr_reader :statement

        # Creates a new timed loop statement execute in a loop +statement+ until
        # +delay+ has passed.
        def initialize(statement,delay)
            # Check and set the statement.
            unless statement.is_a?(Statement)
                raise "Invalid class for a statement: #{statement.class}."
            end
            @statement = statement

            # Check and set the delay.
            unless delay.is_a?(Delay)
                raise "Invalid class for a delay: #{delay.class}."
            end
            @delay = delay
        end
    end


    ## 
    # Describes a block.
    class Block < Statement
        # The execution mode of the block.
        attr_reader :mode

        # Creates a new +mode+ sort of block.
        def initialize(mode)
            # Check and set the type.
            @mode = mode.to_sym
            # Initializes the list of statements.
            @statements = []
        end

        # Adds a +statement+.
        #
        # NOTE: TimeWait is not supported unless for TimeBlock objects.
        def add_statement(statement)
            unless statement.is_a?(Statement) then
                raise "Invalid class for a statement: #{statement.class}"
            end
            if statement.is_a?(TimeWait) then
                raise "Timed statements are not supported in common blocks."
            end
            @statements << statement
            statement
        end

        # Iterates over the statements.
        #
        # Returns an enumerator if no ruby block is given.
        def each_statement(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_statement) unless ruby_block
            # A block? Apply it on each statement.
            @statements.each(&ruby_block)
        end

        # Deletes +statement+.
        def delete_statement(statement)
            @statements.delete(statement)
        end

        # Iterates over all the blocks contained in the current block.
        def each_block_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block_deep) unless ruby_block
            # A block?
            # Apply it on each statement which contains blocks.
            self.each_statement do |statement|
                if statement.respond_to?(:each_block_deep) then
                    statement.each_block_deep(&ruby_block)
                end
            end
        end

        # Iterates over all the stamements of the block and its sub blocks.
        def each_statement_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_statement_deep) unless ruby_block
            # A block?
            # Apply it on each block deeply.
            self.each_block_deep do |block|
                block.each_statement(&ruby_block)
            end
        end
    end

    # Describes a timed block.
    #
    # NOTE: 
    # * this is the only kind of block that can include time statements. 
    # * this kind of block is not synthesizable!
    class TimeBlock < Block
        # Adds a +statement+.
        # 
        # NOTE: TimeBlock is supported.
        def add_statement(statement)
            unless statement.is_a?(Statement) then
                raise "Invalid class for a statement: #{statement.class}"
            end
            @statements << statement
            statement
        end
    end


    ##
    # Decribes a piece of software code.
    class Code
        ## The type of code.
        attr_reader :code

        # Creates a new piece of +type+ code from +content+.
        def initialize(type,content)
            # Check and set type.
            @type = type.to_sym
            # Set the content.
            @content = content
            # Freeze it to avoid dynamic tempering of the hardware.
            content.freeze
        end
    end


    ## 
    # Describes a connection.
    #
    # NOTE: eventhough a connection is semantically different from a
    # transmission, it has a common structure. Therefore, it is described
    # as a subclass of a transmit.
    class Connection < Transmit
    end



    ## 
    # Describes an expression.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Expression
        # Iterates over the expression children if any.
        def each_child(&ruby_block)
            # By default: no child.
        end

        # Iterates over all the references encountered in the expression.
        #
        # NOTE: do not iterate *inside* the references.
        def each_ref_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_ref_deep) unless ruby_block
            # A block?
            # If the expression is a reference, applies ruby_block on it.
            ruby_block.call(self) if self.is_a?(Ref)
        end
    end

    
    ##
    # Describes a value.
    class Value < Expression

        # The type of value.
        attr_reader :type

        # The content of the value.
        attr_reader :content

        # Creates a new value typed +type+ and containing +content+.
        def initialize(type,content)
            # Check and set the type.
            if type.is_a?(Type) then
                @type = type
            else
                raise "Invalid class for a type: #{type.class}."
            end
            # Sets the content witout check: it depends on the abstraction
            # level.
            @content = content 
        end
    end


    ##
    # Describes an operation.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Operation < Expression
        # The operator of the operation.
        attr_reader :operator

        # Creates a new operation applying +operator+.
        def initialize(operator)
            # Check and set the operator.
            @operator = operator.to_sym
        end
    end


    ## 
    # Describes an unary operation.
    class Unary < Operation
        # The child.
        attr_reader :child

        # Creates a new unary expression applying +operator+ on +child+
        # expression.
        def initialize(operator,child)
            # Initialize as a general operation.
            super(operator)
            # Check and set the child.
            unless child.is_a?(Expression)
                raise "Invalid class for an expression: #{child.class}"
            end
            # @children = [ child ]
            @child = child
        end

        # Iterates over the expression children if any.
        def each_child(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_child) unless ruby_block
            # A block? Apply it on the child.
            ruby_block.call(@child)
        end

        # Iterates over all the references encountered in the expression.
        #
        # NOTE: do not iterate *inside* the references.
        def each_ref_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_ref_deep) unless ruby_block
            # A block?
            # Recurse on the child.
            @child.each_ref_deep(&ruby_block)
        end
    end


    ##
    # Describes an binary operation.
    class Binary < Operation
        # The left child.
        attr_reader :left

        # The right child.
        attr_reader :right

        # Creates a new binary expression applying +operator+ on +left+
        # and +right+ children expressions.
        def initialize(operator,left,right)
            # Initialize as a general operation.
            super(operator)
            # Check and set the children.
            unless left.is_a?(Expression)
                raise "Invalid class for an expression: #{left.class}"
            end
            unless right.is_a?(Expression)
                raise "Invalid class for an expression: #{right.class}"
            end
            # @children = [ left, right ]
            @left = left
            @right = right
        end

        # Iterates over the expression children if any.
        def each_child(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_child) unless ruby_block
            # A block? Apply it on the children.
            ruby_block.call(@left)
            ruby_block.call(@right)
        end

        # Iterates over all the references encountered in the expression.
        #
        # NOTE: do not iterate *inside* the references.
        def each_ref_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_ref_deep) unless ruby_block
            # A block?
            # Recurse on the children.
            left.each_ref_deep(&ruby_block)
            right.each_ref_deep(&ruby_block)
        end
    end


    ##
    # Describes a section operation (generalization of the ternary operator).
    #
    # NOTE: choice is using the value of +select+ as an index.
    class Select < Operation
        # The selection child (connection).
        attr_reader :select

        # Creates a new operator selecting from the value of +select+ one
        # of the +choices+.
        def initialize(select,*choices)
            # Initialize as a general operation.
            super(:"?")
            # Check and set the selection.
            unless select.is_a?(Expression)
                raise "Invalid class for an expression: #{select.class}"
            end
            @select = select
            # Check and set the choices.
            @choices = []
            choices.each do |choice|
                unless choice.is_a?(Expression)
                    raise "Invalid class for an expression: #{choice.class}"
                end
                @choices << choice
            end
        end

        # Iterates over the expression children if any.
        def each_child(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_child) unless ruby_block
            # A block? Apply it on the children.
            ruby_block.call(@select)
            @choices.each(&ruby_block)
        end

        # Iterates over the choices.
        #
        # Returns an enumerator if no ruby block is given.
        def each_choice(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_choice) unless ruby_block
            # A block? Apply it on each choice.
            @choices.each(&ruby_block)
        end

        # Iterates over all the references encountered in the expression.
        #
        # NOTE: do not iterate *inside* the references.
        def each_ref_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_ref_deep) unless ruby_block
            # A block?
            # Recurse on the children.
            self.select.each_ref_deep(&ruby_block)
            self.each_choice do |choice|
                choice.each_ref_deep(&ruby_block)
            end
        end
    end


    ## 
    # Describes a concatenation expression.
    class Concat < Expression
        # Creates a new expression concatenation several +expressions+ together.
        def initialize(*expressions)
            # Initialize the array of expressions that are concatenated.
            @expressions = []
            # Check and add the expressions.
            expressions.each { |expression| self.add_expression(expression) }
        end

        # Adds an +expression+ to concat.
        def add_expression(expression)
            # Check expression.
            unless expression.is_a?(Expression) then
                raise "Invalid class for an expression: #{expression.class}"
            end
            # Add it.
            @expressions << expression
        end

        # Iterates over the concatenated expressions.
        #
        # Returns an enumerator if no ruby block is given.
        def each_expression(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_input) unless ruby_block
            # A block? Apply it on each children.
            @expressions.each(&ruby_block)
        end
        alias :each_child :each_expression
    end


    ## 
    # Describes a reference expression.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Ref < Expression
        # Iterates over the names of the path indicated by the reference.
        #
        # NOTE: this is not a method for iterating over all the names included
        # in the reference. For instance, this method will return nil without
        # iterating if a RefConcat or is met.
        #
        # Returns an enumerator if no ruby block is given.
        def path_each(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:path_each) unless ruby_block
            # A block? Apply it on... nothing by default.
            return nil
        end

        # Iterates over the reference children if any.
        def each_child(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_child) unless ruby_block
            # A block? Apply it on the children: default none.
        end
    end


    ##
    # Describes concatenation reference.
    class RefConcat < Ref

        # Creates a new reference concatenating the references of +refs+
        # together.
        def initialize(*refs)
            # Check and set the refs.
            refs.each do |ref|
                unless ref.is_a?(Expression) then
                    raise "Invalid class for an reference: #{ref.class}"
                end
            end
            @refs = refs
        end

        # Iterates over the concatenated references.
        #
        # Returns an enumerator if no ruby block is given.
        def each_ref(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_input) unless ruby_block
            # A block? Apply it on each children.
            @refs.each(&ruby_block)
        end
        alias :each_child :each_ref
    end


    ## 
    # Describes a index reference.
    class RefIndex < Ref
        # The accessed reference.
        attr_reader :ref

        # The access index.
        attr_reader :index

        # Create a new index reference accessing +ref+ at +index+.
        def initialize(ref,index)
            # Check and set the accessed reference.
            unless ref.is_a?(Ref) then
                raise "Invalid class for a reference: #{ref.class}."
            end
            @ref = ref
            # Check and set the index.
            unless index.is_a?(Expression) then
                raise "Invalid class for an index reference: #{index.class}."
            end
            @index = index
        end

        # Iterates over the names of the path indicated by the reference.
        #
        # Returns an enumerator if no ruby block is given.
        def path_each(&ruby_block)
            # Recurse on the base reference.
            return ref.path_each(&ruby_block)
        end

        # Iterates over the reference children if any.
        def each_child(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_child) unless ruby_block
            # A block? Apply it on the child.
            ruby_block.call(@ref)
        end
    end


    ## 
    # Describes a range reference.
    class RefRange < Ref
        # The accessed reference.
        attr_reader :ref

        # The access range.
        attr_reader :range

        # Create a new range reference accessing +ref+ at +range+.
        def initialize(ref,range)
            # Check and set the accessed reference.
            unless ref.is_a?(Ref) then
                raise "Invalid class for a reference: #{ref.class}."
            end
            @ref = ref
            # Check and set the range.
            first = range.first
            unless first.is_a?(Expression) then
                raise "Invalid class for a range first: #{first.class}."
            end
            last = range.last
            unless last.is_a?(Expression) then
                raise "Invalid class for a range last: #{last.class}."
            end
            @range = first..last
        end

        # Iterates over the names of the path indicated by the reference.
        #
        # Returns an enumerator if no ruby block is given.
        def path_each(&ruby_block)
            # Recurse on the base reference.
            return ref.path_each(&ruby_block)
        end

        # Iterates over the reference children if any.
        def each_child(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_child) unless ruby_block
            # A block? Apply it on the child.
            ruby_block.call(@ref)
        end
    end


    ##
    # Describes a name reference.
    class RefName < Ref
        # The accessed reference.
        attr_reader :ref

        # The access name.
        attr_reader :name

        # Create a new named reference accessing +ref+ with +name+.
        def initialize(ref,name)
            # Check and set the accessed reference.
            unless ref.is_a?(Ref) then
                raise "Invalid class for a reference: #{ref.class}."
            end
            @ref = ref
            # Check and set the symbol.
            @name = name.to_sym
        end

        # Iterates over the names of the path indicated by the reference.
        #
        # Returns an enumerator if no ruby block is given.
        def path_each(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:path_each) unless ruby_block
            # Recurse on the base reference.
            ref.path_each(&ruby_block)
            # Applies the block on the current name.
            ruby_block.call(@name)
        end

        # Iterates over the reference children if any.
        def each_child(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_child) unless ruby_block
            # A block? Apply it on the child.
            ruby_block.call(@ref)
        end
    end


    ## 
    # Describe a this reference.
    #
    # This is the current system.
    class RefThis < Ref 
    end
end
