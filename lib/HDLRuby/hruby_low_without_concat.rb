require 'HDLRuby'
require 'HDLRuby/hruby_tools'
require 'HDLRuby/hruby_low_mutable'


module HDLRuby::Low


##
# Breaks the concat assignments.
# Makes handling by some synthesis tools easier.
#
########################################################################
    

    class SystemT
        ## Extends the SystemT class with functionality for breaking assignments
        #  to concats.

        # Breaks the assignments to concats.
        def break_concat_assigns!
            self.scope.break_concat_assigns!
        end

        # Converts initial concat of values of signals to assignment in
        # timed blocks (for making the code compatible with verilog
        # translation).
        #
        # NOTE: Assumes such array as at the top level.
        def initial_concat_to_timed!
            self.scope.initial_concat_to_timed!
        end

    end


    class Scope
        ## Extends the Scope class with functionality for breaking assignments
        #  to concats.

        # Breaks the assignments to concats.
        def break_concat_assigns!
            # Recruse on the sub scopes.
            self.each_scope(&:break_concat_assigns!)
            # Recurse on the statements.
            self.each_behavior do |behavior|
                # behavior.block.each_block_deep(&:break_concat_assigns!)
                behavior.break_concat_assigns!
            end
            # Work on the connections.
            self.each_connection.to_a.each do |connection|
                nconnection = connection.break_concat_assigns
                if nconnection.is_a?(Block) then
                    # The connection has been broken, remove the former
                    # version and add the generated block as a behavior.
                    # self.remove_connection(connection)
                    self.delete_connection!(connection)
                    self.add_behavior(Behavior.new(nconnection))
                end
            end
        end

        # Converts initial array of value of signals to assignment in
        # timed blocks (for making the code compatible with verilog
        # translation).
        #
        # NOTE: Assumes such array as at the top level.
        def initial_concat_to_timed!
            # Gather the signal with concat as initial values.
            sigs = []
            # For the interface signals of the upper system.
            self.parent.each_signal do |sig|
                sigs << sig if sig.value.is_a?(Concat)
            end
            # For the inner signals of the scope.
            self.each_signal do |sig|
                sigs << sig if sig.value.is_a?(Concat)
            end
            # No initial concat? End here.
            return if sigs.empty?
            
            # Create a timed block for moving the concat initialization
            # to it.
            initial = TimeBlock.new(:seq)
            self.add_behavior(TimeBehavior.new(initial))
            # Adds to it the initializations.
            sigs.each do |sig|
                name = sig.name
                styp = sig.type
                btyp = styp.base
                value = sig.value
                sig.value.each_expression.with_index do |expr,i|
                    left = RefIndex.new(btyp,
                                        RefName.new(styp,RefThis.new,name),
                                        i.to_expr)
                    initial.add_statement(Transmit.new(left,expr.clone))
                end
            end
            # Remove the initial values from the signals.
            sigs.each do |sig|
                sig.set_value!(nil)
            end
        end
    end


    class Behavior
        ## Extends the Behavior class with functionality for breaking assignments
        #  to concats.

        # Breaks the assignments to concats.
        def break_concat_assigns!
            # Recruse on the block.
            self.block.each_block_deep(&:break_concat_assigns!)
        end
    end



    class Block
        ## Extends the Block class with functionality for breaking assignments
        #  to concats.

        # Breaks the assignments to concats.
        #
        # NOTE: work on the direct sub statement only, not deeply.
        def break_concat_assigns!
            # puts "breack_concat_assigns! with block=#{self} with #{self.each_statement.count} statements"
            # Check each transmit.
            self.each_statement.to_a.each_with_index do |stmnt|
                # puts "stmnt=#{stmnt}"
                if stmnt.is_a?(Transmit) then
                    # Transmit, breaking may be necessary.
                    nstmnt = stmnt.break_concat_assigns
                    if nstmnt.is_a?(Block) then
                        # The transmit has been broken, remove the former
                        # version and add the generated block as a behavior.
                        # self.set_statement!(i,nstmnt)
                        self.replace_statement!(stmnt,nstmnt)
                        # puts "nstmnt.parent=#{nstmnt.parent}"
                    end
                end
            end
            return self
        end
    end


    class Transmit
        ## Extends the Transmit class with functionality for breaking assignments
        #  to concats.

        # Break the assignments to concats.
        #
        # NOTE: when breaking generates a new Block containing the broken
        #       assignments.
        def break_concat_assigns
            # puts "break_concat_assigns with self=#{self}"
            # Is the left value a RefConcat?
            self.left.each_node_deep do |node|
                if node.is_a?(RefConcat) then
                    # Yes, must break. Create the resulting sequential
                    # block that will contain the new assignements.
                    block = Block.new(:seq)
                    # Create an intermediate signal for storing the
                    # right value. Put it in the top scope.
                    top_block = self.top_block
                    top_scope = top_block.top_scope
                    aux = top_scope.add_inner(
                        SignalI.new(HDLRuby.uniq_name,self.right.type) )
                    aux = RefName.new(aux.type,RefThis.new,aux.name)
                    # Is a default value required to avoid latch generation?
                    unless top_block.is_a?(TimeBlock) ||
                           top_block.parent.each_event.
                            # find {|ev| ev.type!=:change} then
                            find {|ev| ev.type!=:anyedge} then
                        # Yes, generate it.
                        top_block.insert_statement!(0,
                            Transmit.new(aux.clone,Value.new(aux.type,0)))
                    end
                    # Replace the concat in the copy of the left value.
                    if left.eql?(node) then
                        # node was the top of left, replace here.
                        nleft = aux
                    else
                        # node was inside left, replace within left.
                        nleft = self.left.clone
                        nleft.each_node_deep do |ref|
                            ref.map_nodes! do |sub|
                                sub.eql?(node) ? aux.clone : sub
                            end
                        end
                    end
                    # Recreate the transmit and add it to the block.
                    block.add_statement(
                        Transmit.new(nleft,self.right.clone) )
                    # And assign its part to each reference of the
                    # concat.
                    pos = 0
                    node.each_ref.reverse_each do |ref|
                        # Compute the range to assign.
                        range = ref.type.width-1+pos .. pos
                        # Single or multi-bit range?
                        sbit = range.first == range.last
                        # Convert the range to an HDLRuby range for 
                        # using is the resulting statement.
                        # Create and add the statement.
                        if sbit then
                            # Single bit.
                            # Generate the index.
                            idx = Value.new(Integer,range.first)
                            # Generate the assignment.
                            block.add_statement(
                                Transmit.new(ref.clone,
                                # RefIndex.new(aux.type.base, aux.clone, idx)))
                                RefIndex.new(bit, aux.clone, idx)))
                        else
                            # Multi-bits.
                            # Compute the type of the right value.
                            # rtype = TypeVector.new(:"",aux.type.base,range)
                            rtype = TypeVector.new(:"",bit,range)
                            # Generate the range.
                            range = Value.new(Integer,range.first) ..
                                    Value.new(Integer,range.last)
                            # Generate the assignment.
                            block.add_statement(
                                Transmit.new(ref.clone,
                                RefRange.new(rtype, aux.clone, range)))
                        end
                        pos += ref.type.width
                    end
                    # Return the resulting block
                    # puts "new block=#{block}"
                    return block
                end
            end
            # No, nothing to do.
            return self
        end
    end


    class Connection
        ## Extends the Connection class with functionality for breaking
        #  assignments to concats.

        # Break the assignments to concats.
        #
        # NOTE: when breaking generates a new Block containing the broken
        #       assignments.
        def break_concat_assigns
            # puts "break_concat_assigns with self=#{self}"
            # Is the left value a RefConcat?
            self.left.each_node_deep do |node|
                if node.is_a?(RefConcat) then
                    # Yes, must break. Create the resulting sequential
                    # block that will contain the new assignements.
                    block = Block.new(:par)
                    # Create an intermediate signal for storing the
                    # right value. Put it in the top scope.
                    top_scope = self.top_scope
                    aux = top_scope.add_inner(
                        SignalI.new(HDLRuby.uniq_name,self.right.type) )
                    # puts "new signal: #{aux.name}"
                    aux = RefName.new(aux.type,RefThis.new,aux.name)
                    # Set a default value to avoid latch generation.
                    block.insert_statement!(0,
                            Transmit.new(aux.clone,Value.new(aux.type,0)))
                    # Replace the concat in the copy of the left value.
                    if left.eql?(node) then
                        # node was the top of left, replace here.
                        nleft = aux
                    else
                        # node was inside left, replace within left.
                        nleft = self.left.clone
                        nleft.each_node_deep do |ref|
                            ref.map_nodes! do |sub|
                                sub.eql?(node) ? aux.clone : sub
                            end
                        end
                    end
                    # Recreate the transmit and add it to the block.
                    block.add_statement(
                        Transmit.new(nleft,self.right.clone) )
                    # And assign its part to each reference of the
                    # concat.
                    pos = 0
                    node.each_ref.reverse_each do |ref|
                        # Compute the range to assign.
                        range = ref.type.width-1+pos .. pos
                        # Single or multi-bit range?
                        sbit = range.first == range.last
                        # Convert the range to an HDLRuby range for 
                        # using is the resulting statement.
                        # Create and add the statement.
                        if sbit then
                            # Single bit.
                            # Generate the index.
                            idx = Value.new(Integer,range.first)
                            # Generate the assignment.
                            block.add_statement(
                                Transmit.new(ref.clone,
                                # RefIndex.new(aux.type.base, aux.clone, idx)))
                                RefIndex.new(bit, aux.clone, idx)))
                        else
                            # Multi-bits.
                            # Compute the type of the right value.
                            # rtype = TypeVector.new(:"",aux.type.base,range)
                            rtype = TypeVector.new(:"",bit,range)
                            # Generate the range.
                            range = Value.new(Integer,range.first) ..
                                    Value.new(Integer,range.last)
                            # Generate the assignment.
                            block.add_statement(
                                Transmit.new(ref.clone,
                                RefRange.new(rtype, aux.clone, range)))
                        end
                        pos += ref.type.width
                    end
                    # puts "Resulting block=#{block.to_vhdl}"
                    # Return the resulting block
                    return block
                end
            end
            # No, nothing to do.
            return self
        end
    end
end
