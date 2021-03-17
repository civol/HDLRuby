require 'HDLRuby'
require 'HDLRuby/hruby_tools'
require 'HDLRuby/hruby_low_resolve'
require 'HDLRuby/hruby_low_mutable'


module HDLRuby::Low


##
# Convert the connections to transmit statement within a behavior.
# Used by the HDLRuby simulator.
#
########################################################################
    

    ## Extends the SystemT class with functionality for breaking assingments
    #  to concats.
    class SystemT

        ## Remove the connections and replace them by behaviors.
        #  NOTE: one behavior is created for input connections and
        #        one for output ones while inout/inner-only connections
        #        are copied in both behaviors.
        def connections_to_behaviors!
            # Process the connections: create a behavior containing
            # them all within a par block.
            self.scope.each_scope_deep do |scope|
                if scope.each_connection.to_a.any? then
                    inputs_blk = Block.new(:par)
                    outputs_blk = Block.new(:par)
                    timed_blk = TimeBlock.new(:seq)
                    scope.each_connection do |connection|
                        # puts "For connection: #{connection}"
                        # Check the left and right of the connection
                        # for input or output port.
                        left = connection.left
                        left_r = left.resolve
                        # puts "left_r=#{left_r.name}" if left_r
                        # puts "left_r.parent=#{left_r.parent.name}" if left_r && left_r.parent
                        right = connection.right
                        right_r = right.resolve if right.respond_to?(:resolve)
                        # puts "right_r=#{right_r.name}" if right_r
                        # puts "right_r.parent=#{right_r.parent.name}" if right_r && right_r.parent
                        if right.is_a?(Value) then
                        # if right.immutable? || 
                        #         (right_r && right_r.immutable?) then
                            # Right is value, the new transmit is to add
                            # to the timed block.
                            timed_blk.add_statement(
                                Transmit.new(left.clone,right.clone))
                            # No more process for this connection.
                            next
                        end

                        # Check if left is an input or an output.
                        left_is_i = left_is_o = false
                        if left_r && left_r.parent.is_a?(SystemT) then
                            if left_r.parent.each_input.include?(left_r) then
                                # puts "Left is input."
                                # puts "Left is from systemI: #{left.from_systemI?}"
                                left_is_i = left.from_systemI?
                                left_is_o = !left_is_i
                            elsif left_r.parent.each_output.include?(left_r) then
                                # puts "Left is output."
                                # puts "Left is from systemI: #{left.from_systemI?}"
                                left_is_o = left.from_systemI?
                                left_is_i = !left_is_o
                            end
                        end
                        # Check if right is an input or an output.
                        right_is_i = right_is_o = false
                        if right_r && right_r.parent.is_a?(SystemT) then
                            if right_r.parent.each_input.include?(right_r) then
                                # puts "Right is input."
                                # puts "Right is from systemI: #{right.from_systemI?}"
                                right_is_i = right.from_systemI?
                                right_is_o = !right_is_i
                            elsif right_r.parent.each_output.include?(right_r) then
                                # puts "Right is output."
                                # puts "Right is from systemI: #{right.from_systemI?}"
                                right_is_o = right.from_systemI?
                                right_is_i = !right_is_o
                            end
                        end
                        # puts "left_is_i=#{left_is_i} left_is_o=#{left_is_o}"
                        # puts "right_is_i=#{right_is_i} right_is_o=#{right_is_o}"
                        # Fills the relevant block.
                        if (left_is_i) then
                            inputs_blk.add_statement(
                                Transmit.new(left.clone,right.clone))
                        elsif (right_is_i) then
                            inputs_blk.add_statement(
                                Transmit.new(right.clone,left.clone))
                        elsif (left_is_o) then
                            outputs_blk.add_statement(
                                Transmit.new(right.clone,left.clone))
                        elsif (right_is_o) then
                            outputs_blk.add_statement(
                                Transmit.new(left.clone,right.clone))
                        else
                            # # puts "left/right is inout"
                            # if (left.is_a?(Ref)) then
                            #     inputs_blk.add_statement(
                            #         Transmit.new(left.clone,right.clone))
                            # end
                            # if (right.is_a?(Ref)) then
                            #     outputs_blk.add_statement(
                            #         Transmit.new(right.clone,left.clone))
                            # end
                            # Both or neither input/output, make a behavior
                            # for each.
                            if (left.is_a?(Ref) && 
                                    !(left_r && left_r.immutable?)) then
                                blk = Block.new(:par)
                                blk.add_statement(
                                    Transmit.new(left.clone,right.clone))
                                scope.add_behavior(Behavior.new(blk))
                            end
                            if (right.is_a?(Ref) &&
                                    !(right_r && right_r.immutable?)) then
                                blk = Block.new(:par)
                                blk.add_statement(
                                    Transmit.new(right.clone,left.clone))
                                scope.add_behavior(Behavior.new(blk))
                            end
                        end
                    end
                    # Adds the behaviors.
                    if inputs_blk.each_statement.any? then
                        scope.add_behavior(Behavior.new(inputs_blk))
                    end
                    if outputs_blk.each_statement.any? then
                        scope.add_behavior(Behavior.new(outputs_blk))
                    end
                    if timed_blk.each_statement.any? then
                        scope.add_behavior(TimeBehavior.new(timed_blk))
                    end
                end
            end
        end

    end

end
