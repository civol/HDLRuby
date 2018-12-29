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
            @inputs.map(&ruby_block)
        end

        # Maps on the outputs.
        def map_outputs!(&ruby_block)
            @outputs.map(&ruby_block)
        end

        # Maps on the inouts.
        def map_inouts!(&ruby_block)
            @inouts.map(&ruby_block)
        end

        # Deletes an input.
        def delete_input!(input)
            if @inputs.key?(signal) then
                # The signal is present, delete it.
                @inputs.delete(signal.name)
                @interface.delete(signal)
                # And remove its parent.
                signal.parent = nil
            end
            signal
        end

        # Deletes an output.
        def delete_output!(output)
            if @outputs.key?(signal) then
                # The signal is present, delete it.
                @outputs.delete(signal.name)
                @interface.delete(signal)
                # And remove its parent.
                signal.parent = nil
            end
            signal
        end

        # Deletes an inout.
        def delete_inout!(inout)
            if @inouts.key?(signal) then
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

        # Maps on the scopes.
        def map_scopes!(&ruby_block)
            @scopes.map(&ruby_block)
        end

        # Maps on the inners.
        def map_inners!(&ruby_block)
            @inners.map(&ruby_block)
        end

        # Maps on the systemIs.
        def map_systemIs!(&ruby_block)
            @systemIs.map(&ruby_block)
        end

        # Maps on the connections.
        def map_connections!(&ruby_block)
            @connections.map(&ruby_block)
        end

        # Maps on the behaviors.
        def map_behaviors!(&ruby_block)
            @behaviors.map(&ruby_block)
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
        def delete_inner!(inner)
            if @inners.key?(signal) then
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
        def set_base(type)
            # Check and set the base
            unless base.is_a?(Type)
                raise AnyError,
                      "Invalid class for VectorType base: #{base.class}."
            end
            @base = base
        end

        # Sets the +range+.
        def set_range
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
            @events.map(&ruby_block)
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
        def map_children!(&ruby_block)
            @left = ruby_block.call(@left)
            left.parent = self
            @right = ruby_block.call(@right)
            right.parent = self
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

        # Maps on the alternate ifs.
        def map_noifs!(&ruby_block)
            @no_ifs.map(&ruby_block)
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

        # Maps on the children (including the condition).
        def map_children!(&ruby_block)
            @condition = ruby_block.call(@condition)
            @yes = ruby_block.call(@yes)
            @no = ruby_block.call(@no) if @no
            map_noifs!(&ruby_block)
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

        # Maps on the children (including the condition).
        def map_children!(&ruby_block)
            @match = ruby_block.call(@match)
            @statement = ruby_block.call(@statement)
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
            @whens.map(&ruby_block)
        end

        # Delete a when.
        def delete_when!(w)
            @whens.delete(w)
        end

        # Maps on the children (including the value).
        def map_children!(&ruby_block)
            # A block? Apply it on each child.
            @value = ruby_block.call(@value)
            map_whens!(&ruby_block)
            @default = ruby_block.call(@default) if @default
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
        def map_children!(&ruby_block)
            @statement = ruby_block.call(@statement)
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
            @inners.map(&ruby_block)
        end

        # Maps on the statements.
        def map_statements!(&ruby_block)
            @statements.map(&ruby_block)
        end

        alias :map_children! :map_statements!

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

    ##
    # Describes a cast.
    class Cast

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
        def map_children!(&ruby_block)
            @child = ruby_block.call(@child)
        end
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
        def map_children!(&ruby_block)
            @child = ruby_block.call(@child)
        end
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
        def map_children!(&ruby_block)
            @left  = ruby_block.call(@left)
            @right = ruby_block.call(@right)
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
            @choices.map(ruby_block)
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
        def map_children!(&ruby_block)
            @select = ruby_block.call(@select)
            map_choices!(&ruby_block)
        end
    end


    ## 
    # Describes a concatenation expression.
    class Concat
        # Maps on the expression.
        def map_expressions!(&ruby_block)
            @expressions.map(&ruby_block)
        end

        alias :map_children! :map_expressions!

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
        def map_children!(&ruby_block)
            # Nothing to do.
        end
    end


    ##
    # Describes concatenation reference.
    class RefConcat

        # Maps on the references.
        def map_refs!(&ruby_block)
            @refs.map(&ruby_block)
        end

        alias :map_children! :map_refs!

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
        def map_children!(&ruby_block)
            @index = ruby_block.call(@index)
            @ref   = ruby_block.call(@ref)
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
        def map_children!(&ruby_block)
            @range.first = ruby_block.call(@range.first)
            @range.last  = ruby_block.call(@range.last)
            @ref         = ruby_block.call(@ref)
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
        def map_children!(&ruby_block)
            @ref = ruby_block.call(@ref)
        end
    end


    ## 
    # Describe a this reference.
    #
    # This is the current system.
    class RefThis

        # Maps on the children.
        def map_children!(&ruby_block)
            # Nothing to do.
        end
    end
end
