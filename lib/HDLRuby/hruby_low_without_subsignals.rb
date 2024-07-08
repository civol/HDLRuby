require 'HDLRuby'
require 'HDLRuby/hruby_tools'
require 'HDLRuby/hruby_low_mutable'
require 'HDLRuby/hruby_low_resolve'


module HDLRuby::Low


##
# Replace hierachical signals by the list of their sub signals.
# Makes handling by some synthesis tools easier.
#
########################################################################
 

    class SystemT
        ## Extends the SystemT class with functionality for decomposing the
        #  hierachical signals in the statements.

        # # Decompose the hierarchical signals in the statements.
        # def signal2subs!
        #     self.scope.signal2subs!
        # end

        # Decompose the hierarchical signals in the statements.
        # If +decompose_vec2d+ is true then also decompose 2 dimension vectors
        # (e.g., for Verilog HDL that does not support handling such signals
        #  as usual expressions).
        def signal2subs!(decompose_vec2d = false)
            @@decompose_vec2d = decompose_vec2d == true
            self.scope.signal2subs!
        end

        ## Tell if 2d vector signals must be decomposed too.
        def self.decompose_vec2d?
            @@decompose_vec2d
        end
    end


    class Scope
        ## Extends the Scope class with functionality for decomposing the
        #  hierachical signals in the statements.

        # Decompose the hierarchical signals in the statements.
        def signal2subs!
            # Recruse on the sub scopes.
            self.each_scope(&:signal2subs!)

            # Recurse on the blocks.
            self.each_behavior do |behavior|
                # behavior.block.each_block_deep(&:signal2subs!)
                behavior.signal2subs!
            end

            # Work on the connections.
            self.each_connection.to_a.each do |connection|
                # Recurse on the left and right.
                connection.set_left!(connection.left.signal2subs!)
                connection.set_right!(connection.right.signal2subs!)
            end
        end
    end


    class Behavior
        ## Extends the Behavior class with functionality for decomposing the
        #  hierachical signals in the statements.

        # Decompose the hierarchical signals in the statements.
        def signal2subs!
            # Process the events.
            self.each_event.to_a.each do |ev|
                subrefs = ev.ref.flatten
                if subrefs.any? then
                    # The refence have been flattend, remove the event.
                    self.delete_event!(ev)
                    # And add instead new events for the sub references.
                    subrefs.each do |subref|
                        nev = Event.new(ev.type,subref)
                        self.add_event(nev)
                    end
                end
            end
            # Recurse on the blocks.
            self.block.each_block_deep(&:signal2subs!)
        end
    end


    class Block
        ## Extends the Block class with functionality for decomposing the
        #  hierachical signals in the statements.

        # Decompose the hierarchical signals in the statements.
        def signal2subs!
            # Recurse on the statments.
            self.map_statements! do |stmnt|
                stmnt.signal2subs!
            end
            return self
        end
    end


    class TimeWait
        ## Extends the TimeWait class with functionality for decomposing the
        #  hierachical signals in the statements.

        # Decompose the hierarchical signals in the statements.
        def signal2subs!
            # Nothing to do.
            return self
        end
    end


    class TimeRepeat
        ## Extends the TimeRepeat class with functionality for decomposing the
        #  hierachical signals in the statements.

        # Decompose the hierarchical signals in the statements.
        def signal2subs!
            # Recurse on the statement.
            self.set_statement!(self.statement.signal2subs!)
            return self
        end
    end


    class Transmit
        ## Extends the Transmit class with functionality for decomposing the
        #  hierachical signals in the statements.

        # Decompose the hierarchical signals in the statements.
        def signal2subs!
            # Recurse on the left and right.
            self.set_left!(self.left.signal2subs!)
            self.set_right!(self.right.signal2subs!)
            return self
        end
    end


    class Print
        ## Extends the Print class with functionality for decomposing the
        #  hierachical signals in the statements.

        # Decompose the hierarchical signals in the statements.
        def signal2subs!
            # Recurse on the arguments.
            self.map_args! { |arg| arg.signal2subs! }
            return self
        end
    end


    class TimeTerminate
        ## Extends the Print class with functionality for decomposing the
        #  hierachical signals in the statements.

        # Decompose the hierarchical signals in the statements.
        def signal2subs!
            # Nothing to do.
            return self
        end
    end
    

    class If
        ## Extends the If class with functionality for decomposing the
        #  hierachical signals in the statements.

        # Decompose the hierarchical signals in the statements.
        def signal2subs!
            # Recurse on the condition.
            self.set_condition!(self.condition.signal2subs!)
            # Recurse on the yes block.
            self.yes.signal2subs!
            # Recurse on the no block if any.
            self.no.signal2subs! if self.no
            # Recurse on the alternate ifs.
            self.map_noifs! do |cond,stmnt|
                [cond.signal2subs!,stmnt.signal2subs!]
            end
            return self
        end
    end


    class When
        ## Extends the When class with functionality for decomposing the
        #  hierachical signals in the statements.

        # Decompose the hierarchical signals in the statements.
        def signal2subs!
            # Recurse on the match.
            self.set_match!(self.match.signal2subs!)
            # Recurse on the statement.
            self.set_statement!(self.statement.signal2subs!)
            return self
        end

    end


    class Case
        ## Extends the Case class with functionality for decomposing the
        #  hierachical signals in the statements.

        # Decompose the hierarchical signals in the statements.
        def signal2subs!
            # Recurse on the case value.
            self.set_value!(self.value.signal2subs!)
            # Recurse on the whens.
            self.each_when(&:signal2subs!)
            # Recurse on the default.
            self.set_default!(self.default.signal2subs!) if self.default
            return self
        end
    end


    class Expression
        ## Extends the Expression class with functionality for decomposing the
        #  hierachical signals in the statements.

        # Decompose the hierarchical signals in the statements.
        def signal2subs!
            # puts "signal2subs! for expr=#{self}"
            # Recurse on the subexpressions.
            self.map_expressions!(&:signal2subs!)
            return self
        end
    end


    class RefName
        ## Extends the RefName class with functionality for decomposing the
        #  hierachical signals in the statements.

        # Flatten a reference to a list of reference to leaf signals
        # from signal +sig+ and add to result to +subrefs+
        def flatten_to(sig,subrefs)
            # Shall we decompose 2d vectors, and is the current signal
            # for one of them?
            if SystemT.decompose_vec2d? and sig.type.is_a?(TypeVector) and
                    sig.type.base.is_a?(TypeVector) then
                # Is the reference used other than for a memory access?
                unless self.parent.is_a?(RefIndex) then
                    # Yes, do the decomposition.
                    # Selects the direction.
                    rng = sig.type.range
                    if rng.first > rng.last then
                        itr = (rng.last..rng.first).each
                    else
                        itr = rng.reverse_each
                    end
                    # Iterate on each element.
                    itr.each do |i|
                        # Create a reference fo the sub.
                        subref = RefIndex.new(sig.type.base,self.clone,
                                                  Value.new(TypeUnsigned.new(:""),i))
                        # Add it.
                        subrefs << subref
                    end
                end
            else
                # Work on the sub signals if any.
                sig.each_signal do |sub|
                    # Create a reference for the sub.
                    subref = RefName.new(sub.type,self.clone,sub.name)
                    # Recurse on it.
                    subref.flatten_to(sub,subrefs)
                    # Was it a leaf?
                    unless sub.each_signal.any? then
                        # Yes, add its new ref to the list of subs.
                        subrefs << subref
                    end
                end
            end
        end

        # Flatten the current ref to a list of references.
        # If the reference is not heirachical, returns an empty list.
        def flatten
            subrefs = []
            self.flatten_to(self.resolve,subrefs)
            return subrefs
        end

        # Decompose the hierarchical signals in the statements.
        def signal2subs!
            # puts "signal2subs! for RefName: #{self.name}"
            return self if self.type == void # Not a singal anyway.
            # Decompose it to a list of reference to each leaf sub signal.
            subrefs = []
            self.flatten_to(self.resolve,subrefs)
            # puts "subrefs=#{subrefs.map{|subref| subref.name}}"
            # Has it sub signals?
            if (subrefs.any?) then
                # Yes, convert it to a Concat.
                if self.leftvalue? then
                    return RefConcat.new(self.type,subrefs)
                else
                    return Concat.new(self.type,subrefs)
                end
            else
                # Nothing to do.
                return self
            end
        end
    end




end
