require "HDLRuby.rb"

#
# High-level libraries for describing digital hardware.        
#######################################################
module HDLRuby::High

    ##
    # Module providing high-level features to hardware types.
    module HType
        # The proc used for instantiating the hardware type.
        attr_reader :instantiater

        # Sets the proc for instantiating the hardware type to +block+.
        def instantiater=(block)
            # Checks and sets the proc.
            unless block.is_a?(Proc)
                raise "Invalid class for an instantiater: #{block.class}."
            end
            @instantiater = instantiater
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


    ## 
    # Describes a high-level system type.
    class SystemT < HDLRuby::Low::SystemT
        include HMix
        include HType
    end


    ##
    # Describes a high-level signal type.
    class SignalT < HDLRuby::Low::SignalT
        include HMix
        include HType
    end


    ##
    # Describes a high-level behavior type.
    #
    # NOTE: behavior types do not support mixins!
    class BehaviorT < HDLRuby::Low::Behavior
        include HType
    end


    ##
    # Describes a high-level data type.
    #
    # NOTE: data types do not support mixins nor instantiation.
    class DataT
    end



    # Methods for declaring type elements.

    # Declares a high-level system type named +name+, with +includes+ mixins
    # hardware types and using +block+ for instantiating.
    def system(name, *includes, &block)
        # Creates the resulting system.
        systemT = SystemT.new(name)
        # Include the mixins.
        systemT.include(*includes)
        # Sets the proc used for instantiating if any.
        systemT.instantiater = block if block
        # Returns the resulting system.
        return systemT
    end

end
