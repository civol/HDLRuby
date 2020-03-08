require "HDLRuby/hruby_error"
require "HDLRuby/hruby_low_mutable"
require "HDLRuby/hruby_low2sym"
require "HDLRuby/hruby_low2seq"


##
# Explicitely seperate variables from signals in an HDLRuby::Low
# description.
#
# NOTE: variable and signal are to be taken in the VHDL meaning.
#
########################################################################
module HDLRuby::Low

    ## Extends the SystemT class with separation between signals and variables.
    class SystemT
        # Converts to a variable-compatible system.
        #
        # NOTE: the result is the same systemT.
        def with_var!
            self.each_behavior { |behavior| behavior.with_var! }
            return self
        end
    end


    ## Extends the SystemI class with separation between signals and variables.
    class SystemI
        # Converts to a variable-compatible system.
        #
        # NOTE: the result is the same systemT.
        def with_var!
            self.systemT.with_var!
            return self
        end
    end


    ## Extends the Behavior class with separation between signals and variables.
    class Behavior
        # Converts to a variable-compatible behavior.
        #
        # NOTE: the result is the same systemT.
        def with_var!(upper = nil)
            @block = @block.with_var
            @block.parent = self
            return self
        end
    end


    ## Extends the Block class with separation between signals and variables.
    class Block

        # Converts a variable to a reference to it.
        def var2ref(var)
            return RefName.new(var.type,RefThis.new,var.name)
        end

        # Converts symbol +sym+ representing an HDLRuby reference to a variable
        # name.
        def sym2var_name(sym)
            return ("%" + sym.to_s).to_sym
        end

        # Converts a variable +name+ to the symbol giving the corresponding
        # HDLRuby reference.
        def var_name2sym(name)
            return name[1..-1].to_sym
        end

        # Tell if a name is a variable one.
        def variable_name?(name)
            name[0] == "%"
        end

        # Extract the variables corresponding to external signals from
        # block-based statement +stmnt+, and put the extraction result is
        # table +sym2var+ that associate variable with corresponding signal
        # name.
        def extract_from_externals!(stmnt,sym2var)
            if (stmnt.is_a?(Block)) then
                # Block case, gather its declared and signals variables.
                vars = {}
                sigs = {}
                stmnt.each_inner do |inner|
                    if variable_name?(inner.name) then
                        vars[inner.name] = inner
                    else
                        sigs[inner.name] = inner
                    end
                end
                # Select the variables that correspond to external signals.
                vars.each do |name,inner|
                    sym = var_name2sym(name)
                    unless sigs.key?(sym) then
                        # The variable correspond to an external signal,
                        # extract it.
                        sym2var[sym] = inner
                        stmnt.delete_inner(inner)
                    end
                end
            elsif
                # Other case, recurse on the sub blocks.
                stmnt.each_block do |block|
                    extract_from_externals!(block,sym2var)
                end
            end
        end


        # Replaces the references by corresponding variables in +stmnt+ from
        # +sym2var+ table.
        def refs_by_variables!(stmnt,sym2var)
            # First, recurse.
            if stmnt.respond_to?(:each_node) then
                stmnt.each_node {|elem| refs_by_variables!(elem,sym2var) }
            end
            # Now replace an element if required.
            if stmnt.respond_to?(:map_nodes!) then
                stmnt.map_nodes! do |elem| 
                    var = sym2var[elem.to_sym]
                    var ? var2ref(var) : elem
                end
            end
        end

        # Get access to the variables
        def variables
            # Initializes the set of variables if required.
            @variables ||= {}
            return @variables
        end
       
        # Adds variable +name+ with +type+.
        def add_variable(name,type)
            # Ensure name is a symbol.
            name = name.to_sym
            # Declares the variable as an inner.
            inner = add_inner(SignalI.new(name,type))
            # And register it as a variable.
            variables[name] = inner 
        end

        # Gets a variable by +name+.
        def get_variable(name)
            # Ensure name is a symbol.
            name = name.to_sym
            # Get the variable.
            return variables[name]
        end


        # Converts to a variable-compatible block where +upper+ is
        # the upper block if any.
        #
        # NOTE: the result is a new block.
        def with_var(upper = nil)
            # puts "with_var for #{self} with upper=#{upper}"
            # Recurse on the statements.
            new_stmnts = []
            self.each_statement do |stmnt|
                # Process stmnt
                if stmnt.respond_to?(:with_var) then
                    # Can be converted
                    stmnt = stmnt.with_var(self)
                else
                    # Cannot be converted, simply clone.
                    stmnt = stmnt.clone
                end
                # Adds the result.
                new_stmnts << stmnt
            end
            # Handle the cases that does not need directly a variable
            # convertion
            # Is the block a par?
            if self.mode == :par then
                # Yes, creates a new block with the new statements.
                block = Block.new(self.mode)
                self.each_inner { |inner| block.add_inner(inner.clone) }
                new_stmnts.each {|stmnt| block.add_statement(stmnt) }
                # Is the block within a seq?
                if upper && upper.mode == :seq then
                    # Yes, converts to seq.
                    # return self.to_seq
                    return block.blocks2seq!
                end
                # No, simply return the block.
                # block = self.clone
                return block
            end

            # The block is a seq, convert it.
            # Treat the block
            sym2var = {} # The table of variable by corresponding signal name
            # Generate and replace the variables
            new_stmnts.each do |stmnt|
                unless stmnt.is_a?(Transmit) then
                    # The statement is not a transmission, extract the
                    # variables that correspond to external signals.
                    extract_from_externals!(stmnt,sym2var)
                else 
                    # Other case: transmission, the left value is to convert
                    # to a variable, and the right values are to be updated
                    # with the existing variables.
                    # First convert the left value to the corresponding symbol.
                    sym = stmnt.left.to_sym
                    # puts "sym=#{sym}"
                    var = sym2var[sym]
                    unless var then
                        var = SignalI.new(sym2var_name(sym),stmnt.left.type)
                        sym2var[sym] = var
                    end
                    # Then replace the relevant references by corresponding
                    # variables
                    refs_by_variables!(stmnt,sym2var)
                end
            end
            # puts "sym2var=#{sym2var}"
            # Declare the variables in the top block.
            top = self.top_block
            # puts "top=#{top}"
            sym2var.each_value do |var|
                # puts "Adding var=#{var.name}"
                top.add_inner(var.clone) unless top.each_inner.find {|v| v.eql?(var) }
            end
            # Generate the new block.
            result = self.class.new(self.mode,self.name)
            # Adds the inner signals of current block.
            self.each_inner do |inner|
                result.add_inner(inner.clone)
            end
            # Adds the new statements.
            new_stmnts.each do |stmnt|
                result.add_statement(stmnt)
            end
            # Adds final statements assigning variables back to the orginal
            # signals.
            sym2var.each do |sym,var|
                result.add_statement(
                    Transmit.new(sym.to_hdr.clone,var2ref(var)))
            end
            # End of the conversion.
            return result
        end

    end


    ## Extends the TimeBlock class with separation between signals and variables.
    class TimeBlock
        # Converts to a variable-compatible block where +upper+ is
        # the upper block if any.
        #
        # NOTE: the result is a new block.
        def with_var(upper = nil)
            # For the specific case of block, the conversion is not
            # done.
            return self
        end
    end


    ## Extends the If class with separation between signals and variables.
    class If
        # Converts to a variable-compatible if where +upper+ is
        # the upper block if any.
        #
        # NOTE: the result is a new if.
        def with_var(upper = nil)
            # Treat the sub nodes.
            # Condition.
            ncond = self.condition.clone
            # Yes.
            nyes =self.yes.with_var(upper)
            # Noifs.
            noifs = self.each_noif.map do |cond,stmnt|
                [cond.clone,stmnt.with_var(upper)]
            end
            # No.
            nno = self.no ? self.no.with_var(upper) : nil
            # Create the resulting If.
            res= If.new(ncond,nyes, nno)
            noifs.each do |cond,stmnt|
                res.add_noif(cond,stmnt)
            end
            return res
        end
    end


    ## Extends the When class with separation between signals and variables.
    class When
        # Converts to a variable-compatible case where +upper+ is
        # the upper block if any.
        #
        # NOTE: the result is a new case.
        def with_var(upper = nil)
            return When.new(self.match.clone,self.statement.with_var(upper))
        end
    end


    ## Extends the Case class with separation between signals and variables.
    class Case
        # Converts to a variable-compatible case where +upper+ is
        # the upper block if any.
        #
        # NOTE: the result is a new case.
        def with_var(upper = nil)
            ndefault = self.default ? self.default.clone : nil
            return Case.new(self.value.clone,ndefault,
                            self.each_when.map {|w| w.with_var(upper) })
        end
    end
end
