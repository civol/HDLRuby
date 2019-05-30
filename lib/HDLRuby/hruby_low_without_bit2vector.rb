require "HDLRuby/hruby_error"
require "HDLRuby/hruby_low_mutable"


##
# Ensures that there is no conversion of bit types to vector types.
#
#
# NOTE: Used for instance for converting to old versions of VHDL where
#       bit types cannot be casted to vector types.
#
########################################################################
module HDLRuby::Low



    ## Extends the SystemT class for removing bit to vector conversions.
    class SystemT
        # Replace bit to vector conversions by assignment to on bit of
        # an intermediate inner vector.
        #
        # NOTE: the result is the same systemT.
        def bit2vector2inner!
            # puts "For system: #{self.name}"
            # First gather the bit conversions to vector.
            bits2vectors = Set.new
            gather_bits2vectors = proc do |node|
                if node.is_a?(Expression) && node.type == Bit &&
                        node.parent.is_a?(Expression) && 
                        # References are not relevant parents
                        !node.parent.is_a?(Ref) && 
                        # Neither do concat that are processed separatly
                        !node.parent.is_a?(Concat) && 
                        node.parent.type != Bit then
                    # puts "node=#{node.to_high}, node.parent=#{node.parent}"
                    bits2vectors.add(node)
                end
            end
            # Apply the procedure for gathering the read on outputs signals.
            self.scope.each_scope_deep do |scope|
                scope.each_connection do |connection|
                    # Recurse on the connection.
                    connection.each_node_deep(&gather_bits2vectors)
                end
                scope.each_behavior do |behavior|
                    behavior.each_event do |event|
                        gather_bits2vectors.(event.ref)
                    end
                    behavior.each_statement do |statement|
                        # puts "statement=#{statement.class}"
                        statement.each_node_deep(&gather_bits2vectors)
                    end
                end
            end
            # puts "bits2vectors=#{bits2vectors.size}"

            # Create the 1-bit-vector type.
            vec1T = TypeVector.new(:"bit1",Bit,0..0)
            # Generate one inner 1-bit-vector signal per read output.
            bit2inner = {}
            bits2vectors.each do |node|
                # Generate the inner variable.
                sig = self.scope.add_inner(SignalI.new(HDLRuby::uniq_name,vec1T))
                ref = RefName.new(vec1T,RefThis.new,sig.name)
                bit2inner[node] = 
                    [ ref, RefIndex.new(Bit,ref,Value.new(Integer,0)) ]
                # puts "new inner=#{out2inner[name].name}"
            end

            # Apply the replacement procedure on the code
            self.scope.each_scope_deep do |scope|
                scope.each_connection.to_a.each do |connection|
                    connection.reassign_expressions!(bit2inner)
                end
                scope.each_behavior do |behavior|
                    behavior.each_event do |event|
                        event.reassign_expressions!(bit2inner)
                    end
                    behavior.block.reassign_expressions!(bit2inner)
                end
            end

            return self
        end
    end


end
