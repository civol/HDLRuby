require "HDLRuby/hruby_low"
require "HDLRuby/hruby_types"
require "HDLRuby/hruby_values"
require "HDLRuby/hruby_bstr"

require 'set'
require 'forwardable'

##
# High-level libraries for describing digital hardware.        
#######################################################
module HDLRuby::High

    # Tells HDLRuby is currently booting.
    def self.booting?
        true
    end

    # Base = HDLRuby::Base
    Low  = HDLRuby::Low

    # Gets the infinity.
    def infinity
        return HDLRuby::Infinity
    end



    ##
    # Module providing extension of class.
    module SingletonExtend
        # Adds the singleton contents of +obj+ to current eigen class.
        #
        # NOTE: conflicting existing singleton content will be overridden if
        def eigen_extend(obj)
            # puts "eigen_extend for #{self} class=#{self.class}"
            obj.singleton_methods.each do |name|
                next if name == :yaml_tag # Do not know why we need to skip
                # puts "name=#{name}"
                self.define_singleton_method(name, &obj.singleton_method(name))
            end
        end
    end


    ##
    # Describes a namespace.
    # Used for managing the access points to internals of hardware constructs.
    class Namespace

        include SingletonExtend

        # The reserved names
        RESERVED = [ :user, :initialize, :add_method, :concat_namespace,
                     :to_namespace, :user?, :user_deep? ]

        # The construct using the namespace.
        attr_reader :user

        # Creates a new namespace attached to +user+.
        def initialize(user)
            # Sets the user.
            @user = user
            # Initialize the concat namespaces.
            @concats = []
        end

        # Adds method +name+ provided the name is not empty and the method
        # is not already defined in the current namespace.
        def add_method(name,&ruby_block)
            # puts "add_method with name=#{name}"
            unless name.empty? then
                if RESERVED.include?(name.to_sym) then
                    raise "Resevered name #{name} cannot be overridden."
                end
                if self.respond_to?(name) then
                    raise "Symbol #{name} is already defined."
                end
                define_singleton_method(name,&ruby_block) 
            end
        end

        # Concats another +namespace+ to current one.
        def concat_namespace(namespace)
            # Ensure namespace is really a namespace and concat it.
            namespace = namespace.to_namespace
            self.eigen_extend(namespace)
            # Adds the concat the the list.
            @concats << namespace
        end

        # Ensure it is a namespace
        def to_namespace
            return self
        end

        # Tell if an +object+ is the user of the namespace.
        def user?(object)
            return @user.equal?(object)
        end

        # Tell if an +object+ is the user of the namespace or of one of its
        # concats.
        def user_deep?(object)
            # puts "@user=#{@user}, @concats=#{@concats.size}, object=#{object}"
            # Convert the object to a user if appliable (for SystemT)
            object = object.to_user if object.respond_to?(:to_user)
            # Maybe object is the user of this namespace.
            return true if user?(object)
            # No, try in the concat namespaces.
            @concats.any? { |concat| concat.user_deep?(object) }
        end
    end


    ##
    # Module providing handling of unknown methods for hardware constructs.
    module Hmissing
        High = HDLRuby::High

        # Missing methods may be immediate values, if not, they are looked up
        # in the upper level of the namespace if any.
        def method_missing(m, *args, &ruby_block)
            # print "method_missing in class=#{self.class} with m=#{m}\n"
            # Is the missing method an immediate value?
            value = m.to_value
            return value if value and args.empty?
            # No, is there an upper namespace, i.e. is the current object
            # present in the space?
            if High.space_index(self) then
                # Yes, self is in it, can try the methods in the space.
                High.space_call(m,*args,&ruby_block)
            elsif self.respond_to?(:namespace) and
                  High.space_index(self.namespace) then
                # Yes, the private namespace is in it, can try the methods in
                # the space.
                begin
                    High.space_call(m,*args,&ruby_block)
                rescue
                    # Not in the private namespace, maybe in the public one.
                    if self.respond_to?(:public_namespace) and
                    High.space_index(self.public_namespace) then
                        High.space_call(m,*args,&ruby_block)
                    end
                end
            elsif self.respond_to?(:public_namespace) and
                  High.space_index(self.public_namespace) then
                # Yes, the private namespace is in it, can try the methods in
                # the space.
                High.space_call(m,*args,&ruby_block)
            else
                # No, this is a true error.
                raise NoMethodError.new("undefined local variable or method `#{m}'.")
            end
        end
    end

    module HScope_missing

        include Hmissing

        alias h_missing method_missing

        # Missing methods are looked for in the private namespace.
        # 
        # NOTE: it is ok to use the private namespace because the scope
        # can only be accessed if it is available from its systemT.
        def method_missing(m, *args, &ruby_block)
            # Is the scope currently opened?
            # puts "self.class=#{self.class}"
            if High.space_top.user_deep?(self) then
                # Yes, use the stack of namespaces.
                h_missing(m,*args,&ruby_block)
            else
                # No, look into the current namespace and return a reference
                # to the result if it is a referable hardware object.
                res = self.namespace.send(m,*args,&ruby_block)
                if res.respond_to?(:to_ref) then
                    # This is a referable object, build the reference from
                    # the namespace.
                    return RefObject.new(self.to_ref,res)
                end
            end

            # puts "method_missing in scope=#{@name}(#{self}) with m=#{m}"
            # puts "self.namespace=#{self.namespace}" 
            # # puts "namespace methods = #{self.namespace.methods}"
            # if self.namespace.respond_to?(m) then
            #     puts "Found"
            #     self.namespace.send(m,*args,&ruby_block)
            # else
            #     puts "NOT Found"
            #     h_missing(m,*args,&ruby_block)
            # end
        end
    end


    ##
    # Module providing methods for declaring select expressions.
    module Hmux
        # Creates an operator selecting from +select+ one of the +choices+.
        #
        # NOTE: +choices+ can either be a list of arguments or an array.
        # If +choices+ has only two entries
        # (and it is not a hash), +value+ will be converted to a boolean.
        def mux(select,*choices)
            # Process the choices.
            choices = choices.flatten(1) if choices.size == 1
            choices.map! { |choice| choice.to_expr }
            # Generate the select expression.
            return Select.new(choices[0].type,"?",select.to_expr,*choices)
        end
    end


    ##
    # Module providing declaration of inner signal (assumes inner signals
    # are present.
    module Hinner

        # Only adds the methods if not present.
        def self.included(klass)
            klass.class_eval do
                # unless instance_methods.include?(:add_inner) then
                #     # Adds inner signal +signal+.
                #     def add_inner(signal)
                #         # Checks and add the signal.
                #         unless signal.is_a?(SignalI)
                #             raise "Invalid class for a signal instance: #{signal.class}"
                #         end
                #         if @inners.has_key?(signal.name) then
                #             raise "SignalI #{signal.name} already present."
                #         end
                #         @inners[signal.name] = signal
                #     end

                #     # Iterates over the inner signals.
                #     #
                #     # Returns an enumerator if no ruby block is given.
                #     def each_inner(&ruby_block)
                #         # No ruby block? Return an enumerator.
                #         return to_enum(:each_inner) unless ruby_block
                #         # A block? Apply it on each inner signal instance.
                #         @inners.each_value(&ruby_block)
                #     end
                #     alias :each_signal :each_inner

                #     ## Gets an inner signal by +name+.
                #     def get_inner(name)
                #         return @inners[name]
                #     end
                #     alias :get_signal :get_inner

                #     # Iterates over all the signals of the block and its sub block's ones.
                #     def each_signal_deep(&ruby_block)
                #         # No ruby block? Return an enumerator.
                #         return to_enum(:each_signal_deep) unless ruby_block
                #         # A block?
                #         # First, apply on the signals of the block.
                #         self.each_signal(&ruby_block)
                #         # Then apply on each sub block. 
                #         self.each_block_deep do |block|
                #             block.each_signal_deep(&ruby_block)
                #         end
                #     end
                # end

                unless instance_methods.include?(:make_inners) then
                    # Creates and adds a set of inners typed +type+ from a list of +names+.
                    #
                    # NOTE: a name can also be a signal, is which case it is duplicated. 
                    def make_inners(type, *names)
                        res = nil
                        names.each do |name|
                            if name.respond_to?(:to_sym) then
                                # Adds the inner signal
                                res = self.add_inner(SignalI.new(name,type,:inner))
                            else
                                # Deactivated because conflict with parent.
                                # signal = name.clone
                                # signal.dir = :inner
                                # self.add_inner(signal)
                                raise "Invalid class for a name: #{name.class}"
                            end
                        end
                        return res
                    end
                end

                unless instance_methods.include?(:inner) then
                    # Declares high-level bit inner signals named +names+.
                    def inner(*names)
                        self.make_inners(bit,*names)
                    end
                end
            end
        end
    end


    # Classes describing hardware types.

    ## 
    # Describes a high-level system type.
    class SystemT < Low::SystemT
        High = HDLRuby::High

        # include Hinner

        include SingletonExtend

        # The public namespace
        #
        # NOTE: the private namespace is the namespace of the scope object.
        attr_reader :public_namespace

        ##
        # Creates a new high-level system type named +name+ and inheriting
        # from +mixins+.
        #
        # # If name is hash, it is considered the system is unnamed and the
        # # table is used to rename its signals or instances.
        #
        # The proc +ruby_block+ is executed when instantiating the system.
        def initialize(name, *mixins, &ruby_block)
            # Initialize the system type structure.
            # super(name,Scope.new())
            super(name,Scope.new(name,self))
            # # Save the Location for debugging information
            # @location = caller_locations

            # Initialize the set of extensions to transmit to the instances'
            # eigen class
            @singleton_instanceO = Namespace.new(self.scope)

            # Create the public namespace.
            @public_namespace = Namespace.new(self.scope)

            # Check and set the mixins.
            mixins.each do |mixin|
                unless mixin.is_a?(SystemT) then
                    raise "Invalid class for inheriting: #{mixin.class}."
                end
            end
            @to_includes = mixins
            # Prepare the instantiation methods
            make_instantiater(name,SystemI,:add_systemI,&ruby_block)

            # # Initialize the set of exported inner signals and instances
            # @exports = {}

            # # Initialize the set of included system instances.
            # @includeIs = {}
        end

        # Converts to a namespace user.
        def to_user
            # Returns the scope.
            return @scope
        end

        # Creates and adds a set of inputs typed +type+ from a list of +names+.
        #
        # NOTE: a name can also be a signal, is which case it is duplicated. 
        def make_inputs(type, *names)
            res = nil
            names.each do |name|
                if name.respond_to?(:to_sym) then
                    res = self.add_input(SignalI.new(name,type,:input))
                else
                    raise "Invalid class for a name: #{name.class}"
                end
            end
            return res
        end

        # Creates and adds a set of outputs typed +type+ from a list of +names+.
        #
        # NOTE: a name can also be a signal, is which case it is duplicated. 
        def make_outputs(type, *names)
            # puts "type=#{type.inspect}"
            res = nil
            names.each do |name|
                # puts "name=#{name}"
                if name.respond_to?(:to_sym) then
                    res = self.add_output(SignalI.new(name,type,:output))
                else
                    raise "Invalid class for a name: #{name.class}"
                end
            end
            return res
        end

        # Creates and adds a set of inouts typed +type+ from a list of +names+.
        #
        # NOTE: a name can also be a signal, is which case it is duplicated. 
        def make_inouts(type, *names)
            res = nil
            names.each do |name|
                if name.respond_to?(:to_sym) then
                    res = self.add_inout(SignalI.new(name,type,:inout))
                else
                    raise "Invalid class for a name: #{name.class}"
                end
            end
            return res
        end

        # # Creates and adds a set of inners typed +type+ from a list of +names+.
        # #
        # # NOTE: a name can also be a signal, is which case it is duplicated. 
        # def make_inners(type, *names)
        #     res = nil
        #     names.each do |name|
        #         if name.respond_to?(:to_sym) then
        #             res = self.add_inner(SignalI.new(name,type,:inner))
        #         else
        #             raise "Invalid class for a name: #{name.class}"
        #         end
        #     end
        #     return res
        # end

        # # Adds a +name+ to export.
        # #
        # # NOTE: if the name do not corresponds to any inner signal nor
        # # instance, raise an exception.
        # def add_export(name)
        #     # Check the name.
        #     name = name.to_sym
        #     # Look for construct to make public.
        #     # Maybe it is an inner signals.
        #     inner = self.get_inner(name)
        #     if inner then
        #         # Yes set it as export.
        #         @exports[name] = inner
        #         return
        #     end
        #     # No, maybe it is an instance.
        #     instance = self.get_systemI(name)
        #     if instance then
        #         # Yes, set it as export.
        #         @exports[name] = instance
        #         return
        #     end
        #     # No, error.
        #     raise NameError.new("Invalid name for export: #{name}")
        # end

        # # Iterates over the exported constructs.
        # #
        # # Returns an enumerator if no ruby block is given.
        # def each_export(&ruby_block)
        #     # No ruby block? Return an enumerator.
        #     return to_enum(:each_export) unless ruby_block
        #     # A block? Apply it on each input signal instance.
        #     @exports.each_value(&ruby_block)
        # end

        # Iterates over the exported constructs
        #
        # NOTE: look into the scope.
        def each_export(&ruby_block)
            @scope.each_export(&ruby_block)
        end

        # Gets class containing the extension for the instances.
        def singleton_instance
            @singleton_instanceO.singleton_class
        end

        # Execute +ruby_block+ in the context of the system.
        def run(&ruby_block)
            self.scope.open(&ruby_block)
        end

        # Opens for extension.
        #
        # NOTE: actually executes +ruby_block+ in the context of the scope
        #       of the system.
        def open(&ruby_block)
            # self.scope.open(&ruby_block)
            #
            # Are we instantiating current system?
            if (High.space_include?(self.scope.namespace)) then
                # Yes, execute the ruby block in the top context of the
                # system.
                # self.scope.open(&ruby_block)
                self.run(&ruby_block)
            else
                # No, add the ruby block to the list of block to execute
                # when instantiating.
                @instance_procs << ruby_block
            end
        end

        # # The proc used for instantiating the system type.
        # attr_reader :instance_proc
        
        # The instantiation target class.
        attr_reader :instance_class

        # The instance owning the system if it is an eigen system
        attr_reader :owner

        # Sets the +owner+.
        #
        # Note: will make the system eigen
        def owner=(owner)
            @owner = owner
        end

        # Iterates over the instance procedures.
        #
        # Returns an enumerator if no ruby block is given.
        def each_instance_proc(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_instance_proc) unless ruby_block
            # A block? Apply it on each input signal instance.
            @instance_procs.each(&ruby_block)
        end

        # Instantiate the system type to an instance named +i_name+ with
        # possible arguments +args+.
        def instantiate(i_name,*args)
            # Create the eigen type.
            # eigen = self.class.new(:"")
            eigen = self.class.new(High.names_create(i_name.to_s+ "::T"))

            # Include the mixin systems given when declaring the system.
            @to_includes.each { |system| eigen.scope.include(system) }

            # Fills the scope of the eigen class.
            eigen.scope.build_top(self.scope,*args)
            # puts "eigen scope=#{eigen.scope}"

            # Fill the public namespace
            space = eigen.public_namespace
            # Interface signals
            eigen.each_signal do |signal|
                # space.send(:define_singleton_method,signal.name) { signal }
                space.send(:define_singleton_method,signal.name) do
                    RefObject.new(eigen.owner.to_ref,signal)
                end
            end
            # Exported objects
            eigen.each_export do |export|
                # space.send(:define_singleton_method,export.name) { export }
                space.send(:define_singleton_method,export.name) do
                    RefObject.new(eigen.owner.to_ref,export)
                end
            end

            # Create the instance.
            instance = @instance_class.new(i_name,eigen)
            # Link it to its eigen system
            eigen.owner = instance

            # Extend the instance.
            instance.eigen_extend(@singleton_instanceO)
            # puts "instance scope= #{instance.systemT.scope}"
            # Return the resulting instance
            return instance
        end

        # Generates the instantiation capabilities including an instantiation
        # method +name+ for hdl-like instantiation, target instantiation as
        # +klass+, added to the calling object with +add_instance+, and
        # whose eigen type is initialized by +ruby_block+.
        #
        # NOTE: actually creates two instantiater, a general one, being
        #       registered in the namespace stack, and one for creating an
        #       array of instances being registered in the Array class.
        def make_instantiater(name,klass,add_instance,&ruby_block)
            # puts "make_instantiater with name=#{name}"
            # Set the instanciater.
            @instance_procs = [ ruby_block ]
            # Set the target instantiation class.
            @instance_class = klass

            # Unnamed types do not have associated access method.
            return if name.empty?

            obj = self # For using the right self within the proc

            # Create and register the general instantiater.
            High.space_reg(name) do |*args|
                # If no name it is actually an access to the system type.
                return obj if args.empty?
                # Get the names from the arguments.
                i_names = args.shift
                # puts "i_names=#{i_names}(#{i_names.class})"
                i_names = [*i_names]
                instance = nil # The current instance
                i_names.each do |i_name|
                    # Instantiate.
                    instance = obj.instantiate(i_name,*args)
                    # Add the instance.
                    High.top_user.send(add_instance,instance)
                end
                # # Return the last instance.
                instance
            end

            # Create and register the array of instances instantiater.
            ::Array.class_eval do
                define_method(name) { |*args| make(name,*args) }
            end
        end

        # Missing methods may be immediate values, if not, they are looked up
        include Hmissing

        # Methods used for describing a system in HDLRuby::High

        # Declares high-level bit input signals named +names+.
        def input(*names)
            self.make_inputs(bit,*names)
        end

        # Declares high-level bit output signals named +names+.
        def output(*names)
            self.make_outputs(bit,*names)
        end

        # Declares high-level bit inout signals named +names+.
        def inout(*names)
            self.make_inouts(bit,*names)
        end

        # # Declares high-level bit inner signals named +names+.
        # def inner(*names)
        #     self.make_inners(bit,*names)
        # end

        # # Declares a high-level behavior activated on a list of +events+, and
        # # built by executing +ruby_block+.
        # def behavior(*events, &ruby_block)
        #     # Preprocess the events.
        #     events.map! do |event|
        #         event.to_event
        #     end
        #     # Create and add the resulting behavior.
        #     self.add_behavior(Behavior.new(*events,&ruby_block))
        # end

        # # Declares a high-level timed behavior built by executing +ruby_block+.
        # def timed(&ruby_block)
        #     # Create and add the resulting behavior.
        #     self.add_behavior(TimeBehavior.new(&ruby_block))
        # end


        # # Creates a new parallel block built from +ruby_block+.
        # #
        # # This methods first creates a new behavior to put the block in.
        # def par(&ruby_block)
        #     self.behavior do
        #         par(&ruby_block)
        #     end
        # end

        # # Creates a new sequential block built from +ruby_block+.
        # #
        # # This methods first creates a new behavior to put the block in.
        # def seq(&ruby_block)
        #     self.behavior do
        #         seq(&ruby_block)
        #     end
        # end

        # # Statements automatically enclosed in a behavior.
        # 
        # # Creates a new if statement with a +condition+ that when met lead
        # # to the execution of the block in +mode+ generated by the +ruby_block+.
        # #
        # # NOTE:
        # #  * the else part is defined through the helse method.
        # #  * a behavior is created to enclose the hif.
        # def hif(condition, mode = nil, &ruby_block)
        #     self.behavior do
        #         hif(condition,mode,&ruby_block)
        #     end
        # end

        # # Sets the block executed when the condition is not met to the block
        # # in +mode+ generated by the execution of +ruby_block+.
        # #
        # # Can only be used once.
        # #
        # # NOTE: added to the hif of the last behavior.
        # def helse(mode = nil, &ruby_block)
        #     # There is a ruby_block: the helse is assumed to be with
        #     # the last statement of the last behavior.
        #     statement = self.last_behavior.last_statement
        #     # Completes the hif or the hcase statement.
        #     unless statement.is_a?(If) or statement.is_a?(Case) then
        #         raise "Error: helse statement without hif nor hcase (#{statement.class})."
        #     end
        #     statement.helse(mode, &ruby_block)
        # end

        # # Sets the condition check when the condition is not met to the block,
        # # with a +condition+ that when met lead
        # # to the execution of the block in +mode+ generated by the +ruby_block+.
        # def helsif(condition, mode = nil, &ruby_block)
        #     # There is a ruby_block: the helse is assumed to be with
        #     # the last statement of the last behavior.
        #     statement = @statements.last
        #     # Completes the hif statement.
        #     unless statement.is_a?(If) then
        #         raise "Error: helsif statement without hif (#{statement.class})."
        #     end
        #     statement.helsif(condition, mode, &ruby_block)
        # end

        # # Creates a new case statement with a +value+ used for deciding which
        # # block to execute.
        # #
        # # NOTE: 
        # #  * the when part is defined through the hwhen method.
        # #  * a new behavior is created to enclose the hcase.
        # def hcase(value)
        #     self.behavior do
        #         hcase(condition,value)
        #     end
        # end

        # # Sets the block of a case structure executed when the +match+ is met
        # # to the block in +mode+ generated by the execution of +ruby_block+.
        # #
        # # Can only be used once.
        # def hwhen(match, mode = nil, &ruby_block)
        #     # There is a ruby_block: the helse is assumed to be with
        #     # the last statement of the last behavior.
        #     statement = @statements.last
        #     # Completes the hcase statement.
        #     unless statement.is_a?(Case) then
        #         raise "Error: hwhen statement without hcase (#{statement.class})."
        #     end
        #     statement.hwhen(match, mode, &ruby_block)
        # end
        # 

        # # Sets the constructs corresponding to +names+ as exports.
        # def export(*names)
        #     names.each {|name| self.add_export(name) }
        # end

        # Extend the class according to another +system+.
        def extend(system)
            # Adds the singleton methods
            self.eigen_extend(system)
            # Adds the singleton methods for the instances.
            @singleton_instanceO.eigen_extend(system.singleton_instance)
        end

        # # Include another +system+ type with possible +args+ instanciation
        # # arguments.
        # def include(system,*args)
        #     if @includeIs.key?(system.name) then
        #         raise "Cannot include twice the same system."
        #     end
        #     # Extends with system.
        #     self.extend(system)
        #     # Create the instance to include
        #     instance = system.instantiate(:"",*args)
        #     # Concat its public namespace to the current one.
        #     self.namespace.concat_namespace(instance.public_namespace)
        #     # Adds it the list of includeds
        #     @includeIs[system.name] = instance
        # end

        # Casts as an included +system+.
        #
        # NOTE: use the includes of the scope.
        def as(system)
            # system = system.name if system.respond_to?(:name)
            # return @includeIs[system].public_namespace
            return self.scope.as(system.scope)
        end

        include Hmux

        # Fills a low level system with self's contents.
        #
        # NOTE: name conflicts are treated in the current NameStack state.
        def fill_low(systemTlow)
            # puts "fill_low with systemTlow=#{systemTlow}"
            # Adds its input signals.
            self.each_input { |input|  systemTlow.add_input(input.to_low) }
            # Adds its output signals.
            self.each_output { |output| systemTlow.add_output(output.to_low) }
            # Adds its inout signals.
            self.each_inout { |inout|  systemTlow.add_inout(inout.to_low) }
            # # Adds the inner signals.
            # self.each_inner { |inner|  systemTlow.add_inner(inner.to_low) }
            # # Adds the instances.
            # # Single ones.
            # self.each_systemI { |systemI|
            #     systemTlow.add_systemI(systemI.to_low) 
            # }
            # # Grouped ones.
            # self.each_groupI do |name,systemIs|
            #     systemIs.each.with_index { |systemI,i|
            #         # Sets the name of the system instance
            #         # (required for conversion of further accesses).
            #         # puts "systemI.respond_to?=#{systemI.respond_to?(:name=)}"
            #         systemI.name = name.to_s + "[#{i}]"
            #         # And convert it to low
            #         systemTlow.add_systemI(systemI.to_low())
            #     }
            # end
            # # Adds the connections.
            # self.each_connection { |connection|
            #     systemTlow.add_connection(connection.to_low)
            # }
            # # Adds the behaviors.
            # self.each_behavior { |behavior|
            #     systemTlow.add_behavior(behavior.to_low)
            # }
        end

        # Converts the system to HDLRuby::Low and set its +name+.
        def to_low(name = self.name)
            name = name.to_s
            if name.empty? then
                raise "Cannot convert a system without a name to HDLRuby::Low."
            end
            # Create the resulting low system type.
            systemTlow = HDLRuby::Low::SystemT.new(High.names_create(name),
                                                   self.scope.to_low)
            # Fills the interface of the new system from the included
            # systems, must look into the scope since it it the scope
            # that contains the included systems.
            self.scope.each_included do |included| 
                included.systemT.fill_low(systemTlow)
            end
            # # Push the private namespace for the low generation.
            # High.space_push(@namespace)
            # # Pushes on the name stack for converting the internals of
            # # the system.
            # High.names_push
            # # Adds the content of its included systems.
            # @includeIs.each_value { |space| space.user.fill_low(systemTlow) }
            # Adds the content of the actual system.
            self.fill_low(systemTlow)
            # # Restores the name stack.
            # High.names_pop
            # # Restores the namespace stack.
            # High.space_pop
            # # Return theresulting system.
            return systemTlow
        end
    end



    ## 
    # Describes a scope for a system type
    class Scope < Low::Scope
        High = HDLRuby::High

        # include HMix
        include Hinner

        include SingletonExtend

        # The name of the scope if any.
        attr_reader :name

        # The namespace
        attr_reader :namespace

        # The return value when building the scope.
        attr_reader :return_value

        ##
        # Creates a new scope with possible +name+.
        # If the scope is a top scope of a system, this systemT is
        # given by +systemT+.
        #
        # The proc +ruby_block+ is executed for building the scope.
        # If no block is provided, the scope is the top of a system and
        # is filled by the instantiation procedure of the system.
        def initialize(name = :"", systemT = nil, &ruby_block)
            # Initialize the scope structure
            super(name)
            # # Save the Location for debugging information
            # @location = caller_locations

            # Initialize the set of grouped system instances.
            @groupIs = {}

            # Creates the namespace.
            @namespace = Namespace.new(self)

            # Register the scope if it is not the top scope of a system
            # (in which case the system has already be registered with
            # the same name).
            unless name.empty? or systemT then
                # Named scope, set the hdl-like access to the scope.
                obj = self # For using the right self within the proc
                High.space_reg(name) { obj }
            end

            # Initialize the set of exported inner signals and instances
            @exports = {}
            # Initialize the set of included system instances.
            @includeIs = {}

            # Builds the scope if a ruby block is provided
            # (which means the scope is not the top of a system).
            self.build(&ruby_block) if block_given?
        end

        # Converts to a namespace user.
        def to_user
            # Already a user.
            return self
        end

        # # The name of the scope if any.
        # #
        # # NOTE: 
        # #  * the name of the first scope of a system is the system's.
        # #  * for building reference path with converting to low.
        # def name
        #     if self.parent.is_a?(SystemT) then
        #         return self.parent.name
        #     else
        #         return @name
        #     end
        # end

        # Adds a group of system +instances+ named +name+.
        def add_groupI(name, *instances)
            # Ensure name is a symbol and is not already used for another
            # group.
            name = name.to_sym
            if @groupIs.key?(name)
                raise "Group of system instances named #{name} already exist."
            end
            # Add the group.
            @groupIs[name.to_sym] = instances
            # Sets the parent of the instances.
            instances.each { |instance| instance.parent = self }
        end

        # Access a group of system instances by +name+.
        #
        # NOTE: the result is a copy of the group for avoiding side effects.
        def get_groupI(name)
            return @groupIs[name.to_sym].clone
        end

        # Iterates over the group of system instances.
        #
        # Returns an enumerator if no ruby block is given.
        def each_groupI(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_groupI) unless ruby_block
            # A block? Apply it on each input signal instance.
            @groupIs.each(&ruby_block)
        end

        # Cf. Hinner
        # # Creates and adds a set of inners typed +type+ from a list of +names+.
        # #
        # # NOTE: a name can also be a signal, is which case it is duplicated. 
        # def make_inners(type, *names)
        #     res = nil
        #     names.each do |name|
        #         if name.respond_to?(:to_sym) then
        #             res = self.add_inner(SignalI.new(name,type,:inner))
        #         else
        #             # Deactivated because conflict with parent.
        #             raise "Invalid class for a name: #{name.class}"
        #         end
        #     end
        #     return res
        # end

        # Adds a +name+ to export.
        #
        # NOTE: if the name do not corresponds to any inner signal nor
        # instance, raise an exception.
        def add_export(name)
            # Check the name.
            name = name.to_sym
            # Look for construct to make public.
            # Maybe it is an inner signals.
            inner = self.get_inner(name)
            if inner then
                # Yes set it as export.
                @exports[name] = inner
                return
            end
            # No, maybe it is an instance.
            instance = self.get_systemI(name)
            if instance then
                # Yes, set it as export.
                @exports[name] = instance
                return
            end
            # No, error.
            raise NameError.new("Invalid name for export: #{name}")
        end

        # Iterates over the exported constructs.
        #
        # Returns an enumerator if no ruby block is given.
        def each_export(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_export) unless ruby_block
            # A block? Apply it on each input signal instance.
            @exports.each_value(&ruby_block)
            # And apply on the sub scopes if any.
            @scopes.each {|scope| scope.each_export(&ruby_block) }
        end

        # Iterates over the included systems.
        def each_included(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_included) unless ruby_block
            # A block? Apply it on each input signal instance.
            @includeIs.each_value(&ruby_block)
            # And apply on the sub scopes if any.
            @scopes.each {|scope| scope.each_included(&ruby_block) }
        end


        # Opens for extension.
        #
        # NOTE: actually executes +ruby_block+ in the context.
        def open(&ruby_block)
            # # No push since should not merge the current environment into
            # # the system's.
            # High.space_insert(-1,@namespace)
            High.space_push(@namespace)
            High.top_user.instance_eval(&ruby_block)
            High.space_pop
        end


        # Build the scope by executing +ruby_block+.
        #
        # NOTE: used when the scope is not the top of a system.
        def build(&ruby_block)
            # Set the namespace for buidling the scope.
            High.space_push(@namespace)
            # Build the scope.
            @return_value = High.top_user.instance_eval(&ruby_block)
            High.space_pop
        end


        # Builds the scope using +base+ as model scope with possible arguments
        # +args+.
        #
        # NOTE: Used by the instantiation procedure of a system.
        def build_top(base,*args)
            High.space_push(@namespace)
            # Fills its namespace with the content of the base scope
            # (this latter may already contains access points if it has been
            #  opended for extension previously).
            @namespace.concat_namespace(base.namespace)
            # Execute the instantiation block
            # instance_proc = base.parent.instance_proc if base.parent.respond_to?(:instance_proc)
            # @return_value = High.top_user.instance_exec(*args,&instance_proc) if instance_proc
            base.parent.each_instance_proc do |instance_proc|
                @return_value = High.top_user.instance_exec(*args,&instance_proc)
            end
            High.space_pop
        end

      
        # Methods delegated to the upper system.

        # Adds input +signal+ in the current system.
        def add_input(signal)
            self.parent.add_input(signal)
        end
       
        # Adds output +signal+ in the current system.
        def add_output(signal)
            self.parent.add_output(signal)
        end

        # Adds inout +signal+ in the current system.
        def add_inout(signal)
            self.parent.add_inout(signal)
        end

        # Creates and adds a set of inputs typed +type+ from a list of +names+
        # in the current system.
        #
        # NOTE: a name can also be a signal, is which case it is duplicated. 
        def make_inputs(type, *names)
            self.parent.make_inputs(type,*names)
        end

        # Creates and adds a set of outputs typed +type+ from a list of +names+
        # in the current system.
        #
        # NOTE: a name can also be a signal, is which case it is duplicated. 
        def make_outputs(type, *names)
            self.parent.make_outputs(type,*names)
        end

        # Creates and adds a set of inouts typed +type+ from a list of +names+
        # in the current system.
        #
        # NOTE: a name can also be a signal, is which case it is duplicated. 
        def make_inouts(type, *names)
            self.parent.make_inouts(type,*names)
        end

        # Converts to a new reference.
        def to_ref
            return RefObject.new(this,self)
        end


        include HScope_missing
        # Moved to Hscope_missing for sharing with block
        # include Hmissing
        # alias h_missing method_missing

        # # Missing methods are looked for in the private namespace.
        # # 
        # # NOTE: it is ok to use the private namespace because the scope
        # # can only be accessed if it is available from its systemT.
        # def method_missing(m, *args, &ruby_block)
        #     # Is the scope currently opened?
        #     if High.space_top.user_deep?(self) then
        #         # Yes, use the stack of namespaces.
        #         h_missing(m,*args,&ruby_block)
        #     else
        #         # No, look into the current namespace and return a reference
        #         # to the result if it is a referable hardware object.
        #         res = self.namespace.send(m,*args,&ruby_block)
        #         if res.respond_to?(:to_ref) then
        #             # This is a referable object, build the reference from
        #             # the namespace.
        #             return RefObject.new(self.to_ref,res)
        #         end
        #     end

        #     # puts "method_missing in scope=#{@name}(#{self}) with m=#{m}"
        #     # puts "self.namespace=#{self.namespace}" 
        #     # # puts "namespace methods = #{self.namespace.methods}"
        #     # if self.namespace.respond_to?(m) then
        #     #     puts "Found"
        #     #     self.namespace.send(m,*args,&ruby_block)
        #     # else
        #     #     puts "NOT Found"
        #     #     h_missing(m,*args,&ruby_block)
        #     # end
        # end

        # Methods used for describing a system in HDLRuby::High

        # Declares high-level bit input signals named +names+
        # in the current system.
        def input(*names)
            self.parent.input(*names)
        end

        # Declares high-level bit output signals named +names+
        # in the current system.
        def output(*names)
            self.parent.output(*names)
        end

        # Declares high-level bit inout signals named +names+
        # in the current system.
        def inout(*names)
            self.parent.inout(*names)
        end

        # Declares a sub scope with possible +name+ and built from +ruby_block+.
        def sub(name = :"", &ruby_block)
            # Creates the new scope.
            scope = Scope.new(name,&ruby_block)
            # puts "new scope=#{scope}"
            # Add it
            self.add_scope(scope)
            # puts "self=#{self}"
            # puts "self scopes=#{self.each_scope.to_a.join(",")}"
            # Use its return value
            return scope.return_value
        end

        # # Declares a high-level behavior activated on a list of
        # # +events+, and built by executing +ruby_block+.
        # def behavior(*events, &ruby_block)
        #     # Preprocess the events.
        #     events.map! do |event|
        #         event.respond_to?(:to_event) ? event.to_event : event
        #     end
        #     # Create and add the resulting behavior.
        #     self.add_behavior(Behavior.new(*events,&ruby_block))
        # end

        # Declares a high-level sequential behavior activated on a list of
        # +events+, and built by executing +ruby_block+.
        def seq(*events, &ruby_block)
            # Preprocess the events.
            events.map! do |event|
                event.respond_to?(:to_event) ? event.to_event : event
            end
            # Create and add the resulting behavior.
            self.add_behavior(Behavior.new(:seq,*events,&ruby_block))
        end

        # Declares a high-level parallel behavior activated on a list of
        # +events+, and built by executing +ruby_block+.
        def par(*events, &ruby_block)
            # Preprocess the events.
            events.map! do |event|
                event.respond_to?(:to_event) ? event.to_event : event
            end
            # Create and add the resulting behavior.
            self.add_behavior(Behavior.new(:par,*events,&ruby_block))
        end

        # Declares a high-level timed behavior built by executing +ruby_block+.
        # By default, timed behavior are sequential.
        def timed(&ruby_block)
            # Create and add the resulting behavior.
            self.add_behavior(TimeBehavior.new(:seq,&ruby_block))
        end


        # # Creates a new parallel block built from +ruby_block+.
        # #
        # # This methods first creates a new behavior to put the block in.
        # def par(&ruby_block)
        #     self.behavior do
        #         par(&ruby_block)
        #     end
        # end

        # # Creates a new sequential block with possible +name+ and
        # # built from +ruby_block+.
        # #
        # # This methods first creates a new behavior to put the block in,
        # # but if no block is given returns :seq.
        # def seq(name = :"", &ruby_block)
        #     return :seq unless ruby_block
        #     self.behavior(:seq,&ruby_block)
        # end

        # Statements automatically enclosed in a behavior.
        
        # Creates a new if statement with a +condition+ that when met lead
        # to the execution of the block in +mode+ generated by the +ruby_block+.
        #
        # NOTE:
        #  * the else part is defined through the helse method.
        #  * a behavior is created to enclose the hif.
        def hif(condition, mode = nil, &ruby_block)
            self.par do
                hif(condition,mode,&ruby_block)
            end
        end

        # Sets the block executed when the condition is not met to the block
        # in +mode+ generated by the execution of +ruby_block+.
        #
        # Can only be used once.
        #
        # NOTE: added to the hif of the last behavior.
        def helse(mode = nil, &ruby_block)
            # There is a ruby_block: the helse is assumed to be with
            # the last statement of the last behavior.
            statement = self.last_behavior.last_statement
            # Completes the hif or the hcase statement.
            unless statement.is_a?(If) or statement.is_a?(Case) then
                raise "Error: helse statement without hif nor hcase (#{statement.class})."
            end
            statement.helse(mode, &ruby_block)
        end

        # Sets the condition check when the condition is not met to the block,
        # with a +condition+ that when met lead
        # to the execution of the block in +mode+ generated by the +ruby_block+.
        def helsif(condition, mode = nil, &ruby_block)
            # There is a ruby_block: the helse is assumed to be with
            # the last statement of the last behavior.
            # statement = @statements.last
            statement = self.last_behavior.last_statement
            # Completes the hif statement.
            unless statement.is_a?(If) then
                raise "Error: helsif statement without hif (#{statement.class})."
            end
            statement.helsif(condition, mode, &ruby_block)
        end

        # Creates a new case statement with a +value+ used for deciding which
        # block to execute.
        #
        # NOTE: 
        #  * the when part is defined through the hwhen method.
        #  * a new behavior is created to enclose the hcase.
        def hcase(value)
            self.par do
                hcase(value)
            end
        end

        # Sets the block of a case structure executed when the +match+ is met
        # to the block in +mode+ generated by the execution of +ruby_block+.
        #
        # Can only be used once.
        def hwhen(match, mode = nil, &ruby_block)
            # There is a ruby_block: the helse is assumed to be with
            # the last statement of the last behavior.
            statement = @behaviors.last.last_statement
            # Completes the hcase statement.
            unless statement.is_a?(Case) then
                raise "Error: hwhen statement without hcase (#{statement.class})."
            end
            statement.hwhen(match, mode, &ruby_block)
        end
        

        # Sets the constructs corresponding to +names+ as exports.
        def export(*names)
            names.each {|name| self.add_export(name) }
        end

        # # Extend the class according to another +system+.
        # def extend(system)
        #     # Adds the singleton methods
        #     self.eigen_extend(system)
        #     @singleton_instanceO.eigen_extend(system.singleton_instance)
        # end

        # Include a +system+ type with possible +args+ instanciation
        # arguments.
        def include(system,*args)
            if @includeIs.key?(system.name) then
                raise "Cannot include twice the same system."
            end
            # Extends with system.
            self.eigen_extend(system)
            # Create the instance to include
            instance = system.instantiate(:"",*args)
            # puts "instance=#{instance}"
            # Concat its public namespace to the current one.
            self.namespace.concat_namespace(instance.public_namespace)
            # Adds it the list of includeds
            @includeIs[system.name] = instance
        end

        # Casts as an included +system+.
        def as(system)
            system = system.name if system.respond_to?(:name)
            return @includeIs[system].public_namespace
        end

        include Hmux

        # Fills a low level scope with self's contents.
        #
        # NOTE: name conflicts are treated in the current NameStack state.
        def fill_low(scopeLow)
            # Adds the inner scopes.
            self.each_scope { |scope| scopeLow.add_scope(scope.to_low) }
            # Adds the inner signals.
            self.each_inner { |inner| scopeLow.add_inner(inner.to_low) }
            # Adds the instances.
            # Single ones.
            self.each_systemI { |systemI|
                scopeLow.add_systemI(systemI.to_low) 
            }
            # Grouped ones.
            self.each_groupI do |name,systemIs|
                systemIs.each.with_index { |systemI,i|
                    # Sets the name of the system instance
                    # (required for conversion of further accesses).
                    # puts "systemI.respond_to?=#{systemI.respond_to?(:name=)}"
                    systemI.name = name.to_s + "[#{i}]"
                    # And convert it to low
                    scopeLow.add_systemI(systemI.to_low())
                }
            end
            # Adds the connections.
            self.each_connection { |connection|
                # puts "connection=#{connection}"
                scopeLow.add_connection(connection.to_low)
            }
            # Adds the behaviors.
            self.each_behavior { |behavior|
                scopeLow.add_behavior(behavior.to_low)
            }
        end

        # Converts the scope to HDLRuby::Low.
        def to_low()
            # Create the resulting low scope.
            scopeLow = HDLRuby::Low::Scope.new()
            # Push the private namespace for the low generation.
            High.space_push(@namespace)
            # Pushes on the name stack for converting the internals of
            # the system.
            High.names_push
            # Adds the content of its included systems.
            @includeIs.each_value {|instance| instance.user.fill_low(scopeLow) }
            # Adds the content of the actual system.
            self.fill_low(scopeLow)
            # Restores the name stack.
            High.names_pop
            # Restores the namespace stack.
            High.space_pop
            # Return theresulting system.
            return scopeLow
        end
    end
    

    ##
    # Module bringing high-level properties to Type classes.
    #
    # NOTE: by default a type is not specified.
    module Htype
        High = HDLRuby::High

        # Type processing
        include HDLRuby::Tprocess

        # Ensures initialize registers the type name
        def self.included(base) # built-in Ruby hook for modules
            base.class_eval do    
                original_method = instance_method(:initialize)
                define_method(:initialize) do |*args, &block|
                    original_method.bind(self).call(*args, &block)
                    # Registers the name (if not empty).
                    self.register(name) unless name.empty?
                end
            end
        end

        # Tells htype has been included.
        def htype?
            return true
        end

        # Sets the +name+.
        #
        # NOTE: can only be done if the name is not already set.
        def name=(name)
            unless @name.empty? then
                raise "Name of type already set to: #{@name}."
            end
            # Checks and sets the name.
            name = name.to_sym
            if name.empty? then
                raise "Cannot set an empty name."
            end
            @name = name
            # Registers the name.
            self.register(name)
        end

        # Register the +name+ of the type.
        def register(name)
            if self.name.empty? then
                raise "Cannot register with empty name."
            else
                # Sets the hdl-like access to the type.
                obj = self # For using the right self within the proc
                High.space_reg(name) { obj }
            end
        end


        # Gets the type as left value.
        #
        # NOTE: used for asymetric types like TypeSystemI.
        def left
            # By default self.
            self
        end

        # Gets the type as right value.
        #
        # NOTE: used for asymetric types like TypeSystemI.
        def right
            # By default self.
            self
        end

        # Type creation in HDLRuby::High.
        
        # Declares a new type definition with +name+ equivalent to current one.
        def typedef(name)
            # Create the new type.
            typ = TypeDef.new(name,self)
            # Register it.
            High.space_reg(name) { typ }
            # Return it.
            return typ
        end

        # Creates a new vector type of range +rng+ and with current type as
        # base.
        def [](rng)
            return TypeVector.new(:"",self,rng)
        end

        # SignalI creation through the type.

        # Declares high-level input signals named +names+ of the current type.
        def input(*names)
            # High.top_user.make_inputs(self.instantiate,*names)
            High.top_user.make_inputs(self,*names)
        end

        # Declares high-level untyped output signals named +names+ of the
        # current type.
        def output(*names)
            # High.top_user.make_outputs(self.instantiate,*names)
            High.top_user.make_outputs(self,*names)
        end

        # Declares high-level untyped inout signals named +names+ of the
        # current type.
        def inout(*names)
            # High.top_user.make_inouts(self.instantiate,*names)
            High.top_user.make_inouts(self,*names)
        end

        # Declares high-level untyped inner signals named +names+ of the
        # current type.
        def inner(*names)
            # High.top_user.make_inners(self.instantiate,*names)
            High.top_user.make_inners(self,*names)
        end

        # Computations of expressions
        
        # Gets the computation method for +operator+.
        def comp_operator(op)
            return (op.to_s + "::C").to_sym
        end

        # Performs unary operation +operator+ on expression +expr+.
        def unary(operator,expr)
            # Look for a specific computation method.
            comp = comp_operator(operator)
            if self.respond_to?(comp) then
                # Found, use it.
                self.send(comp,expr)
            else
                # Not found, back to default generation of unary expression.
                return Unary.new(self.send(operator),operator,expr)
            end
        end

        # Performs binary operation +operator+ on expressions +expr0+
        # and +expr1+.
        def binary(operator, expr0, expr1)
            # Look for a specific computation method.
            comp = comp_operator(operator)
            if self.respond_to?(comp) then
                # Found, use it.
                self.send(comp,expr0,expr1)
            else
                # Not found, back to default generation of binary expression.
                return Binary.new(self.send(operator,expr1.type),operator,
                                  expr0,expr1)
            end
        end

        # Redefinition of +operator+.
        def define_operator(operator,&ruby_block)
            self.define_singleton_method(comp_operator(operator)) do |*args|
                # puts "Top user=#{HDLRuby::High.top_user}"
                HDLRuby::High.top_user.instance_exec do
                   sub do
                        HDLRuby::High.top_user.instance_exec(*args,&ruby_block)
                   end
                end
            end
        end
    end


    ##
    # Describes a high-level data type.
    #
    # NOTE: by default a type is not specified.
    class Type < Low::Type
        High = HDLRuby::High

        include Htype

        # Type creation.

        # Creates a new type named +name+.
        def initialize(name)
            # Initialize the type structure.
            super(name)
            # # Save the Location for debugging information
            # @location = caller_locations
        end

        # Converts the type to HDLRuby::Low and set its +name+.
        #
        # NOTE: should be overridden by other type classes.
        def to_low(name = self.name)
            return HDLRuby::Low::Type.new(name)
        end
    end

 
    # Creates the basic types.
    
    # Module providing the properties of a basic type.
    # NOTE: requires method 'to_low' to be defined.
    module HbasicType
        # Get all the metods from Low::Bit appart from 'base'
        extend Forwardable
        def_delegators :to_low, :signed?, :unsigned?, :fixed?, :float?,
                              :width, :range

        # Get the base type, actually self for leaf types.
        def base
            self
        end

    end
   
    # Defines a basic type +name+.
    def self.define_type(name)
        name = name.to_sym
        type = Type.new(name)
        self.send(:define_method,name) { type }
        return type
    end

    # The void type
    Void = define_type(:void)
    class << Void
        # Converts the type to HDLRuby::Low.
        def to_low
            return Low::Void
        end

        include HbasicType
    end

    # The bit type.
    Bit = define_type(:bit)
    class << Bit
        # # Tells if the type fixed point.
        # def fixed?
        #     return true
        # end
        # # Gets the bitwidth of the type, nil for undefined.
        # def width
        #     1
        # end

        # Converts the type to HDLRuby::Low.
        def to_low
            return Low::Bit
        end

        include HbasicType
    end

    # The signed bit type.
    Signed = define_type(:signed)
    class << Signed 
        # # Tells if the type is signed.
        # def signed?
        #     return true
        # end
        # # Tells if the type is fixed point.
        # def fixed?
        #     return true
        # end
        # # Gets the bitwidth of the type, nil for undefined.
        # def width
        #     1
        # end

        # Converts the type to HDLRuby::Low.
        def to_low
            return Low::Signed
        end

        include HbasicType
    end

    # The unsigned bit type.
    Unsigned = define_type(:unsigned)
    class << Unsigned
        # # Tells if the type is unsigned.
        # def unsigned?
        #     return true
        # end
        # # Tells if the type is fixed point.
        # def fixed?
        #     return true
        # end
        # # Gets the bitwidth of the type, nil for undefined.
        # def width
        #     1
        # end

        # Converts the type to HDLRuby::Low.
        def to_low
            return Low::Unsigned
        end

        include HbasicType
    end

    # # The numeric type (for all the Ruby Numeric types).
    # define_type :numeric

    # The float bit type
    Float = define_type(:float)
    class << Float
        # # Tells if the type is signed.
        # def signed?
        #     return true
        # end
        # # Tells if the type is floating point.
        # def float?
        #     return true
        # end
        # # Gets the bitwidth of the type, nil for undefined.
        # def width
        #     1
        # end

        # Converts the type to HDLRuby::Low.
        def to_low
            return Low::Float
        end

        include HbasicType
    end
    





    # ##
    # # Describes a numeric type.
    # class TypeNumeric < Low::TypeNumeric
    #     High = HDLRuby::High

    #     include Htype

    #     # Converts the type to HDLRuby::Low and set its +name+.
    #     def to_low(name = self.name)
    #         # Generate and return the new type.
    #         return HDLRuby::Low::TypeNumeric.new(name,self.numeric)
    #     end
    # end


    ##
    # Describes a high-level type definition.
    #
    # NOTE: type definition are actually type with a name refering to another
    #       type (and equivalent to it).
    class TypeDef < Low::TypeDef
        High = HDLRuby::High

        include Htype

        # Type creation.

        # Creates a new type definition named +name+ refering +type+.
        def initialize(name,type)
            # Initialize the type structure.
            super(name,type)
        end

        # Converts the type to HDLRuby::Low and set its +name+.
        #
        # NOTE: should be overridden by other type classes.
        def to_low(name = self.name)
            return HDLRuby::Low::TypeDef.new(name,self.def.to_low)
        end
    end




    # Methods for vector types.
    module HvectorType
        # Converts the type to HDLRuby::Low and set its +name+.
        def to_low(name = self.name)
            # Generate and return the new type.
            return HDLRuby::Low::TypeVector.new(name,self.base.to_low,
                                                self.range.to_low)
        end
    end


    ##
    # Describes a vector type.
    # class TypeVector < TypeExtend
    class TypeVector < Low::TypeVector
        High = HDLRuby::High
        include Htype
        include HvectorType

        # # # The range of the vector.
        # # attr_reader :range

        # # # Creates a new vector type named +name+ from +base+ type and with
        # # # +range+.
        # # def initialize(name,base,range)
        # #     # Initialize the type.
        # #     super(name,basa,range)

        # #     # # Check and set the vector-specific attributes.
        # #     # if rng.respond_to?(:to_i) then
        # #     #     # Integer case: convert to a 0..(rng-1) range.
        # #     #     rng = (rng-1)..0
        # #     # elsif
        # #     #     # Other cases: assume there is a first and a last to create
        # #     #     # the range.
        # #     #     rng = rng.first..rng.last
        # #     # end
        # #     # @range = rng
        # # end

        # # Type handling: these methods may have to be overriden when 
        # # subclassing.

        # # Moved to base
        # # # Gets the bitwidth of the type, nil for undefined.
        # # #
        # # # NOTE: must be redefined for specific types.
        # # def width
        # #     first = @range.first
        # #     last  = @range.last
        # #     return @base.width * (first-last).abs
        # # end

        # # # Gets the direction of the range.
        # # def dir
        # #     return (@range.last - @range.first)
        # # end

        # # # Tells if the type signed, false for unsigned.
        # # def signed?
        # #     return @base.signed?
        # # end

        # # # # Tells if a type is generic or not.
        # # # def generic?
        # # #     # The type is generic if the base is generic.
        # # #     return self.base.generic?
        # # # end

        # # # Checks the compatibility with +type+
        # # def compatible?(type)
        # #     # # if type is void, compatible anyway.
        # #     # return true if type.name == :void
        # #     # Compatible if same width and compatible base.
        # #     return false unless type.respond_to?(:dir)
        # #     return false unless type.respond_to?(:base)
        # #     return ( self.dir == type.dir and
        # #              self.base.compatible?(type.base) )
        # # end

        # # # Merges with +type+
        # # def merge(type)
        # #     # # if type is void, return self anyway.
        # #     # return self if type.name == :void
        # #     # Compatible if same width and compatible base.
        # #     unless type.respond_to?(:dir) and type.respond_to?(:base) then
        # #         raise "Incompatible types for merging: #{self}, #{type}."
        # #     end
        # #     unless self.dir == type.dir then
        # #         raise "Incompatible types for merging: #{self}, #{type}."
        # #     end
        # #     return TypeVector.new(@name,@range,@base.merge(type.base))
        # # end

        # # Converts the type to HDLRuby::Low and set its +name+.
        # def to_low(name = self.name)
        #     # Generate and return the new type.
        #     return HDLRuby::Low::TypeVector.new(name,self.base.to_low,
        #                                         self.range.to_low)
        # end
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


    ##
    # Describes a tuple type.
    # class TypeTuple < Tuple
    class TypeTuple < Low::TypeTuple
        High = HDLRuby::High

        include Htype

        # Converts the type to HDLRuby::Low and set its +name+.
        def to_low(name = self.name)
            return HDLRuby::Low::TypeTuple.new(name,
                               *@types.map { |type| type.to_low } )
        end
    end


    ##
    # Describes a structure type.
    # class TypeStruct < TypeHierarchy
    class TypeStruct < Low::TypeStruct
        High = HDLRuby::High

        include Htype

        # Moved to Low
        # # Gets the bitwidth of the type, nil for undefined.
        # #
        # # NOTE: must be redefined for specific types.
        # def width
        #     return @types.reduce(0) {|sum,type| sum + type.width }
        # end

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
        #         raise "Incompatible types for merging: #{self}, #{type}."
        #     end
        #     # Not compatibe unless each entry has the same name and same order.
        #     unless self.each_name == type.each_name then
        #         raise "Incompatible types for merging: #{self}, #{type}."
        #     end
        #     # Creates the new type content
        #     content = {}
        #     self.each do |name,sub|
        #         content[name] = self.get_type(name).merge(sub)
        #     end
        #     return TypeStruct.new(@name,content)
        # end  

        # Converts the type to HDLRuby::Low and set its +name+.
        def to_low(name = self.name)
            return HDLRuby::Low::TypeStruct.new(name,
                                @types.map { |name,type| [name,type.to_low] } )
        end
    end



    ## Methods for declaring system types and functions.

    # The type constructors.

    # Creates an unnamed structure type from a +content+.
    def struct(content)
        return TypeStruct.new(:"",content)
    end

    # # Creates an unnamed union type from a +content+.
    # def union(content)
    #     return TypeUnion.new(:"",content)
    # end

    # # Creates type named +name+ and using +ruby_block+ for building it.
    # def type(name,&ruby_block)
    #     # Builds the type.
    #     type = HDLRuby::High.top_user.instance_eval(&ruby_block)
    #     # Ensures type is really a type.
    #     # unless type.is_a?(Type) then
    #     unless type.respond_to?(:htype?) then
    #         raise "Invalid class for a type: #{type.class}."
    #     end
    #     # Name it.
    #     type.name = name
    #     return type
    # end

    # Methods for declaring systems

    # Declares a high-level system type named +name+, with +includes+ mixins
    # hardware types and using +ruby_block+ for instantiating.
    def system(name = :"", *includes, &ruby_block)
        # print "system ruby_block=#{ruby_block}\n"
        # Creates the resulting system.
        return SystemT.new(name,*includes,&ruby_block)
    end

    # Methods for declaring function

    # Declares a function named +name+ using +ruby_block+ as body.
    #
    # NOTE: a function is a short-cut for a method that creates a scope.
    def function(name, &ruby_block)
        if HDLRuby::High.in_system? then
            define_singleton_method(name.to_sym) do |*args|
                sub do
                    HDLRuby::High.top_user.instance_exec(*args,&ruby_block)
                    # ruby_block.call(*args)
                end
            end
        else
            define_method(name.to_sym) do |*args|
                sub do
                    HDLRuby::High.top_user.instance_exec(*args,&ruby_block)
                end
            end
        end
    end


    # # Extends the system type class for converting it to a data type.
    # class SystemT
    #     # Converts the system type to a data type using +left+ signals
    #     # as left values and +right+ signals as right values.
    #     def to_type(left,right)
    #         return TypeSystemT.new(:"",self,left,right)
    #     end
    # end



    # Classes describing harware instances.


    ##
    # Describes a high-level system instance.
    class SystemI < Low::SystemI
        High = HDLRuby::High

        include SingletonExtend

        # Creates a new system instance of system type +systemT+ named +name+.
        def initialize(name, systemT)
            # Initialize the system instance structure.
            super(name,systemT)
            # # Save the Location for debugging information
            # @location = caller_locations
            # puts "New systemI with scope=#{self.systemT.scope}"

            # Sets the hdl-like access to the system instance.
            obj = self # For using the right self within the proc
            High.space_reg(name) { obj }
        end

        # The type of a systemI: for now Void (may change in the future).
        def type
            return void
        end

        # Converts to a new reference.
        def to_ref
            if self.name.empty? then
                # No name, happens if inside the systemI so use this.
                return this
            else
                # A name.
                return RefObject.new(this,self)
            end
        end

        # Connects signals of the system instance according to +connects+.
        #
        # NOTE: +connects+ can be a hash table where each entry gives the
        # correspondance between a system's signal name and an external
        # signal to connect to, or a list of signals that will be connected
        # in the order of declaration.
        def call(*connects)
            # Checks if it is a connection through is a hash.
            if connects.size == 1 and connects[0].respond_to?(:to_h) then
                # Yes, perform a connection by name
                connects = connects[0].to_h
                # Performs the connections.
                connects.each do |left,right|
                    # Gets the signal corresponding to connect.
                    left = self.get_signal(left)
                    # Convert it to a reference.
                    left = RefObject.new(self.to_ref,left)
                    # Make the connection.
                    left <= right
                end
            else
                # No, perform a connection is order of declaration
                connects.each.with_index do |csig,i|
                    # Gets i-est signal to connect
                    ssig = self.get_interface(i)
                    # Convert it to a reference.
                    ssig = RefObject.new(self.to_ref,ssig)
                    # Make the connection.
                    ssig <= csig
                end
            end
        end

        # Gets an exported element (signal or system instance) by +name+.
        def get_export(name)
            return @systemT.get_export(name)
        end


        # Opens for extension.
        #
        # NOTE: actually executes +ruby_block+ in the context of the
        #       systemT.
        def open(&ruby_block)
            return @systemT.run(&ruby_block)
        end

        # include Hmissing

        # Missing methods are looked for in the public namespace of the
        # system type.
        def method_missing(m, *args, &ruby_block)
            # print "method_missing in class=#{self.class} with m=#{m}\n"
            self.public_namespace.send(m,*args,&ruby_block)
        end


        # Methods to transmit to the systemT
        
        # Gets the public namespace.
        def public_namespace
            self.systemT.public_namespace
        end


        # Converts the instance to HDLRuby::Low and set its +name+.
        def to_low(name = self.name)
            # puts "to_low with #{self} (#{self.name}) #{self.systemT}"
            # Converts the system of the instance to HDLRuby::Low
            # systemTlow = self.systemT.to_low(High.names_create(name.to_s+ "::T"))
            systemTlow = self.systemT.to_low
            # Creates the resulting HDLRuby::Low instance
            return HDLRuby::Low::SystemI.new(High.names_create(name),
                                             systemTlow)
        end
    end


    # Class describing namespace in system.



    # Classes describing hardware statements, connections and expressions


    ##
    # Module giving high-level statement properties
    module HStatement
        # Creates a new if statement with a +condition+ enclosing the statement.
        #
        # NOTE: the else part is defined through the helse method.
        def hif(condition)
            # Creates the if statement.
            return If.new(condition) { self }
        end
    end


    ## 
    # Describes a high-level if statement.
    class If < Low::If
        High = HDLRuby::High

        include HStatement

        # Creates a new if statement with a +condition+ that when met lead
        # to the execution of the block in +mode+ generated by the execution of
        # +ruby_block+.
        def initialize(condition, mode = nil, &ruby_block)
            # Create the yes block.
            # yes_block = High.make_block(:par,&ruby_block)
            yes_block = High.make_block(mode,&ruby_block)
            # Creates the if statement.
            super(condition.to_expr,yes_block)
            # # Save the Location for debugging information
            # @location = caller_locations
        end

        # Sets the block executed in +mode+ when the condition is not met to
        # the block generated by the execution of +ruby_block+.
        #
        # Can only be used once.
        def helse(mode = nil, &ruby_block)
            # If there is a no block, it is an error.
            raise "Cannot have two helse for a single if statement." if self.no
            # Create the no block if required
            no_block = High.make_block(mode,&ruby_block)
            # Sets the no block.
            self.no = no_block
        end

        # Sets the block executed in +mode+ when the condition is not met
        # but +next_cond+ is met to the block generated by the execution of
        # +ruby_block+.
        #
        # Can only be used if the no-block is not set yet.
        def helsif(next_cond, mode = nil, &ruby_block)
            # If there is a no block, it is an error.
            raise "Cannot have an helsif after an helse." if self.no
            # Create the noif block if required
            noif_block = High.make_block(mode,&ruby_block)
            # Adds the noif block.
            self.add_noif(next_cond.to_expr,noif_block)
        end

        # Converts the if to HDLRuby::Low.
        def to_low
            # no may be nil, so treat it appart
            noL = self.no ? self.no.to_low : nil
            # Now generate the low-level if.
            low = HDLRuby::Low::If.new(self.condition.to_low,
                                       self.yes.to_low,noL)
            self.each_noif {|cond,block| low.add_noif(cond.to_low,block.to_low)}
            return low
        end
    end

    
    ##
    # Describes a high-level when for a case statement.
    class When < Low::When
        High = HDLRuby::High

        # Creates a new when for a casde statement that executes +statement+
        # on +match+.
        def initialize(match,statement)
            super(match,statement)
            # # Save the Location for debugging information
            # @location = caller_locations
        end

        # Converts the if to HDLRuby::Low.
        def to_low
            return HDLRuby::Low::When.new(self.match.to_low,
                                          self.statement.to_low)
        end
    end


    ## 
    # Describes a high-level case statement.
    class Case < Low::Case
        High = HDLRuby::High

        include HStatement

        # Creates a new case statement with a +value+ that decides which
        # block to execute.
        def initialize(value)
            # Create the yes block.
            super(value.to_expr)
            # # Save the Location for debugging information
            # @location = caller_locations
        end

        # Sets the block executed in +mode+ when the value matches +match+.
        # The block is generated by the execution of +ruby_block+.
        #
        # Can only be used once for the given +match+.
        def hwhen(match, mode = nil, &ruby_block)
            # Create the nu block if required
            # when_block = High.make_block(:par,&ruby_block)
            when_block = High.make_block(mode,&ruby_block)
            # Adds the case.
            self.add_when(When.new(match.to_expr,when_block))
        end

        # Sets the block executed in +mode+ when there were no match to
        # the block generated by the execution of +ruby_block+.
        #
        # Can only be used once.
        def helse(mode = nil, &ruby_block)
            # Create the nu block if required
            # no_block = High.make_block(:par,&ruby_block)
            default_block = High.make_block(mode,&ruby_block)
            # Sets the default block.
            self.default = default_block
        end

        # Converts the case to HDLRuby::Low.
        def to_low
            # Create the low level case.
            caseL = HDLRuby::Low::Case.new(@value.to_low)
            # Add each when case.
            # self.each_when do |match,statement|
            #     caseL.add_when(When.new(match.to_low, statement.to_low))
            # end
            self.each_when do |w|
                caseL.add_when(w.to_low)
            end
            # Add the default if any.
            if self.default then
                caseL.default = self.default.to_low
            end
            return caseL
        end
    end


    ##
    # Describes a delay: not synthesizable.
    class Delay < Low::Delay
        High = HDLRuby::High

        include HStatement

        def !
            High.top_user.wait(self)    
        end

        # Converts the delay to HDLRuby::Low.
        def to_low
            return HDLRuby::Low::Delay.new(self.value, self.unit)
        end
    end

    ##
    # Describes a high-level wait delay statement.
    class TimeWait < Low::TimeWait
        include HStatement

        # Converts the wait statement to HDLRuby::Low.
        def to_low
            return HDLRuby::Low::TimeWait.new(self.delay.to_low)
        end
    end


    ## 
    # Describes a timed loop statement: not synthesizable!
    class TimeRepeat < Low::TimeRepeat
        include HStatement

        # Converts the repeat statement to HDLRuby::Low.
        def to_low
            return HDLRuby::Low::TimeRepeat.new(self.statement.to_low,
                                                self.delay.to_low)
        end
    end


    ##
    # Module giving high-level expression properties
    module HExpression
        # The system type the expression has been resolved in, if any.
        attr_reader :systemT
        # The type of the expression if resolved.
        attr_reader :type

        # Tell if the expression can be converted to a value.
        def to_value?
            return false
        end

        # Converts to a new value.
        #
        # NOTE: to be redefined.
        def to_value
            raise "Expression cannot be converted to a value: #{self.class}"
        end

        # Converts to a new expression.
        #
        # NOTE: to be redefined in case of non-expression class.
        def to_expr
            raise "Internal error: to_expr not defined yet for class: #{self.class}"
        end

        # Casts as +type+.
        def as(type)
            return Cast.new(type.to_type,self)
        end

        # Gets the origin method for operation +op+.
        def self.orig_operator(op)
            return (op.to_s + "_orig").to_sym
        end
        def orig_operator(op)
            HExpression.orig_operator(op)
        end

        # Adds the unary operations generation.
        [:"-@",:"@+",:"~", :abs,
         :boolean, :bit, :signed, :unsigned].each do |operator|
            meth = proc do
                # return Unary.new(self.to_expr.type.send(operator),operator,
                #                  self.to_expr)
                expr = self.to_expr
                return expr.type.unary(operator,expr)
            end
            # Defines the operator method.
            define_method(operator,&meth) 
            # And save it so that it can still be accessed if overidden.
            define_method(orig_operator(operator),&meth)
        end

        # Adds the binary operations generation.
        [:"+",:"-",:"*",:"/",:"%",:"**",
         :"&",:"|",:"^",:"<<",:">>",
         :"==",:"!=",:"<",:">",:"<=",:">="].each do |operator|
            meth = proc do |right|
                # return Binary.new(
                #     self.to_expr.type.send(operator,right.to_expr.type),
                #     operator, self.to_expr,right.to_expr)
                expr = self.to_expr
                return expr.type.binary(operator,expr,right.to_expr)
            end
            # Defines the operator method.
            define_method(operator,&meth) 
            # And save it so that it can still be accessed if overidden.
            define_method(orig_operator(operator),&meth)
        end

        # Converts to a select operator using current expression as
        # condition for one of the +choices+.
        #
        # NOTE: +choices+ can either be a list of arguments or an array.
        # If +choices+ has only two entries
        # (and it is not a hash), +value+ will be converted to a boolean.
        def mux(*choices)
            # Process the choices.
            choices = choices.flatten(1) if choices.size == 1
            choices.map! { |choice| choice.to_expr }
            # Generate the select expression.
            return Select.new(choices[0].type,"?",self.to_expr,*choices)
        end


        # Methods for conversion for HDLRuby::Low: type processing, flattening
        # and so on

        # The type of the expression if any.
        attr_reader :type

        # Sets the data +type+.
        def type=(type)
            # Check and set the type.
            # unless type.is_a?(Type) then
            unless type.respond_to?(:htype?) then
                raise "Invalid class for a type: #{type.class}."
            end
            @type = type
        end
        # Converts to a select operator using current expression as
        # condition for one of the +choices+.
        #
        # NOTE: +choices+ can either be a list of arguments or an array.
        # If +choices+ has only two entries
        # (and it is not a hash), +value+ will be converted to a boolean.
        def mux(*choices)
            # Process the choices.
            choices = choices.flatten(1) if choices.size == 1
            choices.map! { |choice| choice.to_expr }
            # Generate the select expression.
            return Select.new(choices[0].type,"?",self.to_expr,*choices)
        end

        # # The parent construct.
        # attr_reader :parent

        # # Sets the +parent+ construct.
        # def parent=(parent)
        #     # Check and set the type.
        #     unless ( parent.is_a?(Low::Expression) or
        #              parent.is_a?(Low::Transmit) or
        #              parent.is_a?(Low::If) or
        #              parent.is_a?(Low::Case) ) then
        #         raise "Invalid class for a type: #{type.class}."
        #     end
        #     @parent = parent
        # end

        # # Iterates over the expression parents if any (actually at most once).
        # def each_parent(&ruby_block)
        #     # No ruby block? Return an enumerator.
        #     return to_enum(:each_parent) unless ruby_block
        #     # A block? Apply it on the parent.
        #     ruby_block.call(@parent)
        # end

        # # Methods for conversion for HDLRuby::Low: type processing, flattening
        # # and so on

        # # Make the current expression a parent and recurse.
        # def make_parents_deep
        #     # Set the parents of the children and recurse on them.
        #     self.each_child do |child|
        #         if child.respond_to?(:parent=) then
        #             child.parent = self
        #         else
        #             child.add_parent(self)
        #         end
        #         child.make_parents_deep
        #     end
        # end

        # # Resolves the unknown signal types and conflicts in the context
        # # of system type +systemT+.
        # # Returns true if the resolution succeeded.
        # #
        # # NOTE: sets the type of the expression.
        # def resolve_types(systemT)
        #     # Only typed expression can be used for resolving types.
        #     unless @type then
        #         raise "Cannot resolve type: nil type."
        #     end
        #     # Resolve the children.
        #     self.each_child do |child|
        #         if child.type == nil then
        #             # The child's type is unknown, should not happen.
        #             raise "Cannot resolve type: child's type is nil."
        #         end
        #         # Check if the type is compatible with the child's.
        #         if @type.compatible?(child.type) then
        #             # Yes, compute and set the new type for both.
        #             @type = child.type = type.merge(child.type)
        #         else
        #             # Incombatible types, cannot resolve type.
        #             raise "Cannot resolve type: #{@type} and child's #{child.type} are incompatible."
        #         end
        #     end
        #     # Resolve the parents.
        #     self.each_parent do |parent|
        #         if parent.type == nil then
        #             # Simple sets the parent's type to current one.
        #             parent.type = @type
        #         elsif @type.compatible?(parent.type) then
        #             # Yes, compute and set the new type for both.
        #             @type = parent.type = type.merge(parent.type)
        #         else
        #             # Incombatible types, cannot resolve type.
        #             raise "Cannot resolve type: #{@type} and #{parent.type} are incompatible."
        #         end
        #     end
        # end
    end


    ##
    # Module giving high-level properties for handling the arrow (<=) operator.
    module HArrow
        High = HDLRuby::High

        # Creates a transmit, or connection with an +expr+.
        #
        # NOTE: it is converted afterward to an expression if required.
        def <=(expr)
            if High.top_user.is_a?(HDLRuby::Low::Block) then
                # We are in a block, so generate and add a Transmit.
                High.top_user.
                    add_statement(Transmit.new(self.to_ref,expr.to_expr))
            else
                # We are in a system type, so generate and add a Connection.
                High.top_user.
                    add_connection(Connection.new(self.to_ref,expr.to_expr))
            end
        end
    end


    ##
    # Describes a high-level cast expression
    class Cast < Low::Cast
        include HExpression

        # Converts to a new expression.
        def to_expr
            return Cast.new(self.type,self.child.to_expr)
        end

        # Converts the unary expression to HDLRuby::Low.
        def to_low
            return HDLRuby::Low::Cast.new(self.type.to_low,self.child.to_low)
        end
    end


    ##
    # Describes a high-level unary expression
    class Unary < Low::Unary
        include HExpression

        # Converts to a new expression.
        def to_expr
            return Unary.new(self.type,self.operator,self.child.to_expr)
        end

        # Converts the unary expression to HDLRuby::Low.
        def to_low
            return HDLRuby::Low::Unary.new(self.type.to_low, self.operator,
                                           self.child.to_low)
        end
    end


    ##
    # Describes a high-level binary expression
    class Binary < Low::Binary
        include HExpression

        # Converts to a new expression.
        def to_expr
            # return Binary.new(self.operator,self.left.to_expr,self.right.to_expr)
            return Binary.new(self.type, self.operator,
                              self.left.to_expr, self.right.to_expr)
        end

        # Converts the binary expression to HDLRuby::Low.
        def to_low
            # return HDLRuby::Low::Binary.new(self.operator,
            return HDLRuby::Low::Binary.new(self.type.to_low, self.operator,
                                           self.left.to_low, self.right.to_low)
        end
    end


    # ##
    # # Describes a high-level ternary expression
    # class Ternary < Low::Ternary
    #     include HExpression
    # end

    ##
    # Describes a section operation (generalization of the ternary operator).
    #
    # NOTE: choice is using the value of +select+ as an index.
    class Select < Low::Select
        include HExpression

        # Converts to a new expression.
        def to_expr
            return Select.new(self.type,"?",self.select.to_expr,
            *self.each_choice.map do |choice|
                choice.to_expr
            end)
        end

        # Converts the selection expression to HDLRuby::Low.
        def to_low
            # return HDLRuby::Low::Select.new("?",self.select.to_low,
            return HDLRuby::Low::Select.new(self.type.to_low,"?",
                                            self.select.to_low,
            *self.each_choice.map do |choice|
                choice.to_low
            end)
        end
    end


    ##
    # Describes z high-level concat expression.
    class Concat < Low::Concat
        include HExpression

        # Converts to a new expression.
        def to_expr
            # return Concat.new(
            #     self.each_expression.lazy.map do |expr|
            #         expr.to_expr
            #     end
            # )
            return Concat.new(self.type,
                self.each_expression.lazy.map do |expr|
                    expr.to_expr
                end
            )
        end

        # Converts the concatenation expression to HDLRuby::Low.
        def to_low
            # return HDLRuby::Low::Concat.new(
            #     self.each_expression.lazy.map do |expr|
            #         expr.to_low
            #     end
            return HDLRuby::Low::Concat.new(self.type.to_low,
                self.each_expression.lazy.map do |expr|
                    expr.to_low
                end
            )
        end
    end


    ##
    # Describes a high-level value.
    class Value < Low::Value
        include HExpression
        include HDLRuby::Vprocess

        # Tell if the expression can be converted to a value.
        def to_value?
            return true
        end

        # Converts to a new value.
        def to_value
            # # Already a value.
            # self
            return Value.new(self.type,self.content)
        end

        # Converts to a new expression.
        def to_expr
            return self.to_value
        end

        # Converts the value to HDLRuby::Low.
        def to_low
            # Clone the content if possible
            content = self.content.frozen? ? self.content : self.content.clone
            # Create and return the resulting low-level value
            return HDLRuby::Low::Value.new(self.type.to_low,self.content)
        end

        # # For support in ranges.
        # def <=>(expr)
        #     return self.to_s <=> expr.to_s
        # end
    end



    ## 
    # Module giving high-level reference properties.
    module HRef
        # Properties of expressions are also required
        def self.included(klass)
            klass.class_eval do
                include HExpression
                include HArrow

                # Converts to a new expression.
                def to_expr
                    self.to_ref
                end
            end
        end

        # Converts to a new reference.
        #
        # NOTE: to be redefined in case of non-reference class.
        def to_ref
            raise "Internal error: to_ref not defined yet for class: #{self.class}"
        end

        # Converts to a new event.
        def to_event
            return Event.new(:change,self.to_ref)
        end

        # Creates an access to elements of range +rng+ of the signal.
        #
        # NOTE: +rng+ can be a single expression in which case it is an index.
        def [](rng)
            if rng.respond_to?(:to_expr) then
                # Number range: convert it to an expression.
                rng = rng.to_expr
            end 
            if rng.is_a?(HDLRuby::Low::Expression) then
                # Index case
                # return RefIndex.new(self.to_ref,rng)
                return RefIndex.new(self.type.base,self.to_ref,rng)
            else
                # Range case, ensure it is made among expression.
                first = rng.first.to_expr
                last = rng.last.to_expr
                # Abd create the reference.
                # return RefRange.new(self.to_ref,first..last)
                return RefRange.new(self.type.slice(first..last),
                                    self.to_ref,first..last)
            end
        end

        # Iterate over the elements.
        #
        # Returns an enumerator if no ruby block is given.
        def each(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each) unless ruby_block
            # A block? Apply it on each element.
            self.type.range.heach do |i|
                yield(self[i])
            end
        end

        # Reference can be used like enumerator
        include Enumerable
    end



    ##
    # Describes a high-level object reference: no low-level equivalent!
    class RefObject < Low::Ref
        include HRef

        # The base of the reference
        attr_reader :base

        # The refered object.
        attr_reader :object

        # Creates a new reference from a +base+ reference and named +object+.
        def initialize(base,object)
            if object.respond_to?(:type) then
                # Typed object, so typed reference.
                super(object.type)
            else
                # Untyped object, so untyped reference.
                super(void)
            end
            # # Save the Location for debugging information
            # @location = caller_locations
            # Check and set the base (it must be convertible to a reference).
            unless base.respond_to?(:to_ref)
                raise "Invalid base for a RefObject: #{base}"
            end
            @base = base
            # Check and set the object (it must have a name).
            unless object.respond_to?(:name)
                raise "Invalid object for a RefObject: #{object}"
            end
            @object = object
        end

        # Converts to a new reference.
        def to_ref
            return RefObject.new(@base,@object)
        end

        # Converts the name reference to a HDLRuby::Low::RefName.
        def to_low
            # return HDLRuby::Low::RefName.new(@base.to_ref.to_low,@object.name)
            return HDLRuby::Low::RefName.new(self.type.to_low,
                                             @base.to_ref.to_low,@object.name)
        end

        # Missing methods are looked for into the refered object.
        def method_missing(m, *args, &ruby_block)
            @object.send(m,*args,&ruby_block)
        end


    #     # Converts the reference to a low-level name reference.
    #     def to_low
    #         # Build the path of the reference.
    #         path = []
    #         cur = @object
    #         while(!High.top_user.user_deep?(cur)) do
    #             puts "first cur=#{cur}"
    #             cur = cur.owner if cur.respond_to?(:owner)
    #             puts "cur=#{cur}", "name=#{cur.name}"
    #             path << cur.name
    #             cur = cur.parent
    #             # cur = cur.scope if cur.respond_to?(:scope)
    #             puts " parent=#{cur} found? #{High.top_user.user_deep?(cur)}"
    #         end
    #         # puts "path=#{path}"
    #         # Build the references from the path.
    #         ref = this.to_low
    #         path.each { |name| ref = HDLRuby::Low::RefName.new(ref,name) }
    #         return ref
    #     end
    end


    ##
    # Describes a high-level concat reference.
    class RefConcat < Low::RefConcat
        include HRef

        # Converts to a new reference.
        def to_ref
            # return RefConcat.new(
            #     self.each_ref.lazy.map do |ref|
            #         ref.to_ref
            #     end
            # )
            return RefConcat.new(self.type,
                self.each_ref.lazy.map do |ref|
                    ref.to_ref
                end
            )
        end

        # Converts the concat reference to HDLRuby::Low.
        def to_low
            # return HDLRuby::Low::RefConcat.new(
            #     self.each_ref.lazy.map do |ref|
            #         ref.to_low
            #     end
            # )
            return HDLRuby::Low::RefConcat.new(self.type.to_low,
                self.each_ref.lazy.map do |ref|
                    ref.to_low
                end
            )
        end
    end

    ##
    # Describes a high-level index reference.
    class RefIndex < Low::RefIndex
        include HRef

        # Converts to a new reference.
        def to_ref
            # return RefIndex.new(self.ref.to_ref,self.index.to_expr)
            return RefIndex.new(self.type.base,
                                self.ref.to_ref,self.index.to_expr)
        end

        # Converts the index reference to HDLRuby::Low.
        def to_low
            # return HDLRuby::Low::RefIndex.new(self.ref.to_low,self.index.to_low)
            return HDLRuby::Low::RefIndex.new(self.type.to_low,
                                              self.ref.to_low,self.index.to_low)
        end
    end

    ##
    # Describes a high-level range reference.
    class RefRange < Low::RefRange
        include HRef

        # Converts to a new reference.
        def to_ref
            # return RefRange.new(self.ref.to_ref,
            #                   self.range.first.to_expr..self.range.last.to_expr)
            return RefRange.new(self.type,self.ref.to_ref,
                              self.range.first.to_expr..self.range.last.to_expr)
        end

        # Converts the range reference to HDLRuby::Low.
        def to_low
            # return HDLRuby::Low::RefRange.new(self.ref.to_low,self.range.to_low)
            return HDLRuby::Low::RefRange.new(self.type.to_low,
                self.ref.to_low,self.range.to_low)
        end
    end

    ##
    # Describes a high-level name reference.
    class RefName < Low::RefName
        include HRef

        # Converts to a new reference.
        def to_ref
            return RefName.new(self.ref.to_ref,self.name)
        end

        # Converts the name reference to HDLRuby::Low.
        def to_low
            # puts "To low for ref with name=#{self.name} and subref=#{self.ref}"
            # return HDLRuby::Low::RefName.new(self.ref.to_low,self.name)
            return HDLRuby::Low::RefName.new(self.type.to_low,
                                             self.ref.to_low,self.name)
        end
    end

    ##
    # Describes a this reference.
    class RefThis < Low::RefThis
        High = HDLRuby::High
        include HRef
       
        # Deactivated since incompatible with the parent features.
        # # The only useful instance of RefThis.
        # This = RefThis.new

        # Converts to a new reference.
        def to_ref
            return RefThis.new
        end

        # Gets the enclosing system type.
        def system
            return High.cur_system
        end

        # Gets the enclosing behavior if any.
        def behavior
            return High.cur_behavior
        end

        # Gets the enclosing block if any.
        def block
            return High.cur_block
        end

        # Converts the this reference to HDLRuby::Low.
        def to_low
            return HDLRuby::Low::RefThis.new
        end
    end


    # Gives access to the *this* reference.
    def this
        RefThis.new
    end


    ##
    # Describes a high-level event.
    class Event < Low::Event
        # Converts to a new event.
        def to_event
            # return self
            return Event.new(self.type,self.ref.to_ref)
        end

        # Inverts the event: create a negedge if posedge, a posedge if negedge.
        #
        # NOTE: raise an execption if the event is neigther pos nor neg edge.
        def invert
            if self.type == :posedge then
                return Event.new(:negedge,self.ref.to_ref)
            elsif self.type == :negedge then
                return Event.new(:posedge,self.ref.to_ref)
            else
                raise "Event cannot be inverted: #{self.type}"
            end
        end

        # Converts the event to HDLRuby::Low.
        def to_low
            return HDLRuby::Low::Event.new(self.type,self.ref.to_low)
        end
    end


    ## 
    # Decribes a transmission statement.
    class Transmit < Low::Transmit
        High = HDLRuby::High

        include HStatement

        # Converts the transmission to a comparison expression.
        #
        # NOTE: required because the <= operator is ambigous and by
        # default produces a Transmit or a Connection.
        def to_expr
            # Remove the transission from the block.
            High.top_user.delete_statement(self)
            # Generate an expression.
            # return Binary.new(:<=,self.left.to_expr,self.right.to_expr)
            return Binary.new(
                self.left.to_expr.type.send(:<=,self.right.to_expr.type),
                :<=,self.left.to_expr,self.right.to_expr)
        end

        # Converts the transmit to HDLRuby::Low.
        def to_low
            return HDLRuby::Low::Transmit.new(self.left.to_low,
                                              self.right.to_low)
        end
    end

    ## 
    # Describes a connection.
    class Connection < Low::Connection
        High = HDLRuby::High

        # Converts the connection to a comparison expression.
        #
        # NOTE: required because the <= operator is ambigous and by
        # default produces a Transmit or a Connection.
        def to_expr
            # Remove the connection from the system type.
            High.top_user.delete_connection(self)
            # Generate an expression.
            return Binary.new(:<=,self.left,self.right)
        end

        # Creates a new behavior sensitive to +event+ including the connection
        # converted to a transmission, and replace the former by the new
        # behavior.
        def at(event)
            # Creates the behavior.
            left, right = self.left, self.right
            # Detached left and right from their connection since they will
            # be put in a new behavior instead.
            left.parent = right.parent = nil
            # Create the new behavior replacing the connection.
            behavior = Behavior.new(:par,event) do
                left <= right
            end
            # Adds the behavior.
            High.top_user.add_behavior(behavior)
            # Remove the connection
            High.top_user.delete_connection(self)
        end

        # Creates a new behavior with an if statement from +condition+
        # enclosing the connection converted to a transmission, and replace the
        # former by the new behavior.
        #
        # NOTE: the else part is defined through the helse method.
        def hif(condition)
            # Creates the behavior.
            left, right = self.left, self.right
            # Detached left and right from their connection since they will
            # be put in a new behavior instead.
            left.parent = right.parent = nil
            # Create the new behavior replacing the connection.
            behavior = Behavior.new(:par) do
                hif(condition) do
                    left <= right
                end
            end
            # Adds the behavior.
            High.top_user.add_behavior(behavior)
            # Remove the connection
            High.top_user.delete_connection(self)
        end

        # Converts the connection to HDLRuby::Low.
        def to_low
            return HDLRuby::Low::Connection.new(self.left.to_low,
                                                self.right.to_low)
        end
    end


    ##
    # Describes a high-level signal.
    class SignalI < Low::SignalI
        High = HDLRuby::High

        include HRef

        # The valid bounding directions.
        DIRS = [ :no, :input, :output, :inout, :inner ]

        # # The object the signal is bounded to if any.
        # attr_reader :bound

        # The bounding direction.
        attr_reader :dir

        # Tells if the signal can be read.
        attr_reader :can_read

        # Tells if the signal can be written.
        attr_reader :can_write

        # Creates a new signal named +name+ typed as +type+ and with
        # +dir+ as bounding direction.
        #
        # NOTE: +dir+ can be :input, :output, :inout or :inner
        def initialize(name,type,dir)
            # Initialize the type structure.
            super(name,type)
            # # Save the Location for debugging information
            # @location = caller_locations

            unless name.empty? then
                # Named signal, set the hdl-like access to the signal.
                obj = self # For using the right self within the proc
                High.space_reg(name) { obj }
            end

            # Hierarchical type allows access to sub references, so generate
            # the corresponding methods.
            # if type.respond_to?(:each_name) then
            if type.struct? then
                type.each_name do |name|
                    self.define_singleton_method(name) do
                        RefObject.new(self.to_ref,
                                    SignalI.new(name,type.get_type(name)))
                    end
                end
            end

            # Check and set the bound.
            self.dir = dir

            # Set the read and write authorisations.
            @can_read = 1.to_expr
            @can_write = 1.to_expr
        end

        # Sets the +condition+ when the signal can be read.
        def can_read=(condition)
            @can_read = condition.to_expr
        end

        # Sets the +condition+ when the signal can be write.
        def can_write=(condition)
            @can_write = condition.to_expr
        end

        # # Tells if the signal is bounded or not.
        # def bounded?
        #     return (@dir and @dir != :no)
        # end

        # Sets the direction to +dir+.
        def dir=(dir)
            # if self.bounded? then
            #     raise "Error: signal #{self.name} already bounded."
            # end
            unless DIRS.include?(dir) then
                raise "Invalid bounding for signal #{self.name} direction: #{dir}."
            end
            @dir = dir
        end

        # Creates a positive edge event from the signal.
        def posedge
            return Event.new(:posedge,self.to_ref)
        end

        # Creates a negative edge event from the signal.
        def negedge
            return Event.new(:negedge,self.to_ref)
        end

        # Creates an edge event from the signal.
        def edge
            return Event.new(:edge,self.to_ref)
        end

        # # Creates a change event from the signal.
        # def change
        #     return Event.new(:change,self.to_ref)
        # end

        # Converts to a new reference.
        def to_ref
            return RefObject.new(this,self)
        end

        # Converts to a new expression.
        def to_expr
            return self.to_ref
        end

        # Converts the system to HDLRuby::Low and set its +name+.
        def to_low(name = self.name)
            return HDLRuby::Low::SignalI.new(name,self.type.to_low)
        end
    end

    
    ##
    # Module giving the properties of a high-level block.
    module HBlock
        High = HDLRuby::High

        # The namespace
        attr_reader :namespace

        # The return value when building the scope.
        attr_reader :return_value

        # Build the block by executing +ruby_block+.
        def build(&ruby_block)
            # # # High-level blocks can include inner signals.
            # # @inners ||= {}
            # Already there
            # # And therefore require a namespace.
            # @namespace ||= Namespace.new(self)
            # Build the block.
            # High.space_push(self)
            High.space_push(@namespace)
            @return_value = High.top_user.instance_eval(&ruby_block)
            High.space_pop
        end

        # Converts to a new reference.
        def to_ref
            return RefObject.new(this,self)
        end

        include HScope_missing
        # include Hmissing
        # alias h_missing method_missing

        # # Missing methods are looked for in the private namespace.
        # # 
        # # NOTE: it is ok to use the private namespace because the scope
        # # can only be accessed if it is available from its systemT.
        # def method_missing(m, *args, &ruby_block)
        #     # print "method_missing in class=#{self.class} with m=#{m}\n"
        #     if self.namespace.respond_to?(m) then
        #         self.namespace.send(m,*args,&ruby_block)
        #     else
        #         h_missing(m,*args,&ruby_block)
        #     end
        # end

        # # Adds inner signal +signal+.
        # def add_inner(signal)
        #     # Checks and add the signal.
        #     unless signal.is_a?(SignalI)
        #         raise "Invalid class for a signal instance: #{signal.class}"
        #     end
        #     if @inners.has_key?(signal.name) then
        #         raise "SignalI #{signal.name} already present."
        #     end
        #     @inners[signal.name] = signal
        # end

        # # Creates and adds a set of inners typed +type+ from a list of +names+.
        # #
        # # NOTE: a name can also be a signal, is which case it is duplicated. 
        # def make_inners(type, *names)
        #     names.each do |name|
        #         if name.respond_to?(:to_sym) then
        #             self.add_inner(SignalI.new(name,type,:inner))
        #         else
        #             signal = name.clone
        #             signal.dir = :inner
        #             self.add_inner(signal)
        #         end
        #     end
        # end

        # # Iterates over the inner signals.
        # #
        # # Returns an enumerator if no ruby block is given.
        # def each_inner(&ruby_block)
        #     # No ruby block? Return an enumerator.
        #     return to_enum(:each_inner) unless ruby_block
        #     # A block? Apply it on each inner signal instance.
        #     @inners.each_value(&ruby_block)
        # end
        # alias :each_signal :each_inner

        # ## Gets an inner signal by +name+.
        # def get_inner(name)
        #     return @inners[name]
        # end
        # alias :get_signal :get_inner

        # # Declares high-level bit inner signals named +names+.
        # def inner(*names)
        #     self.make_inners(bit,*names)
        # end
        
        # # Iterates over all the signals of the block and its sub block's ones.
        # def each_signal_deep(&ruby_block)
        #     # No ruby block? Return an enumerator.
        #     return to_enum(:each_signal_deep) unless ruby_block
        #     # A block?
        #     # First, apply on the signals of the block.
        #     self.each_signal(&ruby_block)
        #     # Then apply on each sub block. 
        #     self.each_block_deep do |block|
        #         block.each_signal_deep(&ruby_block)
        #     end
        # end

        # Creates and adds a new block executed in +mode+, with possible +name+
        # and built by executing +ruby_block+.
        def add_block(mode = nil, name = :"", &ruby_block)
            # Creates the block.
            block = High.make_block(mode,name,&ruby_block)
            # Adds it as a statement.
            self.add_statement(block)
            # Use its return value.
            return block.return_value
        end

        # Creates a new parallel block with possible +name+ and 
        # built from +ruby_block+.
        def par(name = :"", &ruby_block)
            return :par unless ruby_block
            self.add_block(:par,name,&ruby_block)
        end

        # Creates a new sequential block with possible +name+ and
        # built from +ruby_block+.
        def seq(name = :"", &ruby_block)
            return :seq unless ruby_block
            self.add_block(:seq,name,&ruby_block)
        end

        # Creates a new block with the current mode with possible +name+ and
        # built from +ruby_block+.
        def sub(name = :"", &ruby_block)
            self.add_block(self.mode,name,&ruby_block)
        end

        # Get the current mode of the block.
        #
        # NOTE: for name coherency purpose only. 
        def block
            return self.mode
        end

        # Need to be able to declare select operators
        include Hmux

        # Creates a new if statement with a +condition+ that when met lead
        # to the execution of the block in +mode+ generated by the +ruby_block+.
        #
        # NOTE: the else part is defined through the helse method.
        def hif(condition, mode = nil, &ruby_block)
            # Creates the if statement.
            self.add_statement(If.new(condition,mode,&ruby_block))
        end

        # Sets the block executed when the condition is not met to the block
        # in +mode+ generated by the execution of +ruby_block+.
        #
        # Can only be used once.
        def helse(mode = nil, &ruby_block)
            # There is a ruby_block: the helse is assumed to be with
            # the hif in the same block.
            # Completes the hif or the hcase statement.
            statement = @statements.last
            unless statement.is_a?(If) or statement.is_a?(Case) then
                raise "Error: helse statement without hif nor hcase (#{statement.class})."
            end
            statement.helse(mode, &ruby_block)
        end

        # Sets the condition check when the condition is not met to the block,
        # with a +condition+ that when met lead
        # to the execution of the block in +mode+ generated by the +ruby_block+.
        def helsif(condition, mode = nil, &ruby_block)
            # There is a ruby_block: the helse is assumed to be with
            # the hif in the same block.
            # Completes the hif statement.
            statement = @statements.last
            unless statement.is_a?(If) then
                raise "Error: helsif statement without hif (#{statement.class})."
            end
            statement.helsif(condition, mode, &ruby_block)
        end



        # Creates a new case statement with a +value+ used for deciding which
        # block to execute.
        #
        # NOTE: the when part is defined through the hwhen method.
        def hcase(value)
            # Creates the case statement.
            self.add_statement(Case.new(value))
        end

        # Sets the block of a case structure executed when the +match+ is met
        # to the block in +mode+ generated by the execution of +ruby_block+.
        #
        # Can only be used once.
        def hwhen(match, mode = nil, &ruby_block)
            # There is a ruby_block: the helse is assumed to be with
            # the hif in the same block.
            # Completes the hcase statement.
            statement = @statements.last
            unless statement.is_a?(Case) then
                raise "Error: hwhen statement without hcase (#{statement.class})."
            end
            statement.hwhen(match, mode, &ruby_block)
        end
    end


    ##
    # Describes a high-level block.
    class Block < Low::Block
        High = HDLRuby::High

        include HBlock
        include Hinner

        # Creates a new +mode+ sort of block, with possible +name+
        # and build it by executing +ruby_block+.
        def initialize(mode, name=:"", &ruby_block)
            # Initialize the block.
            super(mode,name)
            # # Save the Location for debugging information
            # @location = caller_locations

            unless name.empty? then
                # Named block, set the hdl-like access to the block.
                obj = self # For using the right self within the proc
                High.space_reg(name) { obj }
            end

            # Creates the namespace.
            @namespace = Namespace.new(self)

            # puts "methods = #{self.methods.sort}"
            build(&ruby_block)
        end

        # Converts the block to HDLRuby::Low.
        def to_low
            # Create the resulting block
            blockL = HDLRuby::Low::Block.new(self.mode)
            # Push the namespace for the low generation.
            High.space_push(@namespace)
            # Pushes on the name stack for converting the internals of
            # the block.
            High.names_push
            # Add the inner signals
            self.each_inner { |inner| blockL.add_inner(inner.to_low) }
            # Add the statements
            self.each_statement do |statement|
                blockL.add_statement(statement.to_low)
            end
            # Restores the name stack.
            High.names_pop
            # Restores the namespace stack.
            High.space_pop
            # Return the resulting block
            return blockL
        end
    end


    # Describes a timed block.
    #
    # NOTE: 
    # * this is the only kind of block that can include time statements. 
    # * this kind of block is not synthesizable!
    class TimeBlock < Low::TimeBlock
        High = HDLRuby::High

        include HBlock

        # Creates a new +type+ sort of block with possible +name+
        # and build it by executing +ruby_block+.
        def initialize(type, name = :"", &ruby_block)
            # Initialize the block.
            super(type,name)
            # # Save the Location for debugging information
            # @location = caller_locations

            unless name.empty? then
                # Named block, set the hdl-like access to the block.
                obj = self # For using the right self within the proc
                High.space_reg(name) { obj }
            end

            # Creates the namespace.
            @namespace = Namespace.new(self)

            build(&ruby_block)
        end

        # Adds a wait +delay+ statement in the block.
        def wait(delay)
            self.add_statement(TimeWait.new(delay))
        end

        # Adds a loop until +delay+ statement in the block in +mode+ whose
        # loop content is built using +ruby_block+.
        def repeat(delay, mode = nil, &ruby_block)
            # Build the content block.
            # content = High.make_block(:par,&ruby_block)
            content = High.make_block(mode,&ruby_block)
            # Create and add the statement.
            self.add_statement(TimeRepeat.new(content,delay))
        end

        # Converts the time block to HDLRuby::Low.
        def to_low
            # Create the resulting block
            blockL = HDLRuby::Low::TimeBlock.new(self.mode)
            # Add the inner signals
            self.each_inner { |inner| blockL.add_inner(inner.to_low) }
            # Add the statements
            self.each_statement do |statement|
                blockL.add_statement(statement.to_low)
            end
            # Return the resulting block
            return blockL
        end
    end


    # Creates a block executed in +mode+, with possible +name+,
    # that can be timed or not depending on the enclosing object and build
    # it by executing the enclosing +ruby_block+.
    #
    # NOTE: not a method to include since it can only be used with
    # a behavior or a block. Hence set as module method.
    def self.make_block(mode = nil, name = :"", &ruby_block)
        unless mode then
            # No type of block given, get a default one.
            if top_user.is_a?(Block) then
                # There is an upper block, use its mode.
                mode = top_user.mode
            else
                # There is no upper block, use :par as default.
                mode = :par
            end
        end
        if top_user.is_a?(TimeBlock) then
            # return TimeBlock.new(mode,from_users(:block_extensions),&ruby_block)
            return TimeBlock.new(mode,name,&ruby_block)
        else
            # return Block.new(mode,from_users(:block_extensions),&ruby_block)
            return Block.new(mode,name,&ruby_block)
        end
    end

    # Creates a specifically timed block in +mode+, with possible +name+
    # and build it by executing the enclosing +ruby_block+.
    #
    # NOTE: not a method to include since it can only be used with
    # a behavior or a block. Hence set as module method.
    def self.make_time_block(mode = nil, name = :"", &ruby_block)
        unless mode then
            # No type of block given, get a default one.
            if top_user.is_a?(Block) then
                # There is an upper block, use its mode.
                mode = block.mode
            else
                # There is no upper block, use :par as default.
                mode = :par
            end
        end
        # return TimeBlock.new(mode,top_user.block_extensions,&ruby_block)
        return TimeBlock.new(mode,name,&ruby_block)
    end

    ##
    # Describes a high-level behavior.
    class Behavior < Low::Behavior
        High = HDLRuby::High

        # # Creates a new behavior executing +block+ activated on a list of
        # # +events+, and built by executing +ruby_block+.
        # def initialize(*events,&ruby_block)
        #     # Initialize the behavior
        #     super()
        #     # Add the events.
        #     events.each { |event| self.add_event(event) }
        #     # Create a default par block for the behavior.
        #     block = High.make_block(:par,&ruby_block)
        #     self.add_block(block)
        #     # # Build the block by executing the ruby block in context.
        #     # High.space_push(block)
        #     # High.top_user.instance_eval(&ruby_block)
        #     # High.space_pop
        # end

        # Creates a new behavior executing +block+ activated on a list of
        # +events+, and built by executing +ruby_block+.
        # +mode+ can be either :seq or :par for respectively sequential or
        # parallel.
        def initialize(mode,*events,&ruby_block)
            # Create a default par block for the behavior.
            # block = High.make_block(:par,&ruby_block)
            # mode = nil
            # if events.last.respond_to?(:to_sym) then
            #     # A mode is given, use it.
            #     mode = events.pop.to_sym
            # end
            # Initialize the behavior with it.
            super(nil)
            # # Save the Location for debugging information
            # @location = caller_locations
            # Sets the current behavior
            @@cur_behavior = self
            # Add the events.
            events.each { |event| self.add_event(event) }
            # Create and add the block.
            self.block = High.make_block(mode,&ruby_block)
            # Unset the current behavior
            @@cur_behavior = nil
        end

        # Converts the time behavior to HDLRuby::Low.
        def to_low
            # Create the low level block.
            blockL = self.block.to_low
            # Create the low level events.
            eventLs = self.each_event.map { |event| event.to_low }
            # Create and return the resulting low level behavior.
            behaviorL = HDLRuby::Low::Behavior.new(blockL)
            eventLs.each(&behaviorL.method(:add_event))
            return behaviorL
        end
    end

    ##
    # Describes a high-level timed behavior.
    class TimeBehavior < Low::TimeBehavior
        High = HDLRuby::High

        # # Creates a new timed behavior built by executing +ruby_block+.
        # def initialize(&ruby_block)
        #     # Initialize the behavior
        #     super()
        #     # Create and add a default par block for the behavior.
        #     # NOTE: this block is forced to TimeBlock, so do not use
        #     # block(:par).
        #     block = High.make_time_block(:par,&ruby_block)
        #     # block = make_changer(TimeBlock).new(:par,&ruby_block)
        #     self.add_block(block)
        #     # # Build the block by executing the ruby block in context.
        #     # High.space_push(block)
        #     # High.top_user.instance_eval(&ruby_block)
        #     # High.space_pop
        # end

        # Creates a new timed behavior built by executing +ruby_block+.
        # +mode+ can be either :seq or :par for respectively sequential or
        def initialize(mode, &ruby_block)
            # Create a default par block for the behavior.
            block = High.make_time_block(mode,&ruby_block)
            # Initialize the behavior with it.
            super(block)
            # # Save the Location for debugging information
            # @location = caller_locations
        end

        # Converts the time behavior to HDLRuby::Low.
        def to_low
            # Create the low level block.
            blockL = self.block.to_low
            # Create the low level events.
            eventLs = self.each_event.map { |event| event.to_low }
            # Create and return the resulting low level behavior.
            behaviorL = HDLRuby::Low::TimeBehavior.new(blockL)
            eventLs.each(&behaviorL.method(:add_event))
            return behaviorL
        end
    end



    # # Ensures constants defined is this module are prioritary.
    # # @!visibility private
    # def self.included(base) # :nodoc:
    #     if base.const_defined?(:SignalI) then
    #         base.send(:remove_const,:SignalI)
    #         base.const_set(:SignalI,HDLRuby::High::SignalI)
    #     end
    # end



    # Handle the namespaces for accessing the hardware referencing methods.

    # The universe, i.e., the top system type.
    Universe = SystemT.new(:"") {} 

    # The universe does not have input, output, nor inout.
    class << Universe
        undef_method :input
        undef_method :output
        undef_method :inout
        undef_method :add_input
        undef_method :add_output
        undef_method :add_inout
    end


    # include Hmissing

    # The namespace stack: never empty, the top is a nameless system without
    # input nor output.
    Namespaces = [Universe.scope.namespace]
    private_constant :Namespaces

    # Pushes +namespace+.
    def self.space_push(namespace)
        # Emsure namespace is really a namespace.
        namespace = namespace.to_namespace
        # # Concat the current top to namespace so that it has access to the
        # # existing hardware constructs.
        # LALALA
        # # namespace.concat_namespace(Namespaces[-1])
        # Adds the namespace to the top.
        Namespaces.push(namespace)
    end

    # Inserts +namespace+ at +index+.
    def self.space_insert(index,namespace)
        Namespaces.insert(index.to_i,namespace.to_namespace)
    end

    # Pops a namespace.
    def self.space_pop
        if Namespaces.size <= 1 then
            raise "Internal error: cannot pop further namespaces."
        end
        Namespaces.pop
    end

    # Tells if +namespace+ in included within the stack.
    def self.space_include?(namespace)
        return Namespaces.include?(namespace)
    end

    # Gets the index of a +namespace+ within the stack.
    def self.space_index(namespace)
        return Namespaces.index(namespace)
    end

    # Gets the top of the namespaces stack.
    def self.space_top
        Namespaces[-1]
    end

    # Gets construct whose namespace is the top of the namespaces stack.
    def self.top_user
        self.space_top.user
    end

    # Gather the result of the execution of +method+ from all the users
    # of the namespaces.
    def self.from_users(method)
        Namespaces.reverse_each.reduce([]) do |res,space|
            user = space.user
            if user.respond_to?(method) then
                res += [*user.send(method)]
            end
        end
    end

    # Iterates over each namespace.
    #
    # Returns an enumerator if no ruby block is given.
    def self.space_each(&ruby_block)
        # No ruby block? Return an enumerator.
        return to_enum(:space_each) unless ruby_block
        # A block? Apply it on each system instance.
        Namespaces.each(&ruby_block)
    end

    # Tells if within a system type.
    def self.in_system?
        return Namespaces.size > 1
    end

    # Gets the enclosing system type if any.
    def self.cur_system
        if Namespaces.size <= 1 then
            raise "Not within a system type."
        else
            return Namespaces.reverse_each.find do |space|
                # space.user.is_a?(SystemT)
                space.user.is_a?(Scope) and space.user.parent.is_a?(SystemT)
            # end.user
            end.user.parent
        end
    end

    # The current behavior: by default none.
    @@cur_behavior = nil

    # Gets the enclosing behavior if any.
    def self.cur_behavior
        # # Gets the enclosing system type.
        # systemT = self.cur_system
        # # Gets the current behavior from it.
        # unless systemT.each_behavior.any? then
        #     raise "Not within a behavior."
        # end
        # # return systemT.each.reverse_each.first
        # return systemT.last_behavior
        return @@cur_behavior
    end

    # Tell if we are in a behavior.
    def self.in_behavior?
        top_user.is_a?(Block)
    end

    # Gets the enclosing block if any.
    #
    # NOTE: +level+ allows to get an upper block of the currently enclosing
    #       block.
    def self.cur_block(level = 0)
        if Namespaces[-1-level].user.is_a?(Block)
            return Namespaces[-1-level].user
        else
            raise "Not within a block: #{Namespaces[-1-level].user.class}"
        end
    end

    # Registers hardware referencing method +name+ to the current namespace.
    def self.space_reg(name,&ruby_block)
        # print "registering #{name} in #{Namespaces[-1]}\n"
        # # Register it in the top object of the namespace stack.
        # if Namespaces[-1].respond_to?(:define_method) then
        #     Namespaces[-1].send(:define_method,name.to_sym,&ruby_block)
        # else
        #     Namespaces[-1].send(:define_singleton_method,name.to_sym,&ruby_block)
        # end
        Namespaces[-1].add_method(name,&ruby_block)
    end

    # Looks up and calls method +name+ from the namespace stack with arguments
    # +args+ and block +ruby_block+.
    def self.space_call(name,*args,&ruby_block)
        # print "space_call with name=#{name}\n"
        # Ensures name is a symbol.
        name = name.to_sym
        # Look from the top of the namespace stack.
        Namespaces.reverse_each do |space|
            if space.respond_to?(name) then
                # print "Found is space user with class=#{space.user.class}\n"
                # The method is found, call it.
                return space.send(name,*args)
            end
        end
        # Look in the top namespace.
        # if Namespaces[-1].respond_to?(name) then
        #     # Found.
        #     return Namespaces[-1].send(name,*args,&ruby_block)
        # end
        # Look in the global methods.
        if HDLRuby::High.respond_to?(name) then
            # Found.
            return HDLRuby::High.send(name,*args,&ruby_block)
        end
        # Not found.
        raise NoMethodError.new("undefined local variable or method `#{name}'.")
    end




    


    # Extends the standard classes for support of HDLRuby.


    # Extends the Numeric class for conversion to a high-level expression.
    class ::Numeric

        # to_expr is to be defined in the subclasses of ::Numeric
        # # Converts to a new high-level expression.
        # def to_expr
        #     # return Value.new(numeric,self)
        #     return Value.new(TypeNumeric.new(:"",self),self)
        # end

        # Tell if the expression can be converted to a value.
        def to_value?
            return true
        end

        # Converts to a new high-level value.
        def to_value
            to_expr
        end

        # Converts to a new delay in picoseconds.
        def ps
            return Delay.new(self,:ps)
        end

        # Converts to a new delay in nanoseconds.
        def ns
            return Delay.new(self,:ns)
        end

        # Converts to a new delay in microseconds.
        def us
            return Delay.new(self,:us)
        end

        # Converts to a new delay in milliseconds.
        def ms
            return Delay.new(self,:ms)
        end

        # Converts to a new delay in seconds.
        def s
            return Delay.new(self,:s)
        end
    end

    # Extends the Integer class for computing the bit width.
    class ::Integer

        # Gets the bit width
        def width
            return Math.log2(self+1).ceil
        end
    end

    # Extends the Fixnum class for computing for conversion to expression.
    class ::Fixnum
        # Converts to a new high-level expression.
        def to_expr
            return Value.new(Integer,self)
        end
    end

    # Extends the Bignum class for computing for conversion to expression.
    class ::Bignum
        # Converts to a new high-level expression.
        def to_expr
            return Value.new(Bignum,self)
        end
    end

    # Extends the Float class for computing the bit width and conversion
    # to expression.
    class ::Float
        # Converts to a new high-level expression.
        def to_expr
            return Value.new(Real,self)
        end

        # Gets the bit width
        def width
            return 64
        end
    end


    # Extends the Hash class for declaring signals of structure types.
    class ::Hash

        # Converts to a new type.
        def to_type
            return TypeStruct.new(:"",self)
        end

        # Declares a new type definition with +name+ equivalent to current one.
        def typedef(name)
            return self.to_type.typedef(name)
        end

        # Declares high-level input signals named +names+ of the current type.
        def input(*names)
            names.each do |name|
                HDLRuby::High.top_user.
                    add_input(SignalI.new(name,TypeStruct.new(:"",self),:input))
            end
        end

        # Declares high-level untyped output signals named +names+ of the
        # current type.
        def output(*names)
            names.each do |name|
                HDLRuby::High.top_user.
                    add_output(SignalI.new(name,TypeStruct.new(:"",self),:output))
            end
        end

        # Declares high-level untyped inout signals named +names+ of the
        # current type.
        def inout(*names)
            names.each do |name|
                HDLRuby::High.top_user.
                    add_inout(SignalI.new(name,TypeStruct.new(:"",self),:inout))
            end
        end

        # Declares high-level untyped inner signals named +names+ of the
        # current type.
        def inner(*names)
            names.each do |name|
                HDLRuby::High.top_user.
                    add_inner(SignalI.new(name,TypeStruct.new(:"",self),:inner))
            end
        end
    end


    # Extends the Array class for conversion to a high-level expression.
    class ::Array
        include HArrow

        # Converts to a new high-level expression.
        def to_expr
            # expr = Concat.new
            expr = Concat.new(TypeTuple.new(:"",*self.map do |elem|
                elem.to_expr.type
            end))
            self.each {|elem| expr.add_expression(elem.to_expr) }
            expr
        end

        # Converts to a new high-level reference.
        def to_ref
            # expr = RefConcat.new
            expr = RefConcat.new(TypeTuple.new(:"",*self.map do |elem|
                elem.to_ref.type
            end))
            self.each {|elem| expr.add_ref(elem.to_ref) }
            expr
        end

        # Converts to a new type.
        def to_type
            if self.size == 1 and
               ( self[0].is_a?(Range) or self[0].respond_to?(:to_i) ) then
                # Vector type case
                return bit[*self]
            else
                # Tuple type case.
                return TypeTuple.new(:"",*self)
            end
        end

        # Declares a new type definition with +name+ equivalent to current one.
        def typedef(name)
            return self.to_type.typedef(name)
        end

        # SignalI creation through the array take as type.

        # Declares high-level input signals named +names+ of the current type.
        def input(*names)
            High.top_user.make_inputs(self.to_type,*names)
        end

        # Declares high-level untyped output signals named +names+ of the
        # current type.
        def output(*names)
            High.top_user.make_outputs(self.to_type,*names)
        end

        # Declares high-level untyped inout signals named +names+ of the
        # current type.
        def inout(*names)
            High.top_user.make_inouts(self.to_type,*names)
        end

        # Declares high-level untyped inner signals named +names+ of the
        # current type.
        def inner(*names)
            High.top_user.make_inners(self.to_type,*names)
        end

        # Array construction shortcuts

        # Create an array whose number of elements is given by the content
        # of the current array, filled by +obj+ objects.
        # If +obj+ is nil, +ruby_block+ is used instead for filling the array.
        def call(obj = nil, &ruby_block)
            unless self.size == 1 then
                raise "Invalid array for call opertor."
            end
            number = self[0].to_i
            if obj then
                return Array.new(number,obj)
            else
                return Array.new(number,&ruby_block)
            end
        end

        # # Create an array of instances obtained by instantiating the elements
        # # using +args+ as argument and register the result to +name+.
        # #
        # # NOTE: the instances are unnamed since it is the resulting array
        # # that is registered.
        # def make(name,*args)
        #     # Instantiate the types.
        #     instances = self.map { |elem| elem.instantiate(:"",*args) }
        #     # Add them to the top system
        #     High.space_top.user.add_groupI(name,*instances)
        #     # Register and return the result.
        #     High.space_reg(name) { High.space_top.user.get_groupI(name) }
        #     return High.space_top.user.get_groupI(name)
        # end

        # Create an array of instances of system +name+, using +args+ as
        # arguments.
        #
        # NOTE: the array must have a single element that is an integer.
        def make(name,*args)
            # Check the array and get the number of elements.
            size = self[0]
            unless self.size == 1 and size.is_a?(::Integer)
                raise "Invalid array for declaring a list of instances."
            end
            # Get the system to instantiate.
            systemT = High.space_call(name)
            # Get the name of the instance from the arguments.
            nameI = args.shift.to_s
            # Create the instances.
            instances = size.times.map do |i| 
                systemT.instantiate((nameI + "[#{i}]").to_sym,*args)
            end
            nameI = nameI.to_sym
            # Add them to the top system
            High.space_top.user.add_groupI(nameI,*instances)
            # Register and return the result.
            High.space_reg(nameI) { High.space_top.user.get_groupI(nameI) }
            return High.space_top.user.get_groupI(nameI)
        end
    end


    # Extends the symbol class for auto declaration of input or output.
    class ::Symbol
        High = HDLRuby::High

        # # Converts to a new high-level expression.
        # def to_expr
        #     self.to_ref
        # end

        # # Converts to a new high-level reference refering to an unbounded signal.
        # def to_ref
        #     # Create the unbounded signal and add it to the upper system type.
        #     signal = SignalI.new(self,void,:no)
        #     High.cur_system.add_unbound(signal)
        #     # Convert it to a reference and return the result.
        #     return signal.to_ref
        # end
        # alias :+@ :to_ref

        # Tell if the expression can be converted to a value.
        def to_value?
            return true
        end

        # Converts to a new value.
        #
        # Returns nil if no value can be obtained from it.
        def to_value
            str = self.to_s
            # puts "str=#{str}"
            return nil if str[0] != "_" # Bit string are prefixed by "_"
            # Remove the "_" not needed any longer.
            str = str[1..-1]
            # Get and check the type
            type = str[0]
            if type == "0" or type == "1" then
                # Default binary
                type = "b"
            else
                # Not a default type
                str = str[1..-1]
            end
            return nil if str.empty?
            return nil unless ["b","u","s"].include?(type)
            # Get the width if any.
            if str[0].match(/[0-9]/) then
                width = str.scan(/[0-9]*/)[0]
            else
                width = nil
            end
            # puts "width=#{width}"
            old_str = str # Save the string it this state since its first chars
                          # can be erroneously considered as giving the width
            str = str[width.size..-1] if width
            # Get the base and the value
            base = str[0]
            # puts "base=#{base}\n"
            unless ["b", "o", "d", "h"].include?(base) then
                # No base found, default is bit
                base = "b"
                # And the width was actually a part of the value.
                value = old_str
                width = nil
            else
                # Get the value.
                value = str[1..-1]
            end
            # puts "value=#{value}"
            # Compute the bit width and the value
            case base
            when "b" then
                # base 2, compute the width
                width = width ? width.to_i : value.size
                # # Check the value
                # if value.match(/^[0-1]+$/) then
                #     # Numeric value, compute the corresponding integer
                #     value = value.to_i(2)
                # elsif !value.match(/^[0-1zxZX]+$/) then
                #     # Invalid value.
                #     return nil
                # end
                # Check the value
                return nil unless value.match(/^[0-1zxZX]+$/)
            when "o" then
                # base 8, compute the width
                width = width ? width.to_i : value.size * 3
                # Check the value
                # if value.match(/^[0-7]+$/) then
                #     # Numeric value, compute the corresponding integer
                #     value = value.to_i(8)
                # elsif value.match(/^[0-7xXzZ]+$/) then
                if value.match(/^[0-7xXzZ]+$/) then
                    # 4-state value, conpute the correspondig bit string.
                    value = value.each_char.map do |c|
                        c = c.upcase
                        if c == "X" or c.upcase == "Z" then
                            c * 3
                        else
                            c.to_i(8).to_s(2).rjust(3,"0")
                        end
                    end.join
                else
                    # Invalid value
                    return nil
                end
            when "d" then
                # base 10, compute the width 
                width = width ? width.to_i : value.to_i.to_s(2).size + 1
                # Check the value
                return nil unless value.match(/^[0-9]+$/)
                # Compute it (base 10 values cannot be 4-state!)
                value = value.to_i.to_s(2)
            when "h" then
                # base 16, compute the width
                width = width ? width.to_i : value.size * 4
                # Check the value
                # if value.match(/^[0-9a-fA-F]+$/) then
                #     # Numeric value, compute the corresponding integer
                #     value = value.to_i(16)
                # elsif value.match(/^[0-9a-fA-FxXzZ]+$/) then
                if value.match(/^[0-9a-fA-FxXzZ]+$/) then
                    # 4-state value, conpute the correspondig bit string.
                    value = value.each_char.map do |c|
                        c = c.upcase
                        if c == "X" or c.upcase == "Z" then
                            c * 4
                        else
                            c.to_i(16).to_s(2).rjust(4,"0")
                        end
                    end.join
                else
                    # Invalid value
                    return nil
                end
            else
                # Unknown base
                return nil
            end
            # Compute the type.
            case type
            when "b" then
                type = bit[width]
            when "u" then
                type = unsigned[width]
            when "s" then
                type = signed[width]
            else
                # Unknown type
                return nil
            end
            # puts "type=#{type}, value=#{value}"
            # Create and return the value.
            # return Value.new(type,HDLRuby::BitString.new(value))
            return Value.new(type,value)
        end
    end

    # Extends the range class to support to_low
    class ::Range
        # Convert the first and last to HDLRuby::Low
        def to_low
            first = self.first
            first = first.respond_to?(:to_low) ? first.to_low : first
            last = self.last
            last = last.respond_to?(:to_low) ? last.to_low : last
            return (first..last)
        end

        # Iterates over the range as hardware.
        #
        # Returns an enumerator if no ruby block is given.
        def heach(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:heach) unless ruby_block
            # Order the bounds to be able to iterate.
            first,last = self.first, self.last
            first,last = first > last ? [last,first] : [first,last]
            # Iterate.
            (first..last).each(&ruby_block)
        end
    end




    # Method and attribute for generating an absolute uniq name.
    # Such names cannot be used in HDLRuby::High code, but can be used
    # to generate such code.

    @@absoluteCounter = -1 # The absolute name counter.

    # Generates an absolute uniq name.
    def self.uniq_name
        @@absoluteCounter += 1
        return ":#{@@absoluteCounter}".to_sym
    end




    
    # Methods for managing the conversion to HDLRuby::Low

    # Methods for generating uniq names in context

    # The stack of names for creating new names without conflicts.
    NameStack = [ Set.new ]

    # Pushes on the name stack.
    def self.names_push
        NameStack.push(Set.new)
    end

    # Pops from the name stack.
    def self.names_pop
        NameStack.pop
    end

    # Adds a +name+ to the top of the stack.
    def self.names_add(name)
        NameStack[-1].add(name.to_s)
    end

    # Checks if a +name+ is present in the stack.
    def self.names_has?(name)
        NameStack.find do |names|
            names.include?(name)
        end 
    end

    # Creates and adds the new name from +base+ that do not collides with the
    # exisiting names.
    def self.names_create(base)
        base = base.to_s.clone
        # Create a non-conflicting name
        while(self.names_has?(base)) do
            base << "_"
        end
        # Add and return it
        self.names_add(base)
        # puts "created name: #{base}"
        return base.to_sym
    end




    # Standard vector types.
    Integer = TypeSigned.new(:integer)
    Natural = TypeUnsigned.new(:natural)
    Bignum  = TypeSigned.new(:bignum,HDLRuby::Infinity..0)
    Real    = TypeFloat.new(:float)


