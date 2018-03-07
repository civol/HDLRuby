require "HDLRuby/hruby_base"
require "HDLRuby/hruby_bstr"

# @deprecated hruby_db.rb (former hruby_low.rb) is deprecated.


warn "hruby_db.rb (former hruby_low.rb) is deprecated."

##
# Low-level libraries for describing digital hardware.        
#######################################################
module HDLRuby::Low

    Base = HDLRuby::Base

    ## 
    # Describes system type.
    class SystemT < Base::SystemT

        # Library of the existing system types.
        SystemTs = { }
        private_constant :SystemTs

        # Get an existing system type by +name+.
        def self.get(name)
            return name if name.is_a?(SystemT)
            return SystemTs[name.to_sym]
        end

        # Creates a new system type named +name+.
        def initialize(name)
            # Initialize the system type structure.
            super(name)
            # Update the library of existing system types.
            # Note: no check is made so an exisiting system type with a same
            # name is overwritten.
            SystemTs[@name] = self
        end
    end

    ##
    # Module bringing low-level properties to types
    module Ltype

        # Library of the existing types.
        Types = { }
        private_constant :Types

        # # Get an existing signal type by +name+.
        # def self.get(name)
        #     return name if name.is_a?(Type)
        #     return Types[name.to_sym]
        # end

        # Ensures initialize registers the type name
        # and adds the get methods to the class
        def self.included(base) # built-in Ruby hook for modules
            base.class_eval do    
                original_method = instance_method(:initialize)
                define_method(:initialize) do |*args, &block|
                    original_method.bind(self).call(*args, &block)
                    # Update the library of existing types.
                    # Note: no check is made so an exisiting type with a same
                    # name is overwritten.
                    Types[@name] = self
                end

                # Get an existing signal type by +name+.
                def self.get(name)
                    # return name if name.is_a?(Type)
                    return name if name.respond_to?(:ltype?)
                    return Types[name.to_sym]
                end
            end
        end

        # Tells ltype has been included.
        def ltype?
            return true
        end
    end


    # ##
    # # Describes a data type.
    # class Type < Base::Type
    #     # The base type
    #     attr_reader :base

    #     # The size in bits
    #     attr_reader :size

    #     # Library of the existing types.
    #     Types = { }
    #     private_constant :Types

    #     # Get an existing signal type by +name+.
    #     def self.get(name)
    #         return name if name.is_a?(Type)
    #         return Types[name.to_sym]
    #     end

    #     # Creates a new type named +name+ based of +base+ and of +size+ bits.
    #     def initialize(name,base,size)
    #         # Initialize the structure of the data type.
    #         super(name)
    #         # Check and set the base.
    #         @base = base.to_sym
    #         # Check and set the size.
    #         @size = size.to_i

    #         # Update the library of existing types.
    #         # Note: no check is made so an exisiting type with a same
    #         # name is overwritten.
    #         Types[@name] = self
    #     end
    # end

    ##
    # Describes a data type.
    class Type < Base::Type
        include Ltype
    end

    # ##
    # # Describes a numeric type.
    # class TypeNumeric < Base::TypeNumeric
    #     include Ltype
    # end

    ##
    # Describes a vector data type.
    class TypeVector < Base::TypeVector

        # Creates a new type vector named +name+ from a +base+ type and with
        # +range+
        def initialize(name,base,range)
            # Ensure base si a HDLRuby::Low type.
            base = Type.get(base)
            # Create the type.
            super(name,base,range)
        end
        
        include Ltype
    end

    ##
    # Describes a signed integer data type.
    class TypeSigned < Base::TypeSigned
        include Ltype
    end

    ##
    # Describes a unsigned integer data type.
    class TypeUnsigned < Base::TypeUnsigned
        include Ltype
    end

    ##
    # Describes a float data type.
    class TypeFloat < Base::TypeFloat
        include Ltype
    end

    # Standard vector types.
    Integer = TypeSigned.new(:integer)
    Natural = TypeUnsigned.new(:natural)
    Bignum  = TypeSigned.new(:bignum,HDLRuby::Infinity..0)
    Real    = TypeFloat.new(:float)





    ##
    # Describes a tuple data type.
    class TypeTuple < Base::TypeTuple
        include Ltype
    end

    ##
    # Describes a structure data type.
    class TypeStruct< Base::TypeStruct
        include Ltype
    end


    ##
    # Describes a behavior.
    class Behavior < Base::Behavior
    end


    ##
    # Describes a timed behavior.
    #
    # NOTE: 
    # * this is the only kind of behavior that can include time statements. 
    # * this kind of behavior is not synthesizable!
    class TimeBehavior < Base::TimeBehavior
    end


    ## 
    # Describes an event.
    class Event < Base::Event
    end


    ## 
    # Describes a block.
    class Block < Base::Block
    end

    # Describes a timed block.
    #
    # NOTE: 
    # * this is the only kind of block that can include time statements. 
    # * this kind of block is not synthesizable!
    class TimeBlock < Base::TimeBlock
    end


    ##
    # Decribes a piece of software code.
    class Code < Base::Code
    end


    ##
    # Describes a signal.
    class SignalI < Base::SignalI
        # Creates a new signal named +name+ typed as +type+.
        def initialize(name,type)
            # Ensures type is from Low::Type
            type = Type.get(type)
            # Initialize the signal structure.
            super(name,type)
        end
    end


    ## 
    # Describes a system instance.
    class SystemI < Base::SystemI

        # Creates a new system instance of system type +systemT+ named +name+.
        def initialize(name, systemT)
            # Ensures systemT is from Low::SystemT
            systemT = SystemT.get(systemT)
            # Initialize the system instance structure.
            super(name,systemT)
        end
    end



    ## 
    # Describes a statement.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Statement < Base::Statement
    end


    # ##
    # # Describes a declare statement.
    # class Declare < Base::Declare
    # end


    ## 
    # Decribes a transmission statement.
    class Transmit < Base::Transmit
    end


    ## 
    # Describes an if statement.
    class If < Base::If
    end


    ## 
    # Describes a case statement.
    class Case < Base::Case
    end


    ##
    # Describes a delay: not synthesizable.
    class Delay < Base::Delay
    end

    ## 
    # Describes a wait delay statement: not synthesizable!
    class TimeWait < Base::TimeWait
    end

    ## 
    # Describes a timed loop statement: not synthesizable!
    class TimeRepeat < Base::TimeRepeat
    end


    ## 
    # Describes a connection.
    #
    # NOTE: eventhough a connection is semantically different from a
    # transmission, it has a common structure. Therefore, it is described
    # as a subclass of a transmit.
    class Connection < Base::Connection
    end



    ## 
    # Describes an expression.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Expression < Base::Expression
    end
    

    ##
    # Describes a value.
    class Value < Base::Value
        # Creates a new value typed as +type+ and containing numeric +content+.
        def initialize(type,content)
            # Ensures type is from Low::Type
            type = Type.get(type)
            # # Ensures the content is valid for low-level hardware.
            # unless content.is_a?(Numeric) or 
            #        content.is_a?(HDLRuby::BitString) then
            #     raise "Invalid type for a value content: #{content.class}."
            # end # NOW CHECKED BY BASE
            # Initialize the value structure.
            super(type,content)
        end
    end


    ##
    # Describes an operation.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Operation < Base::Operation
    end


    ## 
    # Describes an unary operation.
    class Unary < Base::Unary
    end


    ##
    # Describes an binary operation.
    class Binary < Base::Binary
    end


    # ##
    # # Describes a ternary operation.
    # class Ternary < Base::Ternary
    # end

    
    ##
    # Describes a section operation (generalization of the ternary operator).
    #
    # NOTE: choice is using the value of +select+ as an index.
    class Select < Base::Select
    end


    ## 
    # Describes a concatenation expression.
    class Concat < Base::Concat
    end


    ## 
    # Describes a reference expression.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Ref < Base::Ref
    end


    ##
    # Describes reference concatenation.
    class RefConcat < Base::RefConcat
    end


    ## 
    # Describes an index reference.
    class RefIndex < Base::RefIndex
    end


    ## 
    # Describes a range reference.
    class RefRange < Base::RefRange
    end


    ##
    # Describes a name reference.
    class RefName < Base::RefName
    end


    ## 
    # Describe a this reference.
    #
    # This is the current system.
    class RefThis < Base::RefThis
    end


    # # Ensures constants defined is this module are prioritary.
    # # @!visibility private
    # def self.included(base) # :nodoc:
    #     if base.const_defined?(:SignalI) then
    #         base.send(:remove_const,:SignalI)
    #         base.const_set(:SignalI,HDLRuby::Low::Signal)
    #     end
    # end

end
