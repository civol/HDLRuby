require "HDLRuby/hruby_base"
require "HDLRuby/hruby_low"

##
# High-level libraries for describing digital hardware.        
#######################################################
module HDLRuby::High

    Base = HDLRuby::Base
    Low  = HDLRuby::Low

    # Some useful constants

    Infinity = +1.0/0.0
    
    # Gets the infinity.
    def infinity
        return HDLRuby::High::Infinity
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
        # The proc +ruby_block+ is executed when instantiating the system.
        def initialize(name, *mixins, &ruby_block)
            # Initialize the system type structure.
            super(name)
            self.include(*mixins)
            unless name.empty? then
                # Named system instance, generate the instantiation command.
                make_instantiater(name,SystemI,:add_systemI,&ruby_block)
            end
        end

        # Opens for extension.
        #
        # NOTE: actually executes +ruby_block+ in the context.
        def open(&ruby_block)
            High.space_push(self)
            High.space_top.instance_eval(&ruby_block)
            High.space_pop
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
            eigen.instance_exec(*args,&@instance_proc) if @instance_proc
            High.space_pop
            # Create the instance.
            return @instance_class.new(i_name,eigen)
        end

        # Generates the instantiation capabilities including an instantiation
        # method +name+ for hdl-like instantiation, target instantiation as
        # +klass+, added to the calling object with +add_instance+, and
        # whose eigen type is initialized by +ruby_block+.
        def make_instantiater(name,klass,add_instance,&ruby_block)
            # Set the instanciater.
            @instance_proc = ruby_block
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
        def method_missing(m, *args, &ruby_block)
            High.space_call(m,*args,&ruby_block)
        end

        # Declares high-level untyped input signals named +names+.
        def input(*names)
            names.each do |name|
                self.add_input(Signal.new(name,void,:input))
            end
        end

        # Declares high-level untyped output signals named +names+.
        def output(*names)
            names.each do |name|
                self.add_output(Signal.new(name,void,:output))
            end
        end

        # Declares high-level untyped inout signals named +names+.
        def inout(*names)
            names.each do |name|
                self.add_inout(Signal.new(name,void,:inout))
            end
        end

        # Declares high-level untyped inner signals named +names+.
        def inner(*names)
            names.each do |name|
                self.add_inner(Signal.new(name,void,:inner))
            end
        end

        # Declares a high-level behavior activated on a list of +events+, and
        # built by executing +ruby_block+.
        def behavior(*events, &ruby_block)
            # Preprocess the events.
            events.map! do |event|
                event.to_event
            end
            # Create and add the resulting behavior.
            self.add_behavior(Behavior.new(*events,&ruby_block))
        end

        # Declares a high-level timed behavior built by executing +ruby_block+.
        def timed(&ruby_block)
            # Create and add the resulting behavior.
            self.add_behavior(TimeBehavior.new(&ruby_block))
        end


        # Creates a new parallel block built from +ruby_block+.
        #
        # This methods first creates a new behavior to put the block in.
        def par(&ruby_block)
            self.behavior do
                par(&ruby_block)
            end
        end

        # Creates a new sequential block built from +ruby_block+.
        #
        # This methods first creates a new behavior to put the block in.
        def seq(&ruby_block)
            self.behavior do
                seq(&ruby_block)
            end
        end
    end

    # Methods for declaring system types.

    # Declares a high-level system type named +name+, with +includes+ mixins
    # hardware types and using +ruby_block+ for instantiating.
    def system(name = :"", *includes, &ruby_block)
        # print "system ruby_block=#{ruby_block}\n"
        # Creates the resulting system.
        return SystemT.new(name,*includes,&ruby_block)
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

        # Type handling: these methods may have to be overriden when 
        # subclassing.

        # Gets the type as left value.
        #
        # NOTE: used for asymetric types like TypeSystemI.
        def left
            # By default self.
            self
        end

        # Gets the type as right value.
        #
        # NOTE: used for asymetric types like TypeSystemI.
        def right
            # By default self.
            self
        end

        # Tells if the type is specified or not.
        def is_void?
            return self.name == :void
        end

        # The widths of the basic types.
        WITHDS = { :bit => 1, :unsigned => 1, :signed => 1,
                   :fixnum => 32, :float => 64, :bignum => High::Infinity }

        # The signs of the basic types.
        SIGNS = { :signed => true, :fixnum => true, :float => true,
                  :bignum => true }
        SIGNS.default = false

        # Gets the bitwidth of the type, nil for undefined.
        #
        # NOTE: must be redefined for specific types.
        def width
            return WIDTHS[self.name]
        end

        # Tells if the type signed, false for unsigned.
        def signed?
            return SIGNS[self.name]
        end

        # Instantiate the type with arguments +args+ if required.
        #
        # NOTE: actually, only TypeSystemT actually require instantiation.
        def instantiate
            self
        end


        # Signal creation through the type.

        # Declares high-level input signals named +names+ of the current type.
        def input(*names)
            names.each do |name|
                High.space_top.add_input(
                    Signal.new(name,self.instantiate,:input))
            end
        end

        # Declares high-level untyped output signals named +names+ of the
        # current type.
        def output(*names)
            names.each do |name|
                High.space_top.add_output(
                    Signal.new(name,self.instantiate,:output))
            end
        end

        # Declares high-level untyped inout signals named +names+ of the
        # current type.
        def inout(*names)
            names.each do |name|
                High.space_top.add_inout(
                    Signal.new(name,self.instantiate,:inout))
            end
        end

        # Declares high-level untyped inner signals named +names+ of the
        # current type.
        def inner(*names)
            names.each do |name|
                High.space_top.add_inner(
                    Signal.new(name,self.instantiate,:inner))
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

        # Type handling: these methods may have to be overriden when 
        # subclassing.

        # Gets the bitwidth of the type, nil for undefined.
        #
        # NOTE: must be redefined for specific types.
        def width
            first = rng.first
            last  = rng.last
            return @base.width * (first-last).abs
        end

        # Tells if the type signed, false for unsigned.
        def signed?
            return @base.signed?
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
        # Type handling: these methods may have to be overriden when 
        # subclassing.

        # Gets the bitwidth of the type, nil for undefined.
        #
        # NOTE: must be redefined for specific types.
        def width
            return @types.reduce(0) {|sum,type| sum + type.width }
        end
    end


    ##
    # Describes an union type.
    class TypeUnion < TypeHierarchy
        # Type handling: these methods may have to be overriden when 
        # subclassing.

        # Gets the bitwidth of the type, nil for undefined.
        #
        # NOTE: must be redefined for specific types.
        def width
            return @types.max{ |type| type.width }.width
        end
    end

    ##
    # Describes a type made of a system type.
    #
    # NOTE: must be instantiated before being used.
    class TypeSystemT < Type
        # The system type.
        attr_reader :systemT

        # Creates a new type named +name+ made of system type +systemT+
        # using signal names of +left_names+ as left values and signal names
        # of +right_names+ as right values.
        def initialize(name,systemT,left_names,right_names)
            # Initialize the type.
            super(name)
            # Check and set the system type.
            unless systemT.is_a?(SystemT) then
                raise "Invalid class for a system type: #{systemT.class}."
            end
            @systemT = systemT

            # Check and set the left and right names.
            @left_names = left_names.map {|name| name.to_sym }
            @right_names = right_names.map {|name| name.to_sym }
        end

        # Instantiate the type with arguments +args+.
        # Returns a new type named +name+ based on a system instance.
        #
        # NOTE: to be called when creating a signal of this type, it
        # will instantiate the embedded system.
        def instantiate(*args)
            # Instantiate the system type and create the type instance
            # from it.
            return TypeSystemI.new(:"",@systemT.instantiate(:"",*args),
                                  @left_names, @right_names)
        end
        alias :call :instantiate
    end


    ##
    # Describes a type made of a system instance.
    class TypeSystemI < TypeHierarchy
        # The system instance.
        attr_reader :systemI

        # Creates a new type named +name+ made of system type +systemI+
        # using signal names of +left_names+ as left values and signal names
        # of +right_names+ as right values.
        def initialize(name,systemI,left_names,right_names)
            # Check and set the system instance.
            unless systemI.is_a?(SystemI) then
                raise "Invalid class for a system type: #{systemI.class}."
            end
            @systemI = systemI

            # Initialize the type: each external signal becomes an
            # element of the corresponding hierarchical type.
            super(name, systemI.each_input.map do |signal|
                            [signal.name, signal.type]
                        end + 
                        systemI.each_output.map do |signal|
                            [signal.name, signal.type]
                        end + 
                        systemI.each_inout.map do |signal|
                            [signal.name, signal.type]
                        end)


            # Check and set the left and right names.
            @left_names = left_names.map {|name| name.to_sym }
            @right_names = right_names.map {|name| name.to_sym }

            # Generates the left-value and the right-value side of the type
            # from the inputs and the outputs of the system.
            @left = struct(@left_names.map do |name|
                signal = @systemI.get_signal(name)
                unless signal then
                    raise "Unkown signal in system #{@systemI.name}: #{name}."
                end
                [name, signal.type]
            end)
            @right = struct(@right_names.map do |name|
                signal = @systemI.get_signal(name)
                unless signal then
                    raise "Unkown signal in system #{@systemI.name}: #{name}."
                end
                [name, signal.type]
            end)
        end


        # Type handling: these methods may have to be overriden when 
        # subclassing.
        
        # Gets the type as left value.
        def left
            return @left
        end

        # Gets the type as right value.
        def right
            return @right
        end

    end



    # The type constructors.

    # Creates an unnamed structure type from a +content+.
    def struct(content)
        return TypeStruct.new(:"",content)
    end

    # Creates an unnamed union type from a +content+.
    def union(content)
        return TypeUnion.new(:"",content)
    end

    # Creates type named +name+ and using +ruby_block+ for building it.
    def type(name,&ruby_block)
        # Builds the type.
        type = HDLRuby::High.space_top.instance_eval(&ruby_block)
        # Ensures type is really a type.
        unless type.is_a?(Type) then
            raise "Invalid class for a type: #{type.class}."
        end
        # Name it.
        type.name = name
        return type
    end


    # Extends the system type class for converting it to a data type.
    class SystemT
        # Converts the system type to a data type using +left+ signals
        # as left values and +right+ signals as right values.
        def to_type(left,right)
            return TypeSystemT.new(:"",self,left,right)
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

        # Opens for extension.
        #
        # NOTE: actually executes +ruby_block+ in the context of the
        #       systemT.
        def open(&ruby_block)
            return self.systemT.open(&ruby_block)
        end
    end


    ## 
    # Describes a high-level if statement.
    class If < Base::If
        High = HDLRuby::High

        # Creates a new if statement with a +condition+ that when met lead
        # to the selection of the block generated by the execution of
        # +ruby_block+.
        def initialize(condition, &ruby_block)
            # Create the yes block.
            yes_block = High.block(:par,&ruby_block)
            # # Built it by executing ruby_block in context.
            # High.space_push(yes_block)
            # High.space_top.instance_eval(&ruby_block)
            # High.space_pop
            # Creates the if statement.
            super(condition,yes_block)
        end

        # Sets the no block generated by the execution of +ruby_block+.
        #
        # No can only be set once.
        def helse(&ruby_block)
            # Create the no block.
            no_block = High.block(:par,&ruby_block)
            # # Built it by executing ruby_block in context.
            # High.space_push(no_block)
            # High.space_top.instance_eval(&ruby_block)
            # High.space_pop
            # Sets the no block.
            self.no = no_block
        end
    end


    ## 
    # Describes a high-level case statement.
    class Case < Base::Case
    end


    ##
    # Describes a high-level time statement.
    class TimeDelay < Base::TimeDelay
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
                return Unary.new(operator,self.to_expr)
            end
        end

        # Adds the binary operations generation.
        [:"+",:"-",:"*",:"/",:"%",:"**",
         :"&",:"|",:"^",:"<<",:">>",:"&&",:"||",
         :"==",:"<",:">",:"<=",:">="].each do |operator|
            define_method(operator) do |right|
                return Binary.new(operator,self.to_expr,right.to_expr)
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
            if High.space_top.is_a?(HDLRuby::Base::Block) then
                # We are in a block, so generate and add a Transmit.
                High.space_top.
                    add_statement(Transmit.new(self.to_ref,expr.to_expr))
            else
                # We are in a system type, so generate and add a Connection.
                High.space_top.
                    add_connection(Connection.new(self.to_ref,expr.to_expr))
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


    ##
    # Describes a high-level value.
    class Value < Base::Value
        include HExpression
    end



    ## 
    # Module giving high-level reference properties.
    module HRef
        # Properties of expressions are also required
        def self.included(klass)
            klass.class_eval do
                include HExpression
                include HArrow
            end
        end

        # Converts to a reference.
        #
        # NOTE: to be redefined in case of non-reference class.
        def to_ref
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
                # Number range: convert it to an expression.
                rng = rng.to_i.to_expr
            end 
            if rng.is_a?(HDLRuby::Base::Expression) then
                # Index case
                return RefIndex.new(self.to_ref,rng)
            else
                # Range case, ensure it is made among expression.
                first = rng.first.to_expr
                last = rng.last.to_expr
                # Abd create the reference.
                return RefRange.new(self.to_ref,first..last)
            end
        end
    end


    ##
    # Describes a high-level concat reference.
    class RefConcat < Base::RefConcat
        include HRef
    end

    ##
    # Describes a high-level index reference.
    class RefIndex < Base::RefIndex
        include HRef
    end

    ##
    # Describes a high-level range reference.
    class RefRange < Base::RefRange
        include HRef
    end

    ##
    # Describes a high-level name reference.
    class RefName < Base::RefName
        include HRef
    end

    ##
    # Describes a this reference.
    class RefThis < Base::RefThis
        High = HDLRuby::High
        include HRef
        
        # The only useful instance of RefThis.
        This = RefThis.new

        # Gets the enclosing system type.
        def system
            return High.cur_systemT
        end

        # Gets the enclosing behavior if any.
        def behavior
            return High.cur_behavior
        end

        # Gets the enclosing block if any.
        def block
            return High.cur_block
        end
    end

    # Gives access to the *this* reference.
    def this
        RefThis::This
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

        include HRef

        # The valid bounding directions.
        DIRS = [ :no, :input, :output, :inout, :inner ]

        # The object the signal is bounded to if any.
        attr_reader :bound

        # The bounding direction.
        attr_reader :dir

        # Creates a new signal named +name+ typed as +type+ and with
        # +dir+ as bounding direction (:no for unbounded).
        #
        # NOTE: +dir+ can be :no, :input, :output, :inout or :inner
        def initialize(name,type,dir)
            # Initialize the type structure.
            super(name,type)

            unless name.empty? then
                # Named signal, set the hdl-like access to the signal.
                obj = self # For using the right self within the proc
                High.space_reg(name) { obj }
            end

            # Hierarchical type allows access to sub references, so generate
            # the corresponding methods.
            if type.respond_to?(:each_name) then
                type.each_name do |name|
                    self.define_singleton_method(name) do
                        RefName.new(self.to_ref,name)
                    end
                end
            end

            # Check and set the bound.
            unless DIRS.include?(dir) then
                raise "Invalid bounding direction: #{dir}."
            end
            @dir = dir
            @bound = High.space_top unless @dir == :no
        end

        # Creates a positive edge event from the signal.
        def posedge
            return Event.new(:posedge,self.to_ref)
        end

        # Creates a negative edge event from the signal.
        def negedge
            return Event.new(:negedge,self.to_ref)
        end

        # Creates an edge event from the signal.
        def edge
            return Event.new(:edge,self.to_ref)
        end

        # Creates a change event from the signal.
        def change
            return Event.new(:change,self.to_ref)
        end

        # Converts to a reference.
        def to_ref
            return RefName.new(this,self.name)
        end

        # Converts to an expression.
        def to_expr
            return self.to_ref
        end
    end


    
    ##
    # Module giving the properties of a high-level block.
    module HBlock
        High = HDLRuby::High

        # Build the block by executing +ruby_block+.
        def build(&ruby_block)
            # High-level blocks can include inner signals.
            @inners = {}
            # Build the block.
            High.space_push(self)
            self.instance_eval(&ruby_block)
            High.space_pop
        end

        # Missing methods are looked up in the upper level of the namespace.
        def method_missing(m, *args, &ruby_block)
            High.space_call(m,*args,&ruby_block)
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
                self.add_inner(Signal.new(name,void,:inner))
            end
        end

        # Creates a block typed +type+ built by executing +ruby_block+.
        def block(type,&ruby_block)
            return High.block(type,&ruby_block)
        end

        # Creates and adds a new block typed +type+ built by
        # executing +ruby_block+.
        def add_block(type,&ruby_block)
            # Creates and adds the block.
            block = block(type,&ruby_block)
            self.add_statement(block)
        end

        # Creates a new parallel block built from +ruby_block+.
        def par(&ruby_block)
            self.add_block(:par,&ruby_block)
        end

        # Creates a new sequential block built from +ruby_block+.
        def seq(&ruby_block)
            self.add_block(:seq,&ruby_block)
        end

        # Creates a new if statement with a +condition+ that when met lead
        # to the selection of +ruby_block+.
        #
        # NOTE: the else part is defined through the helse method.
        def hif(condition,&ruby_block)
            # Creates the if statement.
            self.add_statement(If.new(condition,&ruby_block))
        end

        # Adds a else block to the previous if statement.
        def helse(&ruby_block)
            # Completes the if statement.
            statement = @statements.last
            unless statement.is_a?(If) then
                raise "Error: helse statement without hif (#{statement.class})."
            end
            statement.helse(&ruby_block)
        end
    end


    ##
    # Describes a high-level block.
    class Block < Base::Block
        High = HDLRuby::High

        include High::HBlock

        # Creates a new +type+ sort of block and build it by executing
        # +ruby_block+.
        def initialize(type,&ruby_block)
            # Initialize the block.
            super(type)
            build(&ruby_block)
        end
    end


    # Describes a timed block.
    #
    # NOTE: 
    # * this is the only kind of block that can include time statements. 
    # * this kind of block is not synthesizable!
    class TimeBlock < Base::TimeBlock
        High = HDLRuby::High

        include High::HBlock

        # Creates a new +type+ sort of block and build it by executing
        # +ruby_block+.
        def initialize(type,&ruby_block)
            # Initialize the block.
            super(type)
            build(&ruby_block)
        end
    end

    # Declares a block of type +type+, that can be timed or not depending 
    # on the enclosing object and build it by executing the enclosing
    # +ruby_block+.
    #
    # NOTE: not a method to include since it can only be used with
    # a behavior or a block. Hence set as module method.
    def self.block(type,&ruby_block)
        if space_top.is_a?(TimeBlock) then
            return TimeBlock.new(type,&ruby_block)
        else
            return Block.new(type,&ruby_block)
        end
    end

    ##
    # Describes a high-level behavior.
    class Behavior < Base::Behavior
        High = HDLRuby::High

        # Creates a new behavior activated on a list of +events+, and
        # built by executing +ruby_block+.
        def initialize(*events,&ruby_block)
            # Initialize the behavior
            super()
            # Add the events.
            events.each { |event| self.add_event(event) }
            # Create and add a default par block for the behavior.
            block = block(:par,&ruby_block)
            self.add_block(block)
            # # Build the block by executing the ruby block in context.
            # High.space_push(block)
            # High.space_top.instance_eval(&ruby_block)
            # High.space_pop
        end


        # Creates a block typed +type+ built by executing +ruby_block+.
        def block(type,&ruby_block)
            return High.block(type,&ruby_block)
        end
    end

    ##
    # Describes a high-level timed behavior.
    class TimeBehavior < Base::TimeBehavior
        High = HDLRuby::High

        # Creates a new timed behavior built by executing +ruby_block+.
        def initialize(&ruby_block)
            # Initialize the behavior
            super()
            # Create and add a default par block for the behavior.
            # NOTE: this block is forced to TimeBlock, so do not use
            # block(:par).
            block = TimeBlock.new(:par,&ruby_block)
            self.add_block(block)
            # # Build the block by executing the ruby block in context.
            # High.space_push(block)
            # High.space_top.instance_eval(&ruby_block)
            # High.space_pop
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




    # Handle the namespaces for accessing the hardware referencing methods.

    # The universe, i.e., the top system type.
    Universe = SystemT.new(:"") {}
    # The universe does not have input, output, nor inout.
    class << Universe
        undef_method :input
        undef_method :output
        undef_method :inout
        undef_method :add_input
        undef_method :add_output
        undef_method :add_inout
    end

    # The namespace stack: never empty, the top is a nameless system without
    # input nor output.
    NameSpace = [Universe]
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

    # Gets the enclosing system type if any.
    def self.cur_systemT
        if NameSpace.size <= 1 then
            raise "Not within a system type."
        else
            return NameSpace.reverse_each.find { |elem| elem.is_a?(SystemT) }
        end
    end

    # Gets the enclosing behavior if any.
    def self.cur_behavior
        # Gets the enclosing system type.
        systemT = self.cur_systemT
        # Gets the current behavior from it.
        unless systemT.each_behavior.any? then
            raise "Not within a behavior."
        end
        return systemT.each.reverse_each.first
    end

    # Gets the enclosing block if any.
    def self.cur_block
        if NameSpace[-1].is_a?(Block)
            return NameSpace[-1]
        else
            raise "Not within a block."
        end
    end

    # Registers hardware referencing method +name+ to the current namespace.
    def self.space_reg(name,&ruby_block)
        # print "registering #{name} in #{NameSpace[-1]}\n"
        # Register it in the top object of the namespace stack.
        if NameSpace[-1].respond_to?(:define_method) then
            NameSpace[-1].send(:define_method,name.to_sym,&ruby_block)
        else
            NameSpace[-1].send(:define_singleton_method,name.to_sym,&ruby_block)
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



    
    # Creates the basic types.
    
    # Defines a basic type +name+.
    def self.define_type(name)
        name = name.to_sym
        type = Type.new(name)
        self.send(:define_method,name) { type }
    end

    # The void type.
    define_type :void

    # The bit type.
    define_type :bit

    # The signed bit type.
    define_type :signed

    # The numeric type (for all the Ruby Numeric types).
    define_type :numeric





    # Extends the standard classes for support of HDLRuby.


    # Extends the Numeric class for conversion to a high-level expression.
    class ::Numeric

        # Converts to a high-level expression.
        def to_expr
            return HDLRuby::High::Value.new(numeric,self)
        end

        # Converts to a time statement in picoseconds.
        def ps
            HDLRuby::High.space_top.add_statement(TimeDelay.new(self,:ps))
        end

        # Converts to a time statement in nanoseconds.
        def ns
            HDLRuby::High.space_top.add_statement(TimeDelay.new(self,:ns))
        end

        # Converts to a time statement in milliseconds.
        def ms
            HDLRuby::High.space_top.add_statement(TimeDelay.new(self,:ms))
        end

        # Converts to time statement in seconds.
        def s
            HDLRuby::High.space_top.add_statement(TimeDelay.new(self,:s))
        end

    end


    # Extends the Hash class for declaring signals of structure types.
    class ::Hash
        # Declares high-level input signals named +names+ of the current type.
        def input(*names)
            names.each do |name|
                HDLRuby::High.space_top.
                    add_input(Signal.new(name,TypeStruct.new(:"",self),:input))
            end
        end

        # Declares high-level untyped output signals named +names+ of the
        # current type.
        def output(*names)
            names.each do |name|
                HDLRuby::High.space_top.
                    add_output(Signal.new(name,TypeStruct.new(:"",self),:output))
            end
        end

        # Declares high-level untyped inout signals named +names+ of the
        # current type.
        def inout(*names)
            names.each do |name|
                HDLRuby::High.space_top.
                    add_inout(Signal.new(name,TypeStruct.new(:"",self),:inout))
            end
        end

        # Declares high-level untyped inner signals named +names+ of the
        # current type.
        def inner(*names)
            names.each do |name|
                HDLRuby::High.space_top.
                    add_inner(Signal.new(name,TypeStruct.new(:"",self),:inner))
            end
        end
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

        # Converts to a high-level reference.
        def to_ref
            expr = RefConcat.new
            self.each {|elem| expr.add_ref(elem.to_ref) }
            expr
        end
    end


    # Extends the symbol class for auto declaration of input or output.
    class ::Symbol
        High = HDLRuby::High

        # Converts to a high-level expression.
        def to_expr
            self.to_ref
        end

        # Converts to a high-level reference refering to an unbounded signal.
        def to_ref
            return Signal.new(self,void,:no).to_ref
        end
        alias :+@ :to_ref
    end

end