end

# Tell if already configured.
$HDLRuby_configure = false

# Enters in HDLRuby::High mode.
def self.configure_high
    if $HDLRuby_configure then
        # Already configured.
        return
    end
    # Now HDLRuby will be configured.
    $HDLRuby_configure = true
    include HDLRuby::High
    class << self
        # For main, missing methods are looked for in the namespaces.
        def method_missing(m, *args, &ruby_block)
            # print "method_missing in class=#{self.class} with m=#{m}\n"
            # Is the missing method an immediate value?
            value = m.to_value
            return value if value and args.empty?
            # puts "Universe methods: #{Universe.namespace.methods}"
            # Not a value, but maybe it is in the namespaces
            if Namespaces[-1].respond_to?(m) then
                # Yes use it.
                Namespaces[-1].send(m,*args,&ruby_block)
            else
                # No, true error
                raise NoMethodError.new("undefined local variable or method `#{m}'.")
            end
        end
    end

    # Generate the standard signals
    # $clk = SignalI.new(:__universe__clk__,Bit,:inner)
    # $rst = SignalI.new(:__universe__rst__,Bit,:inner)
    $clk = Universe.scope.inner :__universe__clk__
    $rst = Universe.scope.inner :__universe__rst__



    # Tells HDLRuby has finised booting.
    def self.booting?
        false
    end
end
