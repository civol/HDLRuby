require 'HDLRuby'
require 'HDLRuby/hruby_tools'
require 'HDLRuby/hruby_low_mutable'


module HDLRuby::Low


##
# Converts the select expression to case statements.
# Makes handling by some synthesis tools easier.
#
########################################################################
    

    ## Module containing helping methods for converting Select expressions
    #  to Case.
    module LowWithoutSelect

        # Generate a block with Cases from a list of Select objects.
        def self.selects2block(selects) 
            blk = Block.new(:seq)
            selects.each do |select,sig|
                # puts "for select=#{select.to_high} with sig=#{sig.name}(#{sig.type.name})"
                # Create the case.
                cas = Case.new(select.select.clone)
                # Get the type for the matches.
                type = select.select.type
                # Create and add the whens.
                size = select.each_choice.count
                select.each_choice.with_index do |choice,i|
                    # Create the transmission statements of the when.
                    left = RefName.new(sig.type,RefThis.new,sig.name)
                    trans = Transmit.new(left,choice.clone)
                    # Put it into a block for the when.
                    tb = Block.new(:par)
                    tb.add_statement(trans)
                    if i < size-1 then
                        # Create and add the when.
                        cas.add_when( When.new(Value.new(type,i), tb) )
                    else
                        # Last choice, add a default/
                        cas.default = tb
                    end
                end
                # puts "Resulting case: #{cas.to_high}"
                # Adds the case to the block.
                blk.add_statement(cas)
            end
            return blk
        end
    end
    

    ## Extends the SystemT class with functionality for converting select
    #  expressions to case statements.
    class SystemT

        # Converts the Select expressions to Case statements.
        def select2case!
            self.scope.select2case!
        end

    end

    ## Extends the Scope class with functionality for converting select
    #  expressions to case statements.
    class Scope

        # Converts the Select expressions to Case statements.
        def select2case!
            # Recruse on the sub scopes.
            self.each_scope(&:select2case!)

            # Recurse on the blocks.
            self.each_behavior do |behavior|
                behavior.block.each_block_deep(&:select2case!)
            end

            # Work on the connections.
            self.each_connection.to_a.each do |connection|
                selects = connection.extract_selects!
                if selects.any? then
                    # Selects have been extract, replace the connection
                    # by a behavior.
                    # Generate the block with cases.
                    blk = LowWithoutSelect.selects2block(selects)
                    # Add a transmit replacing the connection.
                    blk.add_statement(
                        Transmit.new(connection.left.clone,
                                     connection.right.clone))
                    # Remove the connection and add a behavior instead.
                    self.delete_connection!(connection)
                    self.add_behavior(Behavior.new(blk))
                end
            end
        end
    end


    ## Extends the TimeWait class with functionality for converting booleans
    #  in assignments to select operators.
    class TimeWait
        # Extract the Select expressions.
        def extract_selects!
            # Nothing to extract.
            return []
        end
    end


    ## Extends the TimeRepeat class with functionality for converting booleans
    #  in assignments to select operators.
    class TimeRepeat
        # Extract the Select expressions.
        def extract_selects!
            # Simply recruse on the statement.
            if self.statement.is_a?(Block) then
                return []
            else
                return self.statement.extract_selects!
            end
        end
    end


    ## Extends the Block class with functionality for converting select
    #  expressions to case statements.
    class Block

        # Breaks the assignments to concats.
        #
        # NOTE: work on the direct sub statement only, not deeply.
        def select2case!
            # Check each statement.
            self.map_statements! do |stmnt|
                # Skip blocks that are treated through recursion.
                next stmnt if stmnt.is_a?(Block)
                # Work on the statement.
                # Extract the Select expressions.
                selects = stmnt.extract_selects!
                if selects.any? then
                    # Generate a sequential block containing the cases.
                    blk = LowWithoutSelect.selects2block(selects)
                    # Adds the statement to the block.
                    blk.add_statement(stmnt.clone)
                    stmnt = blk
                end
                stmnt 
            end
        end
    end

    ## Extends the Transmit class with functionality for converting select
    #  expressions to case statements.
    class Transmit
        # Extract the Select expressions.
        def extract_selects!
            selects = []
            self.set_left!(self.left.extract_selects_to!(selects))
            self.set_right!(self.right.extract_selects_to!(selects))
            return selects
        end
    end

    ## Extends the Print class with functionality for converting select
    #  expressions to case statements.
    class Print
        # Extract the Select expressions.
        def extract_selects!
            selects = []
            self.map_args! do |arg|
                arg.extract_selects_to!(selects)
            end
            return selects
        end
    end

    ## Extends the TimeTerminate class with functionality for converting select
    #  expressions to case statements.
    class TimeTerminate
        # Extract the Select expressions.
        def extract_selects!
            # Nothing to extract.
            return []
        end
    end
    
    ## Extends the If class with functionality for converting select
    #  expressions to case statements.
    class If

        # Extract the Select expressions.
        #
        # NOTE: work on the condition only.
        def extract_selects!
            selects = []
            self.set_condition!(self.condition.extract_selects_to!(selects))
            return selects
        end
    end

    ## Extends the If class with functionality for converting select
    #  expressions to case statements.
    class When

        # Extract the Select expressions.
        #
        # NOTE: work on the match only.
        def extract_selects!
            selects = []
            self.set_match!(self.match.extract_selects_to!(selects))
            return selects
        end
    end

    ## Extends the Case class with functionality for converting select
    #  expressions to case statements.
    class Case

        # Extract the Select expressions.
        #
        # Note: the default is not treated.
        def extract_selects!
            selects = []
            # Work on the value.
            self.set_value!(self.value.extract_selects_to!(selects))
            # Work on the whens.
            selects += self.each_when.map(&:extract_selects!).reduce(:+)
            return selects
        end
    end

    ## Extends the Expression class with functionality for converting select
    #  expressions to ase statements.
    class Expression

        # Extract the Select expressions and put them into +selects+
        def extract_selects_to!(selects)
            # Recurse on the sub expressions.
            self.map_expressions! {|expr| expr.extract_selects_to!(selects) }
            # Treat case of select.
            if self.is_a?(Select) then
                # Create the signal replacing self.
                sig = SignalI.new(HDLRuby.uniq_name,self.type)
                # Add the self with replacing sig to the extracted selects
                selects << [self,sig]
                # Create the signal replacing self.
                blk = self.statement.block
                if blk then
                    # Add the signal in the block.
                    blk.add_inner(sig)
                else
                    # No block, this is a connection, add the signal in the
                    # socpe
                    self.statement.scope.add_inner(sig)
                end
                # And return a reference to it.
                return RefName.new(sig.type,RefThis.new,sig.name)
            end
            return self
        end
    end
end
