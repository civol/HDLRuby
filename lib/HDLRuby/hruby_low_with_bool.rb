require "HDLRuby/hruby_error"
require "HDLRuby/hruby_low_mutable"


##
# Provides a new boolean type and converts the comparison and operations
# on it to this new type.
#
# NOTE: * this transformation is a prerequired for supporting target
#         language like VHDL that do not consider boolean to be identical
#         to bit.
#       * Boolean is weak in type promotion, e.g.: boolean & bit = bit
#
########################################################################
module HDLRuby::Low

    # Extend Type with check telling if it is a boolean type.
    class Type
        # Tells if it is a boolean type.
        def boolean?
            return false
        end
    end
    
    
    ##
    # The boolean type leaf.
    class << ( Boolean = Type.new(:bit) )
        include LLeaf
        # Tells if the type fixed point.
        def fixed?
            return true
        end
        # Gets the bitwidth of the type, nil for undefined.
        def width
            1
        end
        # Gets the range of the type.
        def range
            0..0
        end
        # Tells if it is a boolean type.
        def boolean?
            return true
        end
        # # Get the base type, actually self for leaf types.
        # def base
        #     self
        # end
    end


    ## Extends the SystemT class for converting types of comparison and
    #  operations on it to boolean type.
    class SystemT
        # Converts to a variable-compatible system.
        #
        # NOTE: the result is the same systemT.
        def with_boolean!
            self.scope.each_scope_deep do |scope|
                scope.each_connection { |connection| connection.with_boolean! }
                scope.each_behavior   { |behavior|   behavior.with_boolean! }
            end
            return self
        end
    end

    ## Extends the Behaviour class for converting types of comparison and
    #  operations on it to boolean type.
    class Behavior
        # Converts to a variable-compatible system.
        #
        # NOTE: the result is the same Behaviour.
        def with_boolean!
            self.each_statement  { |statement| statement.with_boolean! }
        end
    end

    ## Extends the Statement class for converting types of comparison and
    #  operations on it to boolean type.
    class Statement
        # Converts to a variable-compatible system.
        #
        # NOTE: the result is the same Behaviour.
        def with_boolean!
            self.each_node do |node| 
                if node.is_a?(Expression) && node.boolean? then
                    node.set_type!(HDLRuby::Low::Boolean)
                end
            end
        end
    end

    ## Extends the Expression class for checking if it a boolean expression
    #  or not.
    class Expression
        # Tells if the expression is boolean.
        def boolean?
            return false
        end
    end

    ## Extends the Unary class for checking if it is a boolean expression
    #  or not.
    class Unary
        # Tells if the expression is boolean.
        def boolean?
            return self.child.boolean?
        end
    end

    ## Extends the Binary class for checking if it is a boolean expression
    #  or not.
    class Binary
        # Tells if the expression is boolean.
        def boolean?
            case(self.operator)
            when :==,:!=,:>,:<,:>=,:<= then
                # Comparison, it is a boolean.
                return true
            when :&,:|,:^ then
                # AND, OR or XOR, boolean if both subs are boolean.
                return self.left.boolean? && self.right.boolean?
            else
                # Other cases: not boolean.
                return false
            end
        end
    end

    ## Extends the Select class for checking if it a boolean epression
    #  or not.
    class Select
        # Tells if the expression is boolean.
        def boolean?
            # Boolean if all the choices are boolean.
            return !self.each_choice.any? {|c| !c.boolean? }
        end
    end

end
