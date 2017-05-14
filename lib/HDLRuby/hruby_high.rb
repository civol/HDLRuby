require "HDLRuby/hruby_base"
require "HDLRuby/hruby_low"

##
# High-level libraries for describing digital hardware.        
#######################################################
module HDLRuby::High

    Base = HDLRuby::Base
    Low  = HDLRuby::Low

    # Handle the namespaces for accessing the hardware referencing methods.

    # The namespace stack.
    NameSpace = [self]
    private_constant :NameSpace

    # Pushes namespace +obj+.
    def self.space_push(obj)
        NameSpace.push(obj)
    end

    # Pops a namespace.
    def self.space_pop
        if NameSpace.size <= 1 then
            raise "Internal error: cannot pop further namespaces."
        end
        NameSpace.pop
    end

    # Gets the top of the namespace stack.
    def self.space_top
        NameSpace[-1]
    end

    # Registers hardware referencing method +name+ to the current namespace.
    def self.space_reg(name,&block)
        # print "registering #{name} in #{NameSpace[-1]}\n"
        # Register it in the top object of the namespace stack.
        if NameSpace[-1].respond_to?(:define_method) then
            NameSpace[-1].send(:define_method,name.to_sym,&block)
        else
            NameSpace[-1].send(:define_singleton_method,name.to_sym,&block)
        end
    end

    # Looks up and calls method +name+ from the namespace stack with arguments
    # +args+.
    def self.space_call(name,*args)
        # print "space_call with name=#{name}\n"
        # Ensures name is a symbol.
        name = name.to_sym
        # Look from the top of the stack.
        NameSpace.reverse_each do |space|
            if space.respond_to?(name) then
                # The method is found, call it.
                return space.send(name,*args)
            end
        end
        # Not found.
        raise NoMethodError.new("undefined local variable or method `#{name}'.")
    end



    ##
    # Module providing mixin properties to hardware types.
    module HMix
        # Tells this is a hardware type supporting mixins.
        #
        # NOTE: only there for being checked through respond_to?
        def is_hmix?
            return true
        end

        # Mixins hardware types +htypes+.
        def include(*htypes)
            # Initialize the list of mixins hardware types if required.
            @includes ||= []
            # Check and add the hardware types.
            htypes.each do |htype|
                unless htype.respond_to?(:is_hmix?) then
                    raise "Invalid class for mixin: #{htype.class}"
                end
                @includes << htype
            end
        end

        # Mixins hardware types +htypes+ by extension.
        def extend(htypes)
            # Initialize the list of mixins hardware types if required.
            @extends ||= []
            # Check and add the hardware types.
            htypes.each do |htype|
                unless htype.respond_to?(:is_hmix?) then
                    raise "Invalid class for mixin: #{htype.class}"
                end
                @includes << htype
            end
        end
    end


    # Classes describing hardware types.

    ## 
    # Describes a high-level system type.
    class SystemT < Base::SystemT
        High = HDLRuby::High

        include HMix

        ##
        # Creates a new high-level system type named +name+ and inheriting
        # from +mixins+.
        #
        # The proc +block+ is executed when instantiating the system.
        def initialize(name, *mixins, &block)
            # Initialize the system type structure.
            super(name)
            self.include(*mixins)
            unless name.empty? then
                # Named system instance, generate the instantiation command.
                make_instantiater(name,SystemI,:add_systemI,&block)
            end
        end


        # The proc used for instantiating the system type.
        attr_reader :instance_proc
        
        # The instantiation target class.
        attr_reader :instance_class

        # Instantiate the system type to an instance named +i_name+ with
        # possible arguments +args+.
        def instantiate(i_name,*args)
            # Create the eigen type.
            eigen = self.class.new("")
            High.space_push(eigen)
            eigen.instance_eval(*args,&@instance_proc) if @instance_proc
            High.space_pop
            # Create the instance.
            return @instance_class.new(i_name,eigen)
        end

        # Generates the instantiation capabilities including an instantiation
        # method +name+ for hdl-like instantiation, target instantiation as
        # +klass+, added to the calling object with +add_instance+, and
        # whose eigen type is initialized by +block+.
        def make_instantiater(name,klass,add_instance,&block)
            # Set the instanciater.
            @instance_proc = block
            # Set the target instantiation class.
            @instance_class = klass

            # Unnamed types do not have associated access method.
            return if name.empty?

            # Set the hdl-like instantiation method.
            # HDLRuby::High.send(:define_method,name.to_sym) do |i_name,*args|
            #     # Instantiate.
            #     instance = self.instantiate(i_name,*args)
            #     # Add the instance.
            #     binding.receiver.send(add_instance,instance)
            # end
            obj = self # For using the right self within the proc
            High.space_reg(name) do |i_name,*args|
                # Instantiate.
                instance = obj.instantiate(i_name,*args)
                # Add the instance.
                High.space_top.send(add_instance,instance)
            end
        end

        # Missing methods are looked up in the upper level of the namespace.
        def method_missing(m, *args, &block)
            High.space_call(m,*args,&block)
        end

        # Declares high-level untyped input signals named +names+.
        def input(*names)
            names.each do |name|
                self.add_input(Signal.new(name,void))
            end
        end

        # Declares high-level untyped output signals named +names+.
        def output(*names)
            names.each do |name|
                self.add_output(Signal.new(name,void))
            end
        end

        # Declares high-level untyped inout signals named +names+.
        def inout(*names)
            names.each do |name|
                self.add_inout(Signal.new(name,void))
            end
        end

        # Declares high-level untyped inner signals named +names+.
        def inner(*names)
            names.each do |name|
                self.add_inner(Signal.new(name,void))
            end
        end

        # Declares a high-level behavior activated on a list of +events+, and
        # built by executing +block+.
        def behavior(*events, &block)
            # Preprocess the events.
            events.map! do |event|
                event.to_event
            end
            # Create and add the resulting system.
            self.add_behavior(Behavior.new(*events,&block))
        end
    end

    # Methods for declaring system types.

    # Declares a high-level system type named +name+, with +includes+ mixins
    # hardware types and using +block+ for instantiating.
    def system(name, *includes, &block)
        # print "system block=#{block}\n"
        # Creates the resulting system.
        return SystemT.new(name,*includes,&block)
    end
    

    ##
    # Describes a high-level data type.
    #
    # NOTE: by default a type is not specified.
    class Type < Base::Type
        High = HDLRuby::High

        # Type creation.

        # Creates a new type named +name+.
        def initialize(name)
            # Initialize the type structure.
            super(name)

            # Registers the name (if not empty).
            self.register(name) unless name.empty?
        end

        # Sets the +name+.
        def name=(name)
            # Checks and sets the name.
            name = name.to_sym
            if name.empty? then
                raise "Cannot set an empty name."
            end
            @name = name
            # Registers the name.
            self.register(name)
        end

        # Register the +name+ of the type.
        def register(name)
            if self.name.empty? then
                raise "Cannot register with empty name."
            else
                # Sets the hdl-like access to the type.
                obj = self # For using the right self within the proc
                High.space_reg(name) { obj }
            end
        end

        # Creates a new vector type of range +rng+ and with current type as
        # base.
        def [](rng)
            return TypeVector.new(:"",self,rng)
        end

        # Type handling.

        # Tells if the type is specified or not.
        def is_void?
            return self.name == :void
        end

        # Signal creation through the type.

        # Declares high-level input signals named +names+ of the current type.
        def input(*names)
            names.each do |name|
                High.space_top.add_input(Signal.new(name,self))
            end
        end

        # Declares high-level untyped output signals named +names+ of the
        # current type.
        def output(*names)
            names.each do |name|
                High.space_top.add_output(Signal.new(name,self))
            end
        end

        # Declares high-level untyped inout signals named +names+ of the
        # current type.
        def inout(*names)
            names.each do |name|
                High.space_top.add_inout(Signal.new(name,self))
            end
        end

        # Declares high-level untyped inner signals named +names+ of the
        # current type.
        def inner(*names)
            names.each do |name|
                High.space_top.add_inner(Signal.new(name,self))
            end
        end
    end


    ##
    # Describes a type named +name+ extending a +base+ type.
    class TypeExtend < Type
        # The base type.
        attr_reader :base

        # Creates a new type named +name+ extending a +base+ type.
        def initialize(name,base)
            # Initialize the type.
            super(name)
            
            # Checks and set the base.
            unless base.is_a?(Type) then
                raise "Invalid class for a high-level type: #{base.class}."
            end
            @base = base
        end
    end


    ##
    # Describes a vector type.
    class TypeVector < TypeExtend
        # The range of the vector.
        attr_reader :range

        # Creates a new vector type named +name+ from +base+ type and of 
        # range +rng+.
        def initialize(name,base,rng)
            # Initialize the type.
            super(name,base)

            # Check and set the vector-specific attributes.
            if rng.respond_to?(:to_i) then
                # Integer case: convert to a 0..(rng-1) range.
                rng = (rng-1)..0
            elsif
                # Other cases: assume there is a first and a last to create
                # the range.
                rng = rng.first..rng.last
            end
            @range = rng
        end
    end


    ##
    # Describes a hierarchical type.
    class TypeHierarchy < Type
        # Creates a new hierarchical type named +name+ whose hierachy is given
        # by +content+.
        def initialize(name,content)
            # Initialize the type.
            super(name)

            # Check and set the content.
            content = Hash[content]
            @types = content.map do |k,v|
                unless v.is_a?(Type) then
                    raise "Invalid class for a type: #{v.class}"
                end
                [ k.to_sym, v ]
            end.to_h
        end

        # Gets a sub type by +name+.
        def get_type(name)
            return @types[name.to_sym]
        end

        # Iterates over the sub name/type pair.
        #
        # Returns an enumerator if no ruby block is given.
        def each(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each) unless ruby_block
            # A block? Apply it on each input signal instance.
            @types.each(&ruby_block)
        end

        # Iterates over the sub types.
        #
        # Returns an enumerator if no ruby block is given.
        def each_type(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_type) unless ruby_block
            # A block? Apply it on each input signal instance.
            @types.each_value(&ruby_block)
        end

        # Iterates over the sub type names.
        #
        # Returns an enumerator if no ruby block is given.
        def each_name(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_name) unless ruby_block
            # A block? Apply it on each input signal instance.
            @types.each_key(&ruby_block)
        end
    end


    ##
    # Describes a structure type.
    class TypeStruct < TypeHierarchy
    end


    ##
    # Describes an union type.
    class TypeUnion < TypeHierarchy
    end

    ##
    # Describes a type made of a system type.
    class TypeSystem < Type
        # The system type.
        attr_reader :systemT

        # Creates a new type named +name+ made of system type +systemT+.
        def initialize(name,systemT)
            # Initialize the type.
            super(name)

            # Check and set the system type.
            # NOTE: more check are required to ensure the system type can
            # be made a signal type.
            unless systemT.is_a?(SystemT) then
                raise "Invalid class for a system type: #{systemT.class}."
            end
            @systemT = systemT
        end
    end


    
    # Creates the basic types.

    # The void type.
    Type.new(:void)

    # The bit type.
    Type.new(:bit)

    # The signed bit type.
    Type.new(:signed)


    # The type constructors.

    # Creates an unnamed structure type from a +content+.
    def struct(content)
        return TypeStruct.new(:"",content)
    end

    # Creates an unnamed union type from a +content+.
    def union(content)
        return TypeUnion.new(:"",content)
    end

    # Creates type named +name+ and using +block+ for building it.
    def type(name,&block)
        # Builds the type.
        type = HDLRuby::High.space_top.instance_eval(&block)
        # Ensures type is really a type.
        unless type.is_a?(Type) then
            raise "Invalid class for a type: #{type.class}."
        end
        # Name it.
        type.name = name
    end

    # Extends the Hash class for declaring signals of structure types.
    class ::Hash
        # Declares high-level input signals named +names+ of the current type.
        def input(*names)
            names.each do |name|
                HDLRuby::High.space_top.
                    add_input(Signal.new(name,TypeStruct.new(:"",self)))
            end
        end

        # Declares high-level untyped output signals named +names+ of the
        # current type.
        def output(*names)
            names.each do |name|
                HDLRuby::High.space_top.
                    add_output(Signal.new(name,TypeStruct.new(:"",self)))
            end
        end

        # Declares high-level untyped inout signals named +names+ of the
        # current type.
        def inout(*names)
            names.each do |name|
                HDLRuby::High.space_top.
                    add_inout(Signal.new(name,TypeStruct.new(:"",self)))
            end
        end

        # Declares high-level untyped inner signals named +names+ of the
        # current type.
        def inner(*names)
            names.each do |name|
                HDLRuby::High.space_top.
                    add_inner(Signal.new(name,TypeStruct.new(:"",self)))
            end
        end
    end

    # Extends the system type class for converting it to a data type.
    class SystemT
        # Converts the system type to a data type.
        def to_type
            return TypeSystem.new(:"",self)
        end
    end



    # Classes describing harware instances.


    ##
    # Describes a high-level system instance.
    class SystemI < Base::SystemI
        High = HDLRuby::High

        # Creates a new system instance of system type +systemT+ named +name+.
        def initialize(name, systemT)
            # Initialize the system instance structure.
            super(name,systemT)

            # Sets the hdl-like access to the system instance.
            obj = self # For using the right self within the proc
            High.space_reg(name) { obj }
        end
    end


    ## 
    # Describes a high-level statement.
    class Statement
        # Converts to a statement
        #
        # May be redefined in sub classes.
        def to_stmnt
            return self
        end
    end


    ##
    # Module giving high-level expression properties
    module HExpression
        # Converts to an expression.
        #
        # NOTE: to be redefined in case of non-expression class.
        def to_expr
            return self
        end

        # Adds the unary operations generation.
        [:"-@",:"@+",:"!",:"~"].each do |operator|
            define_method(operator) do
                return Unary.new(self.to_expr)
            end
        end

        # Adds the binary operations generation.
        [:"+",:"-",:"*",:"/",:"%",:"**",
         :"&",:"|",:"^",:"<<",:">>",:"&&",:"||",
         :"==",:"<",:">",:"<=",:">="].each do |operator|
            define_method(operator) do |right|
                return Binary.new(self.to_expr,right)
            end
        end
    end


    ##
    # Module giving high-level properties for handling the arrow (<=) operator.
    module HArrow
        High = HDLRuby::High

        # Creates a transmit, or connection with an +expr+.
        #
        # NOTE: it is converted afterward to an expression if required.
        def <=(expr)
            if High.space_top.is_a?(Block) then
                # We are in a block, so generate and add a Transmit.
                High.space_top.
                    add_statement(Transmit.new(self.to_port,expr.to_expr))
            else
                # We are in a system type, so generate and add a Connection.
                High.space_top.
                    add_connection(Connection.new(self.to_port,expr.to_expr))
            end
        end
    end



    ##
    # Describes a high-level unary expression
    class Unary < Base::Unary
        include HExpression
    end


    ##
    # Describes a high-level binary expression
    class Binary < Base::Binary
        include HExpression
    end


    # ##
    # # Describes a high-level ternary expression
    # class Ternary < Base::Ternary
    #     include HExpression
    # end

    ##
    # Describes a section operation (generalization of the ternary operator).
    #
    # NOTE: choice is using the value of +select+ as an index.
    class Select < Base::Select
        include HExpression
    end


    ##
    # Describes z high-level concat expression.
    class Concat < Base::Concat
        include HExpression
    end

    # Extends the Array class for conversion to a high-level expression.
    class ::Array
        include HArrow
        # Converts to a high-level expression.
        def to_expr
            expr = Concat.new
            self.each {|elem| expr.add_expression(elem.to_expr) }
            expr
        end

        # Converts to a high-level port.
        def to_port
            expr = PortConcat.new
            self.each {|elem| expr.add_port(elem.to_port) }
            expr
        end
    end



    ##
    # Describes a high-level value.
    class Value < Base::Value
        include HExpression
    end

    # Extends the Numeric class for conversion to a high-level expression.
    class ::Numeric
        # Converts to a high-level expression.
        def to_expr
            return Value.new(self.class.to_s,self)
        end
    end



    ## 
    # Module giving high-level port properties.
    module HPort
        # Properties of expressions are also required
        def self.included(klass)
            klass.class_eval do
                include HExpression
                include HArrow
            end
        end

        # Converts to a port.
        #
        # NOTE: to be redefined in case of non-port class.
        def to_port
            return self
        end

        # Converts to an event.
        def to_event
            return Event.new(:change,event)
        end

        # Creates an access to elements of range +rng+ of the signal.
        #
        # NOTE: +rng+ can be a single number in which case it is an index.
        def [](rng)
            if rng.respond_to?(:to_i) then
                # Index case
                return PortIndex.new(self.to_port,rng)
            else
                # Range case
                return PortRange.new(self.to_port,rng)
            end
        end
    end


    ##
    # Describes a high-level concat port.
    class PortConcat < Base::PortConcat
        include HPort
    end

    ##
    # Describes a high-level index port.
    class PortIndex < Base::PortIndex
        include HPort
    end

    ##
    # Describes a high-level range port.
    class PortRange < Base::PortRange
        include HPort
    end

    ##
    # Describes a high-level name port.
    class PortName < Base::PortName
        include HPort
    end

    ##
    # Describes a this port.
    class PortThis < Base::PortThis
        include HPort
        
        # The only useful instance of port this.
        This = PortThis.new
    end

    # Gives access to the *this* port.
    def this
        PortThis::This
    end


    ##
    # Describes a high-level event.
    class Event < Base::Event
        # Converts to an event.
        def to_event
            return self
        end
    end


    ## 
    # Decribes a transmission statement.
    class Transmit < Base::Transmit
        High = HDLRuby::High

        # Converts the transmission to a comparison expression.
        #
        # NOTE: required because the <= operator is ambigous and by
        # default produces a Transmit or a Connection.
        def to_expr
            # Remove the transission from the block.
            High.space_top.delete_statement(self)
            # Generate an expression.
            return Binary.new(:<=,self.left,self.right)
        end
    end

    ## 
    # Describes a connection.
    class Connection < Base::Connection
        High = HDLRuby::High

        # Converts the connection to a comparison expression.
        #
        # NOTE: required because the <= operator is ambigous and by
        # default produces a Transmit or a Connection.
        def to_expr
            # Remove the connection from the system type.
            High.space_top.delete_connection(self)
            # Generate an expression.
            return Binary.new(:<=,self.left,self.right)
        end
    end


    ##
    # Describes a high-level signal.
    class Signal < Base::Signal
        High = HDLRuby::High

        include HPort

        # Creates a new signal named +name+ typed as +type+.
        def initialize(name,type)
            # Initialize the type structure.
            super(name,type)

            unless name.empty? then
                # Named signal, set the hdl-like access to the signal.
                obj = self # For using the right self within the proc
                High.space_reg(name) { obj }
            end

            # Hierarchical type allows access to sub ports, so generate
            # the corresponding methods.
            if type.respond_to?(:each_name) then
                type.each_name do |name|
                    self.define_singleton_method(name) do
                        PortName.new(self.to_port,name)
                    end
                end
            end
        end

        # Creates a positive edge event from the signal.
        def posedge
            return Event.new(:posedge,self.to_port)
        end

        # Creates a negative edge event from the signal.
        def negedge
            return Event.new(:negedge,self.to_port)
        end

        # Creates an edge event from the signal.
        def edge
            return Event.new(:edge,self.to_port)
        end

        # Creates a change event from the signal.
        def change
            return Event.new(:change,self.to_port)
        end

        # Converts to a port.
        def to_port
            return PortName.new(this,self.name)
        end

        # Converts to an expression.
        def to_expr
            return self.to_port
        end
    end


    ##
    # Describes a high-level block.
    class Block < Base::Block
        # Creates a new +type+ sort of block.
        def initialize(type)
            # Initialize the block.
            super(type)

            # High-level blocks can include inner signals.
            @inners = {}
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

        # Iterates over the inner signals.
        #
        # Returns an enumerator if no ruby block is given.
        def each_inner(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_inner) unless ruby_block
            # A block? Apply it on each inner signal instance.
            @inners.each_value(&ruby_block)
        end
        alias :each_signal :each_inner

        ## Gets an inner signal by +name+.
        def get_inner(name)
            return @inners[name]
        end
        alias :get_signal :get_inner

        # Declares high-level untyped inner signals named +names+.
        def inner(*names)
            names.each do |name|
                self.add_inner(Signal.new(name,void))
            end
        end

        # Creates and adds a new block typed +type+ built from +block+.
        def add_block(type,&block)
            # Creates and adds the block.
            par_block = Block.new(:par)
            self.add_statement(par_block)
            # Build it by executing block.
            High.space_push(par_block)
            self.instance_eval(&block)
            High.space_pop
        end

        # Creates a new parallel block built from +block+.
        def par(&block)
            self.add_block(:par,&block)
        end

        # Creates a new sequential block built from +block+.
        def seq(&block)
            self.add_block(:seq,&block)
        end

    end


    ##
    # Describes a high-level behavior.
    class Behavior < Base::Behavior
        High = HDLRuby::High

        # Creates a new behavior activated on a list of +events+, and
        # built by executing +block+.
        def initialize(*events,&block)
            # Initialize the behavior
            super()
            # Add the events.
            events.each { |event| self.add_event(event) }
            # Build the behavior with a default parallel block.
            High.space_push(Block.new(:par))
            self.instance_eval(&block)
            High.space_pop
        end
    end




    # Ensures constants defined is this module are prioritary.
    # @!visibility private
    def self.included(base) # :nodoc:
        if base.const_defined?(:Signal) then
            base.send(:remove_const,:Signal)
            base.const_set(:Signal,HDLRuby::High::Signal)
        end
    end

end
