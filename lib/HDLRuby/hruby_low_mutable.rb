require "HDLRuby/hruby_error"



##
# Make HDLRuby::Low objects mutable trough "!" methods.
#
# NOTE: * should be used with care, since it can comprimize the internal
#         structures.
#       * this is a work in progress.
#
########################################################################
module HDLRuby::Low
    
    ##
    # Describes a system type.
    #
    # NOTE: delegates its content-related methods to its Scope object.
    class SystemT

        # Sets the +name+.
        def set_name!(name)
            @name = name.to_sym
        end

        # Sets the +scope+.
        def set_scope!(scope)
            unless scope.is_a?(Scope) then
                raise AnyError, "Invalid class for a scope: #{scope.class}"
            end
            scope.parent = self
            @scope = scope
        end

        # Maps on the inputs.
        def map_inputs!(&ruby_block)
            @inputs.map! do |input|
                input = ruby_block.call(input)
                input.parent = self unless input.parent
                input
            end
        end

        # Maps on the outputs.
        def map_outputs!(&ruby_block)
            @outputs.map! do |output|
                output = ruby_block.call(output)
                output.parent = self unless output.parent
                output
            end
        end

        # Maps on the inouts.
        def map_inouts!(&ruby_block)
            @inouts.map! do |inout|
                inout = ruby_block.call(inout)
                inout.parent = self unless inout.parent
                inout
            end
        end

        # Deletes an input.
        def delete_input!(signal)
            if @inputs.key?(signal.name) then
                # The signal is present, delete it.
                @inputs.delete(signal.name)
                @interface.delete(signal)
                # And remove its parent.
                signal.parent = nil
            end
            signal
        end

        # Deletes an output.
        def delete_output!(signal)
            if @outputs.key?(signal.name) then
                # The signal is present, delete it.
                @outputs.delete(signal.name)
                @interface.delete(signal)
                # And remove its parent.
                signal.parent = nil
            end
            signal
        end

        # Deletes an inout.
        def delete_inout!(signal)
            if @inouts.key?(signal.name) then
                # The signal is present, delete it.
                @inouts.delete(signal.name)
                @interface.delete(signal)
                # And remove its parent.
                signal.parent = nil
            end
            signal
        end
    end


    ## 
    # Describes scopes of system types.
    class Scope

        # Maps on the local types.
        def map_types!(&ruby_block)
            @types.map(&ruby_block)
        end

        # Maps on the local systemTs.
        def map_systemTs!(&ruby_block)
            @systemTs.map(&ruby_block)
        end

        # Maps on the scopes.
        def map_scopes!(&ruby_block)
            @scopes.map! do |scope|
                scope = ruby_block.call(scope)
                scope.parent = self unless scope.parent
                scope
            end
        end

        # Maps on the inners.
        def map_inners!(&ruby_block)
            @inners.map! do |inner|
                inner = ruby_block.call(inner)
                inner.parent = self unless inner.parent
                inner
            end
        end

        # Maps on the systemIs.
        def map_systemIs!(&ruby_block)
            @systemIs.map! do |systemI|
                systemI = ruby_block.call(systemI)
                systemI.parent = self unless systemI.parent
                systemI
            end
        end

        # Maps on the connections.
        def map_connections!(&ruby_block)
            @connections.map! do |connection|
                connection = ruby_block.call(connection)
                connection.parent = self unless connection.parent
                connection
            end
        end

        # Maps on the behaviors.
        def map_behaviors!(&ruby_block)
            @behaviors.map! do |behavior|
                behavior = ruby_block.call(behavior)
                behavior.parent = self unless behavior.parent
                behavior
            end
        end

        # Deletes an type.
        def delete_type!(type)
            if @types.key?(type.name) then
                # The type is present, delete it. 
                @types.delete(type.name)
                # And remove its parent.
                type.parent = nil
            end
            type
        end

        # Deletes an systemT.
        def delete_systemT!(systemT)
            if @systemTs.key?(systemT.name) then
                # The systemT is present, delete it. 
                @systemTs.delete(systemT.name)
                # And remove its parent.
                systemT.parent = nil
            end
            systemT
        end

        # Deletes a scope.
        def delete_scope!(scope)
            # Remove the scope from the list
            @scopes.delete(scope)
            # And remove its parent.
            scope.parent = nil
            # Return the deleted scope
            scope
        end

        # Deletes an inner.
        def delete_inner!(signal)
            if @inners.key?(signal.name) then
                # The signal is present, delete it. 
                @inners.delete(signal.name)
                # And remove its parent.
                signal.parent = nil
            end
            signal
        end

        # Deletes a systemI.
        def delete_systemI!(systemI)
            if @systemIs.key?(systemI.name) then
                # The instance is present, do remove it.
                @systemIs.delete(systemI.name)
                # And remove its parent.
                systemI.parent = nil
            end
            systemI
        end

        # Deletes a connection.
        def delete_connection!(connection)
            if @connections.include?(connection) then
                # The connection is present, delete it.
                @connections.delete(connection)
                # And remove its parent.
                connection.parent = nil
            end
            connection
        end

        # Deletes a behavior.
        def delete_behavior!(behavior)
            if @behaviors.include?(behavior) then
                # The behavior is present, delete it.
                @behaviors.delete(behavior)
                # And remove its parent.
                behavior.parent = nil
            end
        end
    end

    
    ##
    # Describes a data type.
    class Type

        # Sets the +name+.
        def set_name!(name)
            @name = name.to_sym
        end
    end


    ##
    # Describes a high-level type definition.
    #
    # NOTE: type definition are actually type with a name refering to another
    #       type (and equivalent to it).
    class TypeDef

        # Sets the type definition to +type+.
        def set_def!(type)
            # Checks the referered type.
            unless type.is_a?(Type) then
                raise AnyError, "Invalid class for a type: #{type.class}"
            end
            # Set the referened type.
            @def = type
        end
    end



    ##
    # Describes a vector type.
    class TypeVector
        
        # Sets the +base+ type.
        def set_base!(type)
            # Check and set the base
            unless type.is_a?(Type)
                raise AnyError,
                      "Invalid class for VectorType base: #{base.class}."
            end
            @base = type
        end

        # Sets the +range+.
        def set_range!(ranage)
            # Check and set the range.
            if range.respond_to?(:to_i) then
                # Integer case: convert to 0..(range-1).
                range = (range-1)..0
            elsif
                # Other cases: assume there is a first and a last to create
                # the range.
                range = range.first..range.last
            end
            @range = range
        end
    end


    ##
    # Describes a tuple type.
    class TypeTuple

        # Maps on the sub types.
        def map_types!(&ruby_block)
            @types.map(&ruby_block)
        end

        # Deletes a type.
        def delete_type!(type)
            if @types.include?(type) then
                # The type is present, delete it.
                @types.delete(type)
                # And remove its parent.
                type.parent = nil
            end
            type
        end
    end


    ##
    # Describes a structure type.
    class TypeStruct

        # Maps on the sub types.
        def map_types!(&ruby_block)
            @types.map(&ruby_block)
        end

        # Deletes a sub type by +key+.
        def delete_type!(key)
            if @types.include?(key) then
                # The type is present, delete it.
                type = @types.delete(key)
                # And remove its parent.
                type.parent = nil
            end
            type
        end
    end



    ##
    # Describes a behavior.
    class Behavior

        # Sets the block.
        def set_block!(block)
            self.block = block
        end

        # Maps on the events.
        def map_events!(&ruby_block)
            @events.map! do |event|
                event = ruby_block.call(event)
                event.parent = self unless event.parent
                event
            end
        end

        # Deletes a event.
        def delete_event!(event)
            if @events.include?(event) then
                # The event is present, delete it.
                @events.delete(event)
                # And remove its parent.
                event.parent = nil
            end
            event
        end
    end


    ##
    # Describes a timed behavior.
    #
    # NOTE: 
    # * this is the only kind of behavior that can include time statements. 
    # * this kind of behavior is not synthesizable!
    class TimeBehavior

        # Sets the block.
        def set_block!(block)
            # Check and set the block.
            unless block.is_a?(Block)
                raise AnyError, "Invalid class for a block: #{block.class}."
            end
            # Time blocks are supported here.
            @block = block
            block.parent = self
        end
    end


    ## 
    # Describes an event.
    class Event
        # Sets the type.
        def set_type!(type)
            # Check and set the type.
            @type = type.to_sym
        end

        # Sets the reference to +ref+.
        def set_ref!(ref)
            # Check and set the reference.
            unless ref.is_a?(Ref)
                raise AnyError, "Invalid class for a reference: #{ref.class}"
            end
            @ref = ref
        end

        # Replace node by corresponding replacement from +node2reassign+ that
        # is a table whose entries are:
        # +node+ the node to replace
        # +rep+  the replacement of the node
        # +ref+  the reference where to reassign the node.
        def reassign_expressions!(node2reassign)
            # Build the replacement table.
            node2rep = node2reassign.map {|n,r| [n,r[0]] }.to_h

            # Performs the replacement.
            node2rep_done = {} # The performed replacements.
            # Replace on the sons of the reference.
            node2rep_done.merge!(self.ref.replace_expressions!(node2rep))
            # Shall we replace the ref?
            rep = node2rep[self.ref]
            if rep then
                # Yes, do it.
                rep = rep.clone
                node = self.ref
                # node.set_parent!(nil)
                self.set_ref!(rep)
                node2rep_done[node] = rep
            end

            # Assign the replaced nodes.
            node2rep_done.each do |node,rep|
                reassign = node2reassign[node][1].clone
                self.parent.
                    add_connection(Connection.new(reassign,node.clone))
            end
        end
    end


    ##
    # Describes a signal.
    class SignalI

        # Sets the name.
        def set_name!(name)
            # Check and set the name.
            @name = name.to_sym
        end

        # Sets the type.
        def set_type!(type)
            # Check and set the type.
            if type.is_a?(Type) then
                @type = type
            else
                raise AnyError, "Invalid class for a type: #{type.class}."
            end
        end

        # Sets the value.
        def set_value!(value)
            # Check and set teh value.
            unless value.is_a?(Expression) then
                raise AnyError, "Invalid class for a constant: #{val.class}"
            end
            @value = value
            value.parent = self
        end

    end


    ## 
    # Describes a system instance.
    class SystemI

        # Sets the name.
        def set_name!(name)
            # Set the name as a symbol.
            @name = name.to_sym
        end

        # Sets the systemT.
        def set_systemT(systemT)
            # Check and set the systemT.
            if !systemT.is_a?(SystemT) then
                raise AnyError, "Invalid class for a system type: #{systemT.class}"
            end
            @systemT = systemT
        end

    end



    ## 
    # Describes a statement.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Statement
        # Replaces sub expressions using +node2rep+ table indicating the
        # node to replace and the corresponding replacement.
        # Returns the actually replaced nodes and their corresponding
        # replacement.
        #
        # NOTE: the replacement is duplicated.
        def replace_expressions!(node2rep)
            # By default: nothing to do.
            return {}
        end
    end




    ## 
    # Decribes a transmission statement.
    class Transmit
        # Sets the left.
        def set_left!(left)
            # Check and set the left reference.
            unless left.is_a?(Ref)
                raise AnyError,
                     "Invalid class for a reference (left value): #{left.class}"
            end
            @left = left
            # and set its parent.
            left.parent = self
        end

        # Sets the right.
        def set_right!(right)
            # Check and set the right expression.
            unless right.is_a?(Expression)
                raise AnyError, "Invalid class for an expression (right value): #{right.class}"
            end
            @right = right
            # and set its parent.
            right.parent = self
        end

        # Maps on the children.
        def map_nodes!(&ruby_block)
            @left = ruby_block.call(@left)
            left.parent = self unless left.parent
            @right = ruby_block.call(@right)
            right.parent = self unless right.parent
        end

        # Replaces sub expressions using +node2rep+ table indicating the
        # node to replace and the corresponding replacement.
        # Returns the actually replaced nodes and their corresponding
        # replacement.
        #
        # NOTE: the replacement is duplicated.
        def replace_expressions!(node2rep)
            # First recurse on the children.
            res = self.left.replace_expressions!(node2rep)
            res.merge!(self.right.replace_expressions!(node2rep))
            # Is there a replacement to do on the left?
            rep = node2rep[self.left]
            if rep then
                # Yes, do it.
                rep = rep.clone
                node = self.left
                # node.set_parent!(nil)
                self.set_left!(rep)
                # And register the replacement.
                res[node] = rep
            end
            # Is there a replacement to do on the right?
            rep = node2rep[self.right]
            if rep then
                # Yes, do it.
                rep = rep.clone
                node = self.right
                # node.set_parent!(nil)
                self.set_right!(rep)
                # And register the replacement.
                res[node] = rep
            end

            return res
        end
    end


    ## 
    # Describes an if statement.
    class If

        # Sets the condition.
        def set_condition!(condition)
            # Check and set the condition.
            unless condition.is_a?(Expression)
                raise AnyError,
                      "Invalid class for a condition: #{condition.class}"
            end
            @condition = condition
            # And set its parent.
            condition.parent = self
        end

        # Sets the yes block.
        def set_yes!(yes)
            # Check and set the yes statement.
            unless yes.is_a?(Statement)
                raise AnyError, "Invalid class for a statement: #{yes.class}"
            end
            @yes = yes
            # And set its parent.
            yes.parent = self
        end

        # Sets the no block.
        def set_no!(no)
            # Check and set the yes statement.
            if no and !no.is_a?(Statement)
                raise AnyError, "Invalid class for a statement: #{no.class}"
            end
            @no = no
            # And set its parent.
            no.parent = self if no
        end

        # Deletes an alternate if.
        def delete_noif!(noif)
            if @noifs.include?(noif) then
                # The noif is present, delete it.
                @noifs.delete(noif)
                # And remove its parent.
                noif.parent = nil
            end
            noif
        end

        # Maps on the noifs.
        def map_noifs!(&ruby_block)
            @noifs.map! do |cond,stmnt|
                cond,stmnt  = ruby_block.call(cond,stmnt)
                cond.parent  = self unless cond.parent
                stmnt.parent = self unless stmnt.parent
                [cond,stmnt]
            end
        end

        # Maps on the children (including the condition).
        def map_nodes!(&ruby_block)
            @condition = ruby_block.call(@condition)
            @yes = ruby_block.call(@yes)
            self.map_noifs!(&ruby_block)
            # @noifs.map! do |cond,stmnt|
            #     cond  = ruby_block.call(cond)
            #     stmnt = ruby_block.call(stmnt)
            #     cond.parent  = self unless cond.parent
            #     stmnt.parent = self unless stmnt.parent
            #     [cond,stmnt]
            # end
            @no = ruby_block.call(@no) if @no
        end

        # Replaces sub expressions using +node2rep+ table indicating the
        # node to replace and the corresponding replacement.
        # Returns the actually replaced nodes and their corresponding
        # replacement.
        #
        # NOTE: the replacement is duplicated.
        def replace_expressions!(node2rep)
            # First recurse on the children.
            res = {}
            self.each_node do |node|
                res.merge!(node.replace_expressions!(node2rep))
            end
            # Is there a replacement to do on the condition?
            rep = node2rep[self.condition]
            if rep then
                # Yes, do it.
                rep = rep.clone
                node = self.condition
                # node.set_parent!(nil)
                self.set_condition!(rep)
                # And register the replacement.
                res[node] = rep
            end

            return res
        end
    end

    ##
    # Describes a when for a case statement.
    class When
        # Sets the match.
        def set_match!(match)
            # Checks the match.
            unless match.is_a?(Expression)
                raise AnyError, "Invalid class for a case match: #{match.class}"
            end
            # Set the match.
            @match = match
            # And set their parents.
            match.parent = self
        end

        # Sets the statement.
        def set_statement!(statement)
            # Checks statement.
            unless statement.is_a?(Statement)
                raise AnyError,
                      "Invalid class for a statement: #{statement.class}"
            end
            # Set the statement.
            @statement = statement
            # And set their parents.
            statement.parent = self
        end

        # Maps on the children (including the match).
        def map_nodes!(&ruby_block)
            @match = ruby_block.call(@match)
            @match.parent = self unless @match.parent
            @statement = ruby_block.call(@statement)
            @statement.parent = self unless @statement.parent
        end

        # Replaces sub expressions using +node2rep+ table indicating the
        # node to replace and the corresponding replacement.
        # Returns the actually replaced nodes and their corresponding
        # replacement.
        #
        # NOTE: the replacement is duplicated.
        def replace_expressions!(node2rep)
            # First recurse on the children.
            res = {}
            self.each_node do |node|
                res.merge!(node.replace_expressions!(node2rep))
            end
            # Is there a replacement to do on the value?
            rep = node2rep[self.match]
            if rep then
                # Yes, do it.
                rep = rep.clone
                node = self.match
                # node.set_parent!(nil)
                self.set_match!(rep)
                # And register the replacement.
                res[node] = rep
            end

            return res
        end
    end


    ## 
    # Describes a case statement.
    class Case

        # Sets the value.
        def set_value!(value)
            # Check and set the value.
            unless value.is_a?(Expression)
                raise AnyError, "Invalid class for a value: #{value.class}"
            end
            @value = value
            # And set its parent.
            value.parent = self
        end

        # Sets the default.
        def set_default!(default)
            # Checks and set the default case if any.
            self.default = default
        end

        # Maps on the whens.
        def map_whens!(&ruby_block)
            @whens.map! do |w|
                w = ruby_block.call(w)
                w.parent = self unless w.parent
                w
            end
        end

        # Delete a when.
        def delete_when!(w)
            @whens.delete(w)
        end

        # Maps on the children (including the value).
        def map_nodes!(&ruby_block)
            # A block? Apply it on each child.
            @value = ruby_block.call(@value)
            map_whens!(&ruby_block)
            if @default then
                @default = ruby_block.call(@default)
                @default.parent = self unless @default.parent
            end
        end

        # Replaces sub expressions using +node2rep+ table indicating the
        # node to replace and the corresponding replacement.
        # Returns the actually replaced nodes and their corresponding
        # replacement.
        #
        # NOTE: the replacement is duplicated.
        def replace_expressions!(node2rep)
            # First recurse on the children.
            res = {}
            self.each_node do |node|
                res.merge!(node.replace_expressions!(node2rep))
            end
            # Is there a replacement to do on the value?
            rep = node2rep[self.value]
            if rep then
                # Yes, do it.
                rep = rep.clone
                node = self.value
                # node.set_parent!(nil)
                self.set_value!(rep)
                # And register the replacement.
                res[node] = rep
            end

            return res
        end
    end


    ##
    # Describes a delay: not synthesizable.
    class Delay

        # Sets the value.
        def set_value!(value)
            # Check and set the value.
            unless value.is_a?(Numeric)
                raise AnyError,
                      "Invalid class for a delay value: #{value.class}."
            end
            @value = value
        end

        # Sets the unit.
        def set_unit!(unit)
            # Check and set the unit.
            @unit = unit.to_sym
        end

        # Replaces sub expressions using +node2rep+ table indicating the
        # node to replace and the corresponding replacement.
        # Returns the actually replaced nodes and their corresponding
        # replacement.
        #
        # NOTE: the replacement is duplicated.
        def replace_expressions!(node2rep)
            # First recurse on the children.
            res = self.value.replace_expressions!
            # Is there a replacement to do on the value?
            rep = node2rep[self.value]
            if rep then
                # Yes, do it.
                rep = rep.clone
                node = self.value
                # node.set_parent!(nil)
                self.set_value!(rep)
                # And register the replacement.
                res[node] = rep
            end

            return res
        end
    end


    ## 
    # Describes a wait statement: not synthesizable!
    class TimeWait
        
        # Sets the delay.
        def set_delay!(delay)
            # Check and set the delay.
            unless delay.is_a?(Delay)
                raise AnyError, "Invalid class for a delay: #{delay.class}."
            end
            @delay = delay
            # And set its parent.
            delay.parent = self
        end

        # Maps on the children (including the condition).
        def map_nodes!(&ruby_block)
            # Nothing to do.
        end
    end


    ## 
    # Describes a timed loop statement: not synthesizable!
    class TimeRepeat
        
        # Sets the statement.
        def set_statement!(statement)
            # Check and set the statement.
            unless statement.is_a?(Statement)
                raise AnyError,
                      "Invalid class for a statement: #{statement.class}."
            end
            @statement = statement
            # And set its parent.
            statement.parent = self
        end

        # Sets the delay.
        def set_delay!(delay)
            # Check and set the delay.
            unless delay.is_a?(Delay)
                raise AnyError, "Invalid class for a delay: #{delay.class}."
            end
            @delay = delay
            # And set its parent.
            delay.parent = self
        end

        # Maps on the child.
        def map_nodes!(&ruby_block)
            @statement = ruby_block.call(@statement)
            @statement.parent = self unless @statement.parent
        end

        # Replaces sub expressions using +node2rep+ table indicating the
        # node to replace and the corresponding replacement.
        # Returns the actually replaced nodes and their corresponding
        # replacement.
        #
        # NOTE: the replacement is duplicated.
        def replace_expressions!(node2rep)
            res = {}
            # Recurse on the children.
            self.each_node do |node|
                res.merge!(node.replace_expressions!(node2rep))
            end
            return res
        end
    end


    ## 
    # Describes a block.
    class Block

        # Sets the mode.
        def set_mode!(mode)
            # Check and set the type.
            @mode = mode.to_sym
        end

        # Sets the name.
        def set_name!(name)
            # Check and set the name.
            @name = name.to_sym
        end

        # Maps on the inners.
        def map_inners!(&ruby_block)
            @inners.map! do |inner|
                inner = ruby_block.call(inner)
                inner.parent = self unless inner.parent
                inner
            end
        end

        # Deletes an inner.
        def delete_inner!(signal)
            if @inners.key?(signal.name) then
                # The signal is present, delete it. 
                @inners.delete(signal.name)
                # And remove its parent.
                signal.parent = nil
            end
            signal
        end

        # Inserts statement *stmnt+ at index +idx+.
        def insert_statement!(idx,stmnt)
            # Checks the index.
            if idx > @statements.size then
                raise AryError, "Index out of range: #{idx}"
            end
            # Checks the statement.
            unless stmnt.is_a?(Statement)
                raise AnyError, "Invalid type for a statement: #{stmnt.class}"
            end
            # Inserts the statement.
            @statements.insert(idx,stmnt)
            stmnt.parent = self
        end

        # Sets statement +stmnt+ at index +idx+.
        def set_statement!(idx,stmnt)
            # Checks the index.
            if idx > @statements.size then
                raise AryError, "Index out of range: #{idx}"
            end
            # Checks the statement.
            unless stmnt.is_a?(Statement)
                raise AnyError, "Invalid type for a statement: #{stmnt.class}"
            end
            # Detach the previous statement if any.
            @statements[idx].parent = nil if @statements[idx]
            # Set the new statement.
            @statements[idx] = stmnt
            stmnt.parent = self
        end

        # Maps on the statements.
        def map_statements!(&ruby_block)
            @statements.map! do |stmnt|
                stmnt = ruby_block.call(stmnt)
                stmnt.parent = self unless stmnt.parent
                stmnt
            end
        end

        alias_method :map_nodes!, :map_statements!

        # Deletes a statement.
        def delete_statement!(statement)
            if @statements.include?(statement) then
                # Statement is present, delete it.
                @statements.delete(statement)
                # And remove its parent.
                statement.parent = nil
            end
            statement
        end

        # Replaces sub expressions using +node2rep+ table indicating the
        # node to replace and the corresponding replacement.
        # Returns the actually replaced nodes and their corresponding
        # replacement.
        #
        # NOTE: the replacement is duplicated.
        def replace_expressions!(node2rep)
            res = {}
            # Recurse on the children.
            self.each_node do |node|
                res.merge!(node.replace_expressions!(node2rep))
            end
            return res
        end

        # Replace node by corresponding replacement from +node2reassign+ that
        # is a table whose entries are:
        # +node+ the node to replace
        # +rep+  the replacement of the node
        # +ref+  the reference where to reassign the node.
        def reassign_expressions!(node2reassign)
            # Build the replacement table.
            node2rep = node2reassign.map {|n,r| [n,r[0]] }.to_h

            # First recurse on the sub blocks.
            self.each_block { |block| block.reassign_expressions!(node2rep) }

            # Now work on the block.
            # Replace on the statements.
            self.map_statements! do |statement|
                # Do the replacement
                node2rep_done = statement.replace_expressions!(node2rep)
                # Assign the replaced nodes in a new block.
                unless node2rep_done.empty?
                    blk = Block.new(:seq)
                    node2rep_done.each do |node,rep|
                        reassign = node2reassign[node][1].clone
                        blk.add_statement(Transmit.new(reassign,node.clone))
                    end
                    blk.add_statement(statement.clone)
                    blk
                else
                    statement
                end
            end
        end
    end

    # Describes a timed block.
    #
    # NOTE: 
    # * this is the only kind of block that can include time statements. 
    # * this kind of block is not synthesizable!
    class TimeBlock
    end


    ##
    # Decribes a piece of software code.
    class Code
        # Sets the type.
        def set_type!(type)
            # Check and set type.
            @type = type.to_sym
        end

        # Sets the content.
        def set_content!(content)
            @content = content
            # Freeze it to avoid dynamic tempering of the hardware.
            content.freeze
        end
    end


    ## 
    # Describes a connection.
    #
    # NOTE: eventhough a connection is semantically different from a
    # transmission, it has a common structure. Therefore, it is described
    # as a subclass of a transmit.
    class Connection

        # Replace node by corresponding replacement from +node2reassign+ that
        # is a table whose entries are:
        # +node+ the node to replace
        # +rep+  the replacement of the node
        # +ref+  the reference where to reassign the node.
        def reassign_expressions!(node2reassign)
            # Build the replacement table.
            node2rep = node2reassign.map {|n,r| [n,r[0]] }.to_h

            # Performs the replacements.
            node2rep_done = {} # The performed replacements.
            # Replace on the sons of the left.
            node2rep_done.merge!(self.left.replace_expressions!(node2rep))
            # Replace on the sons of the left.
            node2rep_done.merge!(self.right.replace_expressions!(node2rep))
            # Shall we replace the right?
            rep = node2rep[self.right]
            if rep then
                # Yes, do it.
                rep = rep.clone
                node = self.right
                # node.set_parent!(nil)
                self.set_right!(rep)
                node2rep_done[node] = rep
            end

            # Assign the replaced nodes.
            node2rep_done.each do |node,rep|
                reassign = node2reassign[node][1].clone
                self.parent.add_connection(
                    Connection.new(reassign,node.clone))
            end
        end
    end



    ## 
    # Describes an expression.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Expression

        # Sets the type.
        def set_type!(type)
            # Check and set the type.
            if type.is_a?(Type) then
                @type = type
            else
                raise AnyError, "Invalid class for a type: #{type.class}."
            end
        end

        # Maps on the children.
        def map_nodes!(&ruby_block)
            # By default, nothing to do.
        end

        alias_method :map_expressions!, :map_nodes!

        # Replaces sub expressions using +node2rep+ table indicating the
        # node to replace and the corresponding replacement.
        # Returns the actually replaced nodes and their corresponding
        # replacement.
        #
        # NOTE: the replacement is duplicated.
        def replace_expressions!(node2rep)
            # By default, nothing to do.
            return {}
        end
    end

    
    ##
    # Describes a value.
    class Value

        # Sets the content.
        def set_content!(content)
            unless content.is_a?(Numeric) or content.is_a?(HDLRuby::BitString)
                content = HDLRuby::BitString.new(content.to_s)
            end
            @content = content 
        end
    end

    # Module for mutable expressions with one child.
    module OneChildMutable
        # Sets the child.
        def set_child!(child)
            # Check and set the child.
            unless child.is_a?(Expression)
                raise AnyError,"Invalid class for an expression: #{child.class}"
            end
            @child = child
            # And set its parent.
            child.parent = self
        end

        # Maps on the child.
        def map_nodes!(&ruby_block)
            @child = ruby_block.call(@child)
            @child.parent = self unless @child.parent
        end

        # Replaces sub expressions using +node2rep+ table indicating the
        # node to replace and the corresponding replacement.
        # Returns the actually replaced nodes and their corresponding
        # replacement.
        #
        # NOTE: the replacement is duplicated.
        def replace_expressions!(node2rep)
            # First recurse on the child.
            res = self.child.replace_expressions!(node2rep)
            # Is there a replacement to do?
            rep = node2rep[self.child]
            if rep then
                # Yes, do it.
                rep = rep.clone
                node = self.child
                # node.set_parent!(nil)
                self.set_child!(rep)
                # And register the replacement.
                res[node] = rep
            end
            return res
        end
    end

    ##
    # Describes a cast.
    class Cast
        include OneChildMutable
    end


    ##
    # Describes an operation.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Operation

        # Sets the operator.
        def set_operator!(operator)
            # Check and set the operator.
            @operator = operator.to_sym
        end
    end


    ## 
    # Describes an unary operation.
    class Unary
        include OneChildMutable

        # Moved to OneChildMutable
        # # Sets the child.
        # def set_child!(child)
        #     # Check and set the child.
        #     unless child.is_a?(Expression)
        #         raise AnyError,"Invalid class for an expression: #{child.class}"
        #     end
        #     @child = child
        #     # And set its parent.
        #     child.parent = self
        # end

        # # Maps on the child.
        # def map_nodes!(&ruby_block)
        #     @child = ruby_block.call(@child)
        #     @child.parent = self unless @child.parent
        # end
    end


    ##
    # Describes an binary operation.
    class Binary

        # Sets the left.
        def set_left!(left)
            # Check and set the left.
            unless left.is_a?(Expression)
                raise AnyError,"Invalid class for an expression: #{left.class}"
            end
            @left = left
            # And set its parent.
            left.parent = self
        end

        # Sets the right.
        def set_right!(right)
            # Check and set the right.
            unless right.is_a?(Expression)
                raise AnyError,"Invalid class for an expression: #{right.class}"
            end
            @right = right
            # And set its parent.
            right.parent = self
        end

        # Maps on the child.
        def map_nodes!(&ruby_block)
            @left  = ruby_block.call(@left)
            @left.parent = self unless @left.parent
            @right = ruby_block.call(@right)
            @right.parent = self unless @right.parent
        end

        # Replaces sub expressions using +node2rep+ table indicating the
        # node to replace and the corresponding replacement.
        # Returns the actually replaced nodes and their corresponding
        # replacement.
        #
        # NOTE: the replacement is duplicated.
        def replace_expressions!(node2rep)
            # First recurse on the children.
            res = self.left.replace_expressions!(node2rep)
            res.merge!(self.right.replace_expressions!(node2rep))
            # Is there a replacement to do on the left?
            rep = node2rep[self.left]
            if rep then
                # Yes, do it.
                rep = rep.clone
                node = self.left
                # node.set_parent!(nil)
                self.set_left!(rep)
                # And register the replacement.
                res[node] = rep
            end
            # Is there a replacement to do on the right?
            rep = node2rep[self.right]
            if rep then
                # Yes, do it.
                rep = rep.clone
                node = self.right
                # node.set_parent!(nil)
                self.set_right!(rep)
                # And register the replacement.
                res[node] = rep
            end

            return res
        end
    end


    ##
    # Describes a section operation (generalization of the ternary operator).
    #
    # NOTE: choice is using the value of +select+ as an index.
    class Select

        # Sets the select.
        def set_select!(select)
            # Check and set the selection.
            unless select.is_a?(Expression)
                raise AnyError,
                      "Invalid class for an expression: #{select.class}"
            end
            @select = select
            # And set its parent.
            select.parent = self
        end

        # Maps on the choices.
        def map_choices!(&ruby_block)
            @choices.map! do |choice|
                choice = ruby_block.call(choice)
                choice.parent = self unless choice.parent
                choice
            end
        end

        # Deletes a choice.
        def delete_choice!(choice)
            if @choices.include?(choice) then
                # The choice is present, delete it.
                @choices.delete(choice)
                # And remove its parent.
                choice.parent = nil
            end
            choice
        end

        # Maps on the children.
        def map_nodes!(&ruby_block)
            @select = ruby_block.call(@select)
            @select.parent = self unless @select.parent
            map_choices!(&ruby_block)
        end

        # Replaces sub expressions using +node2rep+ table indicating the
        # node to replace and the corresponding replacement.
        # Returns the actually replaced nodes and their corresponding
        # replacement.
        #
        # NOTE: the replacement is duplicated.
        def replace_expressions!(node2rep)
            # First recurse on the children.
            res = {}
            self.each_node do |node|
                res.merge!(node.replace_expressions!(node2rep))
            end
            # Is there a replacement to do on the select?
            rep = node2rep[self.select]
            if rep then
                # Yes, do it.
                rep = rep.clone
                node = self.select
                # node.set_parent!(nil)
                self.set_select!(rep)
                # And register the replacement.
                res[node] = rep
            end
            # Is there a replacement of on a choice.
            self.map_choices! do |choice|
                rep = node2rep[choice]
                if rep then
                    # Yes, do it.
                    rep = rep.clone
                    node = choice
                    # node.set_parent!(nil)
                    # And register the replacement.
                    res[node] = rep
                    rep
                else
                    choice
                end
            end
            return res
        end
    end

    # Module adding some (but not all) mutable methods to Concat and
    # RefConcat.
    module MutableConcat

        # Replaces sub expressions using +node2rep+ table indicating the
        # node to replace and the corresponding replacement.
        # Returns the actually replaced nodes and their corresponding
        # replacement.
        #
        # NOTE: the replacement is duplicated.
        def replace_expressions!(node2rep)
            # First recurse on the children.
            res = {}
            self.each_node do |node|
                res.merge!(node.replace_expressions!(node2rep))
            end
            # Is there a replacement of on a sub node?
            self.map_nodes! do |sub|
                rep = node2rep[sub]
                if rep then
                    # Yes, do it.
                    rep = rep.clone
                    node = sub
                    # node.set_parent!(nil)
                    # And register the replacement.
                    res[node] = rep
                    rep
                else
                    sub
                end
            end
            return res
        end
    end


    ## 
    # Describes a concatenation expression.
    class Concat
        include MutableConcat

        # Maps on the expression.
        def map_expressions!(&ruby_block)
            @expressions.map! do |expression|
                expression = ruby_block.call(expression)
                expression.parent = self unless expression.parent
                expression
            end
        end

        alias_method :map_nodes!, :map_expressions!

        # Delete an expression.
        def delete_expression!(expression)
            if @expressions.include?(expression) then
                # The expression is present, delete it.
                @expressions.delete(expression)
                # And remove its parent.
                expression.parent = nil
            end
            expression
        end

    end


    ## 
    # Describes a reference expression.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Ref
        # Maps on the children.
        def map_nodes!(&ruby_block)
            # Nothing to do.
        end
    end


    ##
    # Describes concatenation reference.
    class RefConcat
        include MutableConcat

        # Maps on the references.
        def map_refs!(&ruby_block)
            @refs.map! do |ref|
                ref = ruby_block.call(ref)
                ref.parent = self unless ref.parent
                ref
            end
        end

        alias_method :map_nodes!, :map_refs!

        # Delete a reference.
        def delete_ref!(ref)
            if @refs.include?(ref) then
                # The ref is present, delete it.
                @refs.delete(ref)
                # And remove its parent.
                ref.parent = nil
            end
            ref
        end

    end


    ## 
    # Describes a index reference.
    class RefIndex
        
        # Sets the base reference.
        def set_ref!(ref)
            # Check and set the accessed reference.
            unless ref.is_a?(Ref) then
                raise AnyError, "Invalid class for a reference: #{ref.class}."
            end
            @ref = ref
            # And set its parent.
            ref.parent = self
        end

        # Sets the index.
        def set_index!(ref)
            # Check and set the index.
            unless index.is_a?(Expression) then
                raise AnyError,
                      "Invalid class for an index reference: #{index.class}."
            end
            @index = index
            # And set its parent.
            index.parent = self
        end

        # Maps on the children.
        def map_nodes!(&ruby_block)
            @index = ruby_block.call(@index)
            @index.parent = self unless @index.parent
            @ref   = ruby_block.call(@ref)
            @ref.parent = self unless @ref.parent
        end

        # Replaces sub expressions using +node2rep+ table indicating the
        # node to replace and the corresponding replacement.
        # Returns the actually replaced nodes and their corresponding
        # replacement.
        #
        # NOTE: the replacement is duplicated.
        def replace_expressions!(node2rep)
            # First recurse on the ref.
            res = self.ref.replace_expressions!(node2rep)
            # And and the index.
            res = self.index.replace_expressions!(node2rep)
            
            # Is there a replacement to on the ref?
            rep = node2rep[self.ref]
            if rep then
                # Yes, do it.
                rep = rep.clone
                node = self.ref
                # node.set_parent!(nil)
                self.set_ref!(rep)
                # And register the replacement.
                res[node] = rep
            end
            # Is there a replacement to on the index?
            rep = node2rep[self.index]
            if rep then
                # Yes, do it.
                rep = rep.clone
                node = self.index
                # node.set_parent!(nil)
                self.set_index!(rep)
                # And register the replacement.
                res[node] = rep
            end
            return res
        end
    end


    ## 
    # Describes a range reference.
    class RefRange
        
        # Sets the base reference.
        def set_ref!(ref)
            # Check and set the refered object.
            # unless ref.is_a?(Ref) then
            unless ref.is_a?(Expression) then
                raise AnyError, "Invalid class for a reference: #{ref.class}."
            end
            @ref = ref
            # And set its parent.
            ref.parent = self
        end

        # Sets the range.
        def set_range!(range)
            # Check and set the range.
            first = range.first
            unless first.is_a?(Expression) then
                raise AnyError,
                      "Invalid class for a range first: #{first.class}."
            end
            last = range.last
            unless last.is_a?(Expression) then
                raise AnyError, "Invalid class for a range last: #{last.class}."
            end
            @range = first..last
            # And set their parents.
            first.parent = last.parent = self
        end

        # Maps on the children.
        def map_nodes!(&ruby_block)
            @range = ruby_block.call(@range.first)..ruby_block.call(@range.last)
            @range.first.parent = self unless @range.first.parent
            @range.last.parent = self unless @range.last.parent
            @ref   = ruby_block.call(@ref)
            @ref.parent = self unless @ref.parent
        end

        # Replaces sub expressions using +node2rep+ table indicating the
        # node to replace and the corresponding replacement.
        # Returns the actually replaced nodes and their corresponding
        # replacement.
        #
        # NOTE: the replacement is duplicated.
        def replace_expressions!(node2rep)
            # First recurse on the ref.
            res = self.ref.replace_expressions!(node2rep)
            # And and the range.
            res = self.range.first.replace_expressions!(node2rep)
            res = self.range.last.replace_expressions!(node2rep)
            
            # Is there a replacement to on the ref?
            rep = node2rep[self.ref]
            if rep then
                # Yes, do it.
                rep = rep.clone
                node = self.ref
                # node.set_parent!(nil)
                self.set_ref!(rep)
                # And register the replacement.
                res[node] = rep
            end
            # Is there a replacement to on the range first?
            range = self.range
            rep = node2rep[range.first]
            if rep then
                # Yes, do it.
                rep = rep.clone
                node = range.first
                # node.set_parent!(nil)
                range.first = rep
                # And register the replacement.
                res[node] = rep
            end
            rep = node2rep[range.last]
            if rep then
                # Yes, do it.
                rep = rep.clone
                node = range.last
                # node.set_parent!(nil)
                range.last = rep
                # And register the replacement.
                res[node] = rep
            end
            self.set_range!(range)
            return res
        end
    end


    ##
    # Describes a name reference.
    class RefName
        # Sets the base reference.
        def set_ref!(ref)
            # Check and set the accessed reference.
            unless ref.is_a?(Ref) then
                raise AnyError, "Invalid class for a reference: #{ref.class}."
            end
            @ref = ref
            # And set its parent.
            ref.parent = self
        end

        # Sets the name.
        def set_name!(name)
            # Check and set the symbol.
            @name = name.to_sym
        end

        # Maps on the children.
        def map_nodes!(&ruby_block)
            @ref = ruby_block.call(@ref)
            @ref.parent = self unless @ref.parent
        end

        # Replaces sub expressions using +node2rep+ table indicating the
        # node to replace and the corresponding replacement.
        # Returns the actually replaced nodes and their corresponding
        # replacement.
        #
        # NOTE: the replacement is duplicated.
        def replace_expressions!(node2rep)
            # First recurse on the ref.
            res = self.ref.replace_expressions!(node2rep)
            
            # Is there a replacement to on the ref?
            rep = node2rep[self.ref]
            if rep then
                # Yes, do it.
                rep = rep.clone
                node = self.ref
                # node.set_parent!(nil)
                self.set_ref!(rep)
                # And register the replacement.
                res[node] = rep
            end
            return res
        end
    end


    ## 
    # Describe a this reference.
    #
    # This is the current system.
    class RefThis

        # Maps on the children.
        def map_nodes!(&ruby_block)
            # Nothing to do.
        end
    end
end
