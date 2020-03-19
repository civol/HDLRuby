require "HDLRuby/hruby_error"
require "HDLRuby/hruby_low_mutable"
require "HDLRuby/hruby_low2sym"



module HDLRuby::Low


##
# Generates port wires for each instance instead of standard signals in
# HDLRuby::Low description.
#
# Port wires can be directly converted to instance connection in VHDL and
# Verilog.
#
########################################################################

    

    ## Extends SystemT with generation of port wires.
    class SystemT

        # Converts to a port-compatible system.
        #
        # NOTE: the result is the same systemT.
        def with_port!
            self.scope.with_port!
            return self
        end
    end


    ## Extends the Scope class with retrival conversion to symbol.
    class Scope

        # Converts a port wire to a reference to it.
        def portw2ref(portw)
            return RefName.new(portw.type,RefThis.new,portw.name)
        end

        # Converts symbol +sym+ representing an HDLRuby reference to a 
        # instance port to a port wire.
        def sym2portw_name(sym)
            return ("^" + sym.to_s).to_sym
        end

        # Converts a port wire +name+ to the symbol giving the corresponding
        # HDLRuby reference.
        def portw_name2sym(name)
            return name[1..-1].to_sym
        end

        # Generates a port wire from a reference.
        def make_portw(ref)
            # First generates the name of the port.
            name = sym2portw_name(ref.to_sym)
            # Then generate the port wire.
            return SignalI.new(name,ref.type)
        end

        # Tells if a +node+ is a reference to an instance's port.
        def instance_port?(node)
            # First the node must be a name reference.
            return false unless node.is_a?(RefName)
            # Then its sub ref must be a RefName of an instance.
            sub = node.ref
            return false unless sub.is_a?(RefName)
            # puts "@systemIs.keys=#{@systemIs.keys}"
            # System instance in current scope?
            return true if @systemIs.key?(sub.name)
            # if self.parent.is_a?(Scope) then
            #     # Recurse the search in the parent.
            #     return parent.instance_port?(node)
            # else
            #     # No parent, failure.
            #     return false
            # end
            return false
        end


        # Converts to a port-compatible system.
        #
        # NOTE: the result is the same scope.
        def with_port!
            # # Recurse on the sub scope.
            # self.each_scope(&:with_port!)
            # Gather the references to instance ports.
            # Also remember if the references were left values or not.
            refs = []
            ref_sym2leftvalue = {}
            self.each_block_deep do |block|
                block.each_node_deep do |node|
                    if instance_port?(node) then
                        # puts "port for node: #{node.ref.name}.#{node.name}"
                        refs << node 
                        ref_sym2leftvalue[node.to_sym] = node.leftvalue?
                    end
                end
            end
            self.each_connection do |connection|
                connection.each_node_deep do |node|
                    if instance_port?(node) then
                        # puts "port for node: #{node.ref.name}.#{node.name}"
                        # puts "leftvalue? #{node.leftvalue?}"
                        refs << node 
                        ref_sym2leftvalue[node.to_sym] = node.leftvalue?
                    end
                end
            end
            # Generate the port wire from the refs.
            ref_sym2portw = {}
            refs.each { |ref| ref_sym2portw[ref.to_sym] = make_portw(ref) }
            # Declare the port wires.
            ref_sym2portw.each_value { |portw| self.add_inner(portw.clone) }
            # Replace the references by their corresponding port wires.
            self.each_block_deep do |block|
                block.each_node_deep do |node|
                    node.map_nodes! do |expr|
                        portw = ref_sym2portw[expr.to_sym]
                        portw ? portw2ref(portw) : expr
                    end
                end
            end
            self.each_connection do |connection|
                connection.each_node_deep do |node|
                    node.map_nodes! do |expr|
                        portw = ref_sym2portw[expr.to_sym]
                        portw ? portw2ref(portw) : expr
                    end
                end
            end

            # Finally adds the connections with the port wires.
            ref_sym2portw.each do |sym,portw|
                ref = sym.to_hdr
                if ref_sym2leftvalue[sym] then
                    # The reference was a left value, assign the port wire
                    # to the ref.
                    self.add_connection(
                        Connection.new(ref.clone,portw2ref(portw)) )
                else
                    # The reference was a right value, assign it to the
                    # port wire.
                    self.add_connection(
                        Connection.new(portw2ref(portw),ref.clone) )
                end
            end
            

            return self
        end
    end



    ## Extends SystemT with generation of port wires.
    class SystemI

        def with_port!
            self.systemT.with_port!
            return self
        end
    end



end
