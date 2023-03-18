require 'set'
require 'HDLRuby'
require 'HDLRuby/hruby_low_mutable'


module HDLRuby::Low


##
# Make explicit all the type conversions and convert the constants accordingly.
#
########################################################################


    class SystemT
        ## Extends the SystemT class with fixing of types and constants.

        # Explicit the types conversions in the system.
        def explicit_types!
            # No direct fix required in the system, recurse on the scope.
            self.scope.explicit_types!
            return self
        end
    end


    class Scope
        ## Extends the Scope class with fixing of types and constants.

        # Explicit the types conversions in the scope.
        def explicit_types!
            # Recurse on the sub scopes.
            self.each_scope(&:explicit_types!)
            # Fix the types of the declarations.
            self.each_inner(&:explicit_types!)
            # Fix the types of the connections.
            self.each_connection(&:explicit_types!)
            # Fix the types of the behaviors.
            self.each_behavior(&:explicit_types!)
            return self
        end
    end


    class Behavior
        ## Extends the Behavior class with fixing of types and constants.

        # Explicit the types conversions in the scope.
        def explicit_types!
            # Fix the types of the block.
            self.block.explicit_types!
            return self
        end
    end

    
    class SignalI
        ## Extends the SignalI class with fixing of types and constants.

        # Explicit the types conversions in the signal.
        def explicit_types!
            # Is there a value?
            value = self.value
            if value then
                # Yes recurse on it.
                self.set_value!(value.explicit_types(self.type))
            end
            # No, nothing to do.
            return self
        end
    end


    class Statement
        ## Extends the Statement class with fixing of types and constants.

        # Explicit the types conversions in the statement.
        def explicit_types!
            raise "Should implement explicit_types! for class #{self.class}."
        end
    end


    class Transmit
        ## Extends the Transmit class with fixing of types and constants.

        # Explicit the types conversions in the statement.
        def explicit_types!
            # Recurse on the left and the right.
            self.set_left!(self.left.explicit_types)
            # The right have to match the left type.
            self.set_right!(self.right.explicit_types(self.left.type))
            return self
        end

    end


    class Print
        ## Extends the Print class with fixing of types and constants.

        # Explicit the types conversions in the statement.
        def explicit_types!
            # Recurse on the arguments.
            self.map_args!(&:explicit_types)
            return self
        end
    end


    class Configure
        ## Extends the Configure class with fixing of types and constants.

        # Explicit the types conversions in the statement.
        def explicit_types!
            # Nothing to do.
            return self
        end
    end


    class TimeTerminate
        ## Extends the TimeTerminate class with fixing of types and constants.

        # Explicit the types conversions in the statement.
        def explicit_types!
            # Nothing to do.
            return self
        end
    end



    
    class If
        ## Extends the If class with fixing of types and constants.

        # Explicit the types conversions in the if.
        def explicit_types!
            # Recurse on the condition: it must be a Bit.
            self.set_condition!(self.condition.explicit_types(Bit))
            # Recurse on the yes block.
            self.yes.explicit_types!
            # Recruse on the alternative ifs, the conditions must be Bit.
            self.map_noifs! do |cond,block|
                [ cond.explicit_types(Bit), block.explicit_types! ]
            end
            # Recurse on the no block.
            self.no.explicit_types! if self.no
            return self
        end
    end


    class When
        ## Extends the When class with fixing of types and constants.

        # Explicit the types conversions in the when where +type+ is the
        # type of the selecting value.
        def explicit_types!(type)
            # Recurse on the match, it must be of type.
            self.set_match!(self.match.explicit_types(type))
            # Recurse on the statement.
            self.statement.explicit_types!
            return self
        end
    end


    class Case
        ## Extends the Case class with fixing of types and constants.

        # Explicit the types conversions in the case.
        def explicit_types!
            # Recurse on the value.
            self.set_value!(self.value.explicit_types)
            # Recurse on the whens, the match of each when must be of the
            # type of the value.
            self.each_when { |w| w.explicit_types!(self.value.type) }
            return self
        end
    end


    class TimeWait
        ## Extends the TimeWait class with fixing of types and constants.

        # Explicit the types conversions in the time wait.
        def explicit_types!
            # Nothing to do.
            return self
        end
    end


    class TimeRepeat
        ## Extends the TimeRepeat class with fixing of types and constants.

        # Explicit the types conversions in the time repeat.
        def explicit_types!
            # Recurse on the statement.
            self.statement.explicit_types!
            return self
        end
    end


    class Block
        ## Extends the Block class with fixing of types and constants.

        # Explicit the types conversions in the block.
        def explicit_types!
            # Recurse on the statements.
            self.each_statement(&:explicit_types!)
            return self
        end
    end


    class Connection
        ## Extends the Connection class with fixing of types and constants.

        # Nothing required, Transmit is generated identically.
    end


    class Expression
        ## Extends the Expression class with fixing of types and constants.

        # Explicit the types conversions in the expression where
        # +type+ is the expected type of the condition if any.
        def explicit_types(type = nil)
            raise "Should implement explicit_types for class #{self.class}."
        end
    end


    class Value
        ## Extends the Value class with fixing of types and constants.

        # Explicit the types conversions in the value where
        # +type+ is the expected type of the condition if any.
        def explicit_types(type = nil)
            # Does the type match the value?
            if type && !self.type.eql?(type) then
                # No, update the type of the value.
                return Value.new(type,self.content)
            else
                # yes, return the value as is.
                return self.clone
            end
        end
    end


    class Cast
        ## Extends the Cast class with fixing of types and constants.

        # Explicit the types conversions in the cast where
        # +type+ is the expected type of the condition if any.
        def explicit_types(type = nil)
            # Does the type match the cast?
            if type && !self.type.eql?(type) then
                # No, Recurse on the child tomatch the type.
                return self.child.explicit_types(type)
            else
                # No simply recurse on the child with the cast's type.
                return self.child.explicit_types(self.type)
            end
        end
    end


    class Operation
        ## Extends the Operation class with fixing of types and constants.

        # Explicit the types conversions in the operation where
        # +type+ is the expected type of the condition if any.
        def explicit_types(type = nil)
            raise "Should implement explicit_types for class #{self.class}."
        end
    end


    class Unary
        ## Extends the Unary class with fixing of types and constants.

        # Explicit the types conversions in the unary operation where
        # +type+ is the expected type of the condition if any.
        def explicit_types(type = nil)
            # Recurse on the child (no type to specify here, unary operations
            # preserve the type of their child).
            op = Unary.new(self.type,self.operator,self.child.explicit_types)
            # Does the type match the operation?
            if type && !self.type.eql?(type) then
                # No create a cast.
                return Cast.new(type,op)
            else
                # Yes, return the operation as is.
                return op
            end
        end
    end


    class Binary
        ## Extends the Binary class with fixing of types and constants.

        # Explicit the types conversions in the binary operation where
        # +type+ is the expected type of the condition if any.
        def explicit_types(type = nil)
            # Find the larger child type.
            ctype = self.left.type.width > self.right.type.width ?
                self.left.type : self.right.type
            # Recurse on the children: match the larger type.
            op = Binary.new(self.type,self.operator,
                            self.left.explicit_types(ctype),
                            self.right.explicit_types(ctype))
            # Does the type match the operation?
            if type && !self.type.eql?(type) then
                # No create a cast.
                return Cast.new(type,op)
            else
                # Yes, return the operation as is.
                return op
            end
        end
    end


    class Select
        ## Extends the Select class with fixing of types and constants.

        # Explicit the types conversions in the selection where
        # +type+ is the expected type of the condition if any.
        def explicit_types(type = nil)
            # If there is no type to match, use the one of the selection.
            type = self.type unless type
            # Each choice child must match the type.
            return Select.new(type,self.operator,self.select.clone,
                  *self.each_choice.map { |choice| choice.explicit_types(type)})
        end
    end


    class Concat
        ## Extends the Concat class with fixing of types and constants.

        # Explicit the types conversions in the concat where
        # +type+ is the expected type of the condition if any.
        def explicit_types(type = nil)
            # Is there a type to match?
            if type then
                # Yes, update the concat to the type.
                # Get the real type in case of typedef.
                type = type.def while type.is_a?(TypeDef)
                # Is it an array type?
                if type.is_a?(TypeVector) then
                    # Yes, update the concat without subcasting.
                    return Concat.new(type,self.each_expression.map do |expr|
                        expr.explicit_types
                    end)
                else
                    # No, it should be a tuple.
                    return Concat.new(type,
                                      self.each_expression.map.with_index do
                        |expr,i|
                        expr.explicit_types(type.get_type(i))
                    end)
                end
            else
                # No, recurse on the sub expressions.
                return Concat.new(self.type,
                                  self.each_expression.map do |expr|
                    expr.explicit_types
                end)
            end
        end
    end


    class Ref
        ## Extends the Ref class with fixing of types and constants.

        # Explicit the types conversions in the reference where
        # +type+ is the expected type of the condition if any.
        def explicit_types(type = nil)
            raise "Should implement explicit_types for class #{self.class}."
        end
    end


    class RefConcat
        ## Extends the RefConcat class with fixing of types and constants.

        # Explicit the types conversions in the concat ref where
        # +type+ is the expected type of the condition if any.
        def explicit_types(type = nil)
            # Is there a type to match?
            if type then
                # Yes, update the concat to the type.
                # Is it an array type?
                if type.is_a?(TypeVector) then
                    # Yes, update the concat accordingly.
                    return RefConcat.new(type,self.each_ref.map do |ref|
                        ref.explicit_types(type.base)
                    end)
                else
                    # No, it should be a tuple.
                    return RefConcat.new(type,self.each_ref.map.with_index do
                        |ref,i|
                        ref.explicit_types(type.get_type(i))
                    end)
                end
            else
                # No, recurse on the sub expressions.
                return RefConcat.new(self.type,self.each_ref.map.with_index do
                    |ref,i| 
                    puts "self.type=#{self.type}"
                    ref.explicit_types(self.type.get_type(i))
                end)
            end
        end
    end


    class RefIndex
        ## Extends the RefIndex class with fixing of types and constants.

        # Explicit the types conversions in the index ref where
        # +type+ is the expected type of the condition if any.
        def explicit_types(type = nil)
            # Is there a type to match ?
            if type then
                # Regenerate the reference and cast it
                return Cast.new(type,
                        RefIndex.new(self.type,self.ref.explicit_types,
                                    self.index.explicit_types))
            else
                # No, recurse with the type of the current index ref.
                return RefIndex.new(self.type,
                                    self.ref.explicit_types,
                                    self.index.explicit_types)
            end
        end
    end


    class RefRange
        ## Extends the RefRange class with fixing of types and constants.

        # Explicit the types conversions in the range ref where
        # +type+ is the expected type of the condition if any.
        def explicit_types(type = nil)
            # Is there a type to match ?
            if type then
                # Regenerate the reference and cast it.
                return Cast.new(type,
                            RefRange.new(self.type,self.ref.explicit_types,
                                    self.range.first.explicit_types ..
                                    self.range.last.explicit_types))
            else
                # No, recurse with the type of the current range ref.
                return RefRange.new(self.type,
                                    self.ref.explicit_types,
                                    self.range.first.explicit_types ..
                                    self.range.last.explicit_types)
            end
        end
    end


    class RefName
        ## Extends the RefName class with fixing of types and constants.

        # Explicit the types conversions in the index ref where
        # +type+ is the expected type of the condition if any.
        def explicit_types(type = nil)
            # Is there a type to match, if not use current one.
            type = self.type unless type
            # Cast if required and return the new reference.
            if self.type.eql?(type) then
                # No need to cast.
                return RefName.new(type,self.ref.explicit_types,self.name)
            else
                # Need a cast.
                return Cast.new(type,
                   RefName.new(self.type,self.ref.explicit_types,self.name))
            end
        end
    end


    class RefThis 
        ## Extends the RefThis class with fixing of types and constants.

        # Explicit the types conversions in the index ref where
        # +type+ is the expected type of the condition if any.
        def explicit_types(type = nil)
            # Simply duplicate.
            return self.clone
        end
    end


    class StringE
        ## Extends the stringE class with fixing of types and constants.

        # Explicit the types conversions in the concat where
        # +type+ is the expected type of the condition if any.
        def explicit_types(type = nil)
            return StringE.new(self.content, 
                               *self.each_arg.map(&:explicit_types))
        end
    end


end
