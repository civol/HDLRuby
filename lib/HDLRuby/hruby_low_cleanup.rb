require 'HDLRuby'
require 'HDLRuby/hruby_tools'
require 'HDLRuby/hruby_low_mutable'


module HDLRuby::Low


##
# Cleans up the HDLRuby::Low description.
#
# NOTE: Assume each name is uniq.
#
########################################################################
    

    class SystemT
        ## Extends the SystemT class with functionality for cleaning up the
        #  structure.

        # Cleans up.
        def cleanup!
            # Gather the output and inout signals' names, they are used to
            # identify the signals that can be removed.
            keep = self.each_output.map {|sig| sig.name } +
                   self.each_inout.map {|sig| sig.name }
            self.scope.cleanup!(keep)
        end

    end

    class Scope
        ## Extends the Scope class with functionality for cleaning up the
        #  structure.

        # Cleans up.
        # +keep+ includes the list of names to be kept.
        def cleanup!(keep)
            # Complete the list of signals to keep with the signals parts
            # of the right values of connections and statements or
            # instance interface.
            self.each_scope_deep do |scope|
                # Connections.
                scope.each_connection do |connection|
                    connection.right.each_node_deep do |node|
                        # Leaf right value references are to keep.
                        # They are either signal of current system or
                        # system instance names.
                        if node.is_a?(RefName) && !node.ref.is_a?(RefName) then
                            keep << node.name 
                        end
                    end
                end
                # System instances.
                scope.each_systemI do |systemI|
                    keep << systemI.name
                end
                # Behaviors.
                scope.each_behavior do |behavior|
                    behavior.block.each_node_deep do |node|
                        # Skip left values.
                        next if node.respond_to?(:leftvalue?) && node.leftvalue?
                        # Leaf right value references are to keep.
                        # They are either signal of current system or
                        # system instance names.
                        if node.is_a?(RefName) && !node.ref.is_a?(RefName) then
                            keep << node.name 
                        end
                    end
                end
            end
            
            # Remove the signals and correspondong assignments that are not 
            # to keep.
            self.delete_unless!(keep)
        end

        # Removes the signals and corresponding assignments whose name is not
        # in +keep+.
        def delete_unless!(keep)
            # Recurse on the sub scopes.
            self.each_scope { |scope| scope.delete_unless!(keep) }

            # Remove the unessary  inner signals.
            self.each_inner.to_a.each do |inner|
                unless keep.include?(inner.name) then
                    self.delete_inner!(inner)
                end
            end

            # Remove the unessary connections.
            self.each_connection.to_a.each do |connection|
                # puts "connection with left=#{connection.left.name}"
                unless connection.left.each_node_deep.any? { |node|
                    node.is_a?(RefName) && keep.include?(node.name) 
                }
                self.delete_connection!(connection)
                end
            end

            # Recurse on the blocks.
            self.each_behavior do |behavior|
                behavior.block.delete_unless!(keep)
            end
        end
            
    end


    class Statement
        ## Extends the Statement class with functionality for cleaning up the
        #  structure.

        # Removes the signals and corresponding assignments whose name is not
        # in +keep+.
        def delete_unless!(keep)
            # By default nothing to do.
        end
    end


    class If
        ## Extends the If class with functionality for cleaning up the structure

        # Removes the signals and corresponding assignments whose name is not
        # in +keep+.
        def delete_unless!(keep)
            # Recurse on the sub statements.
            # Yes.
            self.yes.delete_unless!(keep)
            # Noifs.
            self.each_noif { |cond,stmnt| stmnt.delete_unless!(keep) }
            # No if any.
            self.no.delete_unless!(keep) if self.no
        end
    end


    class When
        ## Extends the When class with functionality for cleaning up the
        #  structure.

        # Removes the signals and corresponding assignments whose name is not
        # in +keep+.
        def delete_unless!(keep)
            # Recurse on the statement.
            self.statement.delete_unless!(keep)
        end
    end


    class Case
        ## Extends the Case class with functionality for cleaning up the
        #  structure.

        # Removes the signals and corresponding assignments whose name is not
        # in +keep+.
        def delete_unless!(keep)
            # Recurse on the whens.
            self.each_when {|w| w.delete_unless!(keep) }
            # Recurse on the default if any.
            self.default.delete_unless!(keep) if self.default
        end
    end


    class Block
        ## Extends the Block class with functionality for cleaning up the
        #  structure.

        # Removes the signals and corresponding assignments whose name is not
        # in +keep+.
        def delete_unless!(keep)
            # Delete the unecessary inner signals.
            self.each_inner.to_a.each do |inner|
                self.delete_inner!(inner) unless keep.include?(inner.name)
            end

            # Recurse on the sub statements.
            self.each_statement {|stmnt| stmnt.delete_unless!(keep) }

            # Delete the unecessary assignments.
            self.each_statement.to_a.each do |stmnt|
                if stmnt.is_a?(Transmit) &&
                     !stmnt.left.each_node_deep.any? { |node| 
                    node.is_a?(RefName) && keep.include?(node.name) } then
                    self.delete_statement!(stmnt)
                end
            end
        end
    end


    class TimeBlock
        ## Extends the TimeBlock class with functionality for cleaning up the
        #  structure.

        # Removes the signals and corresponding assignments whose name is not
        # in +keep+.
        def delete_unless!(keep)
            # Nothing to cleanup.
        end
    end


end
