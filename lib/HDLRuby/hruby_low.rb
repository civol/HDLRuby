require "HDLRuby/hruby_bstr"
require "HDLRuby/hruby_error"
# require "HDLRuby/hruby_decorator"
require 'forwardable'



module HDLRuby
    # Some useful constants
    Infinity = +1.0/0.0
end
    


##
# Library for describing the basic structures of the hardware component.
#
########################################################################
module HDLRuby::Low

    ##
    # Describes a hash for named HDLRuby objects
    class HashName < Hash
        # Adds a named +object+.
        def add(object)
            self[object.name] = object
        end

        # Tells if +object+ is included in the hash.
        def include?(object)
            return self.has_key?(object.name)
        end

        # Iterate over the objects included in the hash.
        alias_method :each, :each_value
    end


    # Hdecorator = HDLRuby::Hdecorator

    ##
    # Gives parent definition and access properties to an hardware object.
    module Hparent
        # The parent.
        attr_reader :parent

        # Set the +parent+.
        #
        # Note: if +parent+ is nil, the current parent is removed.
        def parent=(parent)
            if @parent and parent and !@parent.equal?(parent) then
                # The parent is already defined,it is not to be removed,
                # and the new parent is different, error.
                raise AnyError, "Parent already defined."
            else
                @parent = parent
            end
        end

        # Clears the parent.
        def no_parent!
            @parent = nil
        end

        # Get the parent scope.
        def scope
            cur = self.parent
            cur = cur.parent until cur.is_a?(Scope)
            return cur
        end

        # Get the full parents hierachy.
        def hierarchy
            res = []
            cur = self
            while(cur) do
                res << cur
                cur = cur.parent
            end
            return res
        end
    end



    ##
    # Describes a system type.
    #
    # NOTE: delegates its content-related methods to its Scope object.
    class SystemT

        include Hparent

        # The name of the system.
        attr_reader :name

        # The scope of the system type.
        attr_reader :scope

        # Creates a new system type named +name+ with +scope+.
        def initialize(name,scope)
            # Set the name as a symbol.
            @name = name.to_sym

            # Initialize the interface (signal instance lists).
            @inputs  = HashName.new # The input signals by name
            @outputs = HashName.new # The output signals by name
            @inouts  = HashName.new # The inout signals by name
            @interface = []         # The interface signals in order of
                                    # declaration

            # Check the scope
            unless scope.is_a?(Scope)
                raise AnyError,
                      "Invalid class for a system instance: #{scope.class}"
            end
            # Set the parent of the scope
            scope.parent = self
            # Set the scope
            @scope = scope


            # The methods delegated to the scope.
            # Do not use Delegator to keep hand on the attributes of the class.

            [:add_scope,     :each_scope,                     # :delete_scope,
             :add_systemI,   :each_systemI,   :get_systemI,   # :delete_systemI,
             :add_inner,     :each_inner,     :get_inner,     # :delete_inner,
             :add_behavior,  :each_behavior,  :each_behavior_deep, # :delete_behavior,
             :add_connection,:each_connection,                # :delete_connection
            ].each do |meth_sym|
                define_singleton_method(meth_sym,
                                        &(@scope.method(meth_sym).to_proc))
            end
        end

        # # Add decorator capability (modifies intialize to put after).
        # include Hdecorator

        # Comparison for hash: structural comparison.
        def eql?(obj)
            return false unless obj.is_a?(SystemT)
            return false unless @name.eql?(obj.name)
            return false unless @scope.eql?(obj.scope)
            idx = 0
            obj.each_input do |input|
                return false unless @inputs[input.name].eql?(input)
                idx += 1
            end
            return false unless idx == @inputs.size
            idx = 0
            obj.each_output do |output|
                return false unless @outputs[output.name].eql?(output)
                idx += 1
            end
            return false unless idx == @outputs.size
            idx = 0
            obj.each_inout do |inout|
                return false unless @inouts[inout.name].eql?(inout)
                idx += 1
            end
            return false unless idx == @inouts.size
            return true
        end

        # Hash function.
        def hash
            return [@name,@scope,@inputs,@outputs,@inouts].hash
        end


        # Handling the (re)configuration.

        # Gets the configuration wrapper if any.
        def wrapper
            return defined? @wrapper ? @wrapper : nil
        end

        # Sets the configuration wrapper to +systemT+.
        def wrapper=(systemT)
            unless systemT.is_a?(SystemT) then
                raise "Invalid class for a wrapper system type: #{systemT}."
            end
            @wrapper = systemT
        end


        # Handling the signals.

        # Adds input +signal+.
        def add_input(signal)
            # print "In #{self} add_input with signal: #{signal.name}\n"
            # Check and add the signal.
            unless signal.is_a?(SignalI)
                raise AnyError,
                      "Invalid class for a signal instance: #{signal.class}"
            end
            # if @inputs.include?(signal) then
            #     raise AnyError, "SignalI #{signal.name} already present."
            # end
            if @inputs.include?(signal) then
                signal.parent = self
                # Replace the signal.
                old_signal = @inputs[signal.name]
                @inputs.add(signal)
                @interface[@interface.index(old_signal)] = signal
            else
                # Set the parent of the signal.
                signal.parent = self
                # And add the signal.
                @inputs.add(signal)
                @interface << signal
            end
            return signal
        end

        # Adds output +signal+.
        def add_output(signal)
            # Check and add the signal.
            unless signal.is_a?(SignalI)
                raise AnyError,
                      "Invalid class for a signal instance: #{signal.class}"
            end
            # if @outputs.include?(signal) then
            #     raise AnyError, "SignalI #{signal.name} already present."
            # end
            if @outputs.include?(signal) then
                signal.parent = self
                # Replace the signal.
                old_signal = @outputs[signal.name]
                @outputs.add(signal)
                @interface[@interface.index(old_signal)] = signal
            else
                # Set the parent of the signal.
                signal.parent = self
                # And add the signal.
                @outputs.add(signal)
                @interface << signal
            end
            return signal
        end

        # Adds inout +signal+.
        def add_inout(signal)
            # Check and add the signal.
            unless signal.is_a?(SignalI)
                raise AnyError,
                      "Invalid class for a signal instance: #{signal.class}"
            end
            # if @inouts.include?(signal) then
            #     raise AnyError, "SignalI #{signal.name} already present."
            # end
            if @inouts.include?(signal) then
                signal.parent = self
                # Replace the signal.
                old_signal = @inouts[signal.name]
                @inouts.add(signal)
                @interface[@interface.index(old_signal)] = signal
            else
                # Set the parent of the signal.
                signal.parent = self
                # And add the signal.
                @inouts.add(signal)
                @interface << signal
            end
            return signal
        end

        # Iterates over the input signals.
        #
        # Returns an enumerator if no ruby block is given.
        def each_input(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_input) unless ruby_block
            # A ruby block? Apply it on each input signal instance.
            @inputs.each(&ruby_block)
        end

        # Iterates over the output signals.
        #
        # Returns an enumerator if no ruby block is given.
        def each_output(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_output) unless ruby_block
            # A ruby block? Apply it on each output signal instance.
            @outputs.each(&ruby_block)
        end

        # Iterates over the inout signals.
        #
        # Returns an enumerator if no ruby block is given.
        def each_inout(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_inout) unless ruby_block
            # A ruby block? Apply it on each inout signal instance.
            @inouts.each(&ruby_block)
        end

        # Iterates over all the signals of the interface of the 
        # system.
        #
        # Returns an enumerator if no ruby block is given.
        def each_signal(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_signal) unless ruby_block
            # A ruby block? Apply it on each signal instance.
            @interface.each(&ruby_block)
        end

        # Iterates over all the signals of the system including its
        # scope (input, output, inout, inner).
        #
        # Returns an enumerator if no ruby block is given.
        def each_signal_all(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_signal) unless ruby_block
            # A ruby block? Apply it on each signal instance.
            @inputs.each(&ruby_block)
            @outputs.each(&ruby_block)
            @inouts.each(&ruby_block)
            # And each signal of the direct scope.
            @scope.each_signal(&ruby_block)
        end

        # Iterates over all the signals of the system type and its scope.
        def each_signal_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_signal_deep) unless ruby_block
            # A ruby block?
            # First iterate over the current system type's signals.
            # self.each_signal_all(&ruby_block)
            self.each_signal(&ruby_block)
            # Then apply on the behaviors (since in HDLRuby:High, blocks can
            # include signals).
            @scope.each_signal_deep(&ruby_block)
        end

        # Tells if there is any input signal.
        def has_input?
            return !@inputs.empty?
        end

        # Tells if there is any output signal.
        def has_output?
            return !@outputs.empty?
        end

        # Tells if there is any output signal.
        def has_inout?
            return !@inouts.empty?
        end

        # Tells if there is any signal (including in the scope of the system).
        def has_signal?
            return ( self.has_input? or self.has_output? or self.has_inout? or
                     self.has_inner? )
        end

        # Gets an array containing all the input signals.
        def get_all_inputs
            return each_input.to_a
        end

        # Gets an array containing all the output signals.
        def get_all_outputs
            return each_output.to_a
        end

        # Gets an array containing all the inout signals.
        def get_all_inouts
            return each_inout.to_a
        end

        # Gets an array containing all the signals.
        def get_all_signals
            return each_signal.to_a
        end

        # Gets an input signal by +name+.
        def get_input(name)
            return @inputs[name.to_sym]
        end

        # Gets an output signal by +name+.
        def get_output(name)
            return @outputs[name.to_sym]
        end

        # Gets an inout signal by +name+.
        def get_inout(name)
            return @inouts[name.to_sym]
        end

        # # Gets an inner signal by +name+.
        # def get_inner(name)
        #     return @inners[name.to_sym]
        # end

        # Gets a signal by +name+.
        def get_signal(name)
            return get_input(name) || get_output(name) || get_inout(name) # ||
                   # get_inner(name)
        end

        # Gets an interface signal by order of declaration +i+.
        def get_interface(i)
            return @interface[i]
        end

        # # Deletes input +signal+.
        # def delete_input(signal)
        #     if @inputs.key?(signal) then
        #         # The signal is present, delete it.
        #         @inputs.delete(signal.name)
        #         @interface.delete(signal)
        #         # And remove its parent.
        #         signal.parent = nil
        #     end
        #     signal
        # end

        # # Deletes output +signal+.
        # def delete_output(signal)
        #     if @outputs.key?(signal) then
        #         # The signal is present, delete it.
        #         @outputs.delete(signal.name)
        #         @interface.delete(signal)
        #         # And remove its parent.
        #         signal.parent = nil
        #     end
        #     signal
        # end

        # # Deletes inout +signal+.
        # def delete_inout(signal)
        #     if @inouts.key?(signal) then
        #         # The signal is present, delete it.
        #         @inouts.delete(signal.name)
        #         @interface.delete(signal)
        #         # And remove its parent.
        #         signal.parent = nil
        #     end
        #     signal
        # end
    
        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # Then apply on each signal.
            self.each_signal do |signal|
                signal.each_deep(&ruby_block)
            end
            # Then apply on each scope.
            self.each_scope do |scope|
                scope.each_deep(&ruby_block)
            end
        end

        # Iterates over the systemT deeply if any.
        #
        # Returns an enumerator if no ruby block is given.
        def each_systemT_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_systemT_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # And recurse on the systemT accessible through the instances.
            self.scope.each_scope_deep do |scope|
                scope.each_systemI do |systemI|
                    # systemI.systemT.each_systemT_deep(&ruby_block)
                    systemI.each_systemT do |systemT|
                        systemT.each_systemT_deep(&ruby_block)
                    end
                end
            end
        end

        # Iterates over the systemT deeply if any in order of reference
        # to ensure the refered elements are processed first.
        #
        # Returns an enumerator if no ruby block is given.
        def each_systemT_deep_ref(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_systemT_deep_ref) unless ruby_block
            # A ruby block? 
            # Recurse on the systemT accessible through the instances.
            self.scope.each_scope_deep do |scope|
                scope.each_systemI do |systemI|
                    # systemI.systemT.each_systemT_deep(&ruby_block)
                    systemI.each_systemT do |systemT|
                        systemT.each_systemT_deep_ref(&ruby_block)
                    end
                end
            end
            # Finally apply it to current.
            ruby_block.call(self)
        end
    end


    ## 
    # Describes scopes of system types.
    class Scope

        include Hparent

        # The name of the scope if any
        attr_reader :name

        # Creates a new scope with a possible +name+.
        def initialize(name = :"")
            # Check and set the name.
            @name = name.to_sym
            # Initialize the local types.
            @types = HashName.new
            # Initialize the local system types.
            @systemTs = HashName.new
            # Initialize the sub scopes.
            @scopes = []
            # Initialize the inner signal instance lists.
            @inners  = HashName.new
            # Initialize the system instances list.
            @systemIs = HashName.new
            # Initialize the non-HDLRuby code chunks list.
            @codes = []
            # Initialize the connections list.
            @connections = []
            # Initialize the behaviors lists.
            @behaviors = []
        end

        # # Add decorator capability (modifies intialize to put after).
        # include Hdecorator

        # Comparison for hash: structural comparison.
        def eql?(obj)
            return false unless obj.is_a?(Scope)
            idx = 0
            obj.each_systemT do |systemT|
                return false unless @systemTs[systemT.name].eql?(systemT)
                idx += 1
            end
            return false unless idx == @systemTs.size
            idx = 0
            obj.each_type do |type|
                return false unless @types[type.name].eql?(type)
                idx += 1
            end
            return false unless idx == @types.size
            idx = 0
            obj.each_scope do |scope|
                return false unless @scopes[idx].eql?(scope)
                idx += 1
            end
            return false unless idx == @scopes.size
            idx = 0
            obj.each_inner do |inner|
                return false unless @inners[inner.name].eql?(inner)
                idx += 1
            end
            return false unless idx == @inners.size
            idx = 0
            obj.each_systemI do |systemI|
                return false unless @systemIs[systemI.name].eql?(systemI)
                idx += 1
            end
            return false unless idx == @systemIs.size
            idx = 0
            obj.each_connection do |connection|
                return false unless @connections[idx].eql?(connection)
                idx += 1
            end
            return false unless idx == @connections.size
            idx = 0
            obj.each_behavior do |behavior|
                return false unless @behaviors[idx].eql?(behavior)
                idx += 1
            end
            return false unless idx == @behaviors.size
            return true
        end

        # Hash function.
        def hash
            return [@systemTs,@types,@scopes,@inners,@systemIs,@connections,@behaviors].hash
        end

        # Handling the local system types.

        # Adds system instance +systemT+.
        def add_systemT(systemT)
            # puts "add_systemT with name #{systemT.name}"
            # Check and add the systemT.
            unless systemT.is_a?(SystemT)
                raise AnyError,
                      "Invalid class for a system type: #{systemT.class}"
            end
            # if @systemTs.include?(systemT) then
            #     raise AnyError, "SystemT #{systemT.name} already present."
            # end
            # Set the parent of the instance
            systemT.parent = self
            # puts "systemT = #{systemT}, parent=#{self}"
            # Add the instance
            @systemTs.add(systemT)
        end

        # Iterates over the system instances.
        #
        # Returns an enumerator if no ruby block is given.
        def each_systemT(&ruby_block)
            # puts "each_systemT from scope=#{self}"
            # No ruby block? Return an enumerator.
            return to_enum(:each_systemT) unless ruby_block
            # A ruby block? Apply it on each system instance.
            @systemTs.each(&ruby_block)
        end

        # Tells if there is any system instance.
        def has_systemT?
            return !@systemTs.empty?
        end

        # Gets a system instance by +name+.
        def get_systemT(name)
            return @systemTs[name]
        end

        # # Deletes system instance systemT.
        # def delete_systemT(systemT)
        #     if @systemTs.key?(systemT.name) then
        #         # The instance is present, do remove it.
        #         @systemTs.delete(systemT.name)
        #         # And remove its parent.
        #         systemT.parent = nil
        #     end
        #     systemT
        # end

        # Handle the local types.

        # Adds system instance +type+.
        def add_type(type)
            # puts "add_type with name #{type.name}"
            # Check and add the type.
            unless type.is_a?(Type)
                raise AnyError,
                      "Invalid class for a type: #{type.class}"
            end
            # if @types.include?(type) then
            #     raise AnyError, "Type #{type.name} already present."
            # end
            # Set the parent of the instance
            type.parent = self
            # puts "type = #{type}, parent=#{self}"
            # Add the instance
            @types.add(type)
        end

        # Iterates over the system instances.
        #
        # Returns an enumerator if no ruby block is given.
        def each_type(&ruby_block)
            # puts "each_type from scope=#{self}"
            # No ruby block? Return an enumerator.
            return to_enum(:each_type) unless ruby_block
            # A ruby block? Apply it on each system instance.
            @types.each(&ruby_block)
        end

        # Tells if there is any system instance.
        def has_type?
            return !@types.empty?
        end

        # Gets a system instance by +name+.
        def get_type(name)
            return @types[name]
        end

        # # Deletes system instance type.
        # def delete_type(type)
        #     if @types.key?(type.name) then
        #         # The instance is present, do remove it.
        #         @types.delete(type.name)
        #         # And remove its parent.
        #         type.parent = nil
        #     end
        #     type
        # end



        # Handling the scopes
        
        # Adds a new +scope+.
        def add_scope(scope)
            # Check and add the scope.
            unless scope.is_a?(Scope)
                raise AnyError,
                      "Invalid class for a system instance: #{scope.class}"
            end
            # if @scopes.include?(scope) then
            #     raise AnyError, "Scope #{scope} already present."
            # end
            # Set the parent of the scope
            scope.parent = self
            # Remove a former scope with same name if present (override)
            @scopes.delete_if { |sc| sc.name && sc.name == scope.name }
            # Add the scope
            @scopes << scope
        end

        # Iterates over the sub scopes.
        #
        # Returns an enumerator if no ruby block is given.
        def each_scope(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_scope) unless ruby_block
            # A ruby block? Apply it on each sub scope.
            @scopes.each(&ruby_block)
        end

        # Iterates over the scopes deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_scope_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_scope_deep) unless ruby_block
            # A ruby block? Apply it on self.
            ruby_block.call(self)
            # And recurse each sub scope.
            @scopes.each {|scope| scope.each_scope_deep(&ruby_block) }
        end

        # Tells if there is any sub scope.
        def has_scope?
            return !@scopes.empty?
        end

        # # Deletes a scope.
        # def delete_scope(scope)
        #     # Remove the scope from the list
        #     @scopes.delete(scope)
        #     # And remove its parent.
        #     scope.parent = nil
        #     # Return the deleted scope
        #     scope
        # end

        # Handling the system instances.

        # Adds system instance +systemI+.
        def add_systemI(systemI)
            # puts "add_systemI with name #{systemI.name}"
            # Check and add the systemI.
            unless systemI.is_a?(SystemI)
                raise AnyError,
                      "Invalid class for a system instance: #{systemI.class}"
            end
            # if @systemIs.include?(systemI) then
            #     raise AnyError, "SystemI #{systemI.name} already present."
            # end
            # Set the parent of the instance
            systemI.parent = self
            # puts "systemI = #{systemI}, parent=#{self}"
            # Add the instance
            @systemIs.add(systemI)
        end

        # Iterates over the system instances.
        #
        # Returns an enumerator if no ruby block is given.
        def each_systemI(&ruby_block)
            # puts "each_systemI from scope=#{self}"
            # No ruby block? Return an enumerator.
            return to_enum(:each_systemI) unless ruby_block
            # A ruby block? Apply it on each system instance.
            @systemIs.each(&ruby_block)
        end

        # Tells if there is any system instance.
        def has_systemI?
            return !@systemIs.empty?
        end

        # Gets a system instance by +name+.
        def get_systemI(name)
            return @systemIs[name]
        end

        # # Deletes system instance systemI.
        # def delete_systemI(systemI)
        #     if @systemIs.key?(systemI.name) then
        #         # The instance is present, do remove it.
        #         @systemIs.delete(systemI.name)
        #         # And remove its parent.
        #         systemI.parent = nil
        #     end
        #     systemI
        # end
        #
        # Handling the non-HDLRuby code chunks.

        # Adds code chunk +code+.
        def add_code(code)
            # Check and add the code chunk.
            unless code.is_a?(Code)
                raise AnyError,
                      "Invalid class for a non-hDLRuby code chunk: #{code.class}"
            end
            # if @codes.include?(code) then
            #     raise AnyError, "Code #{code.name} already present."
            # end
            # Set the parent of the code chunk.
            code.parent = self
            # puts "code = #{code}, parent=#{self}"
            # Add the code chunk.
            @codes << code
            code
        end

        # Iterates over the non-HDLRuby code chunks.
        #
        # Returns an enumerator if no ruby block is given.
        def each_code(&ruby_block)
            # puts "each_code from scope=#{self}"
            # No ruby block? Return an enumerator.
            return to_enum(:each_code) unless ruby_block
            # A ruby block? Apply it on each system instance.
            @codes.each(&ruby_block)
        end

        # Tells if there is any non-HDLRuby code chunk.
        def has_code?
            return !@codes.empty?
        end

        # Gets a code chunk by +name+.
        def get_code(name)
            return @codes[name]
        end

        # Handling the signals.
        
        # Adds inner signal +signal+.
        def add_inner(signal)
            # puts "adding inner signal: #{signal.name}(#{signal})"
            # Check and add the signal.
            unless signal.is_a?(SignalI)
                raise AnyError,
                      "Invalid class for a signal instance: #{signal.class}"
            end
            # if @inners.include?(signal) then
            #     raise AnyError, "SignalI #{signal.name} already present."
            # end
            # Set the parent of the signal.
            signal.parent = self
            # And add the signal.
            @inners.add(signal)
            return signal
        end

        # Iterates over the inner signals.
        #
        # Returns an enumerator if no ruby block is given.
        def each_inner(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_inner) unless ruby_block
            # A ruby block? Apply it on each inner signal instance.
            # @inners.each_value(&ruby_block)
            @inners.each(&ruby_block)
        end

        # Iterates over all the signals (Equivalent to each_inner).
        #
        # Returns an enumerator if no ruby block is given.
        def each_signal(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_signal) unless ruby_block
            # A ruby block? Apply it on each signal instance.
            @inners.each(&ruby_block)
        end

        # Iterates over all the signals of the scope, its behaviors', its
        # instances' and its sub scopes'.
        def each_signal_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_signal_deep) unless ruby_block
            # A ruby block?
            # First iterate over the current system type's signals.
            self.each_signal(&ruby_block)
            # Then apply on the behaviors (since in HDLRuby:High, blocks can
            # include signals).
            self.each_behavior do |behavior|
                behavior.block.each_signal_deep(&ruby_block)
            end
            # Then recurse on the system instances.
            self.each_systemI do |systemI|
                systemI.each_signal_deep(&ruby_block)
            end
            # The recurse on the sub scopes.
            self.each_scope do |scope|
                scope.each_signal_deep(&ruby_block)
            end
        end

        # Tells if there is any inner.
        def has_inner?
            return !@inners.empty?
        end

        # Tells if there is any signal, equivalent to has_inner?
        def has_signal?
            return self.has_inner?
        end

        ## Gets an array containing all the inner signals.
        def get_all_inners
            return each_inner.to_a
        end

        ## Gets an inner signal by +name+.
        def get_inner(name)
            return @inners[name.to_sym]
        end

        # ## Gets a signal by +path+.
        # #
        # #  NOTE: +path+ can also be a single name or a reference object.
        # def get_signal(path)
        #     path = path.path_each if path.respond_to?(:path_each) # Ref case.
        #     if path.respond_to?(:each) then
        #         # Path is iterable: look for the first name.
        #         path = path.each
        #         name = path.each.next
        #         # Maybe it is a system instance.
        #         systemI = self.get_systemI(name)
        #         if systemI then
        #             # Yes, look for the remaining of the path into the
        #             # corresponding system type.
        #             return systemI.systemT.get_signal(path)
        #         else
        #             # Maybe it is a signal name.
        #             return self.get_signal(name)
        #         end
        #     else
        #         # Path is a single name, look for the signal in the system's
        #         # Try in the inputs.
        #         signal = get_input(path)
        #         return signal if signal
        #         # Try in the outputs.
        #         signal = get_output(path)
        #         return signal if signal
        #         # Try in the inouts.
        #         signal = get_inout(path)
        #         return signal if signal
        #         # Not found yet, look into the inners.
        #         return get_inner(path)
        #     end
        # end

        # Gets an inner signal by +name+, equivalent to get_inner.
        def get_signal(name)
            return @inners[name]
        end

        # # Deletes inner +signal+.
        # def delete_inner(signal)
        #     if @inners.key?(signal) then
        #         # The signal is present, delete it. 
        #         @inners.delete(signal.name)
        #         # And remove its parent.
        #         signal.parent = nil
        #     end
        #     signal
        # end

        # Handling the connections.

        # Adds a +connection+.
        def add_connection(connection)
            unless connection.is_a?(Connection)
                raise AnyError,
                      "Invalid class for a connection: #{connection.class}"
            end
            # Set the parent of the connection.
            connection.parent = self
            # And add it.
            @connections << connection
            connection
        end

        # Iterates over the connections.
        #
        # Returns an enumerator if no ruby block is given.
        def each_connection(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_connection) unless ruby_block
            # A ruby block? Apply it on each connection.
            @connections.each(&ruby_block)
        end

        # Tells if there is any connection.
        def has_connection?
            return !@connections.empty?
        end

        # # Deletes +connection+.
        # def delete_connection(connection)
        #     if @connections.include?(connection) then
        #         # The connection is present, delete it.
        #         @connections.delete(connection)
        #         # And remove its parent.
        #         connection.parent = nil
        #     end
        #     connection
        # end

        # Iterates over all the connections of the system type and its system
        # instances.
        def each_connection_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_connection_deep) unless ruby_block
            # A ruby block?
            # First iterate over current system type's connection.
            self.each_connection(&ruby_block)
            # Then recurse on the system instances.
            self.each_systemI do |systemI|
                systemI.each_connection_deep(&ruby_block)
            end
        end

        # Handling the behaviors.

        # Adds a +behavior+.
        def add_behavior(behavior)
            unless behavior.is_a?(Behavior)
                raise AnyError,"Invalid class for a behavior: #{behavior.class}"
            end
            # Set its parent
            behavior.parent = self
            # And add it
            @behaviors << behavior
            behavior
        end

        # Iterates over the behaviors.
        #
        # Returns an enumerator if no ruby block is given.
        def each_behavior(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_behavior) unless ruby_block
            # A ruby block? Apply it on each behavior.
            @behaviors.each(&ruby_block)
        end

        # Reverse iterates over the behaviors.
        #
        # Returns an enumerator if no ruby block is given.
        def reverse_each_behavior(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:reverse_each_behavior) unless ruby_block
            # A ruby block? Apply it on each behavior.
            @behaviors.reverse_each(&ruby_block)
        end

        # Returns the last behavior.
        def last_behavior
            return @behaviors[-1]
        end

        # BROKEN
        #
        # # Iterates over all the behaviors of the system type and its system
        # # instances.
        # def each_behavior_deep(&ruby_block)
        #     # No ruby block? Return an enumerator.
        #     return to_enum(:each_behavior_deep) unless ruby_block
        #     # A ruby block?
        #     # First iterate over current system type's behavior.
        #     self.each_behavior(&ruby_block)
        #     # Then recurse on the system instances.
        #     self.each_systemI do |systemI|
        #         systemI.systemT.each_behavior_deep(&ruby_block)
        #     end
        # end
        
        # Iterates over all the behaviors of the system type and its system
        # instances.
        def each_behavior_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_behavior_deep) unless ruby_block
            # A ruby block?
            # First recurse on the sub scopes.
            self.each_scope_deep do |scope|
                scope.each_behavior(&ruby_block)
            end
            # Then iterate over current system type's behavior.
            self.each_behavior(&ruby_block)
        end

        # Tells if there is any inner.
        def has_behavior?
            return !@behaviors.empty?
        end

        # # Deletes +behavior+.
        # def delete_behavior(behavior)
        #     if @behaviors.include?(behavior) then
        #         # The behavior is present, delete it.
        #         @behaviors.delete(behavior)
        #         # And remove its parent.
        #         behavior.parent = nil
        #     end
        # end

        # Iterates over all the blocks of the system type and its system
        # instances.
        def each_block_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block_deep) unless ruby_block
            # A ruby block?
            # Then apply on each sub scope.
            self.each_scope do |scope|
                scope.each_block_deep(&ruby_block)
            end
            # And apply it on each behavior's block deeply.
            self.each_behavior do |behavior|
                behavior.each_block_deep(&ruby_block)
            end
        end

        # Broken
        # # Iterates over all the stamements of the system type and its system
        # # instances.
        # def each_statement_deep(&ruby_block)
        #     # No ruby block? Return an enumerator.
        #     return to_enum(:each_statement_deep) unless ruby_block
        #     # A ruby block?
        #     # Apply it on each block deeply.
        #     self.each_block do |block|
        #         block.each_statement_deep(&ruby_block)
        #     end
        # end

        # Iterates over all the stamements of the system type and its system
        # instances.
        def each_statement_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_statement_deep) unless ruby_block
            # A ruby block?
            # Then apply on each sub scope.
            self.each_scope do |scope|
                scope.each_statement_deep(&ruby_block)
            end
            # And apply it on each behavior's block deeply.
            self.each_behavior do |behavior|
                behavior.each_statement_deep(&ruby_block)
            end
        end

        # Iterates over all the nodes of the system type and its system
        # instances.
        def each_node_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node_deep) unless ruby_block
            # A ruby block?
            # Then apply on each sub scope.
            self.each_scope do |scope|
                scope.each_node_deep(&ruby_block)
            end
            # And apply it on each behavior's block deeply.
            self.each_behavior do |behavior|
                behavior.each_node_deep(&ruby_block)
            end
        end

        # Broken
        # # Iterates over all the statements and connections of the system type
        # # and its system instances.
        # def each_arrow_deep(&ruby_block)
        #     # No ruby block? Return an enumerator.
        #     return to_enum(:each_arrow_deep) unless ruby_block
        #     # A ruby block?
        #     # First, apply it on each connection.
        #     self.each_connection do |connection|
        #         ruby_block.call(connection)
        #     end
        #     # Then recurse over its blocks.
        #     self.each_behavior do |behavior|
        #         behavior.each_block_deep(&ruby_block)
        #     end
        #     # Finally recurse on its system instances.
        #     self.each_systemI do |systemI|
        #         systemI.each_arrow_deep(&ruby_block)
        #     end
        # end

        # Broken
        # # Iterates over all the object executed when a specific event is
        # # activated (they include the behaviors and the connections).
        # #
        # # NOTE: the arguments of the ruby block are the object and an enumerator
        # # over the set of events it is sensitive to.
        # def each_sensitive_deep(&ruby_block)
        #     # No ruby block? Return an enumerator.
        #     return to_enum(:each_sensitive_deep) unless ruby_block
        #     # A ruby block?
        #     # First iterate over the current system type's connections.
        #     self.each_connection do |connection|
        #         ruby_block.call(connection,
        #                         connection.each_ref_deep.lazy.map do |ref|
        #             Event.new(:change,ref)
        #         end)
        #     end
        #     # First iterate over the current system type's behaviors.
        #     self.each_behavior do |behavior|
        #         ruby_block.call(behavior,behavior.each_event)
        #     end
        #     # Then recurse on the system instances.
        #     self.each_systemI do |systemI|
        #         systemI.each_sensitive_deep(&ruby_block)
        #     end
        # end
        
        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # The apply on each type.
            self.each_type do |type|
                type.each_deep(&ruby_block)
            end
            # Then apply on each systemT.
            self.each_systemT do |systemT|
                systemT.each_deep(&ruby_block)
            end
            # Then apply on each scope.
            self.each_scope do |scope|
                scope.each_deep(&ruby_block)
            end
            # Then apply on each inner signal.
            self.each_inner do |inner|
                inner.each_deep(&ruby_block)
            end
            # Then apply on each systemI.
            self.each_systemI do |systemI|
                systemI.each_deep(&ruby_block)
            end
            # Then apply on each code.
            self.each_code do |code|
                code.each_deep(&ruby_block)
            end
            # Then apply on each connection.
            self.each_connection do |connection|
                connection.each_deep(&ruby_block)
            end
            # Then apply on each behavior.
            self.each_behavior do |behavior|
                behavior.each_deep(&ruby_block)
            end
        end
        


        # Gets the top scope, i.e. the first scope of the current system.
        def top_scope
            return self.parent.is_a?(SystemT) ? self : self.parent.top_scope
        end

        # Gets the parent system, i.e., the parent of the top scope.
        def parent_system
            return self.top_scope.parent
        end

    end

    
    ##
    # Describes a data type.
    class Type

        include Hparent

        # The name of the type
        attr_reader :name

        # Creates a new type named +name+.
        def initialize(name)
            # Check and set the name.
            @name = name.to_sym
        end

        # # Add decorator capability (modifies intialize to put after).
        # include Hdecorator

        # Comparison for hash: structural comparison.
        def eql?(obj)
            return false unless obj.is_a?(Type)
            return false unless @name.eql?(obj.name)
            return true
        end

        # Hash function.
        def hash
            return [@name].hash
        end

        # Tells if the type signed.
        def signed?
            return false
        end

        # Tells if the type is unsigned.
        def unsigned?
            return false
        end

        # Tells if the type is fixed point.
        def fixed?
            return false
        end

        # Tells if the type is floating point.
        def float?
            return false
        end

        # Tells if the type is a leaf.
        def leaf?
            return false
        end

        # Tells if the type of of vector kind.
        def vector?
            return false
        end

        # Gets the bitwidth of the type, by default 0.
        # Bit, signed, unsigned and Float base have a width of 1.
        def width
            if [:bit, :signed, :unsigned, :float ].include?(@name) then
                return 1
            else
                return 0
            end
        end

        # Gets the type max value if any.
        # Default: not defined.
        def max
            raise AnyError, "No max value for type #{self}"
        end

        # Gets the type min value if any.
        # Default: not defined.
        def min
            raise AnyError, "No min value for type #{self}"
        end

        # Get the direction of the type, little or big endian.
        def direction
            # By default, little endian.
            return :little
        end

        # Tells if the type has a range.
        def range?
            return false
        end

        # Gets the range of the type, by default range is not defined.
        def range
            raise AnyError, "No range for type #{self}"
        end

        # Tells if the type has a base.
        def base?
            return false
        end

        # Gets the base type, by default base type is not defined.
        def base
            raise AnyError, "No base type for type #{self}"
        end

        # Tells if the type has sub types.
        def types?
            return false
        end

        # Tells if the type is regular (applies for tuples).
        def regular?
            return false
        end

        # Tells if the type has named sub types.
        def struct?
            return false
        end

        # Tells if the type is hierarchical.
        def hierarchical?
            return self.base? || self.types?
        end

        # Tell if +type+ is equivalent to current type.
        #
        # NOTE: type can be compatible while not being equivalent, please
        #       refer to `hruby_types.rb` for type compatibility.
        def equivalent?(type)
            # By default, types are equivalent iff they have the same name.
            return (type.is_a?(Type) and self.name == type.name)
        end

        # Iterates over the types deeply if any.
        def each_type_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_type_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # And that's all by default.
        end
        alias_method :each_deep, :each_type_deep

        # Converts to a bit vector.
        def to_vector
            return TypeVector.new(:"", Bit, self.width-1..0)
        end
    end


    # The leaf types.

    ##
    # The module giving leaf properties to a type.
    module LLeaf
        # Tells if the type is a leaf.
        def leaf?
            return true
        end
    end

    
    ##
    # The void type.
    class << (Void = Type.new(:void) )
        include LLeaf
    end
    
    ##
    # The bit type leaf.
    class << ( Bit = Type.new(:bit) )
        include LLeaf
        # Tells if the type is unsigned.
        def unsigned?
            return true
        end
        # Tells if the type fixed point.
        def fixed?
            return true
        end
        # Gets the bitwidth of the type, nil for undefined.
        def width
            1
        end
        # Gets the range of the type.
        def range
            0..0
        end
        # # Get the base type, actually self for leaf types.
        # def base
        #     self
        # end
    end

    ##
    # The signed types leaf.
    class << ( Signed = Type.new(:signed) )
        include LLeaf
        # Tells if the type is signed.
        def signed?
            return true
        end
        # Tells if the type is fixed point.
        def fixed?
            return true
        end
        # Gets the bitwidth of the type, nil for undefined.
        def width
            1
        end
        # Gets the range of the type.
        def range
            0..0
        end
        # # Get the base type, actually self for leaf types.
        # def base
        #     self
        # end
    end

    ##
    # The unsigned types leaf.
    class << ( Unsigned = Type.new(:unsigned) )
        include LLeaf
        # Tells if the type is unsigned.
        def unsigned?
            return true
        end
        # Tells if the type is fixed point.
        def fixed?
            return true
        end
        # Gets the bitwidth of the type, nil for undefined.
        def width
            1
        end
        # Gets the range of the type.
        def range
            0..0
        end
        # # Get the base type, actually self for leaf types.
        # def base
        #     self
        # end
    end

    ##
    # The float types leaf.
    class << ( Float = Type.new(:float) )
        include LLeaf
        # Tells if the type is signed.
        def signed?
            return true
        end
        # Tells if the type is floating point.
        def float?
            return true
        end
        # Gets the bitwidth of the type, nil for undefined.
        def width
            1
        end
        # Gets the range of the type.
        def range
            0..0
        end
        # # Get the base type, actually self for leaf types.
        # def base
        #     self
        # end
    end

    ##
    # The void type.
    class << (StringT = Type.new(:string) )
        include LLeaf
    end


    ##
    # Describes a high-level type definition.
    #
    # NOTE: type definition are actually type with a name refering to another
    #       type (and equivalent to it).
    class TypeDef < Type
        # The definition of the type.
        attr_reader :def

        # Type creation.

        # Creates a new type definition named +name+ from +type+.
        def initialize(name,type)
            # Initialize with name.
            super(name)
            # Checks the referered type.
            unless type.is_a?(Type) then
                raise AnyError, "Invalid class for a type: #{type.class}"
            end
            # Set the referened type.
            @def = type

            # Sets the delegations
            self.extend Forwardable
            [ :signed?, :unsigned?, :fixed?, :float?, :leaf?, :vector?,
              :width, :range?, :range, :base?, :base, :types?,
              :get_all_types, :get_type, :each, :each_type, 
              :regular?,
              :each_name,
              :equivalent? ].each do |meth|
                  if @def.respond_to?(meth)
                      self.def_delegator :@def, meth
                  end
              end
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            # # General type comparison.
            # return false unless super(obj)
            # Specific comparison.
            return false unless obj.is_a?(TypeDef)
            return false unless @name.eql?(obj.name)
            return false unless @def.eql?(obj.def)
            return true
        end

        # Hash function.
        def hash
            return [super,@def].hash
        end

        # Iterates over the types deeply if any.
        def each_type_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_type_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # And recurse on the definition.
            @def.each_type_deep(&ruby_block)
        end

        alias_method :each_deep, :each_type_deep

        # Tells if the type signed.
        def signed?
            return @def.signed?
        end

        # Tells if the type is unsigned.
        def unsigned?
            return @def.unsigned?
        end

        # Tells if the type is fixed point.
        def fixed?
            return @def.fixed?
        end

        # Tells if the type is floating point.
        def float?
            return @def.float?
        end

        # Tells if the type is a leaf.
        def leaf?
            return @def.leaf?
        end

        # Tells if the type of of vector kind.
        def vector?
            return @def.vector?
        end

        # Gets the bitwidth of the type, by default 0.
        # Bit, signed, unsigned and Float base have a width of 1.
        def width
            return @def.width
        end

        # Gets the type max value if any.
        # Default: not defined.
        def max
            return @def.max
        end

        # Gets the type min value if any.
        # Default: not defined.
        def min
            return @def.min
        end

        # Get the direction of the type, little or big endian.
        def direction
            return @def.direction
        end

        # Tells if the type has a range.
        def range?
            return @def.range?
        end

        # Gets the range of the type, by default range is not defined.
        def range
            return @def.range
        end

        # Tells if the type has a base.
        def base?
            return @def.base?
        end

        # Gets the base type, by default base type is not defined.
        def base
            return @def.base
        end

        # Tells if the type has sub types.
        def types?
            return @def.types?
        end

        # Tells if the type is regular (applies for tuples).
        def regular?
            return @def.regular?
        end

        # Tells if the type has named sub types.
        def struct?
            return @def.struct?
        end

        # Tells if the type is hierarchical.
        def hierarchical?
            return @def.hierarchical?
        end

        # Tell if +type+ is equivalent to current type.
        #
        # NOTE: type can be compatible while not being equivalent, please
        #       refer to `hruby_types.rb` for type compatibility.
        def equivalent?(type)
            return @def.equivalent?(type)
        end

        # Converts to a bit vector.
        def to_vector
            return @def.to_vector
        end

    end



    ##
    # Describes a vector type.
    class TypeVector < Type
        # The base type of the vector
        attr_reader :base

        # Tells if the type of of vector kind.
        def vector?
            return true
        end

        # Tells if the type has a base.
        def base?
            return true
        end

        # The range of the vector.
        attr_reader :range

        # Creates a new vector type named +name+ from +base+ type and with
        # +range+.
        # NOTE: if +range+ is a positive integer it is converted to
        # (range-1)..0, if it is a negative integer it is converted to
        # 0..(-range-1)
        def initialize(name,base,range)
            # Initialize the type.
            super(name)

            # Check and set the base
            unless base.is_a?(Type)
                raise AnyError,
                      "Invalid class for VectorType base: #{base.class}."
            end
            @base = base

            # Check and set the range.
            if range.respond_to?(:to_i) then
                # Integer case: convert to 0..(range-1).
                range = range > 0 ? (range-1)..0 : 0..(-range-1)
            elsif
                # Other cases: assume there is a first and a last to create
                # the range.
                range = range.first..range.last
            end
            @range = range
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            # # General type comparison.
            # return false unless super(obj)
            # Specific comparison.
            return false unless obj.is_a?(TypeVector)
            return false unless @base.eql?(obj.base)
            return false unless @range.eql?(obj.range)
            return true
        end

        # Hash function.
        def hash
            return [super,@base,@range].hash
        end

        # Gets the size of the type in number of base elements.
        def size
            return (@range.first.to_i - @range.last.to_i).abs + 1
        end

        # Gets the bitwidth of the type, nil for undefined.
        #
        # NOTE: must be redefined for specific types.
        def width
            first = @range.first.to_i
            last  = @range.last.to_i
            return @base.width * ((first-last).abs + 1)
        end

        # Gets the type max value if any.
        def max
            if (self.signed?) then
                return (2**(self.width-1))-1
            else
                return (2**(self.width))-1
            end
        end

        # Gets the type min value if any.
        # Default: not defined.
        def min
            if (self.signed?) then
                return -(2**(self.width-1))
            else
                return 0
            end
        end

        # Get the direction of the type, little or big endian.
        def direction
            return @range.first < @range.last ? :big : :little
        end

        # Gets the direction of the range.
        def dir
            return (@range.last - @range.first)
        end

        # Tells if the type signed.
        def signed?
            return @base.signed?
        end

        # Tells if the type is unsigned.
        def unsigned?
            return @base.unsigned?
        end

        # Tells if the type is fixed point.
        def fixed?
            return @base.signed?
        end

        # Tells if the type is floating point.
        def float?
            return @base.float?
        end

        # Tell if +type+ is equivalent to current type.
        #
        # NOTE: type can be compatible while not being equivalent, please
        #       refer to `hruby_types.rb` for type compatibility.
        def equivalent?(type)
            return (type.is_a?(TypeVector) and
                    @range == type.range
                    @base.equivalent?(type.base) )
        end

        # Should not exists since it identifies types with multiple sub types.
        #
        # # Iterates over the sub types.
        # def each_type(&ruby_block)
        #     # No ruby block? Return an enumerator.
        #     return to_enum(:each_type) unless ruby_block
        #     # A ruby block? Apply it on the base.
        #     ruby_block.call(@base)
        # end

        # Iterates over the types deeply if any.
        def each_type_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_type_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # And recurse on the base.
            @base.each_type_deep(&ruby_block)
        end

        alias_method :each_deep, :each_type_deep
    end


    ##
    # Describes a signed integer data type.
    class TypeSigned < TypeVector

        # Creates a new vector type named +name+ from +base+ type and with
        # +range+.
        #
        # NOTE:
        # * The default range is 32-bit.
        def initialize(name,range = 31..0)
            # Initialize the type.
            super(name,Signed,range)
        end
    end

    ##
    # Describes a unsigned integer data type.
    class TypeUnsigned < TypeVector

        # Creates a new vector type named +name+ from +base+ type and with
        # +range+.
        #
        # NOTE:
        # * The default range is 32-bit.
        def initialize(name,range = 31..0)
            # Initialize the type.
            super(name,Unsigned,range)
        end
    end

    ##
    # Describes a float data type.
    class TypeFloat < TypeVector

        # Creates a new vector type named +name+ from +base+ type and with
        # +range+.
        #
        # NOTE:
        # * The bits of negative range stands for the exponent
        # * The default range is for 64-bit IEEE 754 double precision standart
        def initialize(name,range = 52..-11)
            # Initialize the type.
            super(name,Float,range)
        end
    end

    # Standard vector types.
    Integer = TypeSigned.new(:integer)
    Natural = TypeUnsigned.new(:natural)
    Bignum  = TypeSigned.new(:bignum,HDLRuby::Infinity..0)
    Real    = TypeFloat.new(:float)



    ##
    # Describes a tuple type.
    class TypeTuple < Type
        # Creates a new tuple type named +name+ width +direction+ and whose
        # sub types are given by +content+.
        def initialize(name,direction,*content)
            # Initialize the type.
            super(name)

            # Set the direction.
            @direction = direction.to_sym
            unless [:little, :big].include?(@direction)
                raise AnyError, "Invalid direction for a type: #{direction}"
            end

            # Check and set the content.
            content.each do |sub|
                unless sub.is_a?(Type) then
                    raise AnyError, "Invalid class for a type: #{sub.class}"
                end
            end
            @types = content
        end


        # Comparison for hash: structural comparison.
        def eql?(obj)
            # # General type comparison.
            # return false unless super(obj)
            return false unless obj.is_a?(TypeTuple)
            # Specific comparison.
            idx = 0
            obj.each_type do |type|
                return false unless @types[idx].eql?(type)
                idx += 1
            end
            return false unless idx == @types.size
            return true
        end

        # Hash function.
        def hash
            return [super,@types].hash
        end

        # Tells if the type has sub types.
        def types?
            return true
        end

        # Gets an array containing all the syb types.
        def get_all_types
            return @types.clone
        end

        # Gets a sub type by +index+.
        def get_type(index)
            return @types[index.to_i]
        end

        # Adds a sub +type+.
        def add_type(type)
            unless type.is_a?(Type) then
                raise AnyError, 
                      "Invalid class for a type: #{type.class} (#{type})"
            end
            @types << type
        end

        # Iterates over the sub name/type pair.
        #
        # Returns an enumerator if no ruby block is given.
        def each(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each) unless ruby_block
            # A ruby block? Apply it on each sub name/type pair.
            @types.each(&ruby_block)
        end

        # Iterates over the sub types.
        #
        # Returns an enumerator if no ruby block is given.
        def each_type(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_type) unless ruby_block
            # A ruby block? Apply it on each sub type.
            @types.each(&ruby_block)
        end

        # Iterates over the types deeply if any.
        def each_type_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_type_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # And recurse on the sub types.
            @types.each { |type| type.each_type_deep(&ruby_block) }
        end

        alias_method :each_deep, :each_type_deep

        # Tell if the tuple is regular, i.e., all its sub types are equivalent.
        #
        # NOTE: empty tuples are assumed not to be regular.
        def regular?
            return false if @types.empty?
            t0 = @types[0]
            @types[1..-1].each do |type|
                return false unless t0.equivalent?(type)
            end
            return true
        end

        # Gets the bitwidth.
        def width
            return @types.reduce(0) { |sum,type| sum + type.width }
        end

        # Get the direction of the type, little or big endian.
        def direction
            return @direction
        end

        # Gets the range of the type.
        #
        # NOTE: only valid if the tuple is regular (i.e., all its sub types 
        #       are identical)
        def range
            if regular? then
                # Regular tuple, return its range as if it was an array.
                return 0..@types.size-1
            else
                raise AnyError, "No range for type #{self}"
            end
        end

        # Tells if the type has a base.
        #
        # NOTE: only if the tuple is regular (i.e., all its sub types
        #       are identical)
        def base?
            return regular?
        end

        # Gets the base type.
        #
        # NOTE: only valid if the tuple is regular (i.e., all its sub types 
        #       are identical)
        def base
            if regular? then
                # Regular tuple, return the type of its first element.
                return @types[0]
            else
                raise AnyError, "No base type for type #{self}"
            end
        end

        # Tell if +type+ is equivalent to current type.
        #
        # NOTE: type can be compatible while not being equivalent, please
        #       refer to `hruby_types.rb` for type compatibility.
        def equivalent?(type)
            return (type.is_a?(TypeTuple) and
                    !@types.zip(type.types).index {|t0,t1| !t0.equivalent?(t1) })
        end
    end


    ##
    # Describes a structure type.
    class TypeStruct < Type
        attr_reader :direction

        # Creates a new structure type named +name+ with direction +dir+ and 
        # whose hierachy is given by +content+.
        def initialize(name,dir,content)
            # Initialize the type.
            super(name)

            # Set the direction.
            @direction = dir.to_sym
            unless [:little, :big].include?(@direction)
                raise AnyError, "Invalid direction for a type: #{dir}"
            end

            # Check and set the content.
            content = Hash[content]
            @types = content.map do |k,v|
                unless v.is_a?(Type) then
                    raise AnyError, "Invalid class for a type: #{v.class}"
                end
                [ k.to_sym, v ]
            end.to_h
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            # General type comparison.
            # return false unless super(obj)
            return false unless obj.is_a?(TypeStruct)
            # Specific comparison.
            idx = 0
            obj.each_key do |name|
                return false unless @types[name].eql?(obj.get_type(name))
                idx += 1
            end
            return false unless idx == @types.size
            return true
        end

        # Hash function.
        def hash
            return [super,@types].hash
        end

        # Tells if the type has named sub types.
        def struct?
            return true
        end

        # Tells if the type has sub types.
        def types?
            return true
        end

        # Gets an array containing all the syb types.
        def get_all_types
            return @types.values
        end

        # Gets a sub type by +name+.
        # NOTE: +name+ can also be an index.
        def get_type(name)
            if name.respond_to?(:to_sym) then
                return @types[name.to_sym]
            else
                return @types.values[name.to_i]
            end
        end

        # Iterates over the sub name/type pair.
        #
        # Returns an enumerator if no ruby block is given.
        def each(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each) unless ruby_block
            # A ruby block? Apply it on each sub name/type pair.
            @types.each(&ruby_block)
        end

        # Iterates over the sub types.
        #
        # Returns an enumerator if no ruby block is given.
        def each_type(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_type) unless ruby_block
            # A ruby block? Apply it on each sub type.
            @types.each_value(&ruby_block)
        end

        # Iterates over the keys.
        #
        # Returns an enumerator if no ruby block is given.
        def each_key(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_key) unless ruby_block
            # A ruby block? Apply it on each key.
            @types.each_key(&ruby_block)
        end

        # Iterates over the sub type names.
        #
        # Returns an enumerator if no ruby block is given.
        def each_name(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_name) unless ruby_block
            # A ruby block? Apply it on each name.
            @types.each_key(&ruby_block)
        end

        # Iterates over the types deeply if any.
        def each_type_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_type_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # And recurse on the sub types.
            @types.each_value { |type| type.each_type_deep(&ruby_block) }
        end

        alias_method :each_deep, :each_type_deep

        # Gets the bitwidth of the type, nil for undefined.
        #
        # NOTE: must be redefined for specific types.
        def width
            if @types.is_a?(Array) then
                return @types.reduce(0) {|sum,type| sum + type.width }
            else
                return @types.each_value.reduce(0) {|sum,type| sum + type.width }
            end
        end

        # # Checks the compatibility with +type+
        # def compatible?(type)
        #     # # If type is void, compatible anyway.
        #     # return true if type.name == :void
        #     # Not compatible if different types.
        #     return false unless type.is_a?(TypeStruct)
        #     # Not compatibe unless each entry has the same name in same order.
        #     return false unless self.each_name == type.each_name
        #     self.each do |name,sub|
        #         return false unless sub.compatible?(self.get_type(name))
        #     end
        #     return true
        # end

        # # Merges with +type+
        # def merge(type)
        #     # # if type is void, return self anyway.
        #     # return self if type.name == :void
        #     # Not compatible if different types.
        #     unless type.is_a?(TypeStruct) then
        #         raise AnyError, "Incompatible types for merging: #{self}, #{type}."
        #     end
        #     # Not compatibe unless each entry has the same name and same order.
        #     unless self.each_name == type.each_name then
        #         raise AnyError, "Incompatible types for merging: #{self}, #{type}."
        #     end
        #     # Creates the new type content
        #     content = {}
        #     self.each do |name,sub|
        #         content[name] = self.get_type(name).merge(sub)
        #     end
        #     return TypeStruct.new(@name,content)
        # end  

        # Tell if +type+ is equivalent to current type.
        #
        # NOTE: type can be compatible while not being equivalent, please
        #       refer to `hruby_types.rb` for type compatibility.
        def equivalent?(type)
            return (type.is_a?(TypeStruct) and
                    !@types.to_a.zip(type.types.to_a).index do |t0,t1|
                t0[0] != t1[0] or !t0[1].equivalent?(t1[1])
            end)
        end
    end



    ##
    # Describes a behavior.
    class Behavior

        include Hparent

        # The block executed by the behavior.
        attr_reader :block

        # Creates a new behavior executing +block+.
        def initialize(block)
            # Initialize the sensitivity list.
            @events = []
            # Check and set the block.
            return unless block # No block case
            # There is a block
            self.block = block
            # unless block.is_a?(Block)
            #     raise AnyError, "Invalid class for a block: #{block.class}."
            # end
            # # Time blocks are only supported in Time Behaviors.
            # if block.is_a?(TimeBlock)
            #     raise AnyError, "Timed blocks are not supported in common behaviors."
            # end
            # # Set the block's parent.
            # block.parent = self
            # # And set the block
            # @block = block
        end

        # # Add decorator capability (modifies intialize to put after).
        # include Hdecorator

        # Sets the block if not already set.
        def block=(block)
            # Check the block.
            unless block.is_a?(Block)
                raise AnyError, "Invalid class for a block: #{block.class}."
            end
            # Time blocks are only supported in Time Behaviors.
            if block.is_a?(TimeBlock)
                raise AnyError, "Timed blocks are not supported in common behaviors."
            end
            # Set the block's parent.
            block.parent = self
            # And set the block
            @block = block
        end
        private :block=

        # Comparison for hash: structural comparison.
        def eql?(obj)
            return false unless obj.is_a?(Behavior)
            idx = 0
            obj.each_event do |event|
                return false unless @events[idx].eql?(event)
                idx += 1
            end
            return false unless idx == @events.size
            return false unless @block.eql?(obj.block)
            return true
        end

        # Hash function.
        def hash
            return [@events,@block].hash
        end

        # Handle the sensitivity list.

        # Adds an +event+ to the sensitivity list.
        def add_event(event)
            unless event.is_a?(Event)
                raise AnyError, "Invalid class for a event: #{event.class}"
            end
            # Set the event's parent.
            event.parent = self
            # And add the event.
            @events << event
            event
        end

        # Iterates over the events of the sensitivity list.
        #
        # Returns an enumerator if no ruby block is given.
        def each_event(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_event) unless ruby_block
            # A ruby block? Apply it on each event.
            @events.each(&ruby_block)
        end

        # Tells if there is any event.
        def has_event?
            return !@events.empty?
        end

        # Tells if it is activated on one of +events+.
        def on_event?(*events)
            @events.any? { |ev0| events.any? { |ev1| ev0.eql?(ev1) } }
        end

        # Tells if there is a positive or negative edge event.
        def on_edge?
            @events.each do |event|
                return true if event.on_edge?
            end
            return false
        end

        # Iterates over the blocks.
        def each_block(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block) unless ruby_block
            # A ruby block?
            # Apply on it.
            ruby_block.call(@block)
        end

        # Iterates over all the blocks of the system type and its system
        # instances.
        def each_block_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block_deep) unless ruby_block
            # A ruby block?
            # Recurse.
            @block.each_block_deep(&ruby_block)
        end

        # Iterates over all the nodes of the system type and its system
        # instances.
        def each_node_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node_deep) unless ruby_block
            # A ruby block?
            # Recurse on the block.
            @block.each_node_deep(&ruby_block)
        end

        # Short cuts to the enclosed block.
        
        # Iterates over the statements.
        #
        # Returns an enumerator if no ruby block is given.
        def each_statement(&ruby_block)
            @block.each_statement(&ruby_block)
        end

        # Reverse iterates over the statements.
        #
        # Returns an enumerator if no ruby block is given.
        def reverse_each_statement(&ruby_block)
            @block.reverse_each_statement(&ruby_block)
        end

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # Then apply on each event.
            self.each_event do |event|
                event.each_deep(&ruby_block)
            end
            # Then apply on the block.
            self.block.each_deep(&ruby_block)
        end

        # Returns the last statement.
        def last_statement
            @block.last_statement
        end

        # Gets the top scope, i.e. the first scope of the current system.
        def top_scope
            return parent.top_scope
        end

        # Gets the parent system, i.e., the parent of the top scope.
        def parent_system
            return self.top_scope.parent
        end
    end


    ##
    # Describes a timed behavior.
    #
    # NOTE: 
    # * this is the only kind of behavior that can include time statements. 
    # * this kind of behavior is not synthesizable!
    class TimeBehavior < Behavior
        # Creates a new time behavior executing +block+.
        def initialize(block)
            # Initialize the sensitivity list.
            @events = []
            # Check and set the block.
            unless block.is_a?(Block)
                raise AnyError, "Invalid class for a block: #{block.class}."
            end
            # Time blocks are supported here.
            @block = block
            block.parent = self
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            # Specific comparison.
            return false unless obj.is_a?(TimeBehavior)
            # General comparison.
            return super(obj)
        end

        # Hash function.
        def hash
            super
        end

        # Time behavior do not have other event than time, so deactivate
        # the relevant methods.
        def add_event(event)
            raise AnyError, "Time behaviors do not have any sensitivity list."
        end
    end


    ## 
    # Describes an event.
    class Event

        include Hparent

        # The type of event.
        attr_reader :type

        # The reference of the event.
        attr_reader :ref

        # Creates a new +type+ sort of event on signal refered by +ref+.
        def initialize(type,ref)
            # Check and set the type.
            @type = type.to_sym
            # Check and set the reference.
            unless ref.is_a?(Ref)
                raise AnyError, "Invalid class for a reference: #{ref.class}"
            end
            @ref = ref
            # And set the parent of ref.
            ref.parent = self
        end

        # # Add decorator capability (modifies intialize to put after).
        # include Hdecorator

        # Comparison for hash: structural comparison.
        def eql?(obj)
            return false unless obj.is_a?(Event)
            return false unless @type.eql?(obj.type)
            return false unless @ref.eql?(obj.ref)
            return true
        end

        # Hash function.
        def hash
            return [@type,@ref].hash
        end

        # Tells if there is a positive or negative edge event.
        #
        # NOTE: checks if the event type is :posedge or :negedge
        def on_edge?
            return (@type == :posedge or @type == :negedge)
        end

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # Then apply on the type.
            self.type.each_deep(&ruby_block)
            # Then apply on the reference.
            self.ref.each_deep(&ruby_block)
        end
    end


    ##
    # Describes a signal.
    class SignalI

        include Hparent
        
        # The name of the signal
        attr_reader :name

        # The type of the signal
        attr_reader :type

        # The initial value of the signal if any.
        attr_reader :value

        # Creates a new signal named +name+ typed as +type+.
        # If +val+ is provided, it will be the initial value of the
        # signal.
        def initialize(name,type,val = nil)
            # Check and set the name.
            @name = name.to_sym
            # Check and set the type.
            if type.is_a?(Type) then
                @type = type
            else
                raise AnyError, "Invalid class for a type: #{type.class}."
            end
            # Check and set the initial value if any.
            if val then
                unless val.is_a?(Expression) then
                    raise AnyError, "Invalid class for a constant: #{val.class}"
                end
                @value = val
                val.parent = self
            # For memory optimization: no  initialization if not used.
            # else
            #     @value = nil
            end
        end

        # Tells if the signal is immutable (cannot be written.)
        def immutable?
            # By default, signals are not immutable.
            false
        end

        # Adds sub signal +sig+
        def add_signal(sig)
            # puts "add sub=#{sig.name} in signal=#{self}"
            # Sets the hash of sub signals if none.
            @signals = HashName.new unless @signals
            # Check and add the signal.
            unless sig.is_a?(SignalI)
                raise AnyError,
                      "Invalid class for a signal instance: #{sig.class}"
            end
            # if @signals.include?(sig) then
            #     raise AnyError, "SignalI #{sig.name} already present."
            # end
            # Set its parent.
            sig.parent = self
            # And add it
            @signals.add(sig)
        end

        # Gets a sub signal by name.
        def get_signal(name)
            return @signals ? @signals[name] : nil
        end

        # Iterates over the sub signals.
        #
        # Returns an enumerator if no ruby block is given.
        def each_signal(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_signal) unless ruby_block
            # A ruby block? Apply it on each sub signal instance if any.
            @signals.each(&ruby_block) if @signals
        end

        # # Add decorator capability (modifies intialize to put after).
        # include Hdecorator

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # Then apply on the type.
            self.type.each_deep(&ruby_block)
            # Then apply on the value.
            self.value.each_deep(&ruby_block) if self.value
        end

        # # Comparison for hash: structural comparison.
        # def eql?(obj)
        #     return false unless obj.is_a?(SignalI)
        #     return false unless @name.eql?(obj.name)
        #     return false unless @type.eql?(obj.type)
        #     return true
        # end

        # # Hash function.
        # def hash
        #     return [@name,@type].hash
        # end

        # Gets the bit width.
        def width
            return @type.width
        end

        # Clones (deeply)
        def clone
            return SignalI.new(self.name,self.type)
        end
    end

    ##
    # Describes a constant signal.
    class SignalC < SignalI
        # Tells if the signal is immutable (cannot be written.)
        def immutable?
            # Constant signals are immutable.
            true
        end
    end

    ## 
    # Describes a system instance.
    # 
    # NOTE: an instance can actually represented muliple layers
    #       of systems, the first one being the one actually instantiated
    #       in the final RTL code.
    #       This layering can be used for describing software or partial
    #       (re)configuration.
    class SystemI

        include Hparent

        # The name of the instance if any.
        attr_reader :name

        # The instantiated system.
        attr_reader :systemT

        # Creates a new system instance of system type +systemT+ named +name+.
        def initialize(name, systemT)
            # Set the name as a symbol.
            @name = name.to_sym
            # Check and set the systemT.
            if !systemT.is_a?(SystemT) then
                raise AnyError, "Invalid class for a system type: #{systemT.class}"
            end
            # Sets the instantiated system.
            @systemT = systemT

            # Initialize the list of system layers, the first one
            # being the instantiated system.
            @systemTs = [ @systemT ]
        end

        # # Add decorator capability (modifies intialize to put after).
        # include Hdecorator

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            
            # Do not recurse on the systemTs since necesarily processed
            # before!
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            return false unless obj.is_a?(SystemI)
            return false unless @name.eql?(obj.name)
            return false unless @systemT.eql?(obj.systemT)
            return true
        end

        # Hash function.
        def hash
            return [@name,@systemT].hash
        end

        # Rename with +name+
        #
        # NOTE: use with care since it can jeopardise the lookup structures.
        def name=(name)
            @name = name.to_sym
        end

        ## Adds a system configuration.
        def add_systemT(systemT)
            # puts "add_systemT #{systemT.name} to systemI #{self.name}"
            # Check and add the systemT.
            if !systemT.is_a?(SystemT) then
                raise AnyError, "Invalid class for a system type: #{systemT.class}"
            end
            # Set the base configuration of the added system.
            systemT.wrapper = self.systemT
            # Add it.
            @systemTs << systemT
        end

        ## Iterates over the system layers.
        def each_systemT(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_systemT) unless ruby_block
            # A ruby block? Apply it on the system layers.
            @systemTs.each(&ruby_block)
        end

        # Delegate inner accesses to the system type.
        extend Forwardable
        
        # @!method each_input
        #   @see SystemT#each_input
        # @!method each_output
        #   @see SystemT#each_output
        # @!method each_inout
        #   @see SystemT#each_inout
        # @!method each_inner
        #   @see SystemT#each_inner
        # @!method each_signal
        #   @see SystemT#each_signal
        # @!method get_input
        #   @see SystemT#get_input
        # @!method get_output
        #   @see SystemT#get_output
        # @!method get_inout
        #   @see SystemT#get_inout
        # @!method get_inner
        #   @see SystemT#get_inner
        # @!method get_signal
        #   @see SystemT#get_signal
        # @!method each_signal
        #   @see SystemT#each_signal
        # @!method each_signal_deep
        #   @see SystemT#each_signal_deep
        # @!method each_systemI
        #   @see SystemT#each_systemI
        # @!method get_systemI
        #   @see SystemT#get_systemI
        # @!method each_statement_deep
        #   @see SystemT#each_statement_deep
        # @!method each_connection
        #   @see SystemT#each_connection
        # @!method each_connection_deep
        #   @see SystemT#each_connection_deep
        # @!method each_arrow_deep
        #   @see SystemT#each_arrow_deep
        # @!method each_behavior
        #   @see SystemT#each_behavior
        # @!method each_behavior_deep
        #   @see SystemT#each_behavior_deep
        # @!method each_block_deep
        #   @see SystemT#each_block_deep
        # @!method each_sensitive_deep
        #   @see SystemT#each_sensitive_deep
        def_delegators :@systemT,
                       :each_input, :each_output, :each_inout, :each_inner,
                       :each_signal, :each_signal_deep,
                       :get_input, :get_output, :get_inout, :get_inner,
                       :get_signal, :get_interface,
                       :each_systemI, :get_systemI,
                       :each_connection, :each_connection_deep,
                       :each_statement_deep, :each_arrow_deep,
                       :each_behavior, :each_behavior_deep, :each_block_deep,
                       :each_sensitive_deep
    end


    ##
    # Describes a non-HDLRuby code chunk.
    class Chunk

        include Hparent

        # The name of the code chunk.
        attr_reader :name

        ## Creates new code chunk +name+ with made of +lumps+ piece of text.
        def initialize(name,*lumps)
            # Check and set the name.
            @name = name.to_sym
            # Set the content.
            @lumps = []
            lumps.each { |lump| self.add_lump(lump) }
        end

        # # Add decorator capability (modifies intialize to put after).
        # include Hdecorator

        # Adds a +lump+ of code, it is ment to become an expression or
        # some text.
        def add_lump(lump)
            # Set its parent if relevant.
            lump.parent = self if lump.respond_to?(:parent)
            # And add it
            @lumps << lump
            return lump
        end

        # Iterates over the code lumps.
        #
        # Returns an enumerator if no ruby block is given.
        def each_lump(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_lump) unless ruby_block
            # A ruby block? Apply it on each lump.
            @lumps.each(&ruby_block)
        end

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
        end
    end


    ##
    # Decribes a set of non-HDLRuby code chunks.
    class Code

        include Hparent

        # Creates a new chunk of code.
        def initialize
            # Initialize the set of events.
            @events = []
            # Initialize the content.
            @chunks = HashName.new
        end

        # # Add decorator capability (modifies intialize to put after).
        # include Hdecorator

        # Adds a +chunk+ to the sensitivity list.
        def add_chunk(chunk)
            # Check and add the chunk.
            unless chunk.is_a?(Chunk)
                raise AnyError,
                      "Invalid class for a code chunk: #{chunk.class}"
            end
            # if @chunks.include?(chunk) then
            #     raise AnyError, "Code chunk #{chunk.name} already present."
            # end
            # Set its parent.
            chunk.parent = self
            # And add it
            @chunks.add(chunk)
        end

        # Iterates over the code chunks.
        #
        # Returns an enumerator if no ruby block is given.
        def each_chunk(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_chunk) unless ruby_block
            # A ruby block? Apply it on each chunk.
            @chunks.each(&ruby_block)
        end

        # Adds an +event+ to the sensitivity list.
        def add_event(event)
            unless event.is_a?(Event)
                raise AnyError, "Invalid class for a event: #{event.class}"
            end
            # Set the event's parent.
            event.parent = self
            # And add the event.
            @events << event
            event
        end

        # Iterates over the events of the sensitivity list.
        #
        # Returns an enumerator if no ruby block is given.
        def each_event(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_event) unless ruby_block
            # A ruby block? Apply it on each event.
            @events.each(&ruby_block)
        end

        # Tells if there is any event.
        def has_event?
            return !@events.empty?
        end

        # Tells if there is a positive or negative edge event.
        def on_edge?
            @events.each do |event|
                return true if event.on_edge?
            end
            return false
        end

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # Then apply on each chunk.
            self.each_chunk do |chunk|
                chunk.each_deep(&ruby_block)
            end
            # Then apply on each event.
            self.each_event do |event|
                event.each_deep(&ruby_block)
            end
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            return false unless obj.is_a?(Code)
            idx = 0
            obj.each_event do |event|
                return false unless @events[idx].eql?(event)
                idx += 1
            end
            idx = 0
            obj.each_chunk do |chunk|
                return false unless @chunks[idx].eql?(chunk)
                idx += 1
            end
            return true
        end

        # Hash function.
        def hash
            return [@events,@chunk].hash
        end
    end


    ## 
    # Describes a statement.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Statement
        include Hparent
        # include Hdecorator
        
        # Clones (deeply)
        def clone
            raise AnyError,
                  "Internal error: clone is not defined for class: #{self.class}"
        end

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            raise AnyError,
                "Internal error: each_deep is not defined for class: #{self.class}"
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            raise AnyError,
                "Internal error: eql? is not defined for class: #{self.class}"
        end

        # Hash function.
        def hash
            raise AnyError,
                "Internal error: hash is not defined for class: #{self.class}"
        end

        # Iterates over each sub statement if any.
        #
        # Returns an enumerator if no ruby block is given.
        def each_statement(&ruby_block)
            # No ruby statement? Return an enumerator.
            return to_enum(:each_statement) unless ruby_block
            # By default: nothing to do.
        end

        # Get the block of the statement.
        def block
            if self.is_a?(Block)
                return self
            elsif self.parent.is_a?(Scope)
                # No block
                return nil
            else
                return self.parent.block
            end
        end

        # Get the scope of the statement.
        def scope
            if self.parent.is_a?(Scope) then
                return self.parent
            elsif self.parent.is_a?(Behavior) then
                return self.parent.parent
            else
                return self.parent.scope
            end
        end

        # Gets the behavior the statement is in.
        def behavior
            if self.parent.is_a?(Behavior) then
                return self.parent
            else
                return self.parent.behavior
            end
        end

        # Gets the top block, i.e. the first block of the current behavior.
        def top_block
            return self.parent.is_a?(Behavior) ? self : self.parent.top_block
        end

        # Gets the top scope, i.e. the first scope of the current system.
        def top_scope
            return self.scope.top_scope
        end

        # Gets the parent system, i.e., the parent of the top scope.
        def parent_system
            return self.top_scope.parent
        end

        # Tell if the statement includes a signal whose name is one of +names+.
        def use_name?(*names)
            # By default, nothing to do.
        end
    end


    # ##
    # # Describes a declare statement.
    # class Declare < Statement
    #     # The declared signal instance.
    #     attr_reader :signal

    #     # Creates a new statement declaring +signal+.
    #     def initialize(signal)
    #         # Check and set the declared signal instance.
    #         unless signal.is_a?(SignalI)
    #             raise AnyError, "Invalid class for declaring a signal: #{signal.class}"
    #         end
    #         @signal = signal
    #     end
    # end


    ## 
    # Decribes a transmission statement.
    class Transmit < Statement
        
        # The left reference.
        attr_reader :left
        
        # The right expression.
        attr_reader :right

        # Creates a new transmission from a +right+ expression to a +left+
        # reference.
        def initialize(left,right)
            # Check and set the left reference.
            unless left.is_a?(Ref)
                raise AnyError,
                     "Invalid class for a reference (left value): #{left.class}"
            end
            super()
            @left = left
            # and set its parent.
            left.parent = self
            # Check and set the right expression.
            unless right.is_a?(Expression)
                raise AnyError, "Invalid class for an expression (right value): #{right.class}"
            end
            @right = right
            # and set its parent.
            right.parent = self
        end

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # Then apply on the left.
            self.left.each_deep(&ruby_block)
            # Then apply on the right.
            self.right.each_deep(&ruby_block)
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            return false unless obj.is_a?(Transmit)
            return false unless @left.eql?(obj.left)
            return false unless @right.eql?(obj.right)
            return true
        end

        # Hash function.
        def hash
            return [@left,@right].hash
        end

        # Clones the transmit (deeply)
        def clone
            return Transmit.new(@left.clone, @right.clone)
        end

        # Iterates over the children if any.
        def each_node(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node) unless ruby_block
            # A ruby block? Apply it on the children.
            ruby_block.call(@left)
            ruby_block.call(@right)
        end

        alias_method :each_expression, :each_node

        # Iterates over the nodes deeply if any.
        def each_node_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # And recurse on the children
            @left.each_node_deep(&ruby_block)
            @right.each_node_deep(&ruby_block)
        end

        # Iterates over all the stamements of the block and its sub blocks.
        def each_statement_deep(&ruby_block)
            # No ruby statement? Return an enumerator.
            return to_enum(:each_statement_deep) unless ruby_block
            # A ruby block?
            # Apply it on self.
            ruby_block.call(self)
        end

        # Iterates over the sub blocks.
        def each_block(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block) unless ruby_block
            # A ruby block?
            # Nothing to do.
        end

        # Iterates over all the blocks contained in the current block.
        def each_block_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block_deep) unless ruby_block
            # A ruby block?
            # Nothing to do.
        end

        # Tell if the statement includes a signal whose name is one of +names+.
        def use_name?(*names)
            return @left.use_name?(*names) || @right.use_name?(*names)
        end
    end


    ## 
    # Describes an if statement.
    class If < Statement
        # The condition
        attr_reader :condition

        # The yes and no statements
        attr_reader :yes, :no

        # Creates a new if statement with a +condition+ and a +yes+ and +no+
        # blocks.
        def initialize(condition, yes, no = nil)
            # Check and set the condition.
            unless condition.is_a?(Expression)
                raise AnyError,
                      "Invalid class for a condition: #{condition.class}"
            end
            super()
            @condition = condition
            # And set its parent.
            condition.parent = self
            # Check and set the yes statement.
            unless yes.is_a?(Statement)
                raise AnyError, "Invalid class for a statement: #{yes.class}"
            end
            @yes = yes
            # And set its parent.
            yes.parent = self
            # Check and set the yes statement.
            if no and !no.is_a?(Statement)
                raise AnyError, "Invalid class for a statement: #{no.class}"
            end
            @no = no
            # And set its parent.
            no.parent = self if no

            # Initialize the list of alternative if statements (elsif)
            @noifs = []
        end

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # Then apply on the condition.
            self.condition.each_deep(&ruby_block)
            # Then apply on the yes.
            self.yes.each_deep(&ruby_block)
            # The apply on the no.
            self.no.each_deep(&ruby_block)
            # Then apply on the alternate ifs.
            self.each_noif do |cond,stmnt|
                cond.each_deep(&ruby_block)
                stmnt.each_deep(&ruby_block)
            end
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            return false unless obj.is_a?(If)
            return false unless @condition.eql?(obj.condition)
            return false unless @yes.eql?(obj.yes)
            return false unless @no.eql?(obj.no)
            return true
        end

        # Hash function.
        def hash
            return [@condition,@yes,@no].hash
        end

        # Sets the no block.
        #
        # No shoud only be set once, but this is not checked here for
        # sake of flexibility.
        def no=(no)
            # if @no != nil then
            #     raise AnyError, "No already set in if statement."
            # end # Actually better not lock no here.
            # Check and set the yes statement.
            unless no.is_a?(Statement)
                raise AnyError, "Invalid class for a statement: #{no.class}"
            end
            @no = no
            # And set its parent.
            no.parent = self
        end

        # Adds an alternative if statement (elsif) testing +next_cond+
        # and executing +next_yes+ when the condition is met.
        def add_noif(next_cond, next_yes)
            # Check the condition.
            unless next_cond.is_a?(Expression)
                raise AnyError, 
                      "Invalid class for a condition: #{next_cond.class}"
            end
            # And set its parent.
            next_cond.parent = self
            # Check yes statement.
            unless next_yes.is_a?(Statement)
                raise AnyError, 
                      "Invalid class for a statement: #{next_yes.class}"
            end
            # And set its parent.
            next_yes.parent = self
            # Add the statement.
            @noifs << [next_cond,next_yes]
        end

        # Iterates over the alternate if statements (elsif).
        def each_noif(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_noif) unless ruby_block
            # A ruby block?
            # Appy it on the alternate if statements.
            @noifs.each do |next_cond,next_yes|
                yield(next_cond,next_yes)
            end
        end

        # Iterates over each sub statement if any.
        #
        # Returns an enumerator if no ruby block is given.
        def each_statement(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_statement) unless ruby_block
            # A ruby block?
            # Appy it on the statement children.
            ruby_block.call(@yes)
            self.each_noif do |next_cond,next_yes|
                ruby_block.call(next_yes)
            end
            ruby_block.call(@no) if @no
        end

        # Iterates over the children (including the condition).
        #
        # Returns an enumerator if no ruby block is given.
        def each_node(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node) unless ruby_block
            # A ruby block?
            # Appy it on the children.
            ruby_block.call(@condition)
            ruby_block.call(@yes)
            self.each_noif do |next_cond,next_yes|
                ruby_block.call(next_cond)
                ruby_block.call(next_yes)
            end
            ruby_block.call(@no) if @no
        end

        # Iterates over the nodes deeply if any.
        def each_node_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # And recurse on the children
            @condition.each_node_deep(&ruby_block)
            @yes.each_node_deep(&ruby_block)
            self.each_noif do |next_cond,next_yes|
                next_cond.each_node_deep(&ruby_block)
                next_yes.each_node_deep(&ruby_block)
            end
            @no.each_node_deep(&ruby_block) if @no
        end

        # Iterates over the sub blocks.
        def each_block(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block) unless ruby_block
            # A ruby block?
            # Apply it on the yes, the alternate ifs and the no blocks.
            ruby_block.call(@yes) if @yes.is_a?(Block)
            @noifs.each do |next_cond,next_yes|
                ruby_block.call(next_yes) if next_yes.is_a?(Block)
            end
            ruby_block.call(@no) if @no.is_a?(Block)
        end

        # Iterates over all the stamements of the block and its sub blocks.
        def each_statement_deep(&ruby_block)
            # No ruby statement? Return an enumerator.
            return to_enum(:each_statement_deep) unless ruby_block
            # A ruby block?
            # Apply it on self.
            ruby_block.call(self)
            # And recurse on the alternate ifs and the no statements.
            @yes.each_statement_deep(&ruby_block)
            @noifs.each do |next_cond,next_yes|
                next_yes.each_statement_deep(&ruby_block)
            end
            @no.each_statement_deep(&ruby_block) if @no.is_a?(Block)
        end

        # Iterates over all the blocks contained in the current block.
        def each_block_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block_deep) unless ruby_block
            # A ruby block?
            # Apply it on the yes, the alternate ifs and the no blocks.
            @yes.each_block_deep(&ruby_block)
            @noifs.each do |next_cond,next_yes|
                next_yes.each_block_deep(&ruby_block)
            end
            # @no.each_block_deep(&ruby_block) if @no.is_a?(Block)
            @no.each_block_deep(&ruby_block) if @no
        end

        # Tell if the statement includes a signal whose name is one of +names+.
        # NOTE: for the if check only the condition.
        def use_name?(*names)
            return @condition.use_name?(*name)
        end

        # Clones the If (deeply)
        def clone
            # Duplicate the if.
            res = If.new(@condition.clone, @yes.clone, @no ? @no.clone : nil)
            # Duplicate the alternate ifs
            @noifs.each do |next_cond,next_yes|
                res.add_noif(next_cond.clone,next_yes.clone)
            end
            return res
        end
    end

    ##
    # Describes a when for a case statement.
    class When

        include Hparent

        # The value to match.
        attr_reader :match
        # The statement to execute in in case of match.
        attr_reader :statement

        # Creates a new when for a casde statement that executes +statement+
        # on +match+.
        def initialize(match,statement)
            # Checks the match.
            unless match.is_a?(Expression)
                raise AnyError, "Invalid class for a case match: #{match.class}"
            end
            # Checks statement.
            unless statement.is_a?(Statement)
                raise AnyError,
                      "Invalid class for a statement: #{statement.class}"
            end
            # Set the match.
            @match = match
            # Set the statement.
            @statement = statement
            # And set their parents.
            match.parent = statement.parent = self
        end

        # # Add decorator capability (modifies intialize to put after).
        # include Hdecorator

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # Then apply on the match.
            self.match.each_deep(&ruby_block)
            # Then apply on the statement.
            self.statement.each_deep(&ruby_block)
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            return false unless obj.is_a?(When)
            return false unless @match.eql?(obj.match)
            return false unless @statement.eql?(obj.statement)
            return true
        end

        # Hash function.
        def hash
            return [@match,@statement].hash
        end

        # Clones the When (deeply)
        def clone
            return When.new(@match.clone,@statement.clone)
        end

        # Iterates over each sub statement if any.
        #
        # Returns an enumerator if no ruby block is given.
        def each_statement(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_statement) unless ruby_block
            # A ruby block?
            # Appy it on the statement child.
            ruby_block.call(@statement)
        end

        # Iterates over the sub blocks.
        def each_block(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block) unless ruby_block
            # A ruby block?
            # Apply it on the statement if it is a block.
            ruby_block.call(@statement) if @statement.is_a?(Block)
        end

        # Iterates over all the blocks contained in the current block.
        def each_block_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block_deep) unless ruby_block
            # A ruby block?
            # Recurse on the statement.
            @statement.each_block_deep(&ruby_block)
        end

        # Iterates over all the stamements of the block and its sub blocks.
        def each_statement_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_statement_deep) unless ruby_block
            # A ruby block?
            # Recurse on the statement.
            @statement.each_statement_deep(&ruby_block)
        end

        # Interates over the children.
        def each_node(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node) unless ruby_block
            # A ruby block?
            # Appy it on the children.
            ruby_block.call(@match)
            ruby_block.call(@statement)
        end

        # Iterates over the nodes deeply if any.
        def each_node_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # And recurse on the children
            @match.each_node_deep(&ruby_block)
            @statement.each_node_deep(&ruby_block)
        end

        # Gets the top block, i.e. the first block of the current behavior.
        def top_block
            # return self.parent.is_a?(Behavior) ? self : self.parent.top_block
            return self.parent.top_block
        end

        # Tell if the statement includes a signal whose name is one of +names+.
        # NOTE: for the when check only the match.
        def use_name?(*names)
            return @match.use_name?(*name)
        end
    end


    ## 
    # Describes a case statement.
    class Case < Statement
        # The tested value
        attr_reader :value

        # The default block.
        attr_reader :default

        # Creates a new case statement whose excution flow is decided from
        # +value+ with a possible cases given in +whens+ and +default
        # + (can be set later)
        def initialize(value, default = nil, whens = [])
            # Check and set the value.
            unless value.is_a?(Expression)
                raise AnyError, "Invalid class for a value: #{value.class}"
            end
            super()
            @value = value
            # And set its parent.
            value.parent = self
            # Checks and set the default case if any.
            self.default = default if default
            # Check and add the whens.
            @whens = []
            whens.each { |w| self.add_when(w) }
        end

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # Then apply on the value.
            self.value.each_deep(&ruby_block)
            # Then apply on the whens.
            self.each_when do |w|
                w.each_deep(&ruby_block)
            end
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            return false unless obj.is_a?(Case)
            return false unless @value.eql?(obj.value)
            return false unless @whens.eql?(obj.instance_variable_get(:@whens))
            idx = 0
            obj.each_when do |w|
                return false unless @whens[idx].eql?(w)
                idx += 1
            end
            return false unless idx == @whens.size
            return false unless @default.eql?(obj.default)
            return true
        end

        # Hash function.
        def hash
            return [@value,@whens,@default].hash
        end

        # Adds possible when case +w+.
        def add_when(w)
            # Check +w+.
            unless w.is_a?(When)
                raise AnyError, "Invalid class for a when: #{w.class}"
            end
            # Add it.
            @whens << w
            # And set the parent of +w+.
            w.parent = self
        end

        # Sets the default block.
        #
        # No can only be set once.
        def default=(default)
            if @default != nil then
                raise AnyError, "Default already set in if statement."
            end
            # Check and set the yes statement.
            unless default.is_a?(Statement)
                raise AnyError,"Invalid class for a statement: #{default.class}"
            end
            @default = default
            # And set its parent.
            default.parent = self
            @default
        end

        # Iterates over each sub statement if any.
        #
        # Returns an enumerator if no ruby block is given.
        def each_statement(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_statement) unless ruby_block
            # A ruby block?
            # Apply on each when.
            @whens.each { |w| w.each_statement(&ruby_block) }
            # And on the default if any.
            ruby_block.call(@default) if @default
        end

        # Iterates over the match cases.
        #
        # Returns an enumerator if no ruby block is given.
        def each_when(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_when) unless ruby_block
            # A ruby block? Apply it on each when case.
            @whens.each(&ruby_block)
        end

        # Iterates over the children (including the value).
        #
        # Returns an enumerator if no ruby block is given.
        def each_node(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node) unless ruby_block
            # A ruby block? Apply it on each child.
            ruby_block.call(@value)
            @whens.each(&ruby_block)
            ruby_block.call(@default) if @default
        end

        # Iterates over the nodes deeply if any.
        def each_node_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # And recurse on the children
            @value.each_node_deep(&ruby_block)
            @whens.each { |w| w.each_node_deep(&ruby_block) }
            @default.each_node_deep(&ruby_block) if @default
        end

        # Iterates over the sub blocks.
        def each_block(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block) unless ruby_block
            # A ruby block?
            # Apply it on each when's block.
            self.each_when { |w| w.each_block(&ruby_block) }
            # And apply it on the default if any.
            ruby_block.call(@default) if @default
        end

        # Iterates over all the blocks contained in the current block.
        def each_block_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block_deep) unless ruby_block
            # A ruby block?
            # Apply it on each when's block.
            self.each_when { |w| w.each_block_deep(&ruby_block) }
            # And apply it on the default if any.
            @default.each_block_deep(&ruby_block) if @default
        end

        # Iterates over all the statements contained in the current statement.
        def each_statement_deep(&ruby_block)
            # No ruby statement? Return an enumerator.
            return to_enum(:each_statement_deep) unless ruby_block
            # A ruby block?
            # Apply it on self.
            ruby_block.call(self)
            # And apply it on each when's statement.
            self.each_when { |w| w.each_statement_deep(&ruby_block) }
            # And apply it on the default if any.
            @default.each_statement_deep(&ruby_block) if @default
        end

        # Tell if the statement includes a signal whose name is one of +names+.
        # NOTE: for the case check only the value.
        def use_name?(*names)
            return @value.use_name?(*name)
        end

        # Clones the Case (deeply)
        def clone
            # Clone the default if any.
            default = @default ? @default.clone : nil
            # Clone the case.
            return Case.new(@value.clone,default,(@whens.map do |w|
                w.clone
            end) )
        end
    end


    ##
    # Describes a delay: not synthesizable.
    class Delay

        include Hparent

        # The time unit.
        attr_reader :unit

        # The time value.
        attr_reader :value

        # Creates a new delay of +value+ +unit+ of time.
        def initialize(value,unit)
            # Check and set the value.
            unless value.is_a?(Numeric)
                raise AnyError,
                      "Invalid class for a delay value: #{value.class}."
            end
            @value = value
            # Check and set the unit.
            @unit = unit.to_sym
        end

        # # Add decorator capability (modifies intialize to put after).
        # include Hdecorator

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # Then apply on the value.
            self.value.each_deep(&ruby_block)
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            return false unless obj.is_a?(Delay)
            return false unless @unit.eql?(obj.unit)
            return false unless @value.eql?(obj.value)
            return true
        end

        # Hash function.
        def hash
            return [@unit,@value].hash
        end

        # Clones the Delay (deeply)
        def clone
            return Delay.new(@value,@unit)
        end
    end


    ## 
    # Describes a print statement: not synthesizable!
    class Print < Statement

        # Creates a new statement for printing +args+.
        def initialize(*args)
            super()
            # Process the arguments.
            @args = args.map do |arg|
                arg.parent = self 
                arg
            end
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            return false unless obj.is_a?(Print)
            return false if @args.each.zip(obj.each_arg).any? do |a0,a1|
                !a0.eql?(a1)
            end
            return true
        end

        # Iterates over each argument.
        #
        # Returns an enumerator if no ruby block is given.
        def each_arg(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_arg) unless ruby_block
            # A ruby block? First apply it to each argument.
            @args.each(&ruby_block)
        end

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # Then apply on the arguments.
            self.each_arg(&ruby_block)
        end

        # Hash function.
        def hash
            return @args.hash
        end

        # Clones the TimeWait (deeply)
        def clone
            return Print.new(*@args.map { |arg| arg.clone })
        end

        # Iterates over the expression children if any.
        def each_node(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node) unless ruby_block
            # A ruby block?
            # Apply it on each argument.
            @args.each(&ruby_block)
        end

        # Iterates over the nodes deeply if any.
        def each_node_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # And apply it on each argument.
            @args.each(&ruby_block)
        end

        # Iterates over the sub blocks.
        def each_block(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block) unless ruby_block
            # A ruby block?
            # Recurse on each argument.
            @args.each do |arg|
                arg.each_block(&ruby_block) if arg.respond_to?(:each_block)
            end
        end

        # Iterates over all the blocks contained in the current block.
        def each_block_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block_deep) unless ruby_block
            # A ruby block?
            # Recurse on each argument.
            @args.each do |arg|
                if arg.respond_to?(:each_block_deep) then
                    arg.each_block_deep(&ruby_block)
                end
            end
        end

        # Iterates over all the statements contained in the current block.
        def each_statement_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_statement_deep) unless ruby_block
            # A ruby block?
            # Apply it on self.
            ruby_block.call(self)
            # Recurse on each argument.
            @args.each do |arg|
                if arg.respond_to?(:each_statement_deep) then
                    arg.each_statement_deep(&ruby_block)
                end
            end
        end
    end


    ## 
    # Describes a system instance (re)configuration statement: not synthesizable!
    class Configure < Statement

        # attr_reader :systemI, :systemT, :index
        attr_reader :ref, :index

        # Creates a new (re)configure statement of system instance refered by
        # +ref+ with system number +index+
        def initialize(ref,index)
            super()
            # Process the arguments.
            index = index.to_i
            unless ref.is_a?(Ref) then
                raise "Invalid class for a reference: #{ref.class}."
            end
            # Sets the arguments.
            @ref = ref
            ref.parent = self
            @index = index
            # @systemT = systemI.each_systemT.to_a[index]
            # # Check the systemT is valid.
            # unless @systemT then
            #     raise "Invalid configuration index: #{index}."
            # end
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            return false unless obj.is_a?(Configure)
            return false unless @ref.eql?(obj.ref)
            return false unless @index.eql?(obj.index)
            return true
        end

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # Then apply on the reference.
            @ref.each_deep(&ruby_block)
        end

        # Hash function.
        def hash
            return (@ref.hash + @index.hash).hash
        end

        # Clones (deeply)
        def clone
            return Configure.new(@ref.clone,@index)
        end

        # Iterates over the nodes deeply if any.
        def each_node_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # And recurse on the reference.
            @ref.each_node_deep(&ruby_block)
        end

        # Iterates over all the blocks contained in the current block.
        def each_block_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block_deep) unless ruby_block
            # A ruby block?
            # Nothing more to do anyway.
        end

        # Iterates over all the statements contained in the current block.
        def each_statement_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_statement_deep) unless ruby_block
            # A ruby block?
            # Apply it on self.
            ruby_block.call(self)
            # And that's all.
        end

    end


    ## 
    # Describes a wait statement: not synthesizable!
    class TimeWait < Statement
        # The delay to wait.
        attr_reader :delay

        # Creates a new statement waiting +delay+.
        def initialize(delay)
            # Check and set the delay.
            unless delay.is_a?(Delay)
                raise AnyError, "Invalid class for a delay: #{delay.class}."
            end
            super()
            @delay = delay
            # And set its parent.
            delay.parent = self
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            return false unless obj.is_a?(TimeWait)
            return false unless @delay.eql?(obj.delay)
            return true
        end

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # Then apply on the delay.
            self.delay.each_deep(&ruby_block)
        end

        # Hash function.
        def hash
            return [@delay].hash
        end

        # Clones the TimeWait (deeply)
        def clone
            return TimeWait.new(@delay.clone)
        end

        # Iterates over the expression children if any.
        def each_node(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node) unless ruby_block
            # A ruby block?
            # Nothing to do.
        end

        # Iterates over the nodes deeply if any.
        def each_node_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
        end

        # Iterates over the sub blocks.
        def each_block(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block) unless ruby_block
            # A ruby block?
            # Nothing to do.
        end

        # Iterates over all the blocks contained in the current block.
        def each_block_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block_deep) unless ruby_block
            # A ruby block?
            # Nothing to do.
        end

        # Iterates over all the statements contained in the current block.
        def each_statement_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_statement_deep) unless ruby_block
            # A ruby block?
            # Apply it on self.
            ruby_block.call(self)
        end

    end


    ## 
    # Describes a timed loop statement: not synthesizable!
    class TimeRepeat < Statement
        # # The delay until the loop is repeated
        # attr_reader :delay
        # The number of interrations.
        attr_reader :number

        # The statement to execute.
        attr_reader :statement

        # # Creates a new timed loop statement execute in a loop +statement+ until
        # # +delay+ has passed.
        # def initialize(statement,delay)
        # Creates a new timed loop statement execute in a loop +statement+ 
        # +number+ times (negative means inifinity).
        def initialize(number,statement)
            # Check and set the statement.
            unless statement.is_a?(Statement)
                raise AnyError,
                      "Invalid class for a statement: #{statement.class}."
            end
            super()
            @statement = statement
            # And set its parent.
            statement.parent = self

            # # Check and set the delay.
            # unless delay.is_a?(Delay)
            #     raise AnyError, "Invalid class for a delay: #{delay.class}."
            # end
            # @delay = delay
            # Check and set the number.
            @number = number.to_i
            # # And set its parent.
            # delay.parent = self
        end

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # Then apply on the statement.
            self.statement.each_deep(&ruby_block)
            # # Then apply on the delay.
            # self.delay.each_deep(&ruby_block)
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            return false unless obj.is_a?(TimeRepeat)
            # return false unless @delay.eql?(obj.delay)
            return false unless @number.eql?(obj.number)
            return false unless @statement.eql?(obj.statement)
            return true
        end

        # Hash function.
        def hash
            # return [@delay,@statement].hash
            return [@number,@statement].hash
        end

        # Clones the TimeRepeat (deeply)
        def clone
            # return TimeRepeat.new(@statement.clone,@delay.clone)
            return TimeRepeat.new(@statement.clone,@number)
        end

        # Iterates over the expression children if any.
        def each_node(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node) unless ruby_block
            # A ruby block? Apply it on the child.
            ruby_block.call(@statement)
        end

        # Iterates over the nodes deeply if any.
        def each_node_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # And recurse on the child
            @statement.each_node_deep(&ruby_block)
        end

        # Iterates over the sub blocks.
        def each_block(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block) unless ruby_block
            # A ruby block?
            # Apply it on the statement if it is a block.
            ruby_block.call(@statement) if statement.is_a?(Block)
        end

        # Iterates over all the blocks contained in the current block.
        def each_block_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block_deep) unless ruby_block
            # A ruby block?
            # Recurse on the statement.
            @statement.each_block_deep(&ruby_block)
        end

        # Iterates over all the statements contained in the current block.
        def each_statement_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_statement_deep) unless ruby_block
            # A ruby block?
            # Apply it on self.
            ruby_block.call(self)
            # Recurse on the statement.
            @statement.each_statement_deep(&ruby_block)
        end
        
    end


    ## 
    # Describes a timed terminate statement: not synthesizable!
    class TimeTerminate < Statement

        # Creates a new timed terminate statement that terminate execution.
        def initialize
            super()
        end

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # And that's all.
        end

        # Iterates over all the nodes.
        def each_node(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node) unless ruby_block
            # A ruby block?
            # Nothing to do anyway.
        end

        # Iterates over all the nodes deeply.
        def each_node_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node_deep) unless ruby_block
            # A ruby block?
            # Apply of current node.
            ruby_block.call(self)
            # And that's all.
        end

        # Iterates over all the statements deeply.
        def each_statement_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_statement_deep) unless ruby_block
            # A ruby block?
            # Apply of current node.
            ruby_block.call(self)
            # And that's all.
        end

        # Iterates over all the blocks contained in the current block.
        def each_block_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block_deep) unless ruby_block
            # A ruby block?
            # Nothing to do anyway.
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            return false unless obj.is_a?(TimeTerminate)
            return true
        end

        # Hash function.
        def hash
            return TimeTerminate.hash
        end

        # Clones the TimeRepeat (deeply)
        def clone
            return TimeTerminate.new
        end
    end




    ## 
    # Describes a block.
    class Block < Statement
        # The execution mode of the block.
        attr_reader :mode

        # The name of the block if any
        attr_reader :name

        # Creates a new +mode+ sort of block with possible +name+.
        def initialize(mode, name = :"")
            super()
            # puts "new block with mode=#{mode} and name=#{name}"
            # Check and set the type.
            @mode = mode.to_sym
            # Check and set the name.
            @name = name.to_sym
            # Initializes the list of inner statements.
            # @inners = {}
            @inners = HashName.new
            # Initializes the list of statements.
            @statements = []
        end

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # Then apply on the inners.
            self.each_inner do |inner|
                inner.each_deep(&ruby_block)
            end
            # Then apply on the statements.
            self.each_statement do |stmnt|
                stmnt.each_deep(&ruby_block)
            end
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            return false unless obj.is_a?(Block)
            return false unless @mode.eql?(obj.mode)
            return false unless @name.eql?(obj.name)
            idx = 0
            obj.each_inner do |inner|
                return false unless @inners[inner.name].eql?(inner)
                idx += 1
            end
            return false unless idx == @inners.size
            idx = 0
            obj.each_statement do |statement|
                return false unless @statements[idx].eql?(statement)
                idx += 1
            end
            return false unless idx == @statements.size
            return true
        end

        # Hash function.
        def hash
            return [@mode,@name,@inners,@statements].hash
        end

        # Adds inner signal +signal+.
        def add_inner(signal)
            # puts "add inner=#{signal.name} in block=#{self}"
            # Check and add the signal.
            unless signal.is_a?(SignalI)
                raise AnyError,
                      "Invalid class for a signal instance: #{signal.class}"
            end
            # if @inners.include?(signal) then
            #     raise AnyError, "SignalI #{signal.name} already present."
            # end
            # Set its parent.
            signal.parent = self
            # And add it
            @inners.add(signal)
        end

        # Iterates over the inner signals.
        #
        # Returns an enumerator if no ruby block is given.
        def each_inner(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_inner) unless ruby_block
            # A ruby block? Apply it on each inner signal instance.
            @inners.each(&ruby_block)
        end
        alias_method :each_signal, :each_inner

        ## Gets an inner signal by +name+.
        def get_inner(name)
            # puts "name=#{name}, inners=#{@inners.each_key.to_a}"
            return @inners[name.to_sym]
        end
        alias_method :get_signal, :get_inner

        # Iterates over all the signals of the block and its sub block's ones.
        def each_signal_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_signal_deep) unless ruby_block
            # A ruby block?
            # First, apply on the signals of the block.
            self.each_signal(&ruby_block)
            # Then apply on each sub block. 
            self.each_block_deep do |block|
                block.each_signal_deep(&ruby_block)
            end
        end

        # Adds a +statement+.
        #
        # NOTE: TimeWait is not supported unless for TimeBlock objects.
        def add_statement(statement)
            unless statement.is_a?(Statement) then
                raise AnyError,
                      "Invalid class for a statement: #{statement.class}"
            end
            if statement.is_a?(TimeWait) then
                raise AnyError,
                      "Timed statements are not supported in common blocks."
            end
            @statements << statement
            # And set its parent.
            statement.parent = self
            statement
        end

        # Adds a +statement+ and the begining of the block
        #
        # NOTE: TimeWait is not supported unless for TimeBlock objects.
        def unshift_statement(statement)
            unless statement.is_a?(Statement) then
                raise AnyError,
                      "Invalid class for a statement: #{statement.class}"
            end
            if statement.is_a?(TimeWait) then
                raise AnyError,
                      "Timed statements are not supported in common blocks."
            end
            @statements.unshift(statement)
            # And set its parent.
            statement.parent = self
            statement
        end

        # Gets the number of statements.
        def num_statements
            return @statements.size
        end

        # Iterates over the statements.
        #
        # Returns an enumerator if no ruby block is given.
        def each_statement(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_statement) unless ruby_block
            # A ruby block? Apply it on each statement.
            @statements.each(&ruby_block)
        end

        alias_method :each_node, :each_statement

        # Reverse iterates over the statements.
        #
        # Returns an enumerator if no ruby block is given.
        def reverse_each_statement(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:reverse_each_statement) unless ruby_block
            # A ruby block? Apply it on each statement.
            @statements.reverse_each(&ruby_block)
        end

        # Returns the last statement.
        def last_statement
            return @statements[-1]
        end
        
        # Iterates over the sub blocks.
        def each_block(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block) unless ruby_block
            # A ruby block?
            # Apply it on each statement which contains blocks.
            self.each_statement do |statement|
                ruby_block.call(statement) if statement.is_a?(Block)
            end
        end

        # Iterates over all the blocks contained in the current block.
        def each_block_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block_deep) unless ruby_block
            # A ruby block?
            # Apply it on self.
            ruby_block.call(self)
            # And apply it on each statement which contains blocks.
            self.each_statement do |statement|
                statement.each_block_deep(&ruby_block)
            end
        end

        # Iterates over all the stamements of the block and its sub blocks.
        def each_statement_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_statement_deep) unless ruby_block
            # A ruby block?
            # Apply it on current.
            ruby_block.call(self)
            # And apply it on each statement deeply.
            self.each_statement do |statement|
                statement.each_statement_deep(&ruby_block)
            end
        end

        # Iterates over all the stamements of the block and its sub blocks.
        def each_node_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node_deep) unless ruby_block
            # A ruby block?
            # Apply it on current.
            ruby_block.call(self)
            # And apply it on each statement deeply.
            self.each_statement do |stmnt|
                stmnt.each_node_deep(&ruby_block)
            end
        end

        # Clones (deeply)
        def clone
            # Creates the new block.
            nblock = Block.new(self.mode,self.name)
            # Duplicate its content.
            self.each_statement do |statement|
                nblock.add_statement(statement.clone)
            end
            return nblock
        end
    end

    # Describes a timed block.
    #
    # NOTE: 
    # * this is the only kind of block that can include time statements. 
    # * this kind of block is not synthesizable!
    class TimeBlock < Block
        # Adds a +statement+.
        # 
        # NOTE: TimeBlock is supported.
        def add_statement(statement)
            unless statement.is_a?(Statement) then
                raise AnyError, 
                      "Invalid class for a statement: #{statement.class}"
            end
            @statements << statement
            # And set its parent.
            statement.parent = self
            statement
        end

        # Adds a +statement+ and the begining of the block
        #
        # NOTE: TimeWait is not supported unless for TimeBlock objects.
        def unshift_statement(statement)
            unless statement.is_a?(Statement) then
                raise AnyError,
                      "Invalid class for a statement: #{statement.class}"
            end
            @statements.unshift(statement)
            # And set its parent.
            statement.parent = self
            statement
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            return false unless obj.is_a?(TimeBlock)
            return super(obj)
        end

        # Hash function.
        def hash
            return super
        end
    end


    ## 
    # Describes a connection.
    #
    # NOTE: eventhough a connection is semantically different from a
    # transmission, it has a common structure. Therefore, it is described
    # as a subclass of a transmit.
    class Connection < Transmit

        # Comparison for hash: structural comparison.
        def eql?(obj)
            return false unless obj.is_a?(Connection)
            return super(obj)
        end

        # Hash function.
        def hash
            return super
        end

        # Gets the top block, i.e. the first block of the current behavior.
        def top_block
            raise AnyError, "Connections are not within blocks."
        end

        # Gets the top scope, i.e. the first scope of the current system.
        def top_scope
            return self.parent.is_a?(Scope) ? self.parent : self.parent.top_scope
        end

        # Gets the parent system, i.e., the parent of the top scope.
        def parent_system
            return self.top_scope.parent
        end
    end



    ## 
    # Describes an expression.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Expression

        include Hparent

        # # Gets the type of the expression.
        # def type
        #     # By default: the void type.
        #     return Void
        # end

        attr_reader :type

        # Creates a new Expression with +type+
        def initialize(type = Void)
            # Check and set the type.
            if type.is_a?(Type) then
                @type = type
            else
                raise AnyError, "Invalid class for a type: #{type.class}."
            end
        end

        # # Add decorator capability (modifies intialize to put after).
        # include Hdecorator

        # Comparison for hash: structural comparison.
        def eql?(obj)
            return false unless obj.is_a?(Expression)
            return false unless @type.eql?(obj.type)
            return true
        end

        # Hash function.
        def hash
            return [@type].hash
        end

        # Tells if the expression is a left value of an assignment.
        def leftvalue?
            # Maybe its the left of a left value.
            if parent.respond_to?(:leftvalue?) && parent.leftvalue? then
                # Yes so it is also a left value if it is a sub ref.
                if parent.respond_to?(:ref) then
                    # It might nor be a sub ref.
                    # return parent.ref.eql?(self)
                    return parent.ref.equal?(self)
                else
                    # It is necessarily a sub ref (case of RefConcat for now).
                    return true
                end
            end
            # No, therefore maybe it is directly a left value.
            return (parent.is_a?(Transmit) || parent.is_a?(Connection)) &&
                # parent.left.eql?(self)
                parent.left.equal?(self)
        end

        # Tells if the expression is a right value.
        def rightvalue?
            return !self.leftvalue?
        end

        # Tells if the expression is immutable (cannot be written.)
        def immutable?
            false
        end

        # Iterates over the expression children if any.
        def each_node(&ruby_block)
            # By default: no child.
        end

        alias_method :each_expression, :each_node

        # Iterates over the nodes deeply if any.
        def each_node_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # And that's all.
        end

        # Iterates over all the references encountered in the expression.
        #
        # NOTE: do not iterate *inside* the references.
        def each_ref_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_ref_deep) unless ruby_block
            # puts "each_ref_deep for Expression which is:#{self}"
            # A ruby block?
            # If the expression is a reference, applies ruby_block on it.
            ruby_block.call(self) if self.is_a?(Ref)
        end

        # Get the statement of the expression.
        def statement
            if self.parent.is_a?(Statement)
                return self.parent
            else
                return self.parent.statement
            end
        end

        # Tell if the expression includes a signal whose name is one of +names+.
        def use_name?(*names)
            # By default nothing.
            return false
        end

        # Clones the expression (deeply)
        def clone
            raise AnyError,
                  "Internal error: clone not defined for class: #{self.class}"
        end
    end

    
    ##
    # Describes a value.
    class Value < Expression

        # The content of the value.
        attr_reader :content

        # Creates a new value typed +type+ and containing +content+.
        def initialize(type,content)
            super(type)
            if content.nil? then
                # Handle the nil content case.
                unless type.eql?(Void) then
                    raise AnyError, "A value with nil content must have the Void type."
                end
                @content = content
            elsif content.is_a?(FalseClass) then
                @content = 0
            elsif content.is_a?(TrueClass) then
                @content = 1
            else
                # Checks and set the content: Ruby Numeric and HDLRuby
                # BitString are supported. Strings or equivalent are
                # converted to BitString.
                unless content.is_a?(Numeric) or
                        content.is_a?(HDLRuby::BitString)
                    # content = HDLRuby::BitString.new(content.to_s)
                    content = content.to_s
                    if self.type.unsigned? && content[0] != "0" then
                        # content = "0" + content.rjust(self.type.width,content[0])
                        if content[0] == "1" then
                            # Do not extend the 1, but 0 instead.
                            content = "0" + content.rjust(self.type.width,"0")
                        else
                            # But extend the other.
                            content = "0" + content.rjust(self.type.width,content[0])
                        end
                    end
                    content = HDLRuby::BitString.new(content)
                end
                @content = content 
                if (@content.is_a?(Numeric) && self.type.unsigned?) then
                    # Adjust the bits for unsigned.
                    @content = @content & (2**self.type.width-1)
                end
            end
        end

        # Tells if the expression is immutable (cannot be written.)
        def immutable?
            # Values are always immutable.
            true
        end

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # Then apply on the type.
            self.type.each_deep(&ruby_block)
            # Then apply on the content if possible.
            if self.content.respond_to?(:each_deep) then
                self.content.each_deep(&ruby_block)
            end
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            # # General comparison.
            # return false unless super(obj)
            # Specific comparison.
            return false unless obj.is_a?(Value)
            return false unless @content.eql?(obj.content)
            return true
        end

        # Hash function.
        def hash
            return [super,@content].hash
        end


        # Compare values.
        #
        # NOTE: mainly used for being supported by ranges.
        def <=>(value)
            value = value.content if value.respond_to?(:content)
            return self.content <=> value
        end

        # Gets the bit width of the value.
        def width
            return @type.width
        end

        # Tells if the value is even.
        def even?
            return @content.even?
        end

        # Tells if the value is odd.
        def odd?
            return @content.odd?
        end

        # Converts to integer.
        def to_i
            return @content.to_i
        end

        # Clones the value (deeply)
        def clone
            return Value.new(@type,@content)
        end
    end


    ##
    # Describes a cast.
    class Cast < Expression
        # The child
        attr_reader :child

        # Creates a new cast of +child+ to +type+.
        def initialize(type,child)
            # Create the expression and set the type
            super(type)
            # Check and set the child.
            unless child.is_a?(Expression)
                raise AnyError,"Invalid class for an expression: #{child.class}"
            end
            @child = child
            # And set its parent.
            child.parent = self
        end

        # Tells if the expression is immutable (cannot be written.)
        def immutable?
            # Immutable if the child is immutable.
            return child.immutable?
        end

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # Then apply on the type.
            self.type.each_deep(&ruby_block)
            # Then apply on the child.
            self.child.each_deep(&ruby_block)
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            # General comparison.
            return false unless super(obj)
            # Specific comparison.
            return false unless obj.is_a?(Cast)
            return false unless @child.eql?(obj.child)
            return true
        end

        # Hash function.
        def hash
            return [super,@child].hash
        end

        # Iterates over the expression children if any.
        def each_node(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node) unless ruby_block
            # A ruby block? Apply it on the child.
            ruby_block.call(@child)
        end

        alias_method :each_expression, :each_node

        # Iterates over the nodes deeply if any.
        def each_node_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # And recurse on the child.
            @child.each_node_deep(&ruby_block)
        end

        # Iterates over all the references encountered in the expression.
        #
        # NOTE: do not iterate *inside* the references.
        def each_ref_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_ref_deep) unless ruby_block
            # puts "each_ref_deep for Unary"
            # A ruby block?
            # Recurse on the child.
            @child.each_ref_deep(&ruby_block)
        end

        # Tell if the expression includes a signal whose name is one of +names+.
        def use_name?(*names)
            # Recurse on the child.
            return @child.use_name?(*names)
        end

        # Clones the value (deeply)
        def clone
            return Cast.new(@type,@child.clone)
        end
    end


    ##
    # Describes an operation.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Operation < Expression

        # The operator of the operation.
        attr_reader :operator

        # Creates a new operation with +type+ applying +operator+.
        # def initialize(operator)
        def initialize(type,operator)
            super(type)
            # Check and set the operator.
            @operator = operator.to_sym
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            # General comparison.
            return false unless super(obj)
            # Specific comparison.
            return false unless obj.is_a?(Operation)
            return false unless @operator.eql?(obj.operator)
            return true
        end

        # Hash function.
        def hash
            return [super,@operator].hash
        end
    end


    ## 
    # Describes an unary operation.
    class Unary < Operation
        # The child.
        attr_reader :child

        # Creates a new unary expression with +type+ applying +operator+ on 
        # +child+ expression.
        # def initialize(operator,child)
        def initialize(type,operator,child)
            # Initialize as a general operation.
            super(type,operator)
            # Check and set the child.
            unless child.is_a?(Expression)
                raise AnyError,
                      "Invalid class for an expression: #{child.class}"
            end
            @child = child
            # And set its parent.
            child.parent = self
        end

        # Tells if the expression is immutable (cannot be written.)
        def immutable?
            # Immutable if the child is immutable.
            return child.immutable?
        end

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # Then apply on the type.
            self.type.each_deep(&ruby_block)
            # Then apply on the child.
            self.child.each_deep(&ruby_block)
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            # General comparison.
            return false unless super(obj)
            # Specific comparison.
            return false unless obj.is_a?(Unary)
            return false unless @child.eql?(obj.child)
            return true
        end

        # Hash function.
        def hash
            return [super,@child].hash
        end

        # Iterates over the expression children if any.
        def each_node(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node) unless ruby_block
            # A ruby block? Apply it on the child.
            ruby_block.call(@child)
        end

        alias_method :each_expression, :each_node

        # Iterates over the nodes deeply if any.
        def each_node_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # And recurse on the child.
            @child.each_node_deep(&ruby_block)
        end

        # Iterates over all the references encountered in the expression.
        #
        # NOTE: do not iterate *inside* the references.
        def each_ref_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_ref_deep) unless ruby_block
            # puts "each_ref_deep for Unary"
            # A ruby block?
            # Recurse on the child.
            @child.each_ref_deep(&ruby_block)
        end

        # Tell if the expression includes a signal whose name is one of +names+.
        def use_name?(*names)
            # Recurse on the child.
            return @child.use_name?(*names)
        end

        # Clones the unary operator (deeply)
        def clone
            return Unary.new(@type,self.operator,@child.clone)
        end
    end


    ##
    # Describes an binary operation.
    class Binary < Operation
        # The left child.
        attr_reader :left

        # The right child.
        attr_reader :right

        # Creates a new binary expression with +type+ applying +operator+ on
        # +left+ and +right+ children expressions.
        # def initialize(operator,left,right)
        def initialize(type,operator,left,right)
            # Initialize as a general operation.
            super(type,operator)
            # Check and set the children.
            unless left.is_a?(Expression)
                raise AnyError, "Invalid class for an expression: #{left.class}"
            end
            unless right.is_a?(Expression)
                raise AnyError,"Invalid class for an expression: #{right.class}"
            end
            @left = left
            @right = right
            # And set their parents.
            left.parent = right.parent = self
        end

        # Tells if the expression is immutable (cannot be written.)
        def immutable?
            # Immutable if both children are immutable.
            return left.immutable? && right.immutable?
        end

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # Then apply on the type.
            self.type.each_deep(&ruby_block)
            # Then apply on the left.
            self.left.each_deep(&ruby_block)
            # Then apply on the right.
            self.right.each_deep(&ruby_block)
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            # General comparison.
            return false unless super(obj)
            # Specific comparison.
            return false unless obj.is_a?(Binary)
            return false unless @left.eql?(obj.left)
            return false unless @right.eql?(obj.right)
            return true
        end

        # Hash function.
        def hash
            return [super,@left,@right].hash
        end

        # Iterates over the expression children if any.
        def each_node(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node) unless ruby_block
            # A ruby block? Apply it on the children.
            ruby_block.call(@left)
            ruby_block.call(@right)
        end

        alias_method :each_expression, :each_node

        # Iterates over the nodes deeply if any.
        def each_node_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # And recurse on the children.
            @left.each_node_deep(&ruby_block)
            @right.each_node_deep(&ruby_block)
        end

        # Iterates over all the references encountered in the expression.
        #
        # NOTE: do not iterate *inside* the references.
        def each_ref_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_ref_deep) unless ruby_block
            # puts "each_ref_deep for Binary"
            # A ruby block?
            # Recurse on the children.
            @left.each_ref_deep(&ruby_block)
            @right.each_ref_deep(&ruby_block)
        end

        # Tell if the expression includes a signal whose name is one of +names+.
        def use_name?(*names)
            # Recurse on the left and the right.
            return @left.use_name?(*names) || @right.use_name?(*names)
        end

        # Clones the binary operator (deeply)
        def clone
            return Binary.new(@type, self.operator,
                              @left.clone, @right.clone)
        end
    end


    ##
    # Describes a selection operation (generalization of the ternary operator).
    #
    # NOTE: choice is using the value of +select+ as an index.
    class Select < Operation
        # The selection child (connection).
        attr_reader :select

        # Creates a new operator with +type+ selecting from the value of 
        # +select+ one of the +choices+.
        # def initialize(operator,select,*choices)
        def initialize(type,operator,select,*choices)
            # Initialize as a general operation.
            # super(operator)
            super(type,operator)
            # Check and set the selection.
            unless select.is_a?(Expression)
                raise AnyError,
                      "Invalid class for an expression: #{select.class}"
            end
            @select = select
            # And set its parent.
            select.parent = self
            # Check and set the choices.
            @choices = []
            choices.each do |choice|
                self.add_choice(choice)
            end
        end

        # Tells if the expression is immutable (cannot be written.)
        def immutable?
            # Immutable if children are all immutable.
            return self.select.constant &&
              self.each_choice.reduce(true) do |r,c|
                r && c.immutable?
            end
        end

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # Then apply on the type.
            self.type.each_deep(&ruby_block)
            # Then apply on the select.
            self.select.each_deep(&ruby_block)
            # Then apply on the choices.
            self.each_choice do |choice|
                choice.each_deep(&ruby_block)
            end
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            # General comparison.
            return false unless super(obj)
            # Specific comparison.
            return false unless obj.is_a?(Select)
            return false unless @select.eql?(obj.select)
            idx = 0
            obj.each_choice do |choice|
                return false unless @choices[idx].eql?(choice)
                idx += 1
            end
            return false unless idx == @choices.size
            return true
        end

        # Hash function.
        def hash
            return [super,@select,@choices].hash
        end

        # Adds a +choice+.
        def add_choice(choice)
            unless choice.is_a?(Expression)
                raise AnyError,
                      "Invalid class for an expression: #{choice.class}"
            end
            # Set the parent of the choice.
            choice.parent = self
            # And add it.
            @choices << choice
            choice
        end

        # Iterates over the choices.
        #
        # Returns an enumerator if no ruby block is given.
        def each_choice(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_choice) unless ruby_block
            # A ruby block? Apply it on each choice.
            @choices.each(&ruby_block)
        end

        # Gets a choice by +index+.
        def get_choice(index)
            return @choices[index]
        end

        # Iterates over the expression children if any.
        def each_node(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node) unless ruby_block
            # A ruby block? Apply it on the children.
            ruby_block.call(@select)
            @choices.each(&ruby_block)
        end

        alias_method :each_expression, :each_node

        # Iterates over the nodes deeply if any.
        def each_node_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # And recurse on the children.
            @select.each_node_deep(&ruby_block)
            @choices.each { |choice| choice.each_node_deep(&ruby_block) }
        end

        # Iterates over all the references encountered in the expression.
        #
        # NOTE: do not iterate *inside* the references.
        def each_ref_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_ref_deep) unless ruby_block
            # puts "each_ref_deep for Select"
            # A ruby block?
            # Recurse on the children.
            self.select.each_ref_deep(&ruby_block)
            self.each_choice do |choice|
                choice.each_ref_deep(&ruby_block)
            end
        end

        # Tell if the expression includes a signal whose name is one of +names+.
        def use_name?(*names)
            # Recurse on the select.
            return true if @select.use_name?(*names)
            # Recurse on the choices.
            return @choices.any? { |choice| choice.use_name?(*names) }
        end

        # Clones the select (deeply)
        def clone
            return Select.new(@type, self.operator, @select.clone,
                              *@choices.map {|choice| choice.clone } )
        end
    end


    ## 
    # Describes a concatenation expression.
    class Concat < Expression
        # Creates a new concatenation with +type+ of several +expressions+
        # together.  
        # def initialize(expressions = [])
        def initialize(type,expressions = [])
            super(type)
            # puts "Building concat=#{self} with direction=#{type.direction}\n"
            # Initialize the array of expressions that are concatenated.
            @expressions = []
            # Check and add the expressions.
            expressions.each { |expression| self.add_expression(expression) }
        end

        # Tells if the expression is immutable (cannot be written.)
        def immutable?
            # Immutable if children are all immutable.
            return self.each_expression.reduce(true) do |r,c|
                r && c.immutable?
            end
        end

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # Then apply on the type.
            self.type.each_deep(&ruby_block)
            # Then apply on the expressions.
            self.each_expression do |expr|
                expr.each_deep(&ruby_block)
            end
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            # General comparison.
            return false unless super(obj)
            # Specific comparison.
            return false unless obj.is_a?(Concat)
            idx = 0
            obj.each_expression do |expression|
                return false unless @expressions[idx].eql?(expression)
                idx += 1
            end
            return false unless idx == @expressions.size
            return true
        end

        # Hash function.
        def hash
            return [super,@expressions].hash
        end

        # Adds an +expression+ to concat.
        def add_expression(expression)
            # Check expression.
            unless expression.is_a?(Expression) then
                raise AnyError,
                      "Invalid class for an expression: #{expression.class}"
            end
            # Add it.
            @expressions << expression
            # And set its parent.
            expression.parent = self
            expression
        end

        # Iterates over the concatenated expressions.
        #
        # Returns an enumerator if no ruby block is given.
        def each_expression(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_expression) unless ruby_block
            # A ruby block? Apply it on each children.
            @expressions.each(&ruby_block)
        end
        alias_method :each_node, :each_expression

        # Iterates over the nodes deeply if any.
        def each_node_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # And recurse on the children.
            self.each_expression do |expr|
                expr.each_node_deep(&ruby_block)
            end
        end

        # Tell if the expression includes a signal whose name is one of +names+.
        def use_name?(*names)
            # Recurse on the expressions.
            return @expressions.any? { |expr| expr.use_name?(*names) }
        end

        # Clones the concatenated expression (deeply)
        def clone
            return Concat.new(@type,
                              @expressions.map {|expr| expr.clone } )
        end
    end


    ## 
    # Describes a reference expression.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Ref < Expression

        # Comparison for hash: structural comparison.
        def eql?(obj)
            # General comparison.
            return false unless super(obj)
            # Specific comparison.
            return false unless obj.is_a?(Ref)
            return true
        end

        # Hash function.
        def hash
            super
        end

        # Iterates over the names of the path indicated by the reference.
        #
        # NOTE: this is not a method for iterating over all the names included
        # in the reference. For instance, this method will return nil without
        # iterating if a RefConcat or is met.
        #
        # Returns an enumerator if no ruby block is given.
        def path_each(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:path_each) unless ruby_block
            # A ruby block? Apply it on... nothing by default.
            return nil
        end

        # Iterates over the reference children if any.
        def each_node(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node) unless ruby_block
            # A ruby block? Apply it on the children: default none.
        end

        alias_method :each_expression, :each_node

        # Iterates over the nodes deeply if any.
        def each_node_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # And that's all.
        end
    end


    ##
    # Describes concatenation reference.
    class RefConcat < Ref

        # Creates a new reference with +type+ concatenating the references of
        # +refs+ together.
        # def initialize(refs = [])
        def initialize(type, refs = [])
            super(type)
            # Check and set the refs.
            refs.each do |ref|
                # puts "ref.class=#{ref.class}"
                unless ref.is_a?(Ref) then
                    raise AnyError,
                          "Invalid class for an reference: #{ref.class}"
                end
            end
            @refs = refs
            # And set their parents.
            refs.each { |ref| ref.parent = self }
        end

        # Tells if the expression is immutable (cannot be written.)
        def immutable?
            # Immutable if children are all immutable.
            return self.each_ref.reduce(true) do |r,c|
                r && c.immutable?
            end
        end

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # Then apply on the type.
            self.type.each_deep(&ruby_block)
            # Then apply on the sub references.
            self.each_ref do |ref|
                ref.each_deep(&ruby_block)
            end
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            # General comparison.
            return false unless super(obj)
            # Specific comparison.
            return false unless obj.is_a?(RefConcat)
            idx = 0
            obj.each_ref do |ref|
                return false unless @refs[idx].eql?(ref)
                idx += 1
            end
            return false unless idx == @refs.size
            return false unless @refs.eql?(obj.instance_variable_get(:@refs))
            return true
        end

        # Hash function.
        def hash
            return [super,@refs].hash
        end

        # Iterates over the concatenated references.
        #
        # Returns an enumerator if no ruby block is given.
        def each_ref(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_ref) unless ruby_block
            # A ruby block? Apply it on each children.
            @refs.each(&ruby_block)
        end
        alias_method :each_node, :each_ref

        # Adds an +ref+ to concat.
        def add_ref(ref)
            # Check ref.
            unless ref.is_a?(Ref) then
                raise AnyError,
                      "Invalid class for an ref: #{ref.class}"
            end
            # Add it.
            @refs << ref
            # And set its parent.
            ref.parent = self
            ref
        end

        # Iterates over the nodes deeply if any.
        def each_node_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # And recurse on the sub references.
            self.each_ref do |ref|
                ref.each_node_deep(&ruby_block)
            end
        end

        # Tell if the expression includes a signal whose name is one of +names+.
        def use_name?(*names)
            # Recurse on the references.
            return @refs.any? { |expr| expr.use_name?(*names) }
        end

        # Clones the concatenated references (deeply)
        def clone
            return RefConcat.new(@type, @refs.map { |ref| ref.clone } )
        end
    end


    ## 
    # Describes a index reference.
    class RefIndex < Ref
        # The accessed reference.
        attr_reader :ref

        # The access index.
        attr_reader :index

        # Create a new index reference with +type+ accessing +ref+ at +index+.
        # def initialize(ref,index)
        def initialize(type,ref,index)
            super(type)
            # Check and set the accessed reference.
            # unless ref.is_a?(Ref) then
            unless ref.is_a?(Expression) then
                raise AnyError, "Invalid class for a reference: #{ref.class}."
            end
            @ref = ref
            # And set its parent.
            ref.parent = self
            # Check and set the index.
            unless index.is_a?(Expression) then
                raise AnyError,
                      "Invalid class for an index reference: #{index.class}."
            end
            @index = index
            # And set its parent.
            index.parent = self
        end

        # Tells if the expression is immutable (cannot be written.)
        def immutable?
            # Immutable if the ref is immutable.
            return self.ref.immutable?
        end

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # Then apply on the type.
            self.type.each_deep(&ruby_block)
            # Then apply on the reference.
            self.ref.each_deep(&ruby_block)
            # Then apply on the index if possible.
            if self.index.respond_to?(:each_deep) then
                self.index.each_deep(&ruby_block)
            end
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            # General comparison.
            return false unless super(obj)
            # Specific comparison.
            return false unless obj.is_a?(RefIndex)
            return false unless @index.eql?(obj.index)
            return false unless @ref.eql?(obj.ref)
            return true
        end

        # Hash function.
        def hash
            return [super,@index,@ref].hash
        end

        # Iterates over the names of the path indicated by the reference.
        #
        # Returns an enumerator if no ruby block is given.
        def path_each(&ruby_block)
            # Recurse on the base reference.
            return ref.path_each(&ruby_block)
        end

        # Iterates over the reference children if any.
        def each_node(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node) unless ruby_block
            # A ruby block? Apply it on the index and the ref.
            ruby_block.call(@index)
            ruby_block.call(@ref)
        end

        alias_method :each_expression, :each_node

        # Iterates over the nodes deeply if any.
        def each_node_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # And recurse on the children.
            @index.each_node_deep(&ruby_block)
            @ref.each_node_deep(&ruby_block)
        end

        # Tell if the expression includes a signal whose name is one of +names+.
        def use_name?(*names)
            # Recurse on the index and the reference.
            return @index.use_name?(names) || @ref.use_name?(*names)
        end

        # Clones the indexed references (deeply)
        def clone
            return RefIndex.new(@type, @ref.clone, @index.clone)
        end
    end


    ## 
    # Describes a range reference.
    class RefRange < Ref
        # The accessed reference.
        attr_reader :ref

        # The access range.
        attr_reader :range

        # Create a new range reference with +type+ accessing +ref+ at +range+.
        # def initialize(ref,range)
        def initialize(type,ref,range)
            super(type)
            # Check and set the refered object.
            # unless ref.is_a?(Ref) then
            unless ref.is_a?(Expression) then
                raise AnyError, "Invalid class for a reference: #{ref.class}."
            end
            @ref = ref
            # And set its parent.
            ref.parent = self
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

        # Tells if the expression is immutable (cannot be written.)
        def immutable?
            # Immutable if the ref is immutable.
            return self.ref.immutable?
        end

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # Then apply on the type.
            self.type.each_deep(&ruby_block)
            # Then apply on the reference.
            self.ref.each_deep(&ruby_block)
            # Then apply on the range if possible.
            if self.range.first.respond_to?(:each_deep) then
                self.range.first.each_deep(&ruby_block)
            end
            if self.range.last.respond_to?(:each_deep) then
                self.range.last.each_deep(&ruby_block)
            end
        end

        # Comparison for hash: structural comparison.
        #
        # NOTE: ranges are assumed to be flattened (a range of range is
        # a range of same level).
        def eql?(obj)
            # General comparison.
            return false unless super(obj)
            # Specific comparison.
            return false unless obj.is_a?(RefRange)
            return false unless @range.first.eql?(obj.range.first)
            return false unless @range.last.eql?(obj.range.last)
            return false unless @ref.eql?(obj.ref)
            return true
        end

        # Hash function.
        def hash
            return [super,@range,@ref].hash
        end

        # Iterates over the names of the path indicated by the reference.
        #
        # Returns an enumerator if no ruby block is given.
        def path_each(&ruby_block)
            # Recurse on the base reference.
            return ref.path_each(&ruby_block)
        end

        # Iterates over the reference children if any.
        def each_node(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node) unless ruby_block
            # A ruby block? Apply it on the ranfe and the ref.
            ruby_block.call(@range.first)
            ruby_block.call(@range.last)
            ruby_block.call(@ref)
        end

        alias_method :each_expression, :each_node

        # Iterates over the nodes deeply if any.
        def each_node_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # And recurse on the children.
            @range.first.each_node_deep(&ruby_block)
            @range.last.each_node_deep(&ruby_block)
            @ref.each_node_deep(&ruby_block)
        end

        # Tell if the expression includes a signal whose name is one of +names+.
        def use_name?(*names)
            # Recurse on the range and the reference.
            return @range.first.use_name?(names) ||
                   @range.last.use_name?(names)  || @ref.use_name?(*names)
        end

        # Clones the range references (deeply)
        def clone
            return RefRange.new(@type, @ref.clone,
                                (@range.first.clone)..(@range.last.clone) )
        end
    end


    ##
    # Describes a name reference.
    class RefName < Ref
        # The accessed reference.
        attr_reader :ref

        # The access name.
        attr_reader :name

        # Create a new named reference with +type+ accessing +ref+ with +name+.
        # def initialize(ref,name)
        def initialize(type,ref,name)
            super(type)
            # Check and set the accessed reference.
            unless ref.is_a?(Ref) then
                raise AnyError, "Invalid class for a reference: #{ref.class}."
            end
            @ref = ref
            # And set its parent.
            ref.parent = self
            # Check and set the symbol.
            @name = name.to_sym
        end

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # Then apply on the type.
            self.type.each_deep(&ruby_block)
            # Then apply on the reference.
            self.ref.each_deep(&ruby_block)
        end

        # Get the full name of the reference, i.e. including the sub ref
        # names if any.
        def full_name
            name = self.ref.respond_to?(:full_name) ? self.ref.full_name : :""
            return :"#{name}::#{self.name}"
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            # General comparison.
            return false unless super(obj)
            # Specific comparison.
            return false unless obj.is_a?(RefName)
            return false unless @name.eql?(obj.name)
            return false unless @ref.eql?(obj.ref)
            return true
        end

        # Hash function.
        def hash
            return [super,@name,@ref].hash
        end

        # Iterates over the names of the path indicated by the reference.
        #
        # Returns an enumerator if no ruby block is given.
        def path_each(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:path_each) unless ruby_block
            # Recurse on the base reference.
            ref.path_each(&ruby_block)
            # Applies the block on the current name.
            ruby_block.call(@name)
        end

        # Iterates over the reference children if any.
        def each_node(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node) unless ruby_block
            # A ruby block? Apply it on the child.
            ruby_block.call(@ref)
        end

        alias_method :each_expression, :each_node

        # Iterates over the nodes deeply if any.
        def each_node_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # And recurse on the child.
            @ref.each_node_deep(&ruby_block)
        end

        # Tell if the expression includes a signal whose name is one of +names+.
        def use_name?(*names)
            # Is the named used here?
            return true if names.include?(@name)
            # No, recurse the reference.
            return @ref.use_name?(*names)
        end

        # Clones the name references (deeply)
        def clone
            return RefName.new(@type, @ref.clone, @name)
        end
    end


    ## 
    # Describe a this reference.
    #
    # This is the current system.
    class RefThis < Ref 

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # Then apply on the type.
            self.type.each_deep(&ruby_block)
        end

        # Clones this.
        def clone
            return RefThis.new
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            return obj.is_a?(RefThis)
        end

        # Hash function.
        def hash
            return super
        end
    end



    ##
    # Describes a string.
    #
    # NOTE: This is not synthesizable!
    class StringE < Expression

        attr_reader :content

        # Creates a new string whose content is +str+ and is modified using
        # the objects of +args+.
        def initialize(content,*args)
            super(StringT)
            # Checks and set the content.
            @content = content.to_s
            # Process the arguments.
            @args = args.map do |arg|
                arg.parent = self 
                arg
            end
        end

        # Tells if the expression is immutable (cannot be written.)
        def immutable?
            # String objects are always immutable.
            true
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            return false unless obj.is_a?(StringE)
            return false unless @content.eql?(obj.content)
            return false if @args.each.zip(obj.each_arg).any? do |a0,a1|
                !a0.eql?(a1)
            end
            return true
        end

        # Iterates over each argument.
        #
        # Returns an enumerator if no ruby block is given.
        def each_arg(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_arg) unless ruby_block
            # A ruby block? First apply it to each argument.
            @args.each(&ruby_block)
        end

        # Iterates over each object deeply.
        #
        # Returns an enumerator if no ruby block is given.
        def each_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # Then apply on the arguments.
            self.each_arg(&ruby_block)
        end

        # Hash function.
        def hash
            return @args.hash
        end

        # Clones the string.
        def clone
            return StringE.new(@content.clone,*@args.map {|arg| arg.clone})
        end

        # Iterates over the expression children if any.
        def each_node(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node) unless ruby_block
            # A ruby block?
            # Apply it on each argument.
            @args.each(&ruby_block)
        end

        # Iterates over the nodes deeply if any.
        def each_node_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_node_deep) unless ruby_block
            # A ruby block? First apply it to current.
            ruby_block.call(self)
            # And apply it on each argument.
            @args.each(&ruby_block)
        end

        # Iterates over the sub blocks.
        def each_block(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block) unless ruby_block
            # A ruby block?
            # Recurse on each argument.
            @args.each do |arg|
                arg.each_block(&ruby_block) if arg.respond_to?(:each_block)
            end
        end

        # Iterates over all the blocks contained in the current block.
        def each_block_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_block_deep) unless ruby_block
            # A ruby block?
            # Recurse on each argument.
            @args.each do |arg|
                if arg.respond_to?(:each_block_deep) then
                    arg.each_block_deep(&ruby_block)
                end
            end
        end

        # Iterates over all the statements contained in the current block.
        def each_statement_deep(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_statement_deep) unless ruby_block
            # A ruby block?
            # Apply it on self.
            ruby_block.call(self)
            # Recurse on each argument.
            @args.each do |arg|
                if arg.respond_to?(:each_statement_deep) then
                    arg.each_statement_deep(&ruby_block)
                end
            end
        end

    end
end
