require 'HDLRuby'
require 'HDLRuby/hruby_tools'
require 'HDLRuby/hruby_low_mutable'


module HDLRuby::Low


##
# Converts booleans in assignments to select operators.
# Use for generating VHDL code without type compatibility troubles.
#
########################################################################
    

    ## Extends the SystemT class with functionality for converting booleans
    #  in assignments to select operators.
    class SystemT

        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select!
            self.scope.boolean_in_assign2select!
            return self
        end

    end


    ## Extends the Scope class with functionality for converting booleans
    #  in assignments to select operators.
    class Scope

        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select!
            # Recurse on the sub scopes.
            self.each_scope(&:boolean_in_assign2select!)

            # Apply on the connections.
            self.each_connection(&:boolean_in_assign2select!)

            # Apply on the behaviors.
            self.each_behavior do |behavior|
                behavior.block.boolean_in_assign2select!
            end
            return self
        end
    end


    ## Extends the Transmit class with functionality for converting booleans
    #  in assignments to select operators.
    class Transmit

        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select!
            # Apply on the left value.
            self.set_left!(self.left.boolean_in_assign2select)
            # Apply on the right value.
            self.set_right!(self.right.boolean_in_assign2select)
            return self
        end
    end
    
    ## Extends the If class with functionality for converting booleans
    #  in assignments to select operators.
    class If

        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select!
            # Apply on the condition.
            self.set_condition(self.condition.boolean_in_assign2select)
            # Apply on the yes.
            self.yes.boolean_in_assign2select!
            # Apply on the noifs.
            self.map_noifs! do |cond,stmnt|
                [cond.boolean_in_assign2select,stmnt.boolean_in_assign2select!]
            end
            # Apply on the no if any.
            self.no.boolean_in_assign2select! if self.no
            return self
        end
    end

    ## Extends the When class with functionality for converting booleans
    #  in assignments to select operators.
    class When

        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select!
            # Apply on the match.
            self.set_match!(self.match.boolean_in_assign2select)
            # Apply on the statement.
            self.statement.boolean_in_assign2select!
            return self
        end
    end


    ## Extends the Case class with functionality for converting booleans
    #  in assignments to select operators.
    class Case

        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select!
            # Apply on the value.
            self.set_value!(self.value.boolean_in_assign2select)
            # Apply on the whens.
            self.each_when(&:boolean_in_assign2select!)
            # Apply on the default if any.
            self.default.boolean_in_assign2select!
            return self
        end
    end


    ## Extends the Block class with functionality for converting booleans
    #  in assignments to select operators.
    class Block

        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select!
            # Apply on each statement.
            self.each_statement(&:boolean_in_assign2select!)
            return self
        end
    end


    ## Extends the Value class with functionality for converting booleans
    #  in assignments to select operators.
    class Value
        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select
            # Simple clones.
            return self.clone
        end
    end


    ## Extends the Cast class with functionality for converting booleans
    #  in assignments to select operators.
    class Cast
        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select
            # Recurse on the child.
            return Cast.new(self.type,self.child.boolean_in_assign2select)
        end
    end

    ## Extends the Unary class with functionality for converting booleans
    #  in assignments to select operators.
    class Unary

        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select
            # Recurse on the sub node.
            return Unary.new(self.type,self.operator,
                             self.child.boolean_in_assign2select)
            return self
        end
    end


    ## Extends the Binary class with functionality for converting booleans
    #  in assignments to select operators.
    class Binary

        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select
            # Recurse on the sub nodes.
            nleft = self.left.boolean_in_assign2select
            nright = self.right.boolean_in_assign2select
            # Is it a comparison.
            if [:==,:>,:<,:>=,:<=].include?(self.operator) then
                # Yes, create a select.
                nself = Binary.new(self.type,self.operator,nleft,nright)
                return Select.new(self.type, "?", nself,
                        Value.new(self.type,1), Value.new(self.type,0) )
            else
                # No return it as is.
                self.set_left!(nleft)
                self.set_right!(nright)
                return self
            end
        end
    end


    ## Extends the Select class with functionality for converting booleans
    #  in assignments to select operators.
    class Select

        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select
            # Recurse on the sub node.
            return Select.new(self.type,"?", 
                              self.select.boolean_in_assign2select,
                              *self.each_choice.map do |choice|
                                  choice.boolean_in_assign2select
                              end )
            return self
        end
    end


    ## Extends the Concat class with functionality for converting booleans
    #  in assignments to select operators.
    class Concat
        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select
            # Recurse on the sub expressions.
            return Concat.new(self.type,self.map_expression do |expr|
                expr.boolean_in_assign2select
            end )
        end
    end


    ## Extends the Ref class with functionality for converting booleans
    #  in assignments to select operators.
    class RefConcat
        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select
            # Recurse on the sub references.
            return RefConcat.new(self.type,self.each_expression.map do |expr|
                expr.boolean_in_assign2select
            end )
        end
    end


    ## Extends the RefIndex class with functionality for converting booleans
    #  in assignments to select operators.
    class RefIndex
        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select
            # Recurse on the sub references.
            return RefIndex.new(self.type,
                                self.ref.boolean_in_assign2select,
                                self.index.boolean_in_assign2select)
        end
    end


    ## Extends the RefRange class with functionality for converting booleans
    #  in assignments to select operators.
    class RefRange
        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select
            # Recurse on the sub references.
            return RefRange.new(self.type,
                                self.ref.boolean_in_assign2select,
                                self.range.first.boolean_in_assign2select ..
                                self.range.last.boolean_in_assign2select)
        end
    end


    ## Extends the RefName class with functionality for converting booleans
    #  in assignments to select operators.
    class RefName
        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select
            # Recurse on the sub references.
            return RefName.new(self.type,
                               self.ref.boolean_in_assign2select,
                               self.name)
        end
    end


    ## Extends the RefName class with functionality for converting booleans
    #  in assignments to select operators.
    class RefThis 
        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select
            # Simply clone.
            return self.clone
        end
    end
end
