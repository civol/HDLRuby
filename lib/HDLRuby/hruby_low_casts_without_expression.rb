require 'HDLRuby'
require 'HDLRuby/hruby_tools'
require 'HDLRuby/hruby_low_mutable'
require 'HDLRuby/hruby_low_with_bool'


module HDLRuby::Low


##
# Replace expressions in cast operators with variables.
# Use for generating Verilog code generation since bit extension cannot
# be performed on expression but only on signals. 
#
########################################################################
    

    class SystemT
        ## Extends the SystemT class with functionality for extracting 
        #  expressions from cast.

        # Extracts the expressions from the casts.
        def casts_without_expression!
            self.scope.casts_without_expression!
            return self
        end

    end


    class Scope
        ## Extends the Scope class with functionality for extracting 
        #  expressions from cast.

        # Extracts the expressions from the casts.
        def casts_without_expression!
            # Recurse on the sub scopes.
            self.each_scope(&:casts_without_expression!)

            # Apply on the connections.
            self.each_connection(&:casts_without_expression!)

            # Apply on the behaviors.
            self.each_behavior do |behavior|
                behavior.block.casts_without_expression!
            end
            return self
        end
    end


    class Transmit
        ## Extends the Transmit class with functionality for extracting 
        #  expressions from cast.

        # Extracts the expressions from the casts.
        def casts_without_expression!
            # Apply on the left value.
            self.set_left!(self.left.casts_without_expression!)
            # Apply on the right value.
            self.set_right!(self.right.casts_without_expression!)
            return self
        end
    end


    class Print
        ## Extends the Print class with functionality for extracting 
        #  expressions from cast.

        # Extracts the expressions from the casts.
        def casts_without_expression!
            # Apply on the arguments.
            self.map_args!(&:casts_without_expression!)
            return self
        end
    end

    
    class If
        ## Extends the If class with functionality for extracting 
        #  expressions from cast.

        # Extracts the expressions from the casts.
        def casts_without_expression!
            # Apply on the condition.
            self.set_condition!(self.condition.casts_without_expression!)
            # Apply on the yes.
            self.yes.casts_without_expression!
            # Apply on the noifs.
            @noifs.map! do |cond,stmnt|
                [cond.casts_without_expression!,stmnt.casts_without_expression!]
            end
            # Apply on the no if any.
            self.no.casts_without_expression! if self.no
            return self
        end
    end

    class When
        ## Extends the When class with functionality for extracting 
        #  expressions from cast.

        # Extracts the expressions from the casts.
        def casts_without_expression!
            # Apply on the match.
            self.set_match!(self.match.casts_without_expression!)
            # Apply on the statement.
            self.statement.casts_without_expression!
            return self
        end
    end


    class Case
        ## Extends the Case class with functionality for extracting 
        #  expressions from cast.

        # Extracts the expressions from the casts.
        def casts_without_expression!
            # No need to apply on the value!
            # Apply on the value.
            self.set_value!(self.value.casts_without_expression!)
            # Apply on the whens.
            self.each_when(&:casts_without_expression!)
            # Apply on the default if any.
            self.default.casts_without_expression! if self.default
            return self
        end
    end


    class TimeWait
        ## Extends the TimeWait class with functionality for extracting 
        #  expressions from cast.

        # Extracts the expressions from the casts.
        def casts_without_expression!
            # Nothing to do.
            return self
        end
    end


    class TimeRepeat
        ## Extends the TimeRepeat class with functionality for extracting 
        #  expressions from cast.

        # Extracts the expressions from the casts.
        def casts_without_expression!
            # Simply recurse on the stamtement.
            self.statement.casts_without_expression!
            return self
        end
    end


    class Block
        ## Extends the Block class with functionality for extracting 
        #  expressions from cast.

        # Extracts the expressions from the casts.
        def casts_without_expression!
            # Apply on each statement.
            self.each_statement(&:casts_without_expression!)
            return self
        end
    end


    class Value
        ## Extends the Value class with functionality for extracting 
        #  expressions from cast.

        # Extracts the expressions from the casts.
        def casts_without_expression!
            # # Simple clones.
            # return self.clone
            return self
        end
    end


    class Cast
        ## Extends the Cast class with functionality for extracting 
        #  expressions from cast.

        # Extracts the expressions from the casts.
        def casts_without_expression!
            # Recurse on the child.
            nchild = self.child.casts_without_expression!
            nchild.parent = nil
            # Process the cast.
            unless (nchild.is_a?(Ref)) then
                # Need to extract the child.
                # Create signal holding the child.
                stmnt = self.statement
                if (stmnt.is_a?(Connection)) then
                    # Specific case of connections: need to build
                    # a new block.
                    scop = stmnt.parent
                    scop.delete_connection!(stmnt)
                    stmnt = Transmit.new(stmnt.left.clone, stmnt.right.clone)
                    blk = Block.new(:seq)
                    scop.add_behavior(Behavior.new(blk))
                    blk.add_statement(stmnt)
                else
                    blk = stmnt.block
                end
                name = HDLRuby.uniq_name
                typ = nchild.type
                sig = blk.add_inner(SignalI.new(name,typ))
                # Add a statement assigning the child to the new signal.
                nref = RefName.new(typ,RefThis.new,name)
                nstmnt = Transmit.new(nref,nchild)
                idx = blk.each_statement.find_index(stmnt)
                blk.insert_statement!(idx,nstmnt)
                # Replace the child by a reference to the created
                # signal.
                nchild = nref.clone
            end
            return Cast.new(self.type,nchild)
        end
    end


    class Unary
        ## Extends the Unary class with functionality for extracting 
        #  expressions from cast.

        # Extracts the expressions from the casts.
        def casts_without_expression!
            # # Recurse on the sub node.
            # return Unary.new(self.type,self.operator,
            #                  self.child.casts_without_expression)
            self.set_child!(self.child.casts_without_expression!)
            return self
        end
    end


    class Binary
        ## Extends the Binary class with functionality for extracting 
        #  expressions from cast.

        # Extracts the expressions from the casts.
        def casts_without_expression!
            # # Recurse on the sub nodes.
            # return Binary.new(self.type,self.operator,
            #                   self.left.casts_without_expression,
            #                   self.right.casts_without_expression)
            self.set_left!(self.left.casts_without_expression!)
            self.set_right!(self.right.casts_without_expression!)
            return self
        end
    end

    

    class Select
        ## Extends the Select class with functionality for extracting 
        #  expressions from cast.

        # Extracts the expressions from the casts.
        def casts_without_expression!
            # Recurse on the sub node.
            # return Select.new(self.type,"?", 
            #                   self.select.casts_without_expression,
            #                   *self.each_choice.map do |choice|
            #                       choice.casts_without_expression
            #                   end )
            self.set_select!(self.select.casts_without_expression!)
            self.map_choices! { |choice| choice.casts_without_expression! }
            return self
        end
    end


    class Concat
        ## Extends the Concat class with functionality for converting booleans
        #  in assignments to select operators.

        # Extracts the expressions from the casts.
        def casts_without_expression!
            # Recurse on the sub expressions.
            # return Concat.new(self.type,self.each_expression.map do |expr|
            #     expr.casts_without_expression
            # end )
            self.map_expressions! {|expr| expr.casts_without_expression! }
            return self
        end
    end


    class RefConcat
        ## Extends the RefConcat class with functionality for converting booleans
        #  in assignments to select operators.

        # Extracts the expressions from the casts.
        def casts_without_expression!
            # # Recurse on the sub references.
            # return RefConcat.new(self.type,self.each_expression.map do |expr|
            #     expr.casts_without_expression
            # end )
            self.map_expressions! {|expr| expr.casts_without_expression! }
            return self
        end
    end


    class RefIndex
        ## Extends the RefIndex class with functionality for converting booleans
        #  in assignments to select operators.

        # Extracts the expressions from the casts.
        def casts_without_expression!
            # Recurse on the sub references.
            # return RefIndex.new(self.type,
            #                     self.ref.casts_without_expression,
            #                     self.index.casts_without_expression)
            self.set_ref!(self.ref.casts_without_expression!)
            self.set_index!(self.index.casts_without_expression!)
            return self
        end
    end


    class RefRange
        ## Extends the RefRange class with functionality for converting booleans
        #  in assignments to select operators.

        # Extracts the expressions from the casts.
        def casts_without_expression!
            # Recurse on the sub references.
            # return RefRange.new(self.type,
            #                     self.ref.casts_without_expression,
            #                     self.range.first.casts_without_expression ..
            #                     self.range.last.casts_without_expression)
            self.set_ref!(self.ref.casts_without_expression!)
            self.set_range!(self.range.first.casts_without_expression! ..
                            self.range.last.casts_without_expression!)
            return self
        end
    end


    class RefName
        ## Extends the RefName class with functionality for converting booleans
        #  in assignments to select operators.

        # Extracts the expressions from the casts.
        def casts_without_expression!
            # Recurse on the sub references.
            # return RefName.new(self.type,
            #                    self.ref.casts_without_expression,
            #                    self.name)
            self.set_ref!(self.ref.casts_without_expression!)
            return self
        end
    end


    class RefThis 
        ## Extends the RefThis class with functionality for converting booleans
        #  in assignments to select operators.

        # Extracts the expressions from the casts.
        def casts_without_expression!
            # # Simply clone.
            # return self.clone
            return self
        end
    end


    class StringE
        ## Extends the StringE class with functionality for extracting 
        #  expressions from cast.

        # Extracts the expressions from the casts.
        def casts_without_expression!
            # return StringE.new(self.content,
            #                    *self.each_arg.map(&:casts_without_expression))
            self.map_args! {|arg| arg.casts_without_expression! }
            return self
        end
    end
end
