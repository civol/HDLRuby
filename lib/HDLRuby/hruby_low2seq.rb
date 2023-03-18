require 'HDLRuby'
require 'HDLRuby/hruby_tools'
require 'HDLRuby/hruby_low_mutable'


module HDLRuby::Low


##
# Converts par blocks to seq blocks.
# Also provides detection of mixed par and seq blocks.
#
########################################################################
    

    class SystemT
        ## Extends the SystemT class with functionality for converting par block
        #  to seq.
        
        # Converts the par sub blocks to seq.
        def blocks2seq!
            # Recurse on the scope.
            self.scope.to_seq!
            return self
        end

        # Converts the par sub blocks to seq if they are not full par.
        def mixblocks2seq!
            # Recurse on the scope.
            self.scope.mixblocks2seq!
        end

    end


    class Scope
    ## Extends the Scope class with functionality for converting par block
    #  to seq.
        
        # Converts the par sub blocks to seq.
        def blocks2seq!
            # Recurse on the behaviors.
            self.each_behavior { |beh| beh.blocks2seq! }
            return self
        end

        # Converts the par sub blocks to seq if they are not full par.
        def mixblocks2seq!
            # Recurse on the behaviors.
            self.each_behavior { |beh| beh.mixblocs2seq! }
        end

    end



    class Behavior
        ## Extends the Behavior class with functionality for converting par block
        #  to seq.
        
        # Converts the par sub blocks to seq.
        def blocks2seq!
            # Converts the block to seq.
            self.block.to_seq!
            return self
        end

        # Converts the par sub blocks to seq if they are not full par.
        def mixblocks2seq!
            # Is the block mix?
            return unless block.mix?
            # Mixed, do convert.
            # Converts the block to seq.
            self.block.to_seq!
        end

    end


    class Statement
        ## Extends the Statement class with functionality for converting par
        #  block to seq.

        # Converts the par sub blocks to seq.
        def blocks2seq!
            # By default, nothing to do.
            return self
        end

        # Tell if there is a mix block.
        # +mode+ is the mode of the upper block.
        def mix?(mode = nil)
            # By default, no mix block.
            return false
        end
    end


    class If
        ## Extends the If class with functionality for converting par block
        #  to seq.
        
        # Converts the par sub blocks to seq.
        def blocks2seq!
            # Convert each sub block.
            # If block.
            self.yes.blocks2seq!
            # Elsif blocks
            self.each_noif do |cond, stmnt|
                stmnt.blocks2seq!
            end
            # Else block if any.
            self.no.blocks2seq! if self.no
            return self
        end

        # Tell if there is a mix block.
        # +mode+ is the mode of the upper block.
        def mix?(mode = nil)
            # Check each sub block.
            # If block.
            return true if self.yes.mix?(mode)
            # Elsif blocks
            self.each_noif do |cond, stmnt|
                return true if stmnt.mix?(mode)
            end
            # Else block if any.
            true if self.no && self.no.mix?(mode)
        end

    end


    class When
        ## Extends the When class with functionality for converting par block
        #  to seq.

        # Converts the par sub blocks to seq.
        def blocks2seq!
            # Convert the statement.
            self.statement.blocks2seq!
            return self
        end

        # Tell if there is a mix block.
        # +mode+ is the mode of the upper block.
        def mix?(mode = nil)
            # Check the statement.
            return statement.mix?(mode)
        end

    end


    class Case
        ## Extends the When class with functionality for converting par block
        #  to seq.

        # Converts the par sub blocks to seq.
        def blocks2seq!
            # Recurse on the whens.
            self.each_when(&:blocks2seq!)
            # Converts the default if any.
            self.default.blocks2seq! if self.default
            return self
        end

        # Tell if there is a mix block.
        # +mode+ is the mode of the upper block.
        def mix?(mode = nil)
            # Recuse on the whens.
            return true if self.each_when.any? { |w| w.mix?(mode) }
            # Check the default if any.
            return self.default.mix?(mode)
        end

    end


    class TimeRepeat
        ## Extends the TimeRepeat class with functionality for converting par
        #  block to seq.

        # Converts the par sub blocks to seq.
        def blocks2seq!
            # Converts the statement.
            self.statement.blocks2seq!
            return self
        end

        # Tell if there is a mix block.
        # +mode+ is the mode of the upper block.
        def mix?(mode = nil)
            # Check the statement.
            return self.statement.mix?(mode)
        end

    end


    class Block
        ## Extends the Block class with functionality for converting par block
        #  to seq.

        # Converts the par sub blocks to seq.
        def blocks2seq!
            # First recurse on each statement.
            self.each_statement { |stmnt| stmnt.blocks2seq! }
            # If the block is already seq, nothing more to do.
            return self if self.mode == :seq
            # IF the block contains one or less transmit statement,
            # simply change its mode.
            if self.each_statement.count { |stmnt| stmnt.is_a?(Transmit) } <= 1
                self.set_mode!(:par)
                return self
            end
            # Gather the left values of the assignments.
            lvalues = self.each_statement.select do |stmnt|
                stmnt.is_a?(Transmit)
            end.map { |trans| trans.left }
            # Gather the right values inside the whole block.
            rvalues = self.each_node_deep.select do |node|
                node.is_a?(Expression) and node.rightvalue?
            end
            # Keep the left value that are reused.
            lvalues = lvalues & rvalues
            # Create new inner variable for replacing them.
            nvalues = []
            lvalues.each do |lvalue|
                # Create the replacing variable.
                nvalues << nvalue = self.add_inner(
                    SignalI.new(HDLRuby.uniq_name,lvalue.type))
                # Replace it.
                ref = RefName.new(lvalue.type, RefThis.new, nvalues[-1].name)
                lvalue.parent.set_left!(ref)
                # And reassign it at the end of the block.
                lvalue.parent = nil
                assign = Transmit.new(lvalue,ref.clone)
                self.add_statement(assign)
            end
            return self
        end

        # Tell if there is a mix block.
        # +mode+ is the mode of the upper block.
        def mix?(mode = nil)
            # Check if different from mode block if any.
            return true if mode && self.type != mode
            # No difference with the upper block, maybe there is one within.
            # Check each statement.
            self.each_statement.any? { |stmt| stmnt.mix?(mode) }
        end

    end

end
