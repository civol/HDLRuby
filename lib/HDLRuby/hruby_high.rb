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
        raise NoMethodError.new("undefined method",name)
    end


    ##
    # Module providing high-level features to hardware types.
    module HType
        High = HDLRuby::High

        # The proc used for instantiating the hardware type.
        attr_reader :instance_proc
        
        # The instantiation target class.
        attr_reader :instance_class

        # Instantiate the hardware type to an instance named +i_name+ with
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
        include HMix
        include HType

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


    # Describes a high-level signal.
    class Signal < Base::Signal
        High = HDLRuby::High

        # Creates a new signal named +name+ typed as +type+.
        def initialize(name,type)
            # Initialize the type structure.
            super(name,type)

            unless name.empty? then
                # Named signal, set the hdl-like access to the signal.
                obj = self # For using the right self within the proc
                High.space_reg(name) { obj }
            end
        end
    end


    ##
    # Describes a high-level behavior.
    class Behavior < Base::Behavior
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
