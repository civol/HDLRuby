require 'HDLRuby'
require 'HDLRuby/hruby_tools'
require 'HDLRuby/hruby_low_mutable'
require 'HDLRuby/hruby_low_with_bool'


module HDLRuby::Low


##
# Converts booleans in assignments to select operators.
# Use for generating VHDL code without type compatibility troubles.
#
########################################################################
    

    class SystemT
        ## Extends the SystemT class with functionality for converting booleans
        #  in assignments to select operators.

        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select!
            self.scope.boolean_in_assign2select!
            return self
        end

    end


    class Scope
        ## Extends the Scope class with functionality for converting booleans
        #  in assignments to select operators.

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


    class Transmit
        ## Extends the Transmit class with functionality for converting booleans
        #  in assignments to select operators.

        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select!
            # Apply on the left value.
            self.set_left!(self.left.boolean_in_assign2select)
            # Apply on the right value.
            self.set_right!(self.right.boolean_in_assign2select)
            return self
        end
    end


    class Print
        ## Extends the Print class with functionality for converting booleans
        #  in assignments to select operators.

        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select!
            # Apply on the arguments.
            self.map_args! { |arg| arg.boolean_in_assign2select }
            return self
        end
    end


    class TimeTerminate
        ## Extends the TimeTerminate class with functionality for converting
        #  booleans in assignments to select operators.

        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select!
            # Nothing to do.
            return self
        end
    end

    
    class If
        ## Extends the If class with functionality for converting booleans
        #  in assignments to select operators.

        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select!
            # No need to apply on condition!
            # # Apply on the condition.
            # self.set_condition!(self.condition.boolean_in_assign2select)
            # Apply on the yes.
            self.yes.boolean_in_assign2select!
            # Apply on the noifs.
            @noifs.map! do |cond,stmnt|
                # No need to apply on condition!
                # [cond.boolean_in_assign2select,stmnt.boolean_in_assign2select!]
                [cond,stmnt.boolean_in_assign2select!]
            end
            # Apply on the no if any.
            self.no.boolean_in_assign2select! if self.no
            return self
        end
    end


    class When
        ## Extends the When class with functionality for converting booleans
        #  in assignments to select operators.

        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select!
            # No need to apply on the match!
            # # Apply on the match.
            # self.set_match!(self.match.boolean_in_assign2select)
            # Apply on the statement.
            self.statement.boolean_in_assign2select!
            return self
        end
    end


    class Case
        ## Extends the Case class with functionality for converting booleans
        #  in assignments to select operators.

        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select!
            # No need to apply on the value!
            # # Apply on the value.
            # self.set_value!(self.value.boolean_in_assign2select)
            # Apply on the whens.
            self.each_when(&:boolean_in_assign2select!)
            # Apply on the default if any.
            self.default.boolean_in_assign2select! if self.default
            return self
        end
    end


    class TimeWait
        ## Extends the TimeWait class with functionality for converting booleans
        #  in assignments to select operators.

        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select!
            # Nothing to do.
            return self
        end
    end


    class TimeRepeat
        ## Extends the TimeRepeat class with functionality for converting
        #  booleans in assignments to setlect operators.

        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select!
            # Simply recurse on the stamtement.
            self.statement.boolean_in_assign2select!
            return self
        end
    end


    class Block
        ## Extends the Block class with functionality for converting booleans
        #  in assignments to select operators.

        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select!
            # Apply on each statement.
            self.each_statement(&:boolean_in_assign2select!)
            return self
        end
    end


    class Value
        ## Extends the Value class with functionality for converting booleans
        #  in assignments to select operators.

        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select
            # Simple clones.
            return self.clone
        end
    end


    class Cast
        ## Extends the Cast class with functionality for converting booleans
        #  in assignments to select operators.

        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select
            # Recurse on the child.
            return Cast.new(self.type,self.child.boolean_in_assign2select)
        end
    end


    class Unary
        ## Extends the Unary class with functionality for converting booleans
        #  in assignments to select operators.


        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select
            # Recurse on the sub node.
            return Unary.new(self.type,self.operator,
                             self.child.boolean_in_assign2select)
            return self
        end
    end


    class Binary
        ## Extends the Binary class with functionality for converting booleans
        #  in assignments to select operators.

        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select
            # Recurse on the sub nodes.
            nleft = self.left.boolean_in_assign2select
            nright = self.right.boolean_in_assign2select
            # Is it a comparison but the parent is not a boolean?
            # or a transmit to a boolean.
            if [:==,:>,:<,:>=,:<=].include?(self.operator) &&
              ( (self.parent.is_a?(Expression) && !self.parent.type.boolean?) ||
                (self.parent.is_a?(Transmit) && !self.parent.left.type.boolean?)) then
                # Yes, create a select.
                nself = Binary.new(self.type,self.operator,nleft,nright)
                # return Select.new(self.type, "?", nself,
                return Select.new(HDLRuby::Low::Bit, "?", nself,
                        # Value.new(self.type,1), Value.new(self.type,0) )
                        Value.new(HDLRuby::Low::Bit,0), 
                        Value.new(HDLRuby::Low::Bit,1) )
                        # Value.new(HDLRuby::Low::Boolean,0),
                        # Value.new(HDLRuby::Low::Boolean,1) )
            else
                # No return it as is.
                # self.set_left!(nleft)
                # self.set_right!(nright)
                # return self
                return Binary.new(self.type,self.operator,nleft,nright)
            end
        end
    end


    class Select
        ## Extends the Select class with functionality for converting booleans
        #  in assignments to select operators.

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


    class Concat
        ## Extends the Concat class with functionality for converting booleans
        #  in assignments to select operators.

        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select
            # Recurse on the sub expressions.
            return Concat.new(self.type,self.each_expression.map do |expr|
                expr.boolean_in_assign2select
            end )
        end
    end


    class RefConcat
        ## Extends the RefConcat class with functionality for converting booleans
        #  in assignments to select operators.

        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select
            # Recurse on the sub references.
            return RefConcat.new(self.type,self.each_expression.map do |expr|
                expr.boolean_in_assign2select
            end )
        end
    end


    class RefIndex
        ## Extends the RefIndex class with functionality for converting booleans
        #  in assignments to select operators.

        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select
            # Recurse on the sub references.
            return RefIndex.new(self.type,
                                self.ref.boolean_in_assign2select,
                                self.index.boolean_in_assign2select)
        end
    end


    class RefRange
        ## Extends the RefRange class with functionality for converting booleans
        #  in assignments to select operators.

        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select
            # Recurse on the sub references.
            return RefRange.new(self.type,
                                self.ref.boolean_in_assign2select,
                                self.range.first.boolean_in_assign2select ..
                                self.range.last.boolean_in_assign2select)
        end
    end


    class RefName
        ## Extends the RefName class with functionality for converting booleans
        #  in assignments to select operators.

        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select
            # Recurse on the sub references.
            return RefName.new(self.type,
                               self.ref.boolean_in_assign2select,
                               self.name)
        end
    end


    class RefThis 
        ## Extends the RefName class with functionality for converting booleans
        #  in assignments to select operators.

        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select
            # Simply clone.
            return self.clone
        end
    end


    class StringE
        ## Extends the StringE class with functionality for converting booleans
        #  in assignments to select operators.


        # Converts booleans in assignments to select operators.
        def boolean_in_assign2select
            # Apply on the content.
            # Apply on the arguments.
            return StringE.new(self.content.clone,*self.each_arg.map do |arg|
                arg.boolean_in_assign2select
            end)
        end
    end
end
