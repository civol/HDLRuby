require "HDLRuby.rb"
require "HDLRuby/hruby_verilog_name.rb"

require 'HDLRuby/hruby_low_mutable'


include HDLRuby::Verilog

module HDLRuby::Low


    # The list of base types used both in verilog and HDLRuby
    VERILOG_BASE_TYPES = ["signed"]

    # The list of signals that are actually verilog regs.
    VERILOG_REGS = []

    ## Converts string +str+ to a Verilog-compatible string.
    def self.v_string(str)
        str = str.gsub(/\n/,"\\n")
        str.gsub!(/\t/,"\\t")
        return str
    end


    # Sample of very handy for programming.
    # puts "class=#{self.yes.class}"       # Confirm class of self.yes.
    # puts "methods=#{self.right.methods}" # Confirm method of self.right.
    # puts  "outputs=#{outputs}"           # Confirm outputs

    # each. do |*arg|                      # I forgot this.
    #    puts args
    # end

    # Global variable used for indentation and structure (temporary).
    $vector_reg = ""   # For storing signal type at structure declaration. (temporary)
    $vector_cnt = 0    # For allocating numbers at structure declaration.  (temporary)

    
    class ::Integer
        ## Extends the Integer class with generation of verilog text.

        def to_verilog
            to_s
        end
    end

    
    # Class summarizing "hash" used for "par" or "seq" conversion.
    class Fm
        attr_reader :fm_seq, :fm_par, :rep, :rep_sharp
        def initialize
            @fm_seq = {}      # Used to seq -> par.
            @fm_par = {}      # Used to par -> seq.
            @rep = {}         # Used to give ' to variables
            @rep_sharp = {}   # Used to give # to variables
        end
    end

    # Declaration of fm to manage each hash.
    # $fm = Fm.new
    FmI = Fm.new


    # Class for generating the truncating functions in verilog.
    # Such function are necessary as expression cannot be truncated directly.
    class Truncers
        def initialize
            @truncers = []
        end

        # Convert a range to an array.
        def r2a(rng)
            return [rng.first,rng.last]
        end

        # Add a truncer to of expression of bit range +rngI+ using +rngS+ slice.
        def add(rngI,rngS)
            # Convert the ranges to arrays.
            rngI,rngS = self.r2a(rngI), self.r2a(rngS)
            # Add them
            @truncers << [rngI,rngS]
        end
        alias_method :<<, :add


        # Generate a truncer function name for expression of bit range +rngI+ using +rngS+ slice.
        def truncer_name(rngI,rngS)
            # Convert the ranges to arrays.
            rngI,rngS = self.r2a(rngI), self.r2a(rngS)
            # Generate the name.
            return "truncer_#{rngI[0]}_#{rngI[1]}_#{rngS[0]}_#{rngS[1]}"
        end

        # Generate the truncating functions.
        def dump
            # Ensure there is only one truncating function per range.
            @truncers.sort!.uniq!
            # Generate the resulting code.
            codeT = ""
            @truncers.each do |(rngI,rngS)|
                rngO = [rngS[0]-rngS[1],0]
                codeT << "     function [#{rngO[0]}:#{rngO[1]}] "
                codeT << self.truncer_name(rngI,rngS) 
                codeT << "(input [#{rngI[0]}:#{rngI[1]}] val);\n"
                codeT << "         " << self.truncer_name(rngI,rngS) << " = "
                codeT << "val[#{rngS[0]}:#{rngS[1]}];\n"
                codeT << "      endfunction\n\n"
            end
            # Clears the truncers.
            @truncers = []
            return codeT
        end
    end

    # Declaration of the truncating function generator.
    TruncersI = Truncers.new


    # Class for generating the truncating functions in verilog.
    # Such function are necessary as expression cannot be truncated directly.
    class Indexers
        def initialize
            @indexers = []
        end

        # Add an indexer to of expression of verilog type +typI+ returning 
        # verilog type +typR+.
        def add(typI,typR)
            # Add them
            @indexers << [typI,typR]
        end
        alias_method :<<, :add


        # Generate an indexer function name for expression of verilog type
        # +typI+ returning verilog type +typR+.
        def indexer_name(typI,typR)
            # Generate the name.
            return "indexer_#{name_to_verilog(typI)}_#{name_to_verilog(typR)}"
        end

        # Generate the indexing functions.
        def dump
            # Ensure there is only one indexing function per range.
            @indexers.sort!.uniq!
            # Generate the resulting code.
            codeT = ""
            @indexers.each do |(typI,typR)|
                codeT << "     function #{typR} "
                codeT << self.indexer_name(typI,typR) 
                codeT << "(input #{typI} val, input integer idx);\n"
                codeT << "         " << self.indexer_name(typI,typR) << " = "
                codeT << "val[idx];\n"
                codeT << "      endfunction\n\n"
            end
            # Clears the indexers.
            @indexers = []
            return codeT
        end
    end

    # Declaration of the truncating function generator.
    IndexersI = Indexers.new


    class Binary
        ## Enhances Binary with verilog generation.

        # Converts the system to Verilog code.
        def to_verilog
            # In HDLRuby if on term is signed and the other is not, the
            # computation is signed.
            if self.left.type.signed? and self.right.type.unsigned? then
                return "(#{self.left.to_verilog} #{self.operator} " +
                    "$signed({1'b0,#{self.right.to_verilog}}))"
            elsif self.left.type.unsigned? and right.type.signed? then
                return "($signed({1'b0,#{self.left.to_verilog}})" +
                    " #{self.operator} #{self.right.to_verilog})"
            else
                return "(#{self.left.to_verilog} #{self.operator} #{self.right.to_verilog})"
            end
        end

        # Method called when two or more expression terms are present.
        # When translating par into seq mode = seq, when translating seq to par mode = par.
        # Search recursively and replace if hash matches identifier.
        def to_change(mode)
            # Recursively search the left side and the right side, check the identifier and replace it.
            if self.left.is_a? (Binary) then
                # If there is an expression on the left side of the right side, to_chang is executed again.
                left = self.left.to_change(mode)
            else
                # If you need to replace the variable, replace it. Otherwise we will get a clone.
                if FmI.fm_par.has_key?(self.left.to_verilog) && mode == :par then
                    left = FmI.fm_par["#{self.left.to_verilog}"]
                elsif FmI.fm_seq.has_key?(self.left.to_verilog) && mode == :seq then
                    left = FmI.fm_seq["#{self.left.to_verilog}"]
                else
                    left = self.left.clone
                end
            end
            if self.right.is_a? (Binary) then
                # Recursively search the right side and the right side, check the identifier and replace it.
                right = self.right.to_change(mode)
            else
                # If you need to replace the variable, replace it. Otherwise we will get a clone.
                if FmI.fm_par.has_key?(self.right.to_verilog) && mode == :par then
                    right = FmI.fm_par["#{self.right.to_verilog}"]
                elsif FmI.fm_seq.has_key?(self.right.to_verilog) && mode == :seq then
                    right = FmI.fm_seq["#{self.right.to_verilog}"]
                else
                    right = self.right.clone
                end
            end
            # After confirmation, we create and return an expression.
            return Binary.new(self.type,self.operator,left.clone,right.clone)
        end
    end


    class Transmit
        ## Enhances Transmit with generation of verilog code.

        # Converts the system to Verilog code.
        def to_verilog(spc = 3)
            # Determine blocking assignment or nonblocking substitution from mode and return it.
            code = "#{" " * spc}#{self.left.to_verilog} #{self.block.mode == :seq ? "=" : "<="} #{self.right.to_verilog};"
            return code
        end
    end


    class Print
        ## Enhances Print with generation of verilog code.

        # Converts the print to Verilog code.
        def to_verilog(spc = 3)
            code = "#{" " * spc}$write(#{self.each_arg.map do |arg|
            arg.to_verilog
            end.join(",") });"
            return code
        end
    end


    class TimeTerminate
        ## Enhances TimeTerminate with generation of verilog code.

        # Converts the terminate to Verilog code.
        def to_verilog(spc = 3)
            return "#{" " * spc}$finish;"
        end
    end


    class Block
        ## Enhances Block with generation of verilog code.
        # To scheduling to the Block.

        # Converts the system to Verilog code adding 'spc' spaces at the begining
        # of each line.
        # NOTE: if +vcdmodule+ is not nil add code for generating vcd file when simulating
        def to_verilog(spc = 3, vcdmodule = nil)
            code = "begin"
            if self.name && !self.name.empty? then
                vname = name_to_verilog(self.name)
                code << " : #{vname}"
                # self.properties[:verilog_name] = vname
            end
            code << "\n" if block.each_inner.any?
            # Declaration of "inner" part within "always".
            block.each_inner do |inner|
                if HDLRuby::Low::VERILOG_REGS.include?(inner.to_verilog) then
                    code << "#{" " * (spc+3)}reg"
                else
                    code << "#{" " * (spc+3)}wire"
                end

                # Variable has "base", but if there is width etc, it is not in "base".
                # It is determined by an if.
                if inner.type.base? 
                    if inner.type.base.base? 
                        code << "#{inner.type.base.to_verilog} #{inner.to_verilog} #{inner.type.to_verilog}"
                    else
                        code << "#{inner.type.to_verilog} #{inner.to_verilog}"
                    end
                else
                    code << " #{inner.type.to_verilog}#{inner.to_verilog}"
                end
                if inner.value then
                    # There is an initial value.
                    code << " = #{inner.value.to_verilog}"
                end
                code << ";\n"
            end

            # Make the generation of vcd file if required.
            if vcdmodule then
                code << "\n#{" " * (spc+3)}$dumpfile(\"verilog_simulator.vcd\");"
                code << "\n#{" " * (spc+3)}$dumpvars(0,#{vcdmodule});\n"
            end

            # Translate the block that finished scheduling.
            block.each_statement do |statement|
                # puts "#{statement.to_verilog(spc+3)}"
                if statement.is_a?(Block) then
                    code << "\n#{" " * (spc+3)}#{statement.to_verilog(spc+3)}"
                else
                    code  << "\n#{statement.to_verilog(spc+3)}"
                end
            end
            # Close the block."
            code << "\n#{" "*spc}end"
            return code
        end





        # Deprecated with new TimeRepeat!
        #
        # # Extract and convert to verilog the TimeRepeat statements.
        # # NOTE: work only on the current level of the block (should be called
        # # through each_block_deep).
        # def repeat_to_verilog!
        #     code = ""
        #     # Gather the TimeRepeat statements.
        #     repeats = self.each_statement.find_all { |st| st.is_a?(TimeRepeat) }
        #     # Remove them from the block.
        #     repeats.each { |st| self.delete_statement!(st) }
        #     # Generate them separately in timed always processes.
        #     repeats.each do |st|
        #         code << "   always #{st.delay.to_verilog} begin\n"

        #         # Perform "scheduling" using the method "flatten".
        #         block = st.statement.flatten(st.statement.mode.to_s)

        #         # Declaration of "inner" part within "always".
        #         block.each_inner do |inner|
        #             # if regs.include?(inner.name) then
        #             if HDLRuby::Low::VERILOG_REGS.include?(inner.to_verilog) then
        #                 code << "      reg"
        #             else
        #                 code << "      wire"
        #             end

        #             # Variable has "base", but if there is width etc, it is not in "base".
        #             # It is determined by an if.
        #             if inner.type.base? 
        #                 if inner.type.base.base? 
        #                     code << "#{inner.type.base.to_verilog} #{inner.to_verilog} #{inner.type.to_verilog}"
        #                 else
        #                     code << "#{inner.type.to_verilog} #{inner.to_verilog}"
        #                 end
        #             else
        #                 code << " #{inner.type.to_verilog}#{inner.to_verilog}"
        #             end
        #             if inner.value then
        #                 # There is an initial value.
        #                 code << " = #{inner.value.to_verilog}"
        #             end
        #             code << ";\n"
        #         end

        #         # Translate the block that finished scheduling.
        #         block.each_statement do |statement|
        #             code  << "\n      #{statement.to_verilog(block.mode.to_s)}"
        #         end

        #         FmI.fm_par.clear()

        #         code << "\n   end\n\n"
        #     end
        #     return code
        # end


        # Process top layer of Block.
        # Determine whether there is a block under block and convert it.
        def flatten(mode = nil)
            if self.is_a?(TimeBlock) then
                new_block = TimeBlock.new(self.mode,"")
            else
                new_block  = Block.new(self.mode,"") # A new block to store the converted statement.
            end
            list = []                            # A list for confirming that variable declarations do not overlap.

            # Is block in the statement?
            if (self.each_statement.find {|stmnt| stmnt.is_a?(Block)}) then
                # Process for each type of statement in block.
                self.each_statement do |statement|
                    # If statement is case, there is a block for each default and when, so translate each.      
                    if statement.is_a?(Case) then
                        if statement.default.is_a?(Block)
                            default = statement.default.flatten
                            new_default = Block.new(default.mode,"")

                            default.each_inner do |inner|          
                                # I read inner, but when I am par, I delete all '.
                                unless (list.include?(inner.name.to_s)) then
                                    if (self.mode == :seq) || (inner.name.to_s.include? "#") then
                                        list << inner.name.to_s
                                        new_block.add_inner(inner.clone)
                                    end            
                                end
                            end

                            default.each_statement do |statement|
                                # If statement is Transmit, it is an expression and should be processed.
                                if statement.is_a?(Transmit) then
                                    # If you add a # to the one with 'on the left side, the shape of the formula will collapse and it will be removed.
                                    unless (res_name(statement.left).name.to_s.include? "'") || default.mode == :par then
                                        # Prepare a new signal with the # on the variable on the left side using the att_signal method.
                                        new_signal = att_signal(statement.left, "#")
                                        # Check list and add new variables to inner if they do not duplicate.
                                        unless (list.include?(new_signal.name.to_s)) then
                                            list << new_signal.name.to_s
                                            new_block.add_inner(new_signal)
                                        end

                                        new_statement = Transmit.new(search_refname(statement.left,"#"),statement.right.clone)

                                        FmI.rep_sharp[statement.left] = search_refname(statement.left,"#")

                                        FmI.fm_par["#{statement.left.to_verilog}"] = new_statement.left
                                        new_default.add_statement(new_statement.clone)
                                    else
                                        new_default.add_statement(statement.clone)
                                    end 
                                else
                                    new_default.add_statement(statement.clone)
                                end
                            end     
                        end

                        new_statement = Case.new(statement.value.clone,statement.default ? new_default.clone : nil,[])

                        statement.each_when do |whens|
                            when_smt = whens.statement.flatten
                            new_when_smt = Block.new(when_smt.mode,"")

                            when_smt.each_statement do |statement|
                                # If statement is Transmit, it is an expression and should be processed.
                                if statement.is_a?(Transmit) then
                                    # # If you add a # to the one with 'on the left side, the shape of the formula will collapse and it will be removed.
                                    unless (res_name(statement.left).name.to_s.include? "'") || when_smt.mode == :par then
                                        # # Prepare a new signal with the # on the variable on the left side using the att_signal method.
                                        new_signal = att_signal(statement.left, "#")
                                        # Check list and add new variables to inner if they do not duplicate.
                                        unless (list.include?(new_signal.name.to_s)) then
                                            list << new_signal.name.to_s
                                            new_block.add_inner(new_signal)
                                        end

                                        new_smt = Transmit.new(search_refname(statement.left,"#"),statement.right.clone)

                                        FmI.rep_sharp[statement.left] = search_refname(statement.left,"#")

                                        FmI.fm_par["#{statement.left.to_verilog}"] = new_smt.left
                                        new_when_smt.add_statement(new_smt.clone)
                                    else
                                        new_when_smt.add_statement(statement.clone)
                                    end 
                                else
                                    new_when_smt.add_statement(statement.clone)
                                end
                            end

                            new_when = When.new(whens.match.clone,new_when_smt.clone)
                            new_statement.add_when(new_when.clone)
                        end

                        new_block.add_statement(new_statement)

                        FmI.rep_sharp.each_key do |key|
                            new_smt = Transmit.new(key.clone,FmI.rep_sharp[key].clone)
                            new_block.add_statement(new_smt.clone)
                        end
                        FmI.rep_sharp.clear() # Deactivate rep that has become obsolete.

                        # If the statement is if, there is a block for each of yes, no, noifs, so translate each.
                    elsif statement.is_a?(If) then   
                        yes = statement.yes.flatten       # Smooth yes of if statement. 
                        new_yes = Block.new(yes.mode,"")  # New yes storage block

                        yes.each_inner do |inner|          
                            # I read inner, but when I am par, I delete all '.
                            unless (list.include?(inner.name.to_s)) then
                                if (self.mode == :seq) || (inner.name.to_s.include? "#") then
                                    list << inner.name.to_s
                                    new_block.add_inner(inner.clone)
                                end            
                            end
                        end

                        # Check the statements in "yes" in order.
                        yes.each_statement do |statement|
                            # If statement is Transmit, it is an expression and should be processed.
                            if statement.is_a?(Transmit) then
                                # If you add a # to the one with 'on the left side, the shape of the formula will collapse and it will be removed.
                                unless (res_name(statement.left).name.to_s.include? "'") || yes.mode == :par then
                                    # Prepare a new signal with the # on the variable on the left side using the att_signal method.
                                    new_signal = att_signal(statement.left, "#")
                                    # Check list and add new variables to inner if they do not duplicate.
                                    unless (list.include?(new_signal.name.to_s)) then
                                        list << new_signal.name.to_s
                                        new_block.add_inner(new_signal)
                                    end

                                    new_statement = Transmit.new(search_refname(statement.left,"#"),statement.right.clone)

                                    FmI.rep_sharp[statement.left] = search_refname(statement.left,"#")

                                    new_yes.add_statement(new_statement.clone)


                                    FmI.fm_par["#{statement.left.to_verilog}"] = new_statement.left

                                else
                                    new_yes.add_statement(statement.clone)
                                end 
                            else
                                new_yes.add_statement(statement.clone)
                            end
                        end

                        # Confirm that "else" exists and convert it if it exists.
                        # Because error occurs when trying to convert when "else" does not exist.
                        if statement.no.is_a? (Block) then
                            no = statement.no.flatten
                            new_no = Block.new(no.mode,"")

                            no.each_inner do |inner|          
                                # I read inner, but when I am par, I delete all '.
                                unless (list.include?(inner.name.to_s)) then
                                    if (self.mode == :seq) || (inner.name.to_s.include? "#") then
                                        list << inner.name.to_s
                                        new_block.add_inner(inner.clone)
                                    end            
                                end
                            end

                            no.each_statement do |statement|
                                # If statement is Transmit, it is an expression and should be processed.
                                if statement.is_a?(Transmit) then
                                    # If you add a # to the one with 'on the left side, the shape of the formula will collapse and it will be removed.
                                    unless (res_name(statement.left).name.to_s.include? "'") || yes.mode == :par then

                                        new_signal = att_signal(statement.left, "#")

                                        # Double declaration of existing variable can not be done, so it is excluded.
                                        unless (list.include?(new_signal.name.to_s)) then
                                            list << new_signal.name.to_s
                                            new_block.add_inner(new_signal)
                                        end

                                        new_statement = Transmit.new(search_refname(statement.left,"#"),statement.right.clone)

                                        FmI.rep_sharp[statement.left] = search_refname(statement.left,"#")

                                        FmI.fm_par["#{statement.left.to_verilog}"] = new_statement.left
                                        new_no.add_statement(new_statement.clone)
                                    else
                                        new_no.add_statement(statement.clone)
                                    end 
                                else
                                    new_no.add_statement(statement.clone)
                                end
                            end
                        end

                        # Rebuild the converted "if" as a new" statement (If)".
                        new_statement = If.new(statement.condition.clone,new_yes.clone,statement.no ? new_no.clone : nil)

                        # Just like "no", check if "noifs (elsif)" exists and if there is, take one by one and convert.
                        # After that, add the converted "noif" to "If".
                        statement.each_noif do |condition, block|
                            noif = block.flatten
                            new_noif = Block.new(noif.mode,"")

                            noif.each_inner do |inner|          
                                # I read inner, but when I am par, I delete all '.
                                unless (list.include?(inner.name.to_s)) then
                                    if (self.mode == :seq) || (inner.name.to_s.include? "#") then
                                        list << inner.name.to_s
                                        new_block.add_inner(inner.clone)
                                    end            
                                end
                            end


                            noif.each_statement do |statement|
                                # If statement is Transmit, it is an expression and should be processed.
                                if statement.is_a?(Transmit) then
                                    # If you add a # to the one with 'on the left side, the shape of the formula will collapse and it will be removed.
                                    unless (res_name(statement.left).name.to_s.include? "'") || yes.mode == :par then

                                        new_signal = att_signal(statement.left, "#")

                                        # Double declaration of existing variable can not be done, so it is excluded.
                                        unless (list.include?(new_signal.name.to_s)) then
                                            list << new_signal.name.to_s
                                            new_block.add_inner(new_signal)
                                        end

                                        new_statement = Transmit.new(search_refname(statement.left,"#"),statement.right.clone)

                                        FmI.rep_sharp[statement.left] = search_refname(statement.left,"#")

                                        FmI.fm_par["#{statement.left.to_verilog}"] = new_statement.left
                                        new_noif.add_statement(new_statement.clone)
                                    else
                                        new_noif.add_statement(statement.clone)
                                    end 
                                else
                                    new_noif.add_statement(statement.clone)
                                end
                            end

                            new_statement.add_noif(condition.clone,new_noif.clone)
                        end

                        new_block.add_statement(new_statement.clone)

                        FmI.rep_sharp.each_key do |key|
                            new_smt = Transmit.new(key.clone,FmI.rep_sharp[key].clone)
                            new_block.add_statement(new_smt.clone)
                        end
                        FmI.rep_sharp.clear() # Deactivate rep that has become obsolete.

                        # Process when "statement" is "Transmit" (just expression).
                        # Record the expression in fm_par used for par-> seq and add the expression to new_block which is the "new block".
                    elsif statement.is_a?(Transmit) then
                        if self.mode == :seq then
                            FmI.fm_par["#{statement.left.to_verilog}"] = statement.right
                        end
                        new_block.add_statement(statement.clone)

                        # When statement is Block (lower layer exists).
                        # Smooth the lower layer with do_flat.
                        # Add the added variables (inner) and expressions (statement) to new_block, respectively.
                    elsif statement.is_a?(Block) then
                        smt = statement.do_flat(self.mode)

                        smt.each_inner do |inner|         
                            # I read inner, but when I am par, I delete all '.
                            unless (list.include?(inner.name.to_s)) then
                                if (self.mode == :seq) || (inner.name.to_s.include? "#") then
                                    list << inner.name.to_s
                                    new_block.add_inner(inner.clone)        
                                end
                            end
                        end
                        smt.each_statement do |tmt|
                            # Retrieve the RefName of the variable on the left side and store it in this_name.
                            if ((tmt.is_a? (Transmit)) && (self.mode == :seq)) then
                                FmI.fm_par["#{tmt.left.to_verilog}"] = tmt.right
                            end
                            new_block.add_statement(tmt.clone)           
                        end
                    else
                        # Other statements are simply added as is.
                        new_block.add_statement(statement.clone)
                    end
                end

                return new_block # Return the new_block that completed the smoothing.

                # Processing when there is no block beneath.
                # Unlike ordinary "if" and "case" blocks come down, we check individually block under block.
            else
                self.each_statement do |statement|
                    # If the if statement, convert it, otherwise add it as is
                    if statement.is_a?(If) then
                        # Since yes always exists, it is no problem even if it is converted as it is.
                        yes = statement.yes.flatten 
                        new_yes = Block.new(yes.mode,"")

                        yes.each_inner do |inner|          
                            # I read inner, but when I am par, I delete all '.
                            unless (list.include?(inner.name.to_s)) then
                                if (yes.mode == :seq) || (inner.name.to_s.include? "#") then
                                    list << inner.name.to_s
                                    new_block.add_inner(inner.clone)
                                end            
                            end
                        end

                        # Check the statements in "yes" in order.
                        yes.each_statement do |statement|
                            # If statement is Transmit, it is an expression and should be processed.
                            if statement.is_a?(Transmit) then
                                # If you add a # to the one with 'on the left side, the shape of the formula will collapse and it will be removed.
                                unless (res_name(statement.left).name.to_s.include? "'") || yes.mode == :par then
                                    # Generate a new signal to return #.
                                    new_signal = att_signal(statement.left, "#")

                                    # Double declaration of existing variable can not be done, so it is excluded.
                                    unless (list.include?(new_signal.name.to_s)) then
                                        list << new_signal.name.to_s
                                        new_block.add_inner(new_signal)
                                    end

                                    new_statement = Transmit.new(search_refname(statement.left,"#"),statement.right.clone)

                                    FmI.rep_sharp[statement.left] = search_refname(statement.left,"#")

                                    FmI.fm_par["#{statement.left.to_verilog}"] = new_statement.left
                                    new_yes.add_statement(new_statement.clone)
                                else
                                    new_yes.add_statement(statement.clone)
                                end 
                            else
                                new_yes.add_statement(statement.clone)
                            end
                        end

                        # Confirm that "else" exists and convert it if it exists.
                        # Because error occurs when trying to convert when "else" does not exist.
                        if statement.no.is_a? (Block) then          
                            no = statement.no.flatten
                            new_no = Block.new(no.mode,"")

                            no.each_inner do |inner|          
                                # I read inner, but when I am par, I delete all '.
                                unless (list.include?(inner.name.to_s)) then
                                    if (no.mode == :seq) || (inner.name.to_s.include? "#") then
                                        list << inner.name.to_s
                                        new_block.add_inner(inner.clone)
                                    end            
                                end
                            end

                            no.each_statement do |statement|
                                # If statement is Transmit, it is an expression and should be processed.
                                if statement.is_a?(Transmit) then
                                    # If you add a # to the one with 'on the left side, the shape of the formula will collapse and it will be removed.
                                    unless (res_name(statement.left).name.to_s.include? "'") || no.mode == :par then

                                        new_signal = att_signal(statement.left, "#")

                                        # Double declaration of existing variable can not be done, so it is excluded.
                                        unless (list.include?(new_signal.name.to_s)) then
                                            list << new_signal.name.to_s
                                            new_block.add_inner(new_signal)
                                        end

                                        new_statement = Transmit.new(search_refname(statement.left,"#"),statement.right.clone)

                                        FmI.rep_sharp[statement.left] = search_refname(statement.left,"#")

                                        FmI.fm_par["#{statement.left.to_verilog}"] = new_statement.left
                                        new_no.add_statement(new_statement.clone)
                                    else
                                        new_no.add_statement(statement.clone)
                                    end 
                                else
                                    new_no.add_statement(statement.clone)
                                end
                            end
                        end
                        # Rebuild the converted "if" as a new" statement (If)".
                        new_statement = If.new(statement.condition.clone,new_yes.clone,statement.no ? new_no.clone : nil)
                        # Just like "no", check if "noifs (elsif)" exists and if there is, take one by one and convert.
                        # After that, add the converted "noif" to "If".
                        statement.each_noif do |condition, block|

                            noif = block.flatten
                            new_noif = Block.new(noif.mode,"")

                            noif.each_inner do |inner|          
                                # I read inner, but when I am par, I delete all '.
                                unless (list.include?(inner.name.to_s)) then
                                    if (noif.mode == :seq) || (inner.name.to_s.include? "#") then
                                        list << inner.name.to_s
                                        new_block.add_inner(inner.clone)
                                    end            
                                end
                            end


                            noif.each_statement do |statement|
                                # If statement is Transmit, it is an expression and should be processed.
                                if statement.is_a?(Transmit) then
                                    # If you add a # to the one with 'on the left side, the shape of the formula will collapse and it will be removed.
                                    unless (res_name(statement.left).name.to_s.include? "'") || noif.mode == :par then

                                        new_signal = att_signal(statement.left, "#")

                                        # Double declaration of existing variable can not be done, so it is excluded.
                                        unless (list.include?(new_signal.name.to_s)) then
                                            list << new_signal.name.to_s
                                            new_block.add_inner(new_signal)
                                        end

                                        new_statement = Transmit.new(search_refname(statement.left,"#"),statement.right.clone)

                                        FmI.rep_sharp[statement.left] = search_refname(statement.left,"#")

                                        FmI.fm_par["#{statement.left.to_verilog}"] = new_statement.left
                                        new_noif.add_statement(new_statement.clone)
                                    else
                                        new_noif.add_statement(statement.clone)
                                    end 
                                else
                                    new_noif.add_statement(statement.clone)
                                end
                            end

                            new_statement.add_noif(condition.clone,new_noif.clone)
                        end

                        new_block.add_statement(new_statement.clone)

                        FmI.rep_sharp.each_key do |key|
                            new_smt = Transmit.new(key.clone,FmI.rep_sharp[key].clone)
                            new_block.add_statement(new_smt.clone)
                        end
                        FmI.rep_sharp.clear() # Deactivate rep that has become obsolete.

                    elsif statement.is_a?(Case) then
                        if statement.default.is_a?(Block)
                            new_default = statement.default.flatten
                        end

                        new_statement = Case.new(statement.value.clone,statement.default ? new_default.clone : nil,[])
                        statement.each_when do |whens|
                            new_when_statement = whens.statement.flatten
                            new_when = When.new(whens.match.clone,new_when_statement.clone)

                            new_statement.add_when(new_when.clone)
                        end

                        new_block.add_statement(new_statement)
                    else          
                        new_block.add_statement(statement.clone)
                    end
                end    
                return new_block
            end
        end

        def do_flat(mode = nil)
            flat  = Block.new(self.mode,"")   # Block between lower layers when converting.
            trans = Block.new(self.mode,"")   # The block used for converting itself.
            replase = Block.new(self.mode,"") # block to be used for further conversion in case of if statement.
            list = []
            rep_list = []

            # If there is a block inside the statement it is not the lowest layer. If there is, it is the lowest layer.      
            if (self.each_statement.find {|stmnt| stmnt.is_a?(Block)} || (self.each_statement.find {|stmnt| stmnt.is_a?(If)}) || (self.each_statement.find {|stmnt| stmnt.is_a?(Case)}))then
                # In the case of seq, the lower layer is par. Isolate fm_par so that it is not crosstalked.
                if(self.mode == :seq) then
                    fm_buckup = FmI.fm_par.clone
                    FmI.fm_par.clear()

                    new_block = change_branch(self)
                else
                    new_block = self.clone      
                end

                # Process for each statement.
                new_block.each_statement do |statement|
                    # If statement is If, convert yes, no, noif and add them to flat.
                    if statement.is_a?(Case) then
                        if(self.mode == :seq) then
                            fm_buckup_if = FmI.fm_par.clone
                        end

                        if statement.default.is_a?(Block)
                            default = statement.default.flatten    
                            new_default = Block.new(default.mode,"")

                            default.each_statement do |statement|
                                new_default.add_statement(statement.clone)
                            end     
                        end


                        new_statement = Case.new(statement.value.clone,statement.default ? new_default.clone : nil,[])

                        statement.each_when do |whens|
                            if(self.mode == :seq) then
                                fm_buckup_if.each_key do |key|
                                    FmI.fm_par[key] = fm_buckup_if[key]
                                end
                            end

                            when_smt = whens.statement.flatten
                            new_when = When.new(whens.match.clone,when_smt.clone)
                            new_statement.add_when(new_when.clone)
                        end
                        flat.add_statement(new_statement)

                    elsif statement.is_a?(If) then
                        if(self.mode == :seq) then
                            fm_buckup_if = FmI.fm_par.clone
                        end

                        # Since yes always exist, convert without confirming.
                        new_yes = statement.yes.flatten

                        # I do not know whether no (else) exists, so convert it if it is confirmed.
                        if statement.no.is_a? (Block) then

                            if(self.mode == :seq) then
                                fm_buckup_if.each_key do |key|
                                    FmI.fm_par[key] = fm_buckup_if[key]
                                end
                            end

                            new_no = statement.no.flatten
                        end
                        # Create a new if statement with converted yes and no.
                        new_statement = If.new(statement.condition.clone,new_yes.clone,statement.no ? new_no.clone : nil)

                        # Since I do not know whether there is noifs (elsif), I convert it and add it if it is confirmed.
                        statement.each_noif do |condition, block|
                            if(self.mode == :seq) then
                                fm_buckup_if.each_key do |key|
                                    FmI.fm_par[key] = fm_buckup_if[key]
                                end
                            end

                            new_noif = block.flatten         
                            new_statement.add_noif(condition.clone,new_noif.clone)
                        end
                        # Add the new statement (if statement) created to flat.
                        flat.add_statement(new_statement.clone)

                        # If statement is Transmit, record the expression in fm_par and add the expression to flat as it is.
                    elsif statement.is_a?(Transmit) then
                        if(self.mode == :seq) then
                            FmI.fm_par["#{statement.left.to_verilog}"] = statement.right.clone
                        end

                        flat.add_statement(statement.clone)
                        # If statement is Block, convert it with do_flat and add the returned expression and variable to flat respectively.

                    elsif statement.is_a?(Block) then
                        smt = statement.do_flat(self.mode)
                        # If smt has inner, check it separately and add it if it's convenient.
                        smt.each_inner do |inner|
                            if self.mode == :seq then
                                unless (list.include?(inner.name.to_s)) then
                                    list << inner.name.to_s
                                    flat.add_inner(inner.clone)
                                end
                            else
                                unless (list.include?(inner.name.to_s)) then
                                    if(inner.name.to_s.include? "#") then
                                        list << inner.name.to_s
                                        flat.add_inner(inner.clone) # It was new_block. why?
                                    end
                                end            
                            end
                        end
                        # If it is seq, the expression after conversion is also likely to be used, so record the expression.
                        smt.each_statement do |tmt|
                            if self.mode == :seq then
                                FmI.fm_par["#{tmt.left.to_verilog}"] = tmt.right.clone
                            end
                            flat.add_statement(tmt.clone)
                        end         
                    end
                end

                # Overwrite to restore fm_par which was quarantined.
                if(self.mode == :seq) then
                    FmI.fm_par.clear()
                    fm_buckup.each_key do |key|
                        FmI.fm_par[key] = fm_buckup[key]
                    end
                end



                # Since it is a middle tier itself, it performs flat transformation, shifts inner, and returns the result.
                trans = flat.to_conversion(mode)


                # Write an expression that assigns an identifier that added # to an identifier that has not added.
                trans.each_statement do |statement|
                    replase.add_statement(statement.clone)
                    if statement.is_a?(If)
                        FmI.rep_sharp.each_key do |key|
                            new_statement = Transmit.new(key.clone,FmI.rep_sharp[key].clone)
                            replase.add_statement(new_statement.clone)
                        end
                        FmI.rep_sharp.clear() # Deactivate rep that has become obsolete.
                    end
                end

                # Extract the inner left in flat and add it to replase.
                flat.each_inner do |inner|
                    replase.add_inner(inner.clone)
                end

                # Extract the inner left in trans and add it to replase.
                trans.each_inner do |inner|
                    replase.add_inner(inner.clone)
                end

                return replase

                # Processing when there is no block (reaching the bottom layer).
            else
                # Since it is the lowest layer, it does not smooth but converts itself and returns it.
                flat = self.to_conversion(mode)
                return flat
            end
        end

        def to_conversion(mode = nil, rst = true, rep = true)
            flat = Block.new(mode,"")      # Block that stores results.
            new_yes = Block.new(mode,"")   # Block containing the new yes.
            new_no  = Block.new(mode,"")   # Block containing the new no.
            new_noif  = Block.new(mode,"") # Block containing the new noif.
            list = []

            if rst == false then
                fm_seq_backup = FmI.fm_seq.dup
            end

            # The statement is divided (since it is the lowest layer, there is only Transmit).
            self.each_statement do |statement|
                # Various processing is performed depending on the type of Transmit.
                # If the mode of the upper layer = its own mode, it compresses as it is.

                if(mode == self.mode) then        
                    new_statement = statement.clone
                    # In the case of an If statement, processing of if, else, elsif is performed.
                elsif statement.is_a?(Case) then

                    if statement.default.is_a?(Block)
                        rep_buckup = FmI.rep.dup
                        FmI.rep.clear()
                        default = statement.default.to_conversion(mode,false,false)
                        FmI.rep.clear()
                        rep_buckup.each_key do |key|
                            FmI.rep[key] = rep_buckup[key]
                        end

                        new_default = Block.new(default.mode,"")

                        default.each_inner do |inner|          
                            # I read inner, but when I am par, I delete all '.
                            unless (list.include?(inner.name.to_s)) then
                                if (self.mode == :seq) || (inner.name.to_s.include? "#") then
                                    list << inner.name.to_s
                                    flat.add_inner(inner.clone)
                                end            
                            end
                        end

                        default.each_statement do |statement|
                            # If statement is Transmit, it is an expression and should be processed.
                            if statement.is_a?(Transmit) then
                                # If you add a # to the one with 'on the left side, the shape of the formula will collapse and it will be removed.
                                unless (res_name(statement.left).name.to_s.include? "'") || default.mode == :par then
                                    # Prepare a new signal with the # on the variable on the left side using the att_signal method.
                                    new_signal = att_signal(statement.left, "#")
                                    # Check list and add new variables to inner if they do not duplicate.
                                    unless (list.include?(new_signal.name.to_s)) then
                                        list << new_signal.name.to_s
                                        flat.add_inner(new_signal)
                                    end

                                    new_smt = Transmit.new(search_refname(statement.left,"#"),statement.right.clone)

                                    FmI.rep_sharp[statement.left] = search_refname(statement.left,"#")

                                    FmI.fm_par["#{statement.left.to_verilog}"] = new_smt.left
                                    new_default.add_statement(new_smt.clone)
                                else
                                    new_default.add_statement(statement.clone)
                                end 
                            else
                                new_default.add_statement(statement.clone)
                            end
                        end     
                    end


                    new_statement = Case.new(statement.value.clone,statement.default ? new_default.clone : nil,[])

                    statement.each_when do |whens|

                        rep_buckup = FmI.rep.dup
                        FmI.rep.clear()
                        when_smt = whens.statement.to_conversion(mode,false,false)
                        FmI.rep.clear()
                        rep_buckup.each_key do |key|
                            FmI.rep[key] = rep_buckup[key]
                        end

                        new_when_smt = Block.new(when_smt.mode,"")

                        when_smt.each_statement do |statement|
                            # If statement is Transmit, it is an expression and should be processed.
                            if statement.is_a?(Transmit) then
                                # If you add a # to the one with 'on the left side, the shape of the formula will collapse and it will be removed.
                                unless (res_name(statement.left).name.to_s.include? "'") || when_smt.mode == :par then
                                    # Prepare a new signal with the # on the variable on the left side using the att_signal method.
                                    new_signal = att_signal(statement.left, "#")
                                    # Check list and add new variables to inner if they do not duplicate.
                                    unless (list.include?(new_signal.name.to_s)) then
                                        list << new_signal.name.to_s
                                        flat.add_inner(new_signal)
                                    end

                                    new_smt = Transmit.new(search_refname(statement.left,"#"),statement.right.clone)

                                    FmI.rep_sharp[statement.left] = search_refname(statement.left,"#")

                                    FmI.fm_par["#{statement.left.to_verilog}"] = new_smt.left
                                    new_when_smt.add_statement(new_smt.clone)
                                else
                                    new_when_smt.add_statement(statement.clone)
                                end 
                            else
                                new_when_smt.add_statement(statement.clone)
                            end
                        end

                        new_when = When.new(whens.match.clone,new_when_smt.clone)
                        new_statement.add_when(new_when.clone)
                    end

                elsif statement.is_a?(If) then

                    rep_buckup = FmI.rep.dup
                    FmI.rep.clear()
                    yes = statement.yes.to_conversion(mode, false,false)
                    FmI.rep.clear()
                    rep_buckup.each_key do |key|
                        FmI.rep[key] = rep_buckup[key]
                    end

                    yes.each_inner do |inner|
                        unless (list.include?(inner.name.to_s)) then
                            if (yes.mode == :seq) || (inner.name.to_s.include? "#") then
                                list << inner.name.to_s
                                flat.add_inner(inner.clone) # It was new_block. why?
                            end            
                        end
                    end

                    yes.each_statement do |smt|
                        if(yes.mode == :seq) then
                            new_signal = att_signal(smt.left, "#")

                            unless (list.include?(new_signal.name.to_s)) then
                                list << new_signal.name.to_s
                                flat.add_inner(new_signal)
                            end

                            yes_statement = Transmit.new(search_refname(smt.left,"#"),smt.right.clone)

                            FmI.rep_sharp[statement.left] = search_refname(statement.left,"#")

                            FmI.fm_par["#{smt.left.to_verilog}"] = yes_statement.left
                            new_yes.add_statement(yes_statement)
                        else
                            new_yes.add_statement(smt.clone)
                        end
                    end

                    if statement.no.is_a? (Block) then
                        rep_buckup = FmI.rep.dup
                        FmI.rep.clear()
                        no = statement.no.to_conversion(mode,false,false)
                        FmI.rep.clear()
                        rep_buckup.each_key do |key|
                            FmI.rep[key] = rep_buckup[key]
                        end

                        no.each_inner do |inner|
                            unless (list.include?(inner.name.to_s)) then
                                if (no.mode == :seq) || (inner.name.to_s.include? "#") then
                                    list << inner.name.to_s
                                    flat.add_inner(inner.clone) # It was new_block. why?
                                end            
                            end
                        end

                        no.each_statement do |smt|
                            if(no.mode == :seq) then
                                new_signal = att_signal(smt.left, "#")

                                unless (list.include?(new_signal.name.to_s)) then
                                    list << new_signal.name.to_s
                                    flat.add_inner(new_signal)
                                end

                                no_statement = Transmit.new(search_refname(smt.left,"#"),smt.right.clone)

                                FmI.rep_sharp[statement.left] = search_refname(statement.left,"#")

                                FmI.fm_par["#{smt.left.to_verilog}"] = no_statement.left
                                new_no.add_statement(no_statement)
                            else
                                new_no.add_statement(smt.clone)
                            end
                        end
                    end

                    new_statement = If.new(statement.condition.clone,new_yes.clone,statement.no ? new_no.clone : nil)

                    statement.each_noif do |condition, block|
                        rep_buckup = FmI.rep.dup
                        FmI.rep.clear()
                        noif = block.to_conversion(mode,false,false)
                        FmI.rep.clear()
                        rep_buckup.each_key do |key|
                            FmI.rep[key] = rep_buckup[key]
                        end

                        noif.each_inner do |inner|
                            unless (list.include?(inner.name.to_s)) then
                                if (noif.mode == :seq) || (inner.name.to_s.include? "#") then
                                    list << inner.name.to_s
                                    flat.add_inner(inner.clone) # It was new_block. why?
                                end            
                            end
                        end

                        noif.each_statement do |smt|
                            if(noif.mode == :seq) then
                                new_signal = att_signal(smt.left, "#")

                                unless (list.include?(new_signal.name.to_s)) then
                                    list << new_signal.name.to_s
                                    flat.add_inner(new_signal)
                                end

                                noif_statement = Transmit.new(search_refname(smt.left,"#"),smt.right.clone)

                                FmI.rep_sharp[statement.left] = search_refname(statement.left,"#")

                                FmI.fm_par["#{smt.left.to_verilog}"] = noif_statement.left
                                new_noif.add_statement(no_statement)
                            else
                                new_noif.add_statement(smt.clone)
                            end
                        end

                        new_statement.add_noif(condition.clone,new_noif.clone)
                    end

                    # Otherwise, it is necessary to process par-> seq or seq-> par.
                else       
                    # Make sure the right side is a formula (Binary).
                    if statement.right.is_a?(Binary) then
                        # Check the right side and the left side, and if they are variables, check the corresponding expressions and replace them.
                        # If it is not a variable, it calls the method to be searched.
                        if statement.right.left.is_a? (Ref) then               
                            if (mode == :par && self.mode == :seq) && FmI.fm_seq.has_key?(statement.right.left.to_verilog) then
                                statement_left = FmI.fm_seq["#{statement.right.left.to_verilog}"]
                            elsif (mode == :seq && self.mode == :par) && FmI.fm_par.has_key?(statement.right.left.to_verilog) then
                                statement_left = FmI.fm_par["#{statement.right.left.to_verilog}"]
                            else
                                statement_left = statement.right.left.clone
                            end
                        elsif statement.right.left.is_a? (Binary) then  
                            statement_left = statement.right.left.to_change(self.mode)
                        else
                            statement_left = statement.right.left.clone
                        end

                        if statement.right.right.is_a? (Ref) then
                            if (mode == :par && self.mode == :seq) && FmI.fm_seq.has_key?(statement.right.right.to_verilog) then
                                statement_right = FmI.fm_seq["#{statement.right.right.to_verilog}"]
                            elsif (mode == :seq && self.mode == :par) && FmI.fm_par.has_key?(statement.right.right.to_verilog) then
                                statement_right = FmI.fm_par["#{statement.right.right.to_verilog}"]
                            else
                                statement_right = statement.right.right.clone
                            end
                        elsif statement.right.right.is_a? (Binary) then
                            statement_right = statement.right.right.to_change(self.mode)
                        else
                            statement_right = statement.right.right.clone
                        end   
                        new_right = Binary.new(statement.right.type,statement.right.operator,statement_left.clone,statement_right.clone)
                        # Confirm whether it is a variable.
                    elsif statement.right.is_a?(Ref) then
                        if (mode == :par && self.mode == :seq) && FmI.fm_seq.has_key?(statement.right.to_verilog) then
                            new_right = FmI.fm_seq["#{statement.right.to_verilog}"].clone
                        elsif (mode == :seq && self.mode == :par) && FmI.fm_par.has_key?(statement.right.to_verilog) then
                            new_right = FmI.fm_par["#{statement.right.to_verilog}"].clone
                        else
                            new_right = statement.right.clone
                        end
                        # Because it is not a number. Put it in as it is.
                    else
                        new_right = statement.right.clone
                    end

                    if (mode == :par && self.mode == :seq) then
                        # Dock the existing left hand side and the replaced right hand side to create a new expression.
                        # Record the expression after conversion to hash to continue seq-> par.
                        new_statement = Transmit.new(statement.left.clone,new_right)
                        FmI.fm_seq["#{statement.left.to_verilog}"] = new_right
                    elsif (mode == :seq && self.mode == :par) && (rep) then
                        unless (res_name(statement.left).name.to_s.include? "#")
                            # Search the variable on the left side and give 'to the name.
                            new_signal = att_signal(statement.left,"'")

                            unless (list.include?(new_signal.name.to_s)) then
                                list << new_signal.name.to_s
                                flat.add_inner(new_signal)
                            end

                            new_statement = Transmit.new(search_refname(statement.left,"'"),new_right)

                            FmI.rep[statement.left] = new_statement     
                        end
                    else
                        new_statement = Transmit.new(statement.left.clone,new_right)
                    end          
                end
                # Add the converted statement to flat (because par -> par or seq -> seq will be added until then).

                if new_statement.is_a?(Transmit) then
                    unless (mode == :par && self.mode == :seq) && (res_name(new_statement.left).name.to_s.include? "'") then
                        flat.add_statement(new_statement.clone)
                    end
                else
                    flat.add_statement(new_statement.clone)
                end

                if (rep)
                    FmI.rep_sharp.each_key do |key|
                        new_smt = Transmit.new(key.clone,FmI.rep_sharp[key].clone)
                        flat.add_statement(new_smt.clone)
                    end
                    FmI.rep_sharp.clear() # Deactivate rep that has become obsolete.
                end
            end
            # Add an expression after paragraph based on rep.
            # A complement expression like x = x '.
            FmI.rep.each_key do |key|
                new_statement = Transmit.new(key.clone,FmI.rep[key].left.clone)
                flat.add_statement(new_statement.clone)
            end
            FmI.rep.clear() # Deactivate rep that has become obsolete.


            # Since seq -> par is the end, fm_par is deleted.
            if (mode == :par && self.mode == :seq) then
                FmI.fm_seq.clear()
            end

            # In case of if statement (when rst == false) you can not convert no or else if you delete the contents of fm_seq.
            # Therefore, in this case restore the backup to restore.
            # This means that it is necessary to erase fm_seq once obtained in the if statement once.
            if(rst == false) then
                FmI.fm_seq.clear()
                fm_seq_backup.each_key do |key|
                    FmI.fm_seq[key] = fm_seq_backup[key]
                end
            end

            return flat # Return flat finished checking.
        end


        def change_branch(block)
            flat  = Block.new(self.mode,"")     # Store the expression until if is found.
            trans = Block.new(self.mode,"")     # A block that stores the expression after if is found.
            new_block = Block.new(self.mode,"") # Block storing each converted expression.

            has_branch = false                  # It is true if there is an if in the block.
            more_has_branch = false             # It is true if there are two or more if in the block.

            # Search each expression for if.
            block.each_statement do |statement|
                if (has_branch)
                    trans.add_statement(statement.clone)
                    if statement.is_a?(If) || statement.is_a?(Case) then
                        more_has_branch = true
                    end        
                else
                    if statement.is_a?(If) || statement.is_a?(Case) then
                        flat.add_statement(statement.clone)     
                        has_branch = true          
                    else
                        flat.add_statement(statement.clone)
                    end
                end
            end

            # If there are two or more if, recursively process if.
            if(more_has_branch) then
                conversion_block = change_branch(trans)
            else
                conversion_block = trans.clone
            end

            # Store "trans" contents for "if" and "case" in "flat".
            flat.each_statement do |statement|
                # Since case statements include defaulu and when, we store the expressions saved in each case.
                if statement.is_a?(Case) then
                    if statement.default.is_a?(Block)
                        new_default = statement.default.clone 
                        conversion_block.each_statement do |smt|
                            new_default.add_statement(smt.clone)
                        end         
                    end

                    new_statement = Case.new(statement.value.clone,statement.default ? new_default.clone : nil,[])

                    statement.each_when do |whens|
                        new_when = whens.clone

                        conversion_block.each_statement do |smt|
                            new_when.statement.add_statement(smt.clone)
                        end      
                        new_statement.add_when(new_when.clone)
                    end

                    new_block.add_statement(new_statement.clone)
                    # Because there are yes, no and noifs in the if statement, store the expression saved in each.
                elsif statement.is_a?(If) then
                    new_yes = statement.yes.clone
                    conversion_block.each_statement do |smt|
                        new_yes.add_statement(smt.clone)
                    end

                    if statement.no.is_a? (Block) then
                        new_no = statement.no.clone
                        conversion_block.each_statement do |smt|
                            new_no.add_statement(smt.clone)
                        end
                    end

                    # Make new if with converted yes and no.
                    new_statement = If.new(statement.condition.clone,new_yes.clone,statement.no ? new_no.clone : nil)


                    statement.each_noif do |condition, block|
                        new_noif = block.clone
                        conversion_block.each_statement do |smt|
                            new_noif.add_statement(smt.clone)
                        end
                        new_statement.add_noif(condition.clone,new_noif.clone)
                    end
                    # Add the new statement (if) created to flat.
                    new_block.add_statement(new_statement.clone)
                else
                    new_block.add_statement(statement.clone)
                end
            end

            return new_block # Return block after conversion.
        end

        # Generate a signal for the variable to which "'" or "#" is added.
        def att_signal(left,att = "'")
            this_name = res_name(left)
            new_name = RefName.new(this_name.type, this_name.ref.clone, this_name.name.to_s + att)
            new_signal = SignalI.new(new_name.name,new_name.type)

            return new_signal
        end

        # A method that takes a variable from the sent left side and adds "att".
        def att_sharp(left,att = "'")
            new_left = search_refname(left, att)

            return new_left
        end


        # Recursively search, add "att" to RefName and return.
        def search_refname(me,att = "'")
            if me.is_a? (RefName) then
                return RefName.new(me.type, me.ref.clone, me.name.to_s + att)
            elsif me.ref.is_a? (RefName) then
                return RefName.new(me.ref.type, me.ref.ref.clone, me.ref.name.to_s + att)
            elsif me.ref.is_a? (RefIndex) then
                return RefIndex.new(me.ref.type, search_refname(me.ref), me.ref.index.clone)
            elsif me.ref.is_a? (RefRange) then
                my_range = me.ref.range
                return RefRange.new(me.ref.type, search_refname(me.ref), my_range.first.clone..my_range.last.clone)
            end
        end

        # Recursively search, return Refname.
        def res_name(me)
            if me.is_a? (RefName) then
                return me
            else
                if me.ref.is_a? (RefName) then
                    return RefName.new(me.ref.type, me.ref.ref.clone, me.ref.name.to_s)
                elsif me.ref.is_a? (RefIndex) then
                    return res_name(me.ref)
                elsif me.ref.is_a? (RefRange) then
                    return res_name(me.ref)
                end
            end
        end
    end


    class RefName
        ## Enhances RefName with generation of verilog code.

        # Converts the system to Verilog code using +renamer+ for producing Verilog-compatible names.
        def to_verilog
            if (self.ref.is_a?(RefThis)) then
                # End reference.
                vname = name_to_verilog(self.name)
            else
                # Not end reference, recurse.
                # vname = name_to_verilog(self.name) + "." + self.ref.to_verilog 
                vname = self.ref.to_verilog + "." + name_to_verilog(self.name)
            end
            # self.properties[:verilog_name] = vname
            return "#{vname}"
        end

        # Used for instantiation (emergency procedure).
        def to_another_verilog
            return "_#{self.name.to_s}"
        end

        def ancestor(my)
            if my.parent.parent.respond_to? (:mode) then
                return ancestor(my.parent)
            else
                return "#{my.parent.mode.to_s}#{my.mode.to_s}"
            end
        end
    end

    
    class RefIndex
        ## Enhances RefIndex with generation of verilog code.

        # Converts the system to Verilog code.
        def to_verilog
            # return "#{self.ref.to_verilog}[#{self.index.to_verilog}]"
            if self.ref.is_a?(RefName) then
                return "#{self.ref.to_verilog}[#{self.index.to_verilog}]"
            else
                # No a pure signal, need to use a function for accessing.
                at = self.ref.type.to_verilog
                rt = self.type.to_verilog
                IndexersI.add(at,rt)
                return "#{IndexersI.indexer_name(at,rt)}(#{self.ref.to_verilog},#{self.index.to_verilog})"
            end
        end
    end


    class TypeVector
        ## Enhances TypeVector with generation of verilog code.

        # Converts the system to Verilog code.
        def to_verilog
            # if self.base.name.to_s != "bit"
            if VERILOG_BASE_TYPES.include?(self.base.name.to_s)
                return " #{self.base.name.to_s}[#{self.range.first}:#{self.range.last}]"
            end
            return " [#{self.range.first}:#{self.range.last}]"
        end
    end


    class RefRange
        ## Enhances RefRange with generation of verilog code.

        # Necessary for displaying bit width (eg, specify and assign).

        # Converts the system to Verilog code.
        def to_verilog(unknown = false)
            if self.ref.is_a?(RefName) then
                return "#{self.ref.to_verilog}[#{self.range.first.to_getrange}:#{self.range.last.to_getrange}]"
            else
                # No a pure signal, need to use a function for accessing.
                # sr = self.range.first.to_i..self.range.last.to_i
                # cr = (self.type.width-1)..0
                sr = (self.range.first.to_i+1)*self.ref.type.base.width-1..
                    self.range.last.to_i*self.ref.type.base.width
                cr = (self.ref.type.width-1)..0
                TruncersI.add(cr,sr)
                return "#{TruncersI.truncer_name(cr,sr)}(#{self.ref.to_verilog})"
            end
        end
    end


    class RefConcat
        ## Enhances RefConcat with generation of verilog code.

        def to_verilog    
            ref = self.each_ref.to_a

            result = "{"
            ref[0..-2].each do |ref|
                result << "#{ref.to_verilog},"
            end
            result << "#{ref.last.to_verilog}}"

            return result
        end
    end


    class HDLRuby::BitString
        ## Enhances BitString with generation of verilog code.

        # Converts the system to Verilog code.
        def to_verilog
            return "#{self.to_s}"
        end
    end


    class Select
        ## Enhances Select with generation of verilog code.

        # Converts the system to Verilog code.
        def to_verilog
            # Outputs the first and second choices (choice (0) and choice (1)).
            # return "#{self.select.to_verilog} == 1 #{self.operator} #{self.get_choice(0).to_verilog} : #{self.get_choice(1).to_verilog}"
            res = ""
            sels = self.select.to_verilog
            @choices[0..-2].each_with_index do |choice,i|
                res << "#{sels} == #{i} ? #{choice.to_verilog} : "
            end
            res << @choices[-1].to_verilog
            return res
        end
    end


    class Value
        ## Enhances Value with generation of verilog code.

        # Converts the system to Verilog code.
        # If it is bit, it is b, and if it is int, it is represented by d. (Example: 4'b0000, 32'd1)
        def to_verilog(unknown = nil)
            # if self.type.base.name.to_s == "bit"
            # if self.type.unsigned? then
            #     # return "#{self.type.range.first + 1}'b#{self.content.to_verilog}"
            #     return "#{self.type.width}'b#{self.content.to_verilog}"
            # elsif self.type.name.to_s == "integer"
            #     str = self.content.to_verilog
            #     if str[0] == "-" then
            #         # Negative value.
            #         return "-#{self.type.range.first + 1}'d#{str[1..-1]}"
            #     else
            #         return "#{self.type.range.first + 1}'d#{str}"
            #     end
            # end
            # return "#{self.type.range.first + 1}'b#{self.content.to_verilog}"
            if self.content.is_a?(Numeric) then
                if self.type.signed? then
                    if self.content < 0 then
                        # str = (2**self.type.width + self.content).to_s(2)
                        str = self.content.to_s(2)
                        str = "0" * (self.type.width-str.length+1) + str[1..-1]
                        return "-#{self.type.width}'sb#{str}"
                    else
                        str = self.content.to_s(2)
                        str = "0" * (self.type.width-str.length) + str
                        return "#{self.type.width}'sb#{str}"
                    end
                else
                    return "#{self.type.width}'b#{self.content.to_s(2)}"
                end
                # return "#{self.type.width}'b#{str}"
            else
                str = self.content.to_verilog
                if self.content.negative? then
                    return "#{str.length}'sb#{str}"
                else
                    return "#{str.length}'b#{str}"
                end
            end
        end
        # How to use when simply obtaining the width
        def to_getrange
            return "#{self.content.to_verilog}"
        end
    end


    class If
        ## Enhances If with generation of verilog code.

        # # Converts the system to Verilog code.
        # def to_verilog(mode = nil)
        # Converts to Verilog code, checking adding 'spc' spaces at the begining
        # of each line.
        def to_verilog(spc = 3)

            $blocking = false

            result = " " * spc  # Indented based on space_count.

            result << "if (#{self.condition.to_verilog}) "


            # Check if there is yes (if) and output yes or less.
            if self.respond_to? (:yes)
                result << self.yes.to_verilog(spc)
            end

            # If noif (else if) exists, it outputs it.
            # Since noif is directly under, respond_to is unnecessary.
            self.each_noif do |condition, block|
                result << "\n#{" "*spc}else if (#{condition.to_verilog}) "
                result << block.to_verilog(spc)
            end

            # Check if there is no (else) and output no or less.
            if self.no.respond_to?(:mode)
                result << "\n#{" " * spc}else "
                result << self.no.to_verilog(spc)
            end

            return result
        end
    end


    class Case
        ## Enhances Case with generation of verilog code.

        # Converts to Verilog code, checking if variables are register
        # or wire adding 'spc' spaces at the begining of each line.
        def to_verilog(spc = 3)

            result = " " * spc # Indented based on space_count.

            result << "case(#{self.value.to_verilog})\n"

            # n the case statement, each branch is partitioned by when. Process each time when.
            self.each_when do |whens| 
                # Reads and stores the numbers and expressions stored in when.
                result << " " * (spc+3) + "#{whens.match.to_verilog}: "

                if whens.statement.each_statement.count >= 1 then
                    result << whens.statement.to_verilog(spc+3) << "\n"
                else
                    result << ";\n"
                end
            end
            if self.default then
                result << " " * (spc+3) + "default: "
                if self.default.each_statement.count >= 1 then
                    result << "begin\n"
                    result << self.default.each_statement.map do |stmnt|
                        stmnt.to_verilog(spc+6)
                    end.join("\n") << "\n"
                    result << " " * (spc+3) + "end\n"
                else
                    result << ";\n"
                end
            end
            result << " " * spc + "endcase\n" # Conclusion.

            return result               # Return case after translation.
        end
    end

    
    class Connection
        ## Enhances Connection with generation of verilog code.

        # Converts the system to Verilog code.

        # Method used for array.
        def array_connection(left,right)
            expression = right.each_expression.to_a
            result = ""
            expression[0..-2].each do |expression|
                result << "   assign #{left.to_verilog}[#{expression.content.to_s}] = #{expression.to_verilog};\n"
            end
            result << "   assign #{left.to_verilog}[#{expression.last.content.to_s}] = #{expression.last.to_verilog};\n"
            return result
        end

        def to_verilog
            # Decide whether to assign to array by if.
            # NOTICE: Now array assignment is done trough constant initialization, will be treated later.
            # if self.right.respond_to? (:each_expression) 
            #   array_connection(self.left,self.right);
            # else
            cnt = 0  # Use count.
            bit = -2 # Used to determine the bit width. Since there are 0 and default, -2.

            # Measure the number of choices on the right side (case statement if it is 3 or more).
            if self.right.respond_to? (:each_choice)
                choice = self.right.each_choice.to_a
                choice.each do |choice|
                    bit += 1
                end
            end

            # Three or more choices.
            if (bit > 2)
                # The bit width is obtained by converting the bit into a binary number and obtaining the size.
                bit = bit.to_s(2).size

                # Create a case statement.
                result = "   begin\n"
                result << "      case(#{self.right.select.to_verilog})\n"
                # Output other than the last one in order.
                choice[0..-2].each do |choice|
                    result << "         #{bit}'#{cnt}: #{self.left.to_verilog} = #{choice.to_verilog}\n"
                    cnt += 1
                end
                # At the end, it becomes default because it needs default.
                result << "         default: #{self.left.to_verilog} = #{choice.last.to_verilog}\n"
                result << "      endcase\n"
                result << "   end\n"
                return result
            end

            # It is not a case so call it normally.
            return "   assign #{self.left.to_verilog} = #{self.right.to_verilog};\n"
            # end
        end
    end

    
    class RefThis
        ## Enhances RefThis with generation of verilog code.

        def to_another_verilog
            return ""
        end
    end

    
    class Unary
        ## Enhances Unary with generation of verilog code.

        # Converts the system to Verilog code.
        def to_verilog
            return "#{self.operator[0]}#{self.child.to_verilog}"
        end
    end

    
    class Cast
        ## Enhances Cast with generation of verilog code.

        # Converts the system to Verilog code.
        # NOTE: the cast is rounded up size bit-width cast is not supported
        #       by traditional verilog.
        def to_verilog
            if self.child.is_a?(Value) then
                return self.child.to_verilog
            end
            # Get the type widths, used for computing extensions or truncations.
            cw = self.child.type.width
            sw = self.type.width
            if self.type.signed? then
                # Need to sign extend.
                if cw == 1 then
                    return "$signed({#{sw}{#{self.child.to_verilog}}})"
                elsif (sw>cw) then
                    # return "$signed({{#{sw-cw}{#{self.child.to_verilog}[#{cw-1}]}}," + "#{self.child.to_verilog}})"
                    if self.child.is_a?(RefName) then
                        return "$signed({{#{sw-cw}{#{self.child.to_verilog}[#{cw-1}]}}," + "#{self.child.to_verilog}})"
                    else
                        # No a pure signal, need to use a function for accessing.
                        at = self.child.type.to_verilog
                        rt = bit.to_verilog
                        IndexersI.add(at,rt)
                        return "$signed({{#{sw-cw}{#{IndexersI.indexer_name(at,rt)}(#{self.child.to_verilog},#{cw-1})}}," + "#{self.child.to_verilog}})"
                    end
                elsif (sw<cw) then
                    # Need to truncate
                    # return "$signed(#{self.child.to_verilog}[#{sw-1}:0])"
                    TruncersI.add((cw-1)..0,(sw-1)..0)
                    return "$signed(#{TruncersI.truncer_name((cw-1)..0,(sw-1)..0)}(#{self.child.to_verilog}))"
                else
                    # Only enforce signed.
                    return "$signed(#{self.child.to_verilog})"
                end
            else
                if (sw>cw) then
                    # Need to extend.
                    return "$unsigned({{#{sw-cw}{1'b0}},#{self.child.to_verilog}})"
                elsif (sw<cw) then
                    # Need to truncate
                    # return "$unsigned(#{self.child.to_verilog}[#{sw-1}:0])"
                    TruncersI.add((cw-1)..0,(sw-1)..0)
                    return "$unsigned(#{TruncersI.truncer_name((cw-1)..0,(sw-1)..0)}(#{self.child.to_verilog}))"
                else
                    # Only enforce signed.
                    return "$unsigned(#{self.child.to_verilog})"
                end
            end
        end
    end


    class SignalI
        ## Enhances SignalI with generation of verilog code.

        # Converts the system to Verilog code.
        def to_verilog
            # Convert unusable characters and return them.
            vname = name_to_verilog(self.name)
            # self.properties[:verilog_name] = vname
            return "#{vname}"
        end
    end

    
    class Type
        ## Enhances Type with generation of verilog code.

        # Converts the type to Verilog code.
        def to_verilog
            return self.name == :signed ? "#{self.name.to_s} " : ""
        end
    end

    
    class TypeDef
        ## Enhances TypeDef with generation of verilog code.

        # Converts the type to verilog code.
        def to_verilog
            return self.def.to_verilog
        end
    end

    
    class Concat
        ## Enhances Concat with generation of verilog code.

        def to_verilog    
            expression = self.each_expression.to_a

            result = "{"
            expression[0..-2].each do |expression|
                result << "#{expression.to_verilog},"
            end
            result << "#{expression.last.to_verilog}}"

            return result
        end
    end

    
    class TimeWait
        ## Enhances TimeWait with generation of verilog code.

        def to_verilog(spc = 3)
            return (" " * spc) + self.delay.to_verilog + "\n"
        end
    end


    class Delay
        ## Enhances Delay with generation of verilog code.

        def to_verilog
            time = self.value.to_s
            if(self.unit.to_s == "ps") then
                return "##{time};"
            elsif(self.unit.to_s == "ns")
                return "##{time}000;"
            elsif(self.unit.to_s == "us")
                return "##{time}000000;"
            elsif(self.unit.to_s == "ms")
                return "##{time}000000000;"
            elsif(self.unit.to_s == "s")
                return "##{time}000000000000;"
            end
        end
    end


    class TimeRepeat
        ## Enhances TimeRepeat with generation of verilog code.

        def to_verilog(spc = 3)
            result = (" " * spc) + "repeat(#{self.number})" + "\n"
            result << self.statement.to_verilog(spc+3)
        end
    end

    # Those who disappeared.
    #class SystemI
    #class TypeTuple
    #class Event

    
    class SystemT
        ## Enhances SystemT with generation of verilog code.

        ## Tells if a connection is actually a port connection.
        def port_output_connection?(connection)
            return self.each_systemI.find do |systemI|
                if connection.right.is_a?(RefName) && 
                        connection.right.ref.is_a?(RefName) &&
                        systemI.name == connection.right.ref.name
                    puts "port_connection for right=#{connection.right.name} and systemI=#{systemI.name}"
                    true
                else
                    false
                end
            end
        end

        ## Tells if an expression is a reference to port +systemI.signal+.
        def port_assign?(expr, systemI, signal)
            return expr.is_a?(RefName) && expr.name == signal.name &&
                expr.ref.is_a?(RefName) && expr.ref.name == systemI.name
        end

        ## Extracts the assignments to port +systemI.signal+ and returns
        #  the resulting reference to a port wire.
        #
        #  NOTE: assumes to_upper_space! and with_port! has been called.
        def extract_port_assign!(systemI,signal)
            # Extract the assignment.
            assign = nil
            self.each_connection.to_a.each do |connection|
                if self.port_assign?(connection.left,systemI,signal) then
                    # The left is the port.
                    # Delete the connection.
                    self.scope.delete_connection!(connection)
                    # And return a copy of the right.
                    return connection.right.clone
                elsif self.port_assign?(connection.right,systemI,signal) then
                    # The right is the port.
                    # Delete the connection.
                    self.scope.delete_connection!(connection)
                    # And return a copy of the left.
                    return connection.left.clone
                end
            end
            # No port found, nothing to do
            return nil
        end


        # Get the signals that can be declared as reg.
        # If +vname+ is given, use as base for reference name.
        def self.get_regs(expr,vname = nil)
            if expr.is_a?(RefConcat) then
                return expr.each_ref.map {|ref| self.get_regs(ref,vname) }.flatten
            elsif expr.is_a?(RefName) then
                if vname then
                    puts "vname=#{vname} expr.name=#{expr.name}"
                    if expr.ref && name_to_verilog(expr.name) == vname then
                        return get_regs(expr.ref)
                    else
                        return []
                    end
                else
                    return [expr]
                end
            else
                return get_regs(expr.ref,vname)
            end
        end

        # Get signals indirectly refered that have to become reg in
        # a sub system. +vname+ is the name of the system whose signals
        # are to be processed.
        def self.get_indirect_verilog_regs(systemI,vname)
            # Get the sub systemT.
            sub_systemT = systemI.systemT
            # Get the indirect reg inside it.
            sub_systemT.each_behavior do |behavior|
                behavior.each_block_deep do |block|
                    block.each_statement do |statement|
                        if statement.is_a?(Transmit) &&
                                statement.left.to_verilog.include?(vname + ".")
                            puts "hierachical=#{statement.left.to_verilog}"
                            # HDLRuby::Low::VERILOG_REGS << SystemT.get_regs(statement.left.ref).to_verilog
                            HDLRuby::Low::VERILOG_REGS.concat( SystemT.get_regs(statement.left,vname).map(&:to_verilog))
                        end
                    end
                end
            end
            # And recurse on its systemIs.
            sub_systemT.each_systemI do |sub_systemI|
                SystemT.get_indirect_verilog_regs(sub_systemI,vname)
            end
        end


        # Converts the system to Verilog code.
        # NOTE: if +vcd+ is true, generate verilog code whose simulation
        #       produces a vcd file.
        def to_verilog(vcd = false)
            # Create the name of the module.
            vname = name_to_verilog(self.name)
            # puts "Processing systemT named=#{vname}"
            # Detect the registers
            HDLRuby::Low::VERILOG_REGS.clear
            # The left values.
            self.each_behavior do |behavior|
                behavior.each_block_deep do |block|
                    block.each_statement do |statement|
                        if statement.is_a?(Transmit)
                            # HDLRuby::Low::VERILOG_REGS << SystemT.get_regs(statement.left).to_verilog
                            HDLRuby::Low::VERILOG_REGS.concat(SystemT.get_regs(statement.left).map(&:to_verilog))
                        end
                    end
                end
            end
            self.each_systemI do |systemI|
                SystemT.get_indirect_verilog_regs(systemI,vname)
            end
            # And the initialized signals.
            self.each_output do |output|
                # regs << output.to_verilog if output.value
                HDLRuby::Low::VERILOG_REGS << output.to_verilog if output.value
            end
            self.each_inner do |inner|
                # regs << inner.to_verilog if inner.value
                HDLRuby::Low::VERILOG_REGS << inner.to_verilog if inner.value
            end
            # Actual NOT...
            # # And the array types signals.
            # self.each_signal do |sig|
            #     if sig.type.vector? && sig.type.base.vector? then
            #         HDLRuby::Low::VERILOG_REGS << sig.to_verilog
            #     end
            # end
            # self.each_inner do |sig|
            #     if sig.type.vector? && sig.type.base.vector? then
            #         HDLRuby::Low::VERILOG_REGS << sig.to_verilog
            #     end
            # end

            # Code generation
            inputs = 0
            outputs = 0
            inout = 0

            inputs = self.each_input.to_a
            outputs = self.each_output.to_a
            inout = self.each_inout.to_a

            # Spelling necessary for simulation.
            code = "`timescale 1ps/1ps\n\n"

            # self.properties[:verilog_name] = vname
            # Output the module name.
            code << "module #{vname}("

            # Output the last two to the input. 
            inputs[0..-2].each do |input|
                code << " #{input.to_verilog},"
            end
            # When only input is used, it is necessary to close (), so it branches with if.
            if outputs.empty? && inout.empty? then
                if (inputs.empty?)
                    code << " ); \n"
                end
            else
                code << " #{inputs.last.to_verilog}," unless inputs.empty?
            end

            # Output the last two to the output. 
            outputs[0..-2].each do |output|
                code << " #{output.to_verilog},"
            end
            # When only input and output are used, it is necessary to close (), so it branches with if.
            if inout.empty? then
                code << " #{outputs.last.to_verilog} ); \n" unless outputs.empty?
            else
                code << " #{outputs.last.to_verilog}," unless outputs.empty?
            end

            # Output the last two to the inout. 
            inout[0..-2].each do |inout|
                code << " #{inout.to_verilog},"
            end
            # There is no comma as it is the last one
            code << " #{inout.last.to_verilog} ); \n" unless inout.empty?

            # Declare "input"
            self.each_input do |input|
                if input.type.respond_to? (:each_type) then
                    $vector_reg = "#{input.to_verilog}"
                    $vector_cnt = 0
                    input.type.each_type do |type|
                        code << "input #{type.to_verilog} #{$vector_reg}:#{$vector_cnt};\n"
                        $vector_cnt += 1
                    end        
                else
                    code << "   input#{input.type.to_verilog} #{input.to_verilog};\n"
                end
            end

            # Declare "output"
            self.each_output do |output|
                if output.type.respond_to? (:each_type) then
                    $vector_reg = "#{output.to_verilog}"
                    $vector_cnt = 0
                    output.type.each_type do |type|
                        # if regs.include?(type.name) then
                        if HDLRuby::Low::VERILOG_REGS.include?(type.name) then
                            code << "   output reg"
                        else
                            code << "   output"
                        end
                        code << "#{type.to_verilog} #{$vector_reg}:#{$vector_cnt}"
                        if output.value then
                            # There is an initial value.
                            code << " = #{output.value.to_verilog}"
                        end
                        code << ";\n"
                        $vector_cnt += 1
                    end        
                else
                    if HDLRuby::Low::VERILOG_REGS.include?(output.to_verilog) then
                        code << "   output reg"
                    else
                        code << "   output"
                    end
                    code << "#{output.type.to_verilog} #{output.to_verilog}"
                    if output.value then
                        # There is an initial value.
                        code << " = #{output.value.to_verilog}"
                    end
                    code << ";\n"
                end
            end

            # Declare "inout"
            self.each_inout do |inout|
                if inout.type.respond_to? (:each_type) then
                    $vector_reg = "#{inout.to_verilog}"
                    $vector_cnt = 0
                    inout.type.each_type do |type|
                        code << "inout #{type.to_verilog} #{$vector_reg}:#{$vector_cnt};\n"
                        $vector_cnt += 1
                    end        
                else
                    code << "   inout#{inout.type.to_verilog} #{inout.to_verilog};\n"
                end
            end

            # Generate content code.
            codeC = ""

            # Arrays to initialize.
            arrays_to_init = []

            # Declare "inner".
            self.each_inner do |inner|
                if HDLRuby::Low::VERILOG_REGS.include?(inner.to_verilog) then
                    codeC << "   reg"
                else
                    codeC << "   wire"
                end

                if inner.type.base? 
                    if inner.type.base.base? 
                        codeC << "#{inner.type.base.to_verilog} #{inner.to_verilog} #{inner.type.to_verilog}"
                    else
                        codeC << "#{inner.type.to_verilog} #{inner.to_verilog}"
                    end
                else
                    codeC << " #{inner.type.to_verilog}#{inner.to_verilog}"
                end
                if inner.value then
                    val = inner.value
                    val = val.child while val.is_a?(Cast)
                    if val.is_a?(Concat) then
                        arrays_to_init << [inner,val]
                    else
                        # There is an initial value.
                        codeC << " = #{inner.value.to_verilog}"
                    end
                end
                codeC << ";\n"
            end

            # If there is scope in scope, translate it.
            self.each_scope do |scope|
                scope.each_inner do |inner|
                    if HDLRuby::Low::VERILOG_REGS.include?(inner.to_verilog) then
                        codeC << "   reg "
                    else
                        codeC << "   wire "
                    end

                    if inner.type.respond_to? (:base) 
                        if inner.type.base.base?
                            codeC << "#{inner.type.base.to_verilog} #{inner.to_verilog} #{inner.type.to_verilog}"
                        else
                            codeC << "#{inner.type.to_verilog} #{inner.to_verilog}"
                        end
                    else
                        codeC << "inner #{inner.type.to_verilog} #{inner.to_verilog}"
                    end
                    if inner.value then
                        # There is an initial value.
                        codeC << " = #{inner.value.to_verilog}"
                    end
                    codeC << ";\n"
                end    

                scope.each_connection do |connection|
                    codeC << "\n" 
                    codeC << "#{connection.to_verilog}"
                end
            end

            codeC << "\n"

            # puts "For system=#{self.name}"
            # transliation of the instantiation part.
            # Generate the instances connections.
            self.each_systemI do |systemI| 
                # puts "Processing systemI = #{systemI.name}"
                # Its Declaration.
                codeC << " " * 3
                systemT = systemI.systemT
                codeC << name_to_verilog(systemT.name) << " "
                vname = name_to_verilog(systemI.name)
                # systemI.properties[:verilog_name] = vname
                codeC << vname << "("
                # Its ports connections
                # Inputs
                systemT.each_input do |input|
                    ref = self.extract_port_assign!(systemI,input)
                    if ref then
                        codeC << "." << name_to_verilog(input.name) << "(" 
                        codeC << ref.to_verilog
                        codeC << "),"
                    end
                end
                # Outputs
                systemT.each_output do |output|
                    ref = self.extract_port_assign!(systemI,output)
                    if ref then
                        codeC << "." << name_to_verilog(output.name) << "(" 
                        codeC << ref.to_verilog
                        codeC << "),"
                    end
                end
                # Inouts
                systemT.each_inout do |inout|
                    ref = self.extract_port_assign!(systemI,inout)
                    if ref then
                        codeC << "." << name_to_verilog(inout.name) << "(" 
                        codeC << ref.to_verilog
                        codeC << "),"
                    end
                end
                # Remove the last "," if any for conforming with Verilog syntax.
                codeC.chop! if codeC[-1] == ","
                # And close the port connection.
                codeC << ");\n"
            end



            # translation of the connection part (assigen).
            self.each_connection do |connection|
                codeC << "#{connection.to_verilog}\n"
            end

            # Translation of behavior part (always).
            $timebeh_shown = false
            self.each_behavior do |behavior|
                timebeh = false
                if behavior.block.is_a?(TimeBlock) then
                    # Tell it is a time behavior for further processing.
                    timebeh = true
                    # Deprecated with new TimeRepeat.
                    #
                    # # Extract and translate the TimeRepeat separately.
                    # behavior.each_block_deep do |blk|
                    #     codeC << blk.repeat_to_verilog!
                    # end
                    # And generate an initial block.
                    codeC << "   initial "
                else
                    # Generate a standard process.
                    codeC << "\n   always @( "
                    # If there is no "always" condition, it is always @("*").
                    if behavior.each_event.to_a.empty? then
                        codeC << "*"
                    else
                        event = behavior.each_event.to_a
                        event[0..-2].each do |event|
                            # If "posedge" or "negedge" does not exist, the variable is set to condition.
                            if (event.type.to_s != "posedge" && event.type.to_s != "negedge") then
                                codeC << "#{event.ref.to_verilog}, "
                            else
                                # Otherwise, it outputs "psoedge" or "negedge" as a condition.
                                codeC << "#{event.type.to_s} #{event.ref.to_verilog}, "
                            end
                        end
                        # Since no comma is necessary at the end, we try not to separate commas separately at the end.
                        if (event.last.type.to_s != "posedge" && event.last.type.to_s != "negedge") then
                            codeC << "#{event.last.ref.to_verilog}"
                        else
                            codeC << "#{event.last.type.to_s} #{event.last.ref.to_verilog}"
                        end
                    end
                    codeC << " ) "
                end

                if vcd && timebeh && !$timebeh_shown then
                    codeC << behavior.block.to_verilog(3,name_to_verilog(self.name))
                    $timebeh_shown = true
                else
                    codeC << behavior.block.to_verilog
                end

            end

            # Generate the code for the initialization of the arrays.
            if arrays_to_init.any? then
                codeC << "   initial begin\n"
                arrays_to_init.each do |(sig,val)|
                    val.each_expression.with_index do |expr,i|
                        # Initialization, therefore maybe no cast required...
                        # if sig.value.is_a?(Cast) then
                        #     expr = Cast.new(sig.value.type,expr.clone)
                        # end
                        codeC << "      ";
                        codeC << "#{sig.to_verilog}[#{i}]=#{expr.to_verilog};\n"
                    end
                end
                codeC << "   end\n"
            end

            # Conclusion.
            codeC << "\nendmodule"

            # Adds the truncing functions.
            code << TruncersI.dump
            # Adds the indexing functions.
            code << IndexersI.dump
            # Adds the content code.
            code << codeC
            return code
        end
    end


    class StringE
        ## Enhances stringE with generation of verilog code.

        # Converts the system to Verilog code.
        def to_verilog(spc = 3)
            code = "\"#{Low.v_string(self.content)}" +
                "#{self.each_arg.map do |arg| 
                to.to_verilog
            end.join(",")}\""
            return code
        end
    end

end



class ::Numeric
## Extends the Numeric class with generation of verilog text.

    # Generates the text of the equivalent verilog code.
    # +level+ is the hierachical level of the object.
    def to_verilog(level = 0)
        return self.to_s
    end
end
