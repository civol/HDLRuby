require 'HDLRuby'


module HDLRuby::Low


##
# Converts a HDLRuby::Low description to HDLRuby::High description.
#
########################################################################
    


    # Add the conversion to high.
    class SystemT
        # Creates a new high system type named +name+ with +scope+.
        def to_high
            # Create the high system type.
            res = HDLRuby::High::SystemT.new(self.name,self.scope.to_high)
            # Add the inputs.
            self.each_input  { |i|  res.add_input(i.to_high) }
            # Add the outputs.
            self.each_output { |o|  res.add_output(o.to_high) }
            # Add the inouts.
            self.each_inout  { |io| res.add_inout(io.to_high) }
            return res
        end
    end


    # Add the conversion to high.
    class Scope
        # Creates a new high scope.
        def to_high
            # Create the high scope.
            res = new HDLRuby::High::Scope.new(self.name)
            # Add the local types.
            self.each_type { |t| res.add_type(t.to_high) }
            # Add the local system types.
            self.each_systemT { |s| res.add_systemT(s.to_high) }
            # Add the sub scopes.
            self.each_scope { |s| res.add_scope(s.to_high) }
            # Add the inner signals.
            self.each_inner { |i| res.add_inner(i.to_high) }
            # Add the system instances.
            self.each_systemI { |s| res.add_systemI(s.to_high) }
            # Add the non-HDLRuby cofe chunks.
            self.each_code { |c| res.add_code(c.to_high) }
            # Add the connections.
            self.each_connection { |c| res.add_connection(c.to_high) }
            # Add the behaviors.
            self.each_behavior { |b| res.add_behavior(b.to_high) }
            return res
        end
    end

    
    # Add the conversion to high.
    class Type
        # Creates a new high type.
        def to_high
            return HDLRuby::High::Type.new(self.name)
        end
    end


    # Add the conversion to high.
    class TypeDef
        # Creates a new high type definition.
        def to_high
            return HDLRuby::High::Typdef.new(self.name,self.type.to_high)
        end
    end


    # Add the conversion to high.
    class TypeVector
        # Creates a new high type vector.
        def to_high
            return new HDLRuby::High::TypeVector.new(self.name,
                                                     self.base.to_high,
                                                     self.range)
        end
    end


    # Add the conversion to high.
    class TypeSigned
        # Creates a new high type signed.
        def to_high
            return HDLRuby::High::TypeSigned.new(self.name,self.range)
        end
    end


    # Add the conversion to high.
    class TypeUnsigned
        # Creates a new high type unsigned.
        def to_high
            return HDLRuby::High::TypeUnsigned.new(self.name,self.range)
        end

    end


    # Add the conversion to high.
    class TypeTuple
        # Creates a new high type tuple.
        def to_high
            return HDLRuby::High::TypeTuple.new(self.name,self.direction,
                                *self.each_type.map { |typ| typ.to_high })
        end
    end


    # Add the conversion to high.
    class TypeStruct
        # Creates a new high type struct.
        def to_high
            return HDLRuby::High::TypeString.new(self.name,self.direction,
                                    self.each {|name,typ| [name,typ.to_high]})
        end
    end



    # Add the conversion to high.
    class Behavior
        # Creates a new high behavior.
        def to_high
            # Create the resulting behavior.
            res = HDLRuby::High::Behavior.new(self.block.to_high)
            # Adds the events.
            self.each_event { |ev| res.add_event(ev.to_high) }
            return res
        end
    end


    # Add the conversion to high.
    class TimeBehavior
        # Creates a new high time behavior.
        def to_high
            # Create the resulting behavior.
            res = HDLRuby::High::TimeBehavior.new(self.block.to_high)
            # Adds the events.
            self.each_event { |ev| res.add_event(ev.to_high) }
            return res
        end
    end


    # Add the conversion to high.
    class Event
        # Creates a new high event.
        def to_high
            return HDLRuby::High::Event.new(self.type.to_high,self.ref.to_high)
        end
    end


    # Add the conversion to high.
    class SignalI
        # Creates a new high signal.
        def to_high
            # Is there an initial value?
            if (self.value) then
                # Yes, create a new high signal with it.
                return HDLRuby::High::SignalI.new(self.name,self.type.to_high,
                                              self.val.to_high)
            else
                # No, create a new high signal with it.
                return HDLRuby::High::SignalI.new(self.name,self.type.to_high)
            end
        end
    end


    # Add the conversion to high.
    class SignalC
        # Creates a new high constant signal.
        def to_high
            # Is there an initial value?
            if (self.value) then
                # Yes, create a new high signal with it.
                return HDLRuby::High::SignalC.new(self.name,self.type.to_high,
                                              self.val.to_high)
            else
                # No, create a new high signal with it.
                return HDLRuby::High::SignalC.new(self.name,self.type.to_high)
            end
        end
    end


    # Add the conversion to high.
    class SystemI
        # Creates a new high system instance.
        def to_high
            return HDLRuby::High::SystemI.new(self.name,self.systemT.to_high)
        end
    end


    # Add the conversion to high.
    class Chunk
        # Creates a new high code chunk.
        def to_high
            return HDLRuby::High::Chunk.new(self.name,
                                *self.each_lump { |lump| lump.to_high })
        end
    end


    # Add the conversion to high.
    class Code
        # Creates a new high code.
        def to_high
            # Create the new code.
            res = HDLRuby::High::Code.new
            # Add the events.
            self.each_event { |ev| res.add_event(ev.to_high) }
            # Add the code chunks.
            self.each_chunk { |ch| res.add_chunk(ch.to_high) }
        end
    end


    # Add the conversion to high.
    class Statement
        # Creates a new high statement.
        def to_high
            raise AnyError,
                  "Internal error: to_high is not defined for class: #{self.class}"
        end
    end


    # Add the conversion to high.
    class Transmit
        # Creates a new high transmit statement.
        def to_high
            return HDLRuby::High::Transmit.new(self.left.to_high,
                                               self.right.to_high)
        end
    end


    # Add the conversion to high.
    class If
        # Creates a new high if statement.
        def to_high
            # Is there a no?
            if self.no then
                # Yes, create a new if statement with it.
                res = HDLRuby::High::If.new(self.condition.to_high,
                                        self.yes.to_high,self.no.to_high)
            else
                # No, create a new if statement without it.
                res = HDLRuby::High::If.new(self.condition.to_high,
                                        self.yes.to_high)
            end
            # Add the noifs if any.
            self.each_noif do |cond,stmnt| 
                res.add_noif(cond.to_high,stmt.to_high)
            end
            return res
        end
    end


    # Add the conversion to high.
    class When
        # Creates a new high when.
        def to_high
            return HDLRuby::High::When.new(self.match.to_high,
                                           self.statement.to_high)
        end
    end


    # Add the conversion to high.
    class Case
        # Creates a new high case statement.
        def to_high
            # Is there a default?
            if self.default then
                # Yes, create the new case statement with it.
                return HDLRuby::High::Case.new(self.value.to_high,
                                               self.default.to_high,
                                     self.each_when.map { |w| w.to_high })
            end
        end
    end


    # Add the conversion to high.
    class Delay
        # Creates a new high delay.
        def to_high
            return HDLRuby::High::Delay.new(self.value,self.unit)
        end
    end


    # Add the conversion to high.
    class Print
        # Creates a new high print statement.
        def to_high
            return HDLRuby::High::Print.new(
                *self.each_arg.map {|arg| arg.to_high })
        end
    end


    # Add the conversion to high.
    class TimeWait
        # Creates a new high wait statement.
        def to_high
            return HDLRuby::High::TimeWait.new(self.delay.to_high)
        end
    end


    # Add the conversion to high.
    class TimeRepeat
        # Creates a new high repreat statement.
        def to_high
            return HDLRuby::High::TimeReapeat.new(self.delay.to_high,
                                                  self.statement.to_high)
        end
    end


    # Add the conversion to high.
    class Block
        # Creates a new high block statement.
        def to_high
            # Create the new block statement.
            res = HDLRuby::High::Block.new(self.mode,self.name)
            # Add the statements.
            self.each_statement { |stmnt| res.add_statement(stmnt.to_high) }
            return res
        end
    end


    # Add the conversion to high.
    class TimeBlock
        # Creates a new high time block statement.
        def to_high
            # Create the new block statement.
            res = HDLRuby::High::TimeBlock.new(self.mode,self.name)
            # Add the statements.
            self.each_statement { |stmnt| res.add_statement(stmnt.to_high) }
            return res
        end
    end


    # Add the conversion to high.
    class Connection
        # Creates a new high connection.
        def to_high
            return HDLRuby::High::Connection.new(self.left.to_high,
                                                 self.right.to_high)
        end
    end


    # Add the conversion to high.
    class Expression
        # Creates a new high expression.
        def to_high
            raise AnyError,
                  "Internal error: to_high is not defined for class: #{self.class}"
        end
    end

    
    # Add the conversion to high.
    class Value
        # Creates a new high value expression.
        def to_high
            return HDLRuby::High::Value.new(self.type.to_high,
                                            self.content.to_high)
        end
    end


    # Add the conversion to high.
    class Cast
        # Creates a new high cast expression.
        def to_high
            return HDLRuby::High::Cast(self.type.to_high, self.child.to_high)
        end
    end


    # Add the conversion to high.
    class Operation
    end


    # Add the conversion to high.
    class Unary
        # Creates a new high unary expression.
        def to_high
            return HDLRuby::High::Unary.new(self.type.to_high,self.operator,
                                            self.child.to_high)
        end
    end


    # Add the conversion to high.
    class Binary
        # Creates a new high binary expression.
        def to_high
            return HDLRuby::High::Binary.new(self.type.to_high,self.operator,
                                             self.left.to_high,
                                             self.right.to_high)
        end
    end


    # Add the conversion to high.
    class Select
        # Creates a new high select expression.
        def to_high
            return HDLRuby::High::Select(self.type.to_high,self.operator,
                                         self.select.to_high,
                                    self.each_choice.map { |ch| ch.to_high })
        end
    end


    # Add the conversion to high.
    class Concat
        # Creates a new high concat expression.
        def to_high
            return HDLRuby::High::Concat.new(self.type,
                                self.each_expression.map { |ex| ex.to_high })
        end
    end


    # Add the conversion to high.
    class Ref
    end


    # Add the conversion to high.
    class RefConcat
        # Creates a new high concat reference.
        def to_high
            return HDLRuby::High::Ref.new(self.type.to_high,
                                    self.each_ref.map { |ref| ref.to_high })
        end
    end


    # Add the conversion to high.
    class RefIndex
        # Creates a new high index reference.
        def to_high
            return HDLRuby::High::RefIndex.new(self.type.to_high,
                                               self.ref.to_high,
                                               self.index.to_high)
        end
    end


    # Add the conversion to high.
    class RefRange
        # Creates a new high range reference.
        def to_high
            return HDLRuby::High::RefRange.new(self.type.to_high,
                                               self.ref.to_high,
                            self.range.first.to_high..self.range.last.to_high)
        end
    end


    # Add the conversion to high.
    class RefName
        # Creates a new high range reference.
        def to_high
            return HDLRuby::High::RefName.new(self.type.to_high,
                                              self.ref.to_high,
                                              self.name)
        end
    end


    # Add the conversion to high.
    class RefThis
        # Creates a new high ref this.
        def to_high
            return HDLRuby::High::RefThis.new
        end
    end


    # Add the conversion to high.
    class StringE
        # Creates a new high string expression.
        def to_high
            return HDLRuby::High::StringE.new(self.content,
                                *self.each_arg.map {|arg| arg.to_high })
        end
    end
end
