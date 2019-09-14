require 'HDLRuby'
require 'HDLRuby/hruby_tools'
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
        def connections_to_behaviors!
            # Process the connections: create a behavior containing
            # them all within a par block.
            self.scope.each_scope_deep do |scope|
                if scope.each_connection.to_a.any? then
                    connection_blk = Block.new(:par)
                    scope.each_connection do |connection|
                        connection_blk.add_statement(
                            Transmit.new(connection.left.clone,
                                         connection.right.clone))
                    end
                    scope.add_behavior(Behavior.new(connection_blk))
                end
            end
        end

    end

end
