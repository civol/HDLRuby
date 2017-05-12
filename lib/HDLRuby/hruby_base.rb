#
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

        # Handling the signals.
        
        # Adds input signal +signal+.
        def add_input(signal)
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

        ## Gets an input signal by +name+.
        def get_input(name)
            return @inputs[name]
        end

        ## Gets an output signal by +name+.
        def get_output(name)
            return @outputs[name]
        end

        ## Gets an inout signal by +name+.
        def get_inout(name)
            return @inouts[name]
        end

        ## Gets an inner signal by +name+.
        def get_inner(name)
            return @inners[name]
        end

        ## Gets a signal by +name+.
        def get_signal(name)
            # Try in the inputs.
            signal = get_input(name)
            return signal if signal
            # Try in the outputs.
            signal = get_output(name)
            return signal if signal
            # Try in the inouts.
            signal = get_inout(name)
            return signal if signal
            # Not found yet, look into the inners.
            return get_inner(name)
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

        ## Gets a system instance by +name+.
        def get_systemI(name)
            return @systemIs[name]
        end

        # Handling the connections.

        # Adds a +connection+.
        def add_connection(connection)
            unless connection.is_a?(Connection)
                raise "Invalid class for a connection: #{connection.class}"
            end
            @connections << connection
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

        # Handling the behaviors.

        # Adds a +behavior+.
        def add_behavior(behavior)
            unless behavior.is_a?(Behavior)
                raise "Invalid class for a behavior: #{behavior.class}"
            end
            @behaviors << behavior
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

        # Creates a new beavior.
        def initialize
            # Initialize the sensibility list.
            @events = []
            # Initialize the block list.
            @blocks = []
        end

        # Handle the sensibility list.

        # Adds an +event+ to the sensibility list.
        def add_event(event)
            unless event.is_a?(Event)
                raise "Invalid class for a event: #{event.class}"
            end
            @events << event
        end

        # Iterates over the events of the sensibility list.
        #
        # Returns an enumerator if no ruby block is given.
        def each_event(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_event) unless ruby_block
            # A block? Apply it on each event.
            @events.each(&ruby_block)
        end

        # Handle the blocks.

        # Adds a +block+.
        #
        # NOTE: TimeBlock is not supported unless for TimeBehavior objects.
        def add_block(block)
            unless block.is_a?(Block)
                raise "Invalid class for a block: #{block.class}"
            end
            if block.is_a?(TimeBlock)
                raise "Timed blocks are not supported in common behaviors."
            end
            @blocks << block
        end

        # Iterates over the blocks.
        #
        # Returns an enumerator if no ruby block is given.
        def each_block(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block) unless ruby_block
            # A block? Apply it on each block.
            @blocks.each(&ruby_block)
        end
    end


    ##
    # Describes a timed behavior.
    #
    # NOTE: 
    # * this is the only kind of behavior that can include time statements. 
    # * this kind of behavior is not synthesizable!
    class TimeBehavior
        # Time behavior do not have other event than time, so deactivate
        # the relevant methods.
        def add_event(event)
            raise "Time behaviors do not have any sensitivity list."
        end

        # Handle the blocks.

        # Adds a +block+.
        # 
        # NOTE: TimeBlock is supported.
        def add_block(block)
            unless block.is_a?(Block)
                raise "Invalid class for a block: #{block.class}"
            end
            @blocks << block
        end
    end


    ## 
    # Describes an event.
    class Event
        # The type of event.
        attr_reader :type

        # The signal of the event.
        attr_reader :signal

        # Creates a new +type+ sort of event on signal +signal+.
        def initialize(type,signal)
            # Check and set the type.
            @type = type.to_sym
            # Check and set the signal.
            unless signal.is_a?(Signal)
                raise "Invalid class for a signal: #{signal.class}"
            end
            @signal = signal
        end
    end


    ## 
    # Describes a block.
    class Block
        # The type of block.
        attr_reader :type

        # Creates a new +type+ sort of block.
        def initialize(type)
            # Check and set the type.
            @type = type.to_sym
            # Initializes the list of statements.
            @statements = []
        end

        # Adds a +statement+.
        #
        # NOTE: Time is not supported unless for TimeBlock objects.
        def add_statement(statement)
            unless statement.is_a?(Statement) then
                raise "Invalid class for a statement: #{statement.class}"
            end
            if statement.is_a?(Time) then
                raise "Timed statements are not supported in common blocks."
            end
            @statements << statement
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
        # @!method each_signalI
        #   @see SystemT#each_signalI
        # @!method get_input
        #   @see SystemT#get_input
        # @!method get_output
        #   @see SystemT#get_output
        # @!method get_inout
        #   @see SystemT#get_inout
        # @!method get_inner
        #   @see SystemT#get_inner
        # @!method get_signalI
        #   @see SystemT#get_signalI
        # @!method each_systemI
        #   @see SystemT#each_systemI
        # @!method get_systemI
        #   @see SystemT#get_systemI
        # @!method each_connection
        #   @see SystemT#each_connection
        # @!method each_behavior
        #   @see SystemT#each_behavior
        def_delegators :@systemT,
                       :each_input, :each_output, :each_inout, :each_inner,
                       # :each_signalI,
                       :each_signal,
                       :get_input, :get_output, :get_inout, :get_inner,
                       # :get_signalI,
                       :get_signal,
                       :each_systemI, :get_systemI,
                       :each_connection, :each_behavior
    end



    ## 
    # Describes a statement.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Statement
    end


    ##
    # Describes a declare statement.
    class Declare < Statement
        # The declared signal instance.
        attr_reader :signal

        # Creates a new statement declaring +signal+.
        def initialize(signal)
            # Check and set the declared signal instance.
            unless signal.is_a?(Signal)
                raise "Invalid class for declaring a signal: #{signal.class}"
            end
            @signal = signal
        end
    end


    ## 
    # Decribes a transmission statement.
    class Transmit < Statement
        
        # The left port.
        attr_reader :left
        
        # The right expression.
        attr_reader :right

        # Creates a new transmission from a +right+ expression to a +left+
        # port.
        def initialize(left,right)
            # Check and set the left port.
            unless left.is_a?(Port)
                raise "Invalid class for a port (left value): #{left.class}"
            end
            @left = left
            # Check and set the right expression.
            unless right.is_a?(Expression)
                raise "Invalid class for an expression (right value): #{right.class}"
            end
            @right = right
        end
    end


    ## 
    # Describes an if statement.
    class If < Statement
        # The condition
        attr_reader :condition

        # The yes and no blocks
        attr_reader :yes, :no

        # Creates a new at statement with a +condition+ and a +yes+ and +no+
        # blocks.
        def initialize(condition, yes, no)
            # Check and set the condition.
            unless condition.is_a?(Expression)
                raise "Invalid class for a condition: #{condition.class}"
            end
            @condition = condition
            # Check and set the yes block.
            unless yes.is_a?(Block)
                raise "Invalid class for a yes block: #{yes.class}"
            end
            @yes = block
            # Check and set the yes block.
            unless no.is_a?(Block)
                raise "Invalid class for a no block: #{no.class}"
            end
            @no = block
        end
    end


    ## 
    # Describes a case statement.
    class Case < Statement
        # The tested value
        attr_reader :condition

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
        # execution of +block+.
        def add_when(match,block)
            # Checks and sets the match.
            unless match.is_a?(Expression)
                raise "Invalid class for a case match: #{match.class}"
            end
            # Checks and sets the block.
            unless block.is_a?(Block)
                raise "Invalid class for a block: #{block.class}"
            end
            @whens << [match,block]
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
    end


    ## 
    # Describes a time statement: not synthesizable!
    class Time < Statement
        # The time unit.
        attr_reader :unit

        # The time value.
        attr_reader :value

        # Creates a new time statement waiting +value+ +unit+ of time.
        def initialize(value,unit)
            # Check and set the value.
            unless value.is_a?(Numeric)
                raise "Invalid class for a value: #{value.class}"
            end
            @value = value
            # Check and set the unit.
            @unit = unit.to_sym
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
    end


    ##
    # Describes a ternary operation.
    class Ternary < Operation
        # The left child.
        attr_reader :left

        # The middle child.
        attr_reader :middle

        # The right child.
        attr_reader :right

        # Creates a new ternary expression applying +operator+ on +left+
        # +middle+ and +right+ children expressions.
        def initialize(operator,left,middle,right)
            # Initialize as a general operation.
            super(operator)
            # Check and set the children.
            unless left.is_a?(Expression)
                raise "Invalid class for an expression: #{left.class}"
            end
            unless middle.is_a?(Expression)
                raise "Invalid class for an expression: #{middle.class}"
            end
            unless right.is_a?(Expression)
                raise "Invalid class for an expression: #{right.class}"
            end
            # @children = [ left, middle, right ]
            @left = left
            @middle = middle
            @right = right
        end
    end


    ## 
    # Describes a concatenation expression.
    class Concat < Expression
        # Creates a new expression concatenation several +expressions+ together.
        def initialize(*expressions)
            # Check and set the expressions.
            expressions.each do |expression|
                unless expression.is_a?(Expression) then
                    raise "Invalid class for an expression: #{expression.class}"
                end
            end
            @expressions = expressions
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
    end


    ## 
    # Describes a port expression.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Port < Expression
    end


    ##
    # Describes port concatenation.
    class PortConcat < Port

        # Creates a new port concatenation several +ports+ together.
        def initialize(*ports)
            # Check and set the ports.
            ports.each do |port|
                unless port.is_a?(Expression) then
                    raise "Invalid class for an port: #{port.class}"
                end
            end
            @ports = ports
        end

        # Iterates over the concatenated ports.
        #
        # Returns an enumerator if no ruby block is given.
        def each_port(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_input) unless ruby_block
            # A block? Apply it on each children.
            @ports.each(&ruby_block)
        end
    end


    ## 
    # Describes a port index.
    class PortIndex < Port
        # The accessed port.
        attr_reader :port

        # The access index.
        attr_reader :index

        # Create a new port index accessing +port+ at +index+.
        def initialize(port,index)
            # Check and set the accessed port.
            unless port.is_a?(Port) then
                raise "Invalid class for a port: #{port.class}."
            end
            @port = port
            # Check and set the index.
            @index = index.to_i
        end
    end


    ## 
    # Describes a port range.
    class PortRange < Port
        # The accessed port.
        attr_reader :port

        # The access range.
        attr_reader :range

        # Create a new port range accessing +port+ at +range+.
        def initialize(port,range)
            # Check and set the accessed port.
            unless port.is_a?(Port) then
                raise "Invalid class for a port: #{port.class}."
            end
            @port = port
            # Check and set the range.
            @range = range.first..range.last
        end
    end


    ##
    # Describes a named port.
    class PortName < Port
        # The accessed port.
        attr_reader :port

        # The access name.
        attr_reader :name

        # Create a new named port accessing +port+ with +name+.
        def initialize(port,name)
            # Check and set the accessed port.
            unless port.is_a?(Port) then
                raise "Invalid class for a port: #{port.class}."
            end
            @port = port
            # Check and set the symbol.
            @name = name.to_sym
        end
    end


    ## 
    # Describe a this port.
    #
    # This is the current system.
    class PortThis < Port 
    end
end
