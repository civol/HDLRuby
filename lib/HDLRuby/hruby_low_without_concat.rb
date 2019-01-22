require 'HDLRuby'
require 'HDLRuby/hruby_tools'
require 'HDLRuby/hruby_low_mutable'


module HDLRuby::Low


##
# Breaks the concat assigments.
# Makes handling by some synthesis tools easier.
#
########################################################################
    

    ## Extends the SystemT class with functionality for breaking assingments
    #  to concats.
    class SystemT

        # Breaks the assignments to concats.
        def break_concat_assigns!
            self.scope.break_concat_assigns!
        end

    end

    ## Extends the Scope class with functionality for breaking assingments
    #  to concats.
    class Scope
        # Breaks the assignments to concats.
        def break_concat_assigns!
            # Recruse on the sub scopes.
            self.each_scope(&:break_concat_assigns!)
            # Recurse on the statements.
            self.each_behavior do |behavior|
                behavior.block.each_block_deep(&:break_concat_assigns!)
            end
            # Work on the connections.
            self.each_connection.to_a.each do |connection|
                nconnection = connection.break_concat_assigns
                if nconnection.is_a?(Block) then
                    # The connection has been broken, remove the former
                    # version and add the generated block as a behavior.
                    self.remove_connection(connection)
                    self.add_behavior(Behavior.new(nconnection))
                end
            end
        end
    end

    ## Extends the Block class with functionality for breaking assingments
    #  to concats.
    class Block
        # Breaks the assignments to concats.
        #
        # NOTE: work on the direct sub statement only, not deeply.
        def break_concat_assigns!
            # Check each transmit.
            self.each_statement.each.with_index do |stmnt,i|
                if stmnt.is_a?(Transmit) then
                    # Transmit, breaking may be necessary.
                    nstmnt = stmnt.break_concat_assigns
                    if nstmnt.is_a?(Block) then
                        # The transmit has been broken, remove the former
                        # version and add the generated block as a behavior.
                        self.set_statement!(i,nstmnt)
                    end
                end
            end
        end
    end


    ## Extends the Transmit class with functionality for breaking assingments
    #  to concats.
    class Transmit
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
                    # right value. Put it in the top block of the behavior.
                    top = self.top_block
                    aux = top.add_inner(
                        SignalI.new(HDLRuby.uniq_name,self.right.type) )
                    aux = RefName.new(aux.type,RefThis.new,aux.name)
                    # Is a default value required to avoid latch generation?
                    unless top.parent.each_event.
                            find {|ev| ev.type!=:change} then
                        # Yes, generate it.
                        top.insert_statement!(0,
                            Transmit.new(aux.clone,Value.new(aux.type,0)))
                    end
                    # Replace the concat in the copy of the left value.
                    if left.eql?(node) then
                        # node was the top of left, replace here.
                        nleft = aux
                    else
                        # node was insied left, replace within left.
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
                                RefIndex.new(aux.type.base, aux.clone, idx)))
                        else
                            # Multi-bits.
                            # Compute the type of the right value.
                            rtype = TypeVector.new(:"",aux.type.base,range)
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
