require 'HDLRuby'
require 'HDLRuby/hruby_tools'
require 'HDLRuby/hruby_low_mutable'


module HDLRuby::Low


##
# Converts par blocks within seq blocks to seq blocks.
# For matching the executing model of Verilog.
#
########################################################################
    

    class SystemT
        ## Extends the SystemT class with functionality for converting par blocks
        #  within seq blocks to seq blocks.

        # Converts par blocks within seq blocks to seq blocks.
        def par_in_seq2seq!
            self.scope.par_in_seq2seq!
        end
    end


    class Scope
        ## Extends the Scope class with functionality for converting par blocks
        #  within seq blocks to seq blocks.

        # Converts par blocks within seq blocks to seq blocks.
        def par_in_seq2seq!
            # Recruse on the sub scopes.
            self.each_scope(&:par_in_seq2seq!)
            # Recurse on the block.
            self.each_behavior do |behavior|
                behavior.block.par_in_seq2seq!
            end
        end
    end


    class Statement
        ## Extends the Statement class with functionality for converting par 
        #  blocks within seq blocks to seq blocks.
 
        # Converts par blocks within seq blocks to seq blocks.
        def par_in_seq2seq!
            # By default nothing to do.
            return self
        end

        # Convert the block to seq.
        def to_seq!
            # By default nothing to do.
            return self
        end
    end


    class If
        ## Extends the If class with functionality for converting par blocks
        #  within seq blocks to seq blocks.

        # Converts par blocks within seq blocks to seq blocks.
        def par_in_seq2seq!
            self.yes.par_in_seq2seq!
            self.each_noif do |cond,blk|
                blk.par_in_seq2seq!
            end
            self.no.par_in_seq2seq! if self.no
        end

        # Convert the block to seq.
        def to_seq!
            self.to_seq!
            self.each_noif do |cond,blk|
                blk.to_seq!
            end
            self.no.to_seq! if self.no
        end
    end


    class Case
        ## Extends the Case class with functionality for converting par blocks
        #  within seq blocks to seq blocks.

        # Converts par blocks within seq blocks to seq blocks.
        def par_in_seq2seq!
            self.each_when do |w|
                w.statement.par_in_seq2seq!
            end
            self.default.par_in_seq2seq! if self.default
        end

        # Convert the block to seq.
        def to_seq!
            self.each_when do |w|
                w.statement.to_seq!
            end
            self.default.to_seq! if self.default
        end
    end


    class Block
        ## Extends the Block class with functionality for converting par blocks
        #  within seq blocks to seq blocks.

        # Converts par blocks within seq blocks to seq blocks.
        def par_in_seq2seq!
            # Recurse on the sub blocks.
            self.each_statement(&:par_in_seq2seq!)
            # Is the current block a seq block?
            if self.mode == :seq then
                # Yes, convert its inner par blocks to seq blocks.
                self.each_statement do |statement|
                    if (statement.is_a?(Block)) then
                        statement.to_seq! if statement.mode == :par
                    end
                end
            end
            return self
        end

        # Convert the block to seq.
        def to_seq!
            if self.mode == :par then
                # Need to convert.
                # Get which module is it.
                modul = self.is_a?(HDLRuby::High::Block) ? HDLRuby::High :
                    HDLRuby::Low
                # First recurse on the sub blocks.
                self.each_statement(&:to_seq!)
                # Now replace each left value by a new signal for
                # differed assingment in seq.
                differeds = []
                self.each_statement do |statement|
                    left = statement.left
                    if statement.is_a?(Transmit) then
                        if modul == HDLRuby::High then
                            sig = modul::SignalI.new(HDLRuby.uniq_name,left.type,:inner)
                            self.add_inner(sig)
                            puts "sig.parent=#{sig.parent}"
                            diff = modul::RefObject.new(modul::RefThis.new,sig)
                        else
                            sig = modul::SignalI.new(HDLRuby.uniq_name,left.type)
                            self.add_inner(sig)
                            diff = modul::RefName.new(left.type,modul::RefThis.new,sig.name)
                        end
                        differeds << [left,diff]
                        statement.set_left!(diff)
                    end
                end
                # Adds the differed assignments.
                differeds.each do |left,diff|
                    self.add_statement(modul::Transmit.new(left.clone,diff.clone))
                end
                # Change the mode.
                self.set_mode!(:seq)
            end
            return self
        end
    end

end
