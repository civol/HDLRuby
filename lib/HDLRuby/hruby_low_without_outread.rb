require "HDLRuby/hruby_error"
require "HDLRuby/hruby_low_mutable"


##
# Ensures that there is no read on output port by adding intermediate
# inner signal.
#
#
# NOTE: Used for instance for converting to old versions of VHDL that
#
########################################################################
module HDLRuby::Low



    ## Extends the SystemT class for remove read of output signal.
    class SystemT
        # Replace read of output signal to read of intermediate inner
        # signal.
        #
        # NOTE: the result is the same systemT.
        def outread2inner!
            # puts "For system: #{self.name}"
            # First gather the read on output signals.
            outreads = {}
            gather_outreads = proc do |node|
                # puts "node=#{node.name}" if node.is_a?(RefName)
                if node.is_a?(RefName) && !node.leftvalue? then
                    name = node.name
                    # puts "name=#{name}"
                    sig = self.get_output(name)
                    outreads[node.name] = node if sig
                end
            end
            # Apply the procedure for gathering the read on outputs signals.
            self.scope.each_scope_deep do |scope|
                scope.each_connection do |connection|
                    connection.each_node_deep(&gather_outreads)
                end
                scope.each_behavior do |behavior|
                    behavior.each_event do |event|
                        gather_outreads.(event.ref)
                    end
                    behavior.each_statement do |statement|
                        # puts "statement=#{statement.class}"
                        statement.each_node_deep(&gather_outreads)
                    end
                end
            end
            # puts "outreads=#{outreads.keys}"

            # Generate one inner signal per read output.
            out2inner = {}
            outreads.each do |name,node|
                # Generate the inner variable.
                out2inner[name] = 
                 self.scope.add_inner(SignalI.new(HDLRuby::uniq_name,node.type))
                # puts "new inner=#{out2inner[name].name}"
            end

            # Replace the output by the corresponding inner in the
            # expressions.
            replace_name = proc do |node| # The replacement procedure.
                # Only single name reference are to be replaced, the others
                # cannot correspond to output signal.
                if node.is_a?(RefName) && node.ref.is_a?(RefThis) &&
                        !node.parent.is_a?(RefName) then
                    inner = out2inner[node.name]
                    # puts "node=#{node.name} inner=#{inner}"
                    # puts "Replace name: #{node.name} by #{inner.name}" if inner
                    node.set_name!(inner.name) if inner
                end
            end
            # Apply the replacement procedure on the code
            self.scope.each_scope_deep do |scope|
                scope.each_connection do |connection|
                    connection.each_node_deep do |node|
                        replace_name.(node)
                    end
                end
                scope.each_behavior do |behavior|
                    behavior.each_event do |event|
                        event.ref.each_node_deep do |node|
                            replace_name.(node)
                        end
                    end
                    behavior.each_statement do |statement|
                        statement.each_node_deep do |node|
                            replace_name.(node)
                        end
                    end
                end
            end

            # Finally connect the inner to the output.
            out2inner.each do |out,inner|
                self.scope.add_connection(
                 Connection.new(RefName.new(inner.type,RefThis.new,out),
                                RefName.new(inner.type,RefThis.new,inner.name)))
            end

            return self
        end
    end

end
