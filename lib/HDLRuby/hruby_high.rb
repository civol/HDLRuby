require "HDLRuby/hruby_base"
require "HDLRuby/hruby_low"

#
# High-level libraries for describing digital hardware.        
#######################################################
module HDLRuby::High

    Base = HDLRuby::Base
    Low  = HDLRuby::Low


    ##
    # Module providing high-level features to hardware types.
    module HType
        # The proc used for instantiating the hardware type.
        attr_reader :instance_proc
        
        # The instantiation target class.
        attr_reader :instance_class

        # # Sets the proc for instantiating the hardware type to +block+.
        # def instance_proc=(block)
        #     # Checks and sets the proc.
        #     unless block.is_a?(Proc) then
        #         raise "Invalid class for an instantiation proc: #{block.class}."
        #     end
        #     @instance_proc = block
        # end

        # # Sets the instantiation target class to +klass+.
        # def instance_class=(klass)
        #     # Checks and sets the class.
        #     unless klass.is_a?(Class) then
        #         raise "Invalid class for an instantiation class: #{klass.class}."
        #     end
        #     @instance_class = klass
        # end

        # Instantiate the hardware type to an instance named +i_name+ with
        # possible arguments +args+.
        def instantiate(i_name,*args)
            # Create the eigen type.
            eigen = self.class.new("")
            eigen.instance_eval(*args,&@instance_proc) if @instance_proc
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
            # Set the hdl-like instantiation method.
            HDLRuby::High.send(:define_method,name.to_sym) do |i_name,*args|
                # Instantiate.
                instance = self.instantiate(i_name,*args)
                # Add the instance.
                binding.receiver.send(add_instance,instance)
            end
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
