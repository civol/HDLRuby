#
# Low-level libraries for describing digital hardware.        
#######################################################
module HDLRuby::Low

    # This is too high level
    # ##
    # # Describes a type: base type with a specifier.
    # class Type

    #     # The base type.
    #     attr_reader :base

    #     # The specificier.
    #     attr_reader :specifier

    #     # Creates a new type from a +base+ type and +specifier+ (if any).
    #     def initialize(base, specifier = nil)
    #         # Check and set the base type.
    #         @base = base.to_sym
    #         # Set the specifier.
    #         @specifier = specifier
    #         # Freeze it since a type is not supposed to change.
    #         @specifier.freeze
    #     end
    # end


    ## 
    # Describes system type.
    class SystemT

        # The name of the system.
        attr_reader :name

        # Creates a new system named +name+.
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

        # Handling the signals.

        # Adds input signal instance +signalI+.
        def add_input(signalI)
            # Checks and add the signalI.
            unless signalI.is_a?(SignalI)
                raise "Invalid class for a signal instance: #{signalI.class}"
            end
            if @inputs.has_key?(signalI.name) then
                raise "SignalI #{signalI.name} already present."
            end
            @inputs[signalI.name] = signalI
        end

        # Adds output  signal instance +signalI+.
        def add_output(signalI)
            # Checks and add the signalI.
            unless signalI.is_a?(SignalI)
                raise "Invalid class for a signal instance: #{signalI.class}"
            end
            if @outputs.has_key?(signalI.name) then
                raise "SignalI #{signalI.name} already present."
            end
            @outputs[signalI.name] = signalI
        end

        # Adds inout signal instance +singalI+.
        def add_inout(signalI)
            # Checks and add the signalI.
            unless signalI.is_a?(SignalI)
                raise "Invalid class for a signal instance: #{signalI.class}"
            end
            if @inouts.has_key?(signalI.name) then
                raise "SignalI #{signalI.name} already present."
            end
            @inouts[signalI.name] = signalI
        end

        # Adds inner signal instance +signalI+.
        def add_inner(signalI)
            # Checks and add the signalI.
            unless signalI.is_a?(SignalI)
                raise "Invalid class for a signal instance: #{signalI.class}"
            end
            if @inners.has_key?(signalI.name) then
                raise "SignalI #{signalI.name} already present."
            end
            @inners[signalI.name] = signalI
        end

        # Iterates over the input signal instances.
        #
        # Returns an enumerator if no ruby block is given.
        def each_input(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_input) unless ruby_block
            # A block? Apply it on each input signal instance.
            @inputs.each_value(&ruby_block)
        end

        # Iterates over the output signal instances.
        #
        # Returns an enumerator if no ruby block is given.
        def each_output(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_output) unless ruby_block
            # A block? Apply it on each output signal instance.
            @outputs.each_value(&ruby_block)
        end

        # Iterates over the inout signal instances.
        #
        # Returns an enumerator if no ruby block is given.
        def each_inout(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_inout) unless ruby_block
            # A block? Apply it on each inout signal instance.
            @inouts.each_value(&ruby_block)
        end

        # Iterates over the inner signal instances.
        #
        # Returns an enumerator if no ruby block is given.
        def each_inner(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_inner) unless ruby_block
            # A block? Apply it on each inner signal instance.
            @inners.each_value(&ruby_block)
        end

        # Iterates over all the signal instances (input, output, inout, inner).
        #
        # Returns an enumerator if no ruby block is given.
        def each_signalI(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_signalI) unless ruby_block
            # A block? Apply it on each signal instance.
            @inputs.each_value(&ruby_block)
            @outputs.each_value(&ruby_block)
            @inouts.each_value(&ruby_block)
            @inners.each_value(&ruby_block)
        end

        ## Gets an input by +name+.
        def get_input(name)
            return @inputs[name]
        end

        ## Gets an output by +name+.
        def get_output(name)
            return @outputs[name]
        end

        ## Gets an inout by +name+.
        def get_inout(name)
            return @inouts[name]
        end

        ## Gets an inner by +name+.
        def get_inner(name)
            return @inners[name]
        end

        ## Gets a signal instance by +name+.
        def get_signalI(name)
            # Try in the inputs.
            signalI = get_input(name)
            return signalI if signalI
            # Try in the outputs.
            signalI = get_output(name)
            return signalI if signalI
            # Try in the inouts.
            signalI = get_inout(name)
            return signalI if signalI
            # Not found yet, look into the inners.
            return get_inner(name)
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
    # Describes a signal type.
    class SignalT
    # class SignalT < SystemT # This is too high-level to do that
        
        # The name of the signal
        attr_reader :name

        # The type of the signal
        attr_reader :type

        # The size in bits of the signal
        attr_reader :size

        # Creates a new signal named +name+ typed as +type+ and of +size+ bits.
        def initialize(name,type,size)
            # Check and set the name.
            @name = name.to_sym
            # Check and set the type.
            @type = type.to_sym
            # Check and set the size.
            @size = size.to_i
        end
    end


    ##
    # Describes a behavior.
    class Behavior

        # Creates a new beavior named +name+.
        def initialize(name = "")
            # Set the name as a symbol if any.
            @name = name.to_sym
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
        def add_block(block)
            unless block.is_a?(Block)
                raise "Invalid class for a signal: #{block.class}"
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
    end


    ## 
    # Describes an event.
    class Event
        # The type of event.
        attr_reader :type
        # The signal instance of the event.
        attr_reader :signalI
        
        # Creates a new +type+ sort of event on signal instance +signalI+.
        def initialize(type,signalI)
            # Check and set the type.
            @type = type.to_sym
            # Check and set the signal instance.
            unless signalI.is_a?(SignalI)
                raise "Invalid class for a signal instance: #{signalI.class}"
            end
            @signalI = signalI
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
        def add_statement(statement)
            unless statement.is_a?(Statement)
                raise "Invalid class for a statement: #{statement.class}"
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
    # Describes a signal instance.
    class SignalI
        # The name of the instance if any.
        attr_reader :name

        # The instantiated signal type.
        attr_reader :signalT

        # Creates a new signal instance of +signalT+ named +name+.
        def initialize(signalT, name = "")
            # Check and set the signal type.
            unless signalT.is_a?(SignalT)
                raise "Invalid class for a signal: #{signal.class}"
            end
            @signalT = signalT
            # Set the name as a symbol.
            @name = name.to_sym
        end
    end


    ## 
    # Describes a system instance.
    class SystemI
        # The name of the instance if any.
        attr_reader :name

        # The instantiated system.
        attr_reader :system

        # Creates a new system instance of +system+ named +name+.
        def initialize(system, name = "")
            # Check and set the system.
            unless system.is_a?(SystemT)
                raise "Invalid class for a system: #{system.class}"
            end
            # Set the name as a symbol.
            @name = name.to_sym
        end
    end


    ## 
    # Describes a connection.
    class Connection
        # The expression attached to the connection if any.
        attr_reader :expression

        # Creates a new connection with a possible +expression+ as right value.
        def initialize(expression = nil)
            # Check and set the expression
            if expression != nil then
                unless expression.is_a?(Expression) then
                    raise "Invalid class for an expression: #{expression.class}."
                end
            end
            @expression = expression
            # Initialize the ports.
            @ports = []
        end

        # Handling the access points.

        # Adds a +port+.
        def add_port(port)
            unless port.is_a?(Port)
                raise "Invalid class for a port: #{port.class}"
            end
            @ports << port
        end

        # Iterates over the ports.
        #
        # Returns an enumerator if no ruby block is given.
        def each_port(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_port) unless ruby_block
            # A block? Apply it on each port.
            @ports.each(&ruby_block)
        end

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
        attr_reader :signalI

        # Creates a new statement declaring +signalI+.
        def initialize(signalI)
            # Check and set the declared signal instance.
            unless signalI.is_a?(SignalI)
                raise "Invalid class for declaring a signal instance: #{signal.class}"
            end
            @signalI = signalI
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
        # The yes and no blocks
        attr_reader :yes, :no

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

        # The size in bits of the value
        attr_reader :size

        # The content of the value.
        attr_reader :content

        # Creates a new value typed +type+ and of +size+ bits from a +content+.
        def initialize(type,size,content)
            # Check and set the type.
            @type = type.to_sym
            # Check and set the size.
            @size = size.to_i
            # Check and set the content.
            unless content.is_a?(Numeric) then
                raise "Invalid type for a value content: #{content.class}."
            end
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

        # Iterates over the children of the operation.
        #
        # Returns an enumerator if no ruby block is given.
        def each_children(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_input) unless ruby_block
            # A block? Apply it on each children.
            @children.each(&ruby_block)
        end
    end


    ## 
    # Describes an unary operation.
    class Unary < Operation

        # Creates a new unary expression applying +operator+ on +child+
        # expression.
        def initialize(operator,child)
            # Initialize as a general operation.
            super(operator)
            # Check and set the child.
            unless child.is_a?(Expression)
                raise "Invalid class for an expression: #{child.class}"
            end
            @children = [ child ]
        end

        # Get the child.
        def child
            return @children[0]
        end
    end


    ##
    # Describes an binary operation.
    class Binary < Operation

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
            @children = [ left, right ]
        end

        # Get the left child.
        def left
            return @children[0]
        end

        # Get the right child.
        def right
            return @children[1]
        end
    end


    ##
    # Describes a ternary operation.
    class Ternary < Operation

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
            @children = [ left, middle, right ]
        end

        # Get the left child.
        def left
            return @child[0]
        end

        # Get the middle child.
        def middle
            return @child[1]
        end

        # Get the right child.
        def left
            return @child[2]
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
    class PortIndex < Port
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
