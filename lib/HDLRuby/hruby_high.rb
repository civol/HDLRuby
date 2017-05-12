require "HDLRuby/hruby_base"
require "HDLRuby/hruby_low"

#
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

    # Gets the top of the stack.
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
            High.space_reg(name.to_sym) do |i_name,*args|
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

        # Declares high-level input signals named +names+.
        def input(*names)
            ICIICI
        end

        # Declares high-level output signals named +names+.
        def output(*names)
            ICIICI
        end

        # Declares high-level inout signals named +names+.
        def inout(*names)
            ICIICI
        end

        # Declares high-level inner signals named +names+.
        def signal(*names)
            ICIICI
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
            # Initialize the high-level system type.
            super(name)
            self.include(*mixins)
            # Generate the instantiation command.
            make_instantiater(name,SystemI,:add_systemI,&block)
        end

    end



    # Methods for declaring type elements.

    # Declares a high-level system type named +name+, with +includes+ mixins
    # hardware types and using +block+ for instantiating.
    def system(name, *includes, &block)
        # print "system block=#{block}\n"
        # Creates the resulting system.
        return SystemT.new(name,*includes,&block)
    end


    # Classes describing harware instances.


    ##
    # Describes a high-level system instance.
    class SystemI < Base::SystemI
    end


    # Describes a high-level signal.
    class Signal < Base::Signal
    end


    ##
    # Describes a high-level behavior.
    class Behavior < Base::Behavior
    end


    # Ensures constants defined is this module are prioritary.
    def self.included(base)
        if base.const_defined?(:Signal) then
            base.send(:remove_const,:Signal)
            base.const_set(:Signal,HDLRuby::Low::Signal)
        end
    end

end
