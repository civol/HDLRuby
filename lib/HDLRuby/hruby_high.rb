require "HDLRuby/hruby_base"
require "HDLRuby/hruby_low"
require "HDLRuby/hruby_bstr"

require 'set'

##
# High-level libraries for describing digital hardware.        
#######################################################
module HDLRuby::High

    Base = HDLRuby::Base
    Low  = HDLRuby::Low

    # Some useful constants

    Infinity = +1.0/0.0
    
    # Gets the infinity.
    def infinity
        return HDLRuby::High::Infinity
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

        # The construct using the namespace.
        attr_reader :user

        # Creates a new namespace attached to +user+.
        def initialize(user)
            # Sets the user.
            @user = user
            # Initialize the concat namespaces.
            @concats = []
        end

        # Adds an access point by +name+ provided the name is not empty.
        def add(name,&ruby_block)
            unless name.empty? then
                define_singleton_method(name,&ruby_block) 
            end
        end

        # Concats another +namespace+ to current one.
        def concat(namespace)
            # # Ensure namespace is really a namespace
            # namespace = namespace.to_namespace
            # # Adds its singleton methods to current namespace
            # namespace.singleton_methods.each do |method|
            #     self.add(method,&namespace.singleton_method(method))
            # end
            
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
            # Maybe object is the user of this namespace.
            return true if user?(object)
            # No, try in the concat namespaces.
            @concats.any? { |concat| concat.user_deep?(object) }
        end
    end


    # ##
    # # Module providing mixin properties to hardware types.
    # module HMix
    #     # Tells this is a hardware type supporting mixins.
    #     #
    #     # NOTE: only there for being checked through respond_to?
    #     def hmix?
    #         return true
    #     end

    #     # Mixins hardware types +htypes+.
    #     def include(*htypes)
    #         # Initialize the list of mixins hardware types if required.
    #         @includes ||= []
    #         # Check and add the hardware types.
    #         htypes.each do |htype|
    #             unless htype.respond_to?(:hmix?) then
    #                 raise "Invalid class for mixin: #{htype.class}"
    #             end
    #             @includes << htype
    #         end
    #     end

    #     # # Mixins hardware types +htypes+ by extension.
    #     # def extend(htypes)
    #     #     # Initialize the list of mixins hardware types if required.
    #     #     @extends ||= []
    #     #     # Check and add the hardware types.
    #     #     htypes.each do |htype|
    #     #         unless htype.respond_to?(:hmix?) then
    #     #             raise "Invalid class for mixin: #{htype.class}"
    #     #         end
    #     #         @includes << htype
    #     #     end
    #     # end
    # end



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
            elsif self.respond_to?(:private_namespace) and
                  High.space_index(self.private_namespace) then
                # Yes, the private namespace is in it, can try the methods in
                # the space.
                High.space_call(m,*args,&ruby_block)
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
            return Select.new("?",select.to_expr,*choices)
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
                        names.each do |name|
                            if name.respond_to?(:to_sym) then
                                self.add_inner(SignalI.new(name,type,:inner))
                            else
                                # Deactivated because conflict with parent.
                                # signal = name.clone
                                # signal.dir = :inner
                                # self.add_inner(signal)
                                raise "Invalid class for a name: #{name.class}"
                            end
                        end
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
    class SystemT < Base::SystemT
        High = HDLRuby::High

        # include HMix
        include Hinner

        include SingletonExtend

        # The private namespace
        attr_reader :private_namespace

        # The public namespace
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
            super(name)

            # Initialize the set of grouped system instances.
            @groupIs = {}

            # Initialize the set of extensions to transmit to the instances'
            # eigen class
            @singleton_instanceO = Namespace.new(self)

            # Creates the private and the public namespaces.
            @private_namespace = Namespace.new(self)
            @public_namespace = Namespace.new(self)

            # Check and set the mixins.
            mixins.each do |mixin|
                unless mixin.is_a?(SystemT) then
                    raise "Invalid class for inheriting: #{mixin.class}."
                end
            end
            @to_includes = mixins
            # Prepare the instantiation methods
            make_instantiater(name,SystemI,:add_systemI,&ruby_block)
            # # Initialize the set of unbounded signals.
            # @unbounds = {}

            # Initialize the set of exported inner signals and instances
            @exports = {}
            # Initialize the set of included system instances.
            @includeIs = {}
        end

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

        # Creates and adds a set of inputs typed +type+ from a list of +names+.
        #
        # NOTE: a name can also be a signal, is which case it is duplicated. 
        def make_inputs(type, *names)
            names.each do |name|
                if name.respond_to?(:to_sym) then
                    # self.add_input(SignalI.new(rn!(name),type,:input))
                    self.add_input(SignalI.new(name,type,:input))
                else
                    # Deactivated because conflict with parent.
                    # signal = name.clone
                    # signal.dir = :input
                    # self.add_input(signal)
                    raise "Invalid class for a name: #{name.class}"
                end
            end
        end

        # Creates and adds a set of outputs typed +type+ from a list of +names+.
        #
        # NOTE: a name can also be a signal, is which case it is duplicated. 
        def make_outputs(type, *names)
            # puts "type=#{type.inspect}"
            names.each do |name|
                # puts "name=#{name}"
                if name.respond_to?(:to_sym) then
                    # self.add_output(SignalI.new(rn!(name),type,:output))
                    self.add_output(SignalI.new(name,type,:output))
                else
                    # Deactivated because conflict with parent.
                    # signal = name.clone
                    # signal.dir = :output
                    # self.add_output(signal)
                    raise "Invalid class for a name: #{name.class}"
                end
            end
        end

        # Creates and adds a set of inouts typed +type+ from a list of +names+.
        #
        # NOTE: a name can also be a signal, is which case it is duplicated. 
        def make_inouts(type, *names)
            names.each do |name|
                if name.respond_to?(:to_sym) then
                    # self.add_inout(SignalI.new(rn!(name),type,:inout))
                    self.add_inout(SignalI.new(name,type,:inout))
                else
                    # Deactivated because conflict with parent.
                    # signal = name.clone
                    # signal.dir = :inout
                    # self.add_inout(signal)
                    raise "Invalid class for a name: #{name.class}"
                end
            end
        end

        # Creates and adds a set of inners typed +type+ from a list of +names+.
        #
        # NOTE: a name can also be a signal, is which case it is duplicated. 
        def make_inners(type, *names)
            names.each do |name|
                if name.respond_to?(:to_sym) then
                    # self.add_inner(SignalI.new(rn!(name),type,:inner))
                    self.add_inner(SignalI.new(name,type,:inner))
                else
                    # Deactivated because conflict with parent.
                    # signal = name.clone
                    # signal.dir = :inner
                    # self.add_inner(signal)
                    raise "Invalid class for a name: #{name.class}"
                end
            end
        end

        # # Iterates over all the signals of the system type and its system
        # # instances.
        # def each_signal_deep(&ruby_block)
        #     # No ruby block? Return an enumerator.
        #     return to_enum(:each_signal_deep) unless ruby_block
        #     # A block?
        #     # First, apply on the signals and and system instances.
        #     super(&ruby_block)
        #     # Apply on the behaviors (since in HDLRuby:High, blocks can
        #     # include signals).
        #     self.each_behavior do |behavior|
        #         behavior.block.each_signal_deep(&ruby_block)
        #     end
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
        end

        # # Gets an exported element (signal or system instance) by +name+.
        # def get_export(name)
        #     # Maybe it is an interface signal.
        #     signal = self.get_input(name)
        #     return signal if signal
        #     signal = self.get_output(name)
        #     return signal if signal
        #     signal = self.get_inout(name)
        #     return signal if signal
        #     # No, may be it is an inner signal or an instance explicitely
        #     # exported
        #     return @exports[name.to_sym]
        # end

        # Gets class containing the extension for the instances.
        def singleton_instance
            @singleton_instanceO.singleton_class
        end

        # Opens for extension.
        #
        # NOTE: actually executes +ruby_block+ in the context.
        def open(&ruby_block)
            # High.space_push(self)
            High.space_push(@private_namespace)
            High.top_user.instance_eval(&ruby_block)
            # High.top_user.postprocess
            High.space_pop
        end

        # The proc used for instantiating the system type.
        attr_reader :instance_proc
        
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

        # Instantiate the system type to an instance named +i_name+ with
        # possible arguments +args+.
        def instantiate(i_name,*args)
            # Create the eigen type.
            eigen = self.class.new(:"")
            # Extends eigen with self.
            eigen.extend(self)
            # High.space_push(eigen)
            High.space_push(eigen.private_namespace)
            # Fills its namespace with the content of the current system type
            # (this latter may already contains access points if it has been
            #  opended for extension previously).
            eigen.private_namespace.concat(@private_namespace)
            # Include the mixin systems given when declaring the system.
            @to_includes.each { |system| eigen.include(system) }
            # Execute the instantiation block
            High.top_user.instance_exec(*args,&@instance_proc) if @instance_proc
            # High.top_user.postprocess
            High.space_pop
            
            # Fill the public namespace
            space = eigen.public_namespace
            # Interface signals
            eigen.each_signal do |signal|
                if signal.dir != :inner then
                    space.send(:define_singleton_method,signal.name) { signal }
                end
            end
            # Export objects
            eigen.each_export do |export|
                space.send(:define_singleton_method,export.name) { export }
            end

            # Create the instance.
            instance = @instance_class.new(i_name,eigen)
            # Link it to its eigen system
            eigen.owner = instance
            # Extend it.
            instance.eigen_extend(@singleton_instanceO)
            # Return the resulting instance
            return instance
        end

        # Generates the instantiation capabilities including an instantiation
        # method +name+ for hdl-like instantiation, target instantiation as
        # +klass+, added to the calling object with +add_instance+, and
        # whose eigen type is initialized by +ruby_block+.
        def make_instantiater(name,klass,add_instance,&ruby_block)
            # Set the instanciater.
            @instance_proc = ruby_block
            # Set the target instantiation class.
            @instance_class = klass

            # Unnamed types do not have associated access method.
            return if name.empty?

            # Set the hdl-like instantiation method.
            # HDLRuby::High.send(:define_method,name.to_sym) do |i_name,*args|
            #     # Instantiate.
            #     instance = self.instantiate(i_name,*args)
            #     # Add the instance.
            #     binding.receiver.send(add_instance,instance)
            # end
            obj = self # For using the right self within the proc
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
                # Return the last instance.
                instance
            end
            # High.space_reg(name) do |i_name,*args|
            #     # Instantiate.
            #     instance = obj.instantiate(i_name,*args)
            #     # Add the instance.
            #     High.top_user.send(add_instance,instance)
            # end
        end

        # Tells if the system type is generic or not.
        #
        # NOTE: a system type is generic if one of its signal is generic.
        def generic?
            return self.each_signal_deep.any? do |signal|
                signal.type.generic?
            end
        end

        # # Set up the parent structure of the whole system.
        # def make_parents_deep
        #     # Connections.
        #     self.each_connection_deep.each(:make_parents_deep)
        #     # Statements.
        #     self.each_statement_deep.each(:make_parents_deep)
        # end

        # # Resolves the unknown signal types and conflicts.
        # def resolve_types
        #     # Gather each typed construction and parition them among the
        #     # the processable and the non processable (e.g.: void + void
        #     # cannot be processed as is.)
        #     typed_pro = []
        #     typed_unk = {}
        #     self.each_typed_deep do |typed|
        #         if typed.ref? then
        #             # Reference cases.
        #             if typed.type.generic? then
        #                 # The reference's type is not processable yet.
        #                 typed_unk[self.get_signal(typed)] << typed
        #             else
        #                 # The regerence's type is processable.
        #                 typed_pro << typed
        #             end
        #         else
        #             # Other cases: look for a non-generically typed child.
        #             if typed.each_child.any? {|child|!child.type.generic? } then
        #                 # The typed object is processable.
        #                 typed_pro << typed
        #             else
        #                 # The typed object is not processable yet.
        #                 typed.each_child do |child|
        #                     if child.ref? then
        #                         typed_unk[self.get_signal(typed)] << typed
        #                     else
        #                         typed_unk[child] << typed
        #                     end
        #                 end
        #             end
        #         end
        #     end

        #     # Process the processable types until there is no unprocessable
        #     # types left.
        #     begin
        #         resolved = []
        #         typed_pro.each do |typed|
        #             unless typed.resolve_type(self) then
        #                 raise "Internal error: type unresolvable."
        #             end
        #             ICIICI
        #             resolved_signals += arrow.each_ref.map do |ref|
        #                 self.get_signal(ref)
        #             end
        #         end
        #         typed_pro = resolved_signals.each.reduce([]) do |ar,signal|
        #             ar.concat(typed_unk[signal])
        #         end
        #     end while !typed_pro.empty?
        # end
            


        # # Missing methods may be immediate values, if not, they are looked up
        # # in the upper level of the namespace.
        # def method_missing(m, *args, &ruby_block)
        #     print "method_missing in class=#{self.class} with m=#{m}\n"
        #     # Is the missing method an immediate value?
        #     value = m.to_value
        #     return value if value and args.empty?
        #     # # No, maybe it is an exported construct from an included system
        #     # # provided there are no arguments.
        #     # if args.empty? then
        #     #     @includeIs.each_value do |systemI|
        #     #         construct = systemI.get_export(m)
        #     #         return construct if construct
        #     #     end
        #     # end
        #     # No look in the upper level of the name space
        #     High.space_call(m,*args,&ruby_block)
        # end

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

        # Declares a high-level behavior activated on a list of +events+, and
        # built by executing +ruby_block+.
        def behavior(*events, &ruby_block)
            # Preprocess the events.
            events.map! do |event|
                event.to_event
            end
            # Create and add the resulting behavior.
            self.add_behavior(Behavior.new(*events,&ruby_block))
        end

        # Declares a high-level timed behavior built by executing +ruby_block+.
        def timed(&ruby_block)
            # Create and add the resulting behavior.
            self.add_behavior(TimeBehavior.new(&ruby_block))
        end


        # Creates a new parallel block built from +ruby_block+.
        #
        # This methods first creates a new behavior to put the block in.
        def par(&ruby_block)
            self.behavior do
                par(&ruby_block)
            end
        end

        # Creates a new sequential block built from +ruby_block+.
        #
        # This methods first creates a new behavior to put the block in.
        def seq(&ruby_block)
            self.behavior do
                seq(&ruby_block)
            end
        end

        # Sets the constructs corresponding to +names+ as exports.
        def export(*names)
            names.each {|name| self.add_export(name) }
        end

        # Extend the class according to another +system+.
        def extend(system)
            # Adds the singleton methods
            # system.singleton_methods.each do |name|
            #     unless self.respond_to?(name) then
            #         self.define_singleton_method(name,
            #                                      system.singleton_method(name))
            #     end
            # end
            self.eigen_extend(system)
            # Adds the singleton methods for the instances.
            # iClass = system.singleton_instance
            # iClass.singleton_methods.each do |name|
            #     unless @singleton_instance.respond_to?(name) then
            #         @singleton_instance.define_singleton_method(name,
            #                     iClass.singleton_method(name))
            #     end
            # end
            @singleton_instanceO.eigen_extend(system.singleton_instance)
        end

        # Include another +system+ type with possible +args+ instanciation
        # arguments.
        def include(system,*args)
            if @includeIs.key?(system.name) then
                raise "Cannot include twice the same system."
            end
            # Extends with system.
            self.extend(system)
            # Create the instance to include
            instance = system.instantiate(:"",*args)
            # Concat its public namespace to the current one.
            self.private_namespace.concat(instance.public_namespace)
            # Adds it the list of includeds
            @includeIs[system.name] = instance
        end

        # Casts as an included +system+.
        def as(system)
            system = system.name if system.respond_to?(:name)
            return @includeIs[system].public_namespace
        end

        include Hmux

        # Fills a low level system with self's contents.
        #
        # NOTE: name conflicts are treated in the current NameStack state.
        def fill_low(systemTlow)
            # Adds its input signals.
            self.each_input { |input|  systemTlow.add_input(input.to_low) }
            # Adds its output signals.
            self.each_output { |output| systemTlow.add_output(output.to_low) }
            # Adds its inout signals.
            self.each_inout { |inout|  systemTlow.add_inout(inout.to_low) }
            # Adds the inner signals.
            self.each_inner { |inner|  systemTlow.add_inner(inner.to_low) }
            # Adds the instances.
            # Single ones.
            self.each_systemI { |systemI|
                systemTlow.add_systemI(systemI.to_low) 
            }
            # Grouped ones.
            self.each_groupI do |name,systemIs|
                systemIs.each.with_index { |systemI,i|
                    # Sets the name of the system instance
                    # (required for conversion of further accesses).
                    # puts "systemI.respond_to?=#{systemI.respond_to?(:name=)}"
                    systemI.name = name.to_s + "[#{i}]"
                    # And convert it to low
                    systemTlow.add_systemI(systemI.to_low())
                }
            end
            # Adds the connections.
            self.each_connection { |connection|
                systemTlow.add_connection(connection.to_low)
            }
            # Adds the behaviors.
            self.each_behavior { |behavior|
                systemTlow.add_behavior(behavior.to_low)
            }
        end

        # Converts the system to HDLRuby::Low and set its +name+.
        def to_low(name = self.name)
            name = name.to_s
            if name.empty? then
                raise "Cannot convert a system without a name to HDLRuby::Low."
            end
            # Create the resulting low system type.
            systemTlow = HDLRuby::Low::SystemT.new(High.names_create(name))
            # # Push the low conversion stack.
            # High.low_push(self)
            # Push the private namespace for the low generation.
            High.space_push(@private_namespace)
            # Pushes on the name stack for converting the internals of
            # the system.
            High.names_push
            # Adds the content of its included systems.
            @includeIs.each_value { |space| space.user.fill_low(systemTlow) }
            # Adds the content of the actual system.
            self.fill_low(systemTlow)
            # Restores the name stack.
            High.names_pop
            # # Restores the low conversion stack.
            # High.low_pop
            # Restores the namespace stack.
            High.space_pop
            # Return theresulting system.
            return systemTlow
        end
    end

    # Methods for declaring system types.

    # Declares a high-level system type named +name+, with +includes+ mixins
    # hardware types and using +ruby_block+ for instantiating.
    def system(name = :"", *includes, &ruby_block)
        # print "system ruby_block=#{ruby_block}\n"
        # Creates the resulting system.
        return SystemT.new(name,*includes,&ruby_block)
        # return make_changer(SystemT).new(name,*includes,&ruby_block)
    end
    

    ##
    # Module bringing high-level properties to Type classes.
    #
    # NOTE: by default a type is not specified.
    module Htype
        High = HDLRuby::High

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

        # The widths of the basic types.
        WIDTHS = { :bit => 1, :unsigned => 1, :signed => 1,
                   :fixnum => 32, :float => 64, :bignum => High::Infinity }

        # The signs of the basic types.
        SIGNS = { :signed => true, :fixnum => true, :float => true,
                  :bignum => true }
        SIGNS.default = false

        # Gets the bitwidth of the type, nil for undefined.
        #
        # NOTE: must be redefined for specific types.
        def width
            return WIDTHS[self.name]
        end

        # Tells if the type signed, false for unsigned.
        def signed?
            return SIGNS[self.name]
        end

        # # Tells if the type is specified or not.
        # def void?
        #     return self.name == :void
        # end

        # # Tells if a type is generic or not.
        # def generic?
        #     return self.void?
        # end

        # Checks the compatibility with +type+
        def compatible?(type)
            # # If type is void, compatible anyway.
            # return true if type.name == :void
            # Default: base types cases.
            case self.name
            # when :void then
            #     # void is compatible with anything.
            #     return true
            when :bit then
                # bit is compatible with bit signed and unsigned.
                return [:bit,:signed,:unsigned].include?(type.name)
            when :signed then
                # Signed is compatible with bit and signed.
                return [:bit,:signed].include?(type.name)
            when :unsigned then
                # Unsigned is compatible with bit and unsigned.
                return [:bit,:unsigned].include?(type.name)
            else
                # Unknown type for compatibility: not compatible by default.
                return false
            end
        end

        # Merges with +type+
        def merge(type)
            # # If type is void, return self.
            # return self if type.name == :void
            # Default: base types cases.
            case self.name
            # when :void then
            #     # void: return type
            #     return type
            when :bit then
                # bit is compatible with bit signed and unsigned.
                if [:bit,:signed,:unsigned].include?(type.name) then
                    return type
                else
                    raise "Incompatible types for merging: #{self}, #{type}."
                end
            when :signed then
                # Signed is compatible with bit and signed.
                if [:bit,:signed].include?(type.name) then
                    return self
                else
                    raise "Incompatible types for merging: #{self}, #{type}."
                end
            when :unsigned then
                # Unsigned is compatible with bit and unsigned.
                if [:bit,:unsigned].include?(type.name)
                    return self
                else
                    raise "Incompatible types for merging: #{self}, #{type}."
                end
            else
                # Unknown type for compatibility: not compatible by default.
                raise "Incompatible types for merging: #{self}, #{type}."
            end
        end


        # # Instantiate the type with arguments +args+ if required.
        # #
        # # NOTE: actually, only TypeSystemT actually require instantiation.
        # def instantiate
        #     self
        # end

        # Type creation in HDLRuby::High.

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
    end


    ##
    # Describes a high-level data type.
    #
    # NOTE: by default a type is not specified.
    class Type < Base::Type
        High = HDLRuby::High

        include Htype

        # Type creation.

        # Creates a new type named +name+.
        def initialize(name)
            # Initialize the type structure.
            super(name)
        end

        # Converts the type to HDLRuby::Low and set its +name+.
        #
        # NOTE: should be overridden by other type classes.
        def to_low(name = self.name)
            return HDLRuby::Low::Type.new(name)
        end
    end


    # ##
    # # Describes a type named +name+ extending a +base+ type.
    # class TypeExtend < Type
    #     # The base type.
    #     attr_reader :base

    #     # Creates a new type named +name+ extending a +base+ type.
    #     def initialize(name,base)
    #         # Initialize the type.
    #         super(name)
    #         
    #         # Checks and set the base.
    #         unless base.is_a?(Type) then
    #             raise "Invalid class for a high-level type: #{base.class}."
    #         end
    #         @base = base
    #     end

    #     # Tells if a type is generic or not.
    #     def generic?
    #         # The type is generic if the base is generic.
    #         return @base.generic?
    #     end

    #     # Checks the compatibility with +type+
    #     def compatible?(type)
    #         # # If type is void, compatible anyway.
    #         # return true if type.name == :void
    #         # Compatible if same name and compatible base.
    #         return false unless type.respond_to?(:base)
    #         return ( @name == type.name and 
    #                  @base.compatible?(type.base) )
    #     end

    #     # Merges with +type+
    #     def merge(type)
    #         # # If type is void, return self anway.
    #         # return self if type.name == :void
    #         # Compatible if same name and compatible base.
    #         unless type.respond_to?(:base) then
    #             raise "Incompatible types for merging: #{self}, #{type}."
    #         end
    #         if @name == type.name then
    #             return TypeExtend.new(@name,self.base.merge(type.base))
    #         else
    #             raise "Incompatible types for merging: #{self}, #{type}."
    #         end
    #     end
    # end


    ##
    # Describes a vector type.
    # class TypeVector < TypeExtend
    class TypeVector < Base::TypeVector
        High = HDLRuby::High

        include Htype

        # # The range of the vector.
        # attr_reader :range

        # # Creates a new vector type named +name+ from +base+ type and with
        # # +range+.
        # def initialize(name,base,range)
        #     # Initialize the type.
        #     super(name,basa,range)

        #     # # Check and set the vector-specific attributes.
        #     # if rng.respond_to?(:to_i) then
        #     #     # Integer case: convert to a 0..(rng-1) range.
        #     #     rng = (rng-1)..0
        #     # elsif
        #     #     # Other cases: assume there is a first and a last to create
        #     #     # the range.
        #     #     rng = rng.first..rng.last
        #     # end
        #     # @range = rng
        # end

        # Type handling: these methods may have to be overriden when 
        # subclassing.

        # Gets the bitwidth of the type, nil for undefined.
        #
        # NOTE: must be redefined for specific types.
        def width
            first = @range.first
            last  = @range.last
            return @base.width * (first-last).abs
        end

        # Gets the direction of the range.
        def dir
            return (@range.last - @range.first)
        end

        # Tells if the type signed, false for unsigned.
        def signed?
            return @base.signed?
        end

        # # Tells if a type is generic or not.
        # def generic?
        #     # The type is generic if the base is generic.
        #     return self.base.generic?
        # end

        # Checks the compatibility with +type+
        def compatible?(type)
            # # if type is void, compatible anyway.
            # return true if type.name == :void
            # Compatible if same width and compatible base.
            return false unless type.respond_to?(:dir)
            return false unless type.respond_to?(:base)
            return ( self.dir == type.dir and
                     self.base.compatible?(type.base) )
        end

        # Merges with +type+
        def merge(type)
            # # if type is void, return self anyway.
            # return self if type.name == :void
            # Compatible if same width and compatible base.
            unless type.respond_to?(:dir) and type.respond_to?(:base) then
                raise "Incompatible types for merging: #{self}, #{type}."
            end
            unless self.dir == type.dir then
                raise "Incompatible types for merging: #{self}, #{type}."
            end
            return TypeVector.new(@name,@range,@base.merge(type.base))
        end

        # Converts the type to HDLRuby::Low and set its +name+.
        def to_low(name = self.name)
            # Generate and return the new type.
            return HDLRuby::Low::TypeVector.new(name,self.base.to_low,
                                                self.range.to_low)
        end
    end


    ##
    # Describes a tuple type.
    # class TypeTuple < Tuple
    class TypeTuple < Base::TypeTuple
        High = HDLRuby::High

        include Htype

        # # Creates a new tuple type named +name+ whose sub types are given
        # # by +content+.
        # def initialize(name,*content)
        #     # Initialize the type.
        #     super(name,*content)

        #     # # Check and set the content.
        #     # content.each do |sub|
        #     #     unless sub.is_a?(Type) then
        #     #         raise "Invalid class for a type: #{sub.class}"
        #     #     end
        #     # end
        #     # @types = content
        # end

        # # Gets a sub type by +index+.
        # def get_type(index)
        #     return @types[index.to_i]
        # end

        # # Iterates over the sub name/type pair.
        # #
        # # Returns an enumerator if no ruby block is given.
        # def each(&ruby_block)
        #     # No ruby block? Return an enumerator.
        #     return to_enum(:each) unless ruby_block
        #     # A block? Apply it on each input signal instance.
        #     @types.each(&ruby_block)
        # end

        # # Iterates over the sub types.
        # #
        # # Returns an enumerator if no ruby block is given.
        # def each_type(&ruby_block)
        #     # No ruby block? Return an enumerator.
        #     return to_enum(:each_type) unless ruby_block
        #     # A block? Apply it on each input signal instance.
        #     @types.each_value(&ruby_block)
        # end

        # # Tells if a type is generic or not.
        # def generic?
        #     # The type is generic if one of the sub types is generic.
        #     return self.each_type.any? { |type| type.generic? }
        # end

        # Converts the type to HDLRuby::Low and set its +name+.
        def to_low(name = self.name)
            return HDLRuby::Low::TypeTuple.new(name,
                               *@types.map { |type| type.to_low } )
        end
    end


    # ##
    # # Describes a hierarchical type.
    # class TypeHierarchy < Type
    #     # Creates a new hierarchical type named +name+ whose hierachy is given
    #     # by +content+.
    #     def initialize(name,content)
    #         # Initialize the type.
    #         super(name)

    #         # Check and set the content.
    #         content = Hash[content]
    #         @types = content.map do |k,v|
    #             unless v.is_a?(Type) then
    #                 raise "Invalid class for a type: #{v.class}"
    #             end
    #             [ k.to_sym, v ]
    #         end.to_h
    #     end

    #     # Gets a sub type by +name+.
    #     def get_type(name)
    #         return @types[name.to_sym]
    #     end

    #     # Iterates over the sub name/type pair.
    #     #
    #     # Returns an enumerator if no ruby block is given.
    #     def each(&ruby_block)
    #         # No ruby block? Return an enumerator.
    #         return to_enum(:each) unless ruby_block
    #         # A block? Apply it on each input signal instance.
    #         @types.each(&ruby_block)
    #     end

    #     # Iterates over the sub types.
    #     #
    #     # Returns an enumerator if no ruby block is given.
    #     def each_type(&ruby_block)
    #         # No ruby block? Return an enumerator.
    #         return to_enum(:each_type) unless ruby_block
    #         # A block? Apply it on each input signal instance.
    #         @types.each_value(&ruby_block)
    #     end

    #     # Iterates over the sub type names.
    #     #
    #     # Returns an enumerator if no ruby block is given.
    #     def each_name(&ruby_block)
    #         # No ruby block? Return an enumerator.
    #         return to_enum(:each_name) unless ruby_block
    #         # A block? Apply it on each input signal instance.
    #         @types.each_key(&ruby_block)
    #     end

    #     # Tells if a type is generic or not.
    #     def generic?
    #         # The type is generic if one of the sub types is generic.
    #         return self.each_type.any? { |type| type.generic? }
    #     end
    # end


    ##
    # Describes a structure type.
    # class TypeStruct < TypeHierarchy
    class TypeStruct < Base::TypeStruct
        High = HDLRuby::High

        include Htype

        # Gets the bitwidth of the type, nil for undefined.
        #
        # NOTE: must be redefined for specific types.
        def width
            return @types.reduce(0) {|sum,type| sum + type.width }
        end

        # Checks the compatibility with +type+
        def compatible?(type)
            # # If type is void, compatible anyway.
            # return true if type.name == :void
            # Not compatible if different types.
            return false unless type.is_a?(TypeStruct)
            # Not compatibe unless each entry has the same name in same order.
            return false unless self.each_name == type.each_name
            self.each do |name,sub|
                return false unless sub.compatible?(self.get_type(name))
            end
            return true
        end

        # Merges with +type+
        def merge(type)
            # # if type is void, return self anyway.
            # return self if type.name == :void
            # Not compatible if different types.
            unless type.is_a?(TypeStruct) then
                raise "Incompatible types for merging: #{self}, #{type}."
            end
            # Not compatibe unless each entry has the same name and same order.
            unless self.each_name == type.each_name then
                raise "Incompatible types for merging: #{self}, #{type}."
            end
            # Creates the new type content
            content = {}
            self.each do |name,sub|
                content[name] = self.get_type(name).merge(sub)
            end
            return TypeStruct.new(@name,content)
        end  

        # Converts the type to HDLRuby::Low and set its +name+.
        def to_low(name = self.name)
            return HDLRuby::Low::TypeStruct.new(name,
                                @types.map { |name,type| [name,type.to_low] } )
        end
    end


    # ##
    # # Describes an union type.
    # class TypeUnion < TypeHierarchy
    #     # Creates a new union type named +name+ whose hierachy is given
    #     # by +content+.
    #     def initialize(name,content)
    #         # Initialize the type structure.
    #         super(name,content)
    #         # Check the content: a union cannot contain any generic sub-type.
    #         self.each_type do |type|
    #             if type.generic? then
    #                 raise "Union types cannot contain any generic sub-type."
    #             end
    #         end
    #     end

    #     # Type handling: these methods may have to be overriden when 
    #     # subclassing.

    #     # Gets the bitwidth of the type, nil for undefined.
    #     #
    #     # NOTE: must be redefined for specific types.
    #     def width
    #         return @types.max{ |type| type.width }.width
    #     end

    #     # Tells if a type is generic or not.
    #     def generic?
    #         # No.
    #         return false
    #     end
    # end

    # ##
    # # Describes a type made of a system type.
    # #
    # # NOTE: must be instantiated before being used.
    # class TypeSystemT < Type
    #     # The system type.
    #     attr_reader :systemT

    #     # Creates a new type named +name+ made of system type +systemT+
    #     # using signal names of +left_names+ as left values and signal names
    #     # of +right_names+ as right values.
    #     def initialize(name,systemT,left_names,right_names)
    #         # Initialize the type.
    #         super(name)
    #         # Check and set the system type.
    #         unless systemT.is_a?(SystemT) then
    #             raise "Invalid class for a system type: #{systemT.class}."
    #         end
    #         @systemT = systemT

    #         # Check and set the left and right names.
    #         @left_names = left_names.map {|name| name.to_sym }
    #         @right_names = right_names.map {|name| name.to_sym }
    #     end

    #     # Instantiate the type with arguments +args+.
    #     # Returns a new type named +name+ based on a system instance.
    #     #
    #     # NOTE: to be called when creating a signal of this type, it
    #     # will instantiate the embedded system.
    #     def instantiate(*args)
    #         # Instantiate the system type and create the type instance
    #         # from it.
    #         return TypeSystemI.new(:"",@systemT.instantiate(:"",*args),
    #                               @left_names, @right_names)
    #     end
    #     alias :call :instantiate
    # end


    # ##
    # # Describes a type made of a system instance.
    # class TypeSystemI < TypeHierarchy
    #     # The system instance.
    #     attr_reader :systemI

    #     # Creates a new type named +name+ made of system type +systemI+
    #     # using signal names of +left_names+ as left values and signal names
    #     # of +right_names+ as right values.
    #     def initialize(name,systemI,left_names,right_names)
    #         # Check and set the system instance.
    #         unless systemI.is_a?(SystemI) then
    #             raise "Invalid class for a system instance: #{systemI.class}."
    #         end
    #         @systemI = systemI

    #         # Initialize the type: each external signal becomes an
    #         # element of the corresponding hierarchical type.
    #         super(name, systemI.each_input.map do |signal|
    #                         [signal.name, signal.type]
    #                     end + 
    #                     systemI.each_output.map do |signal|
    #                         [signal.name, signal.type]
    #                     end + 
    #                     systemI.each_inout.map do |signal|
    #                         [signal.name, signal.type]
    #                     end)


    #         # Check and set the left and right names.
    #         @left_names = left_names.map {|name| name.to_sym }
    #         @right_names = right_names.map {|name| name.to_sym }

    #         # Generates the left-value and the right-value side of the type
    #         # from the inputs and the outputs of the system.
    #         @left = struct(@left_names.map do |name|
    #             signal = @systemI.get_signal(name)
    #             unless signal then
    #                 raise "Unkown signal in system #{@systemI.name}: #{name}."
    #             end
    #             [name, signal.type]
    #         end)
    #         @right = struct(@right_names.map do |name|
    #             signal = @systemI.get_signal(name)
    #             unless signal then
    #                 raise "Unkown signal in system #{@systemI.name}: #{name}."
    #             end
    #             [name, signal.type]
    #         end)
    #     end


    #     # Type handling: these methods may have to be overriden when 
    #     # subclassing.
    #     
    #     # Gets the type as left value.
    #     def left
    #         return @left
    #     end

    #     # Gets the type as right value.
    #     def right
    #         return @right
    #     end


    #     # Tells if a type is generic or not.
    #     def generic?
    #         return (self.left.generic? or self.right.generic?)
    #     end

    #     # Checks the compatibility with +type+
    #     def compatible?(type)
    #         # Not compatible, must use left or right for connections.
    #         return false
    #     end

    #     # Merges with +type+
    #     def merge(type)
    #         # Cannot merge, must use left or right for connections.
    #         raise "Incompatible types for merging: #{self}, #{type}."
    #     end

    # end



    # The type constructors.

    # Creates an unnamed structure type from a +content+.
    def struct(content)
        return TypeStruct.new(:"",content)
    end

    # # Creates an unnamed union type from a +content+.
    # def union(content)
    #     return TypeUnion.new(:"",content)
    # end

    # Creates type named +name+ and using +ruby_block+ for building it.
    def type(name,&ruby_block)
        # Builds the type.
        type = HDLRuby::High.top_user.instance_eval(&ruby_block)
        # Ensures type is really a type.
        # unless type.is_a?(Type) then
        unless type.respond_to?(:htype?) then
            raise "Invalid class for a type: #{type.class}."
        end
        # Name it.
        type.name = name
        return type
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
    class SystemI < Base::SystemI
        High = HDLRuby::High

        include SingletonExtend

        # Creates a new system instance of system type +systemT+ named +name+.
        def initialize(name, systemT)
            # Initialize the system instance structure.
            super(name,systemT)

            # Sets the hdl-like access to the system instance.
            obj = self # For using the right self within the proc
            High.space_reg(name) { obj }
        end

        # Connects signals of the system instance according to +connects+.
        #
        # NOTE: +connects+ is a hash table where each entry gives the
        # correspondance between a system's signal name and an external
        # signal to connect to.
        def call(connects)
            # Ensures connect is a hash.
            connects = connects.to_h
            # Performs the connections.
            connects.each do |left,right|
                # Gets the signal corresponding to connect.
                left = self.get_signal(left)
                # Make the connection.
                left <= right
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
            return @systemT.open(&ruby_block)
        end

        # include Hmissing

        # Missing methods are looked for in the public namespace of the
        # system type.
        def method_missing(m, *args, &ruby_block)
            # print "method_missing in class=#{self.class} with m=#{m}\n"
            # # No argument, might be an exported element
            # if args.empty? then
            #     exported = self.get_export(m)
            #     if exported then
            #         # A exported element is found, return it.
            #         return exported
            #     end
            # end
            # # Nothing found.
            # raise NoMethodError.new("undefined local variable or method `#{name}'.")
            self.public_namespace.send(m,*args,&ruby_block)
        end


        # Methods to transmit to the systemT
        
        # Gets the private namespace.
        def private_namespace
            self.systemT.private_namespace
        end
        
        # Gets the public namespace.
        def public_namespace
            self.systemT.public_namespace
        end


        # Converts the instance to HDLRuby::Low and set its +name+.
        def to_low(name = self.name)
            # puts "to_low with #{self} (#{self.name}) #{self.systemT}"
            # Converts the system of the instance to HDLRuby::Low
            systemTlow = self.systemT.to_low(High.names_create(name.to_s+ "::T"))
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
    class If < Base::If
        High = HDLRuby::High

        include HStatement

        # Creates a new if statement with a +condition+ that when met lead
        # to the execution of the block in +mode+ generated by the execution of
        # +ruby_block+.
        def initialize(condition, mode = nil, &ruby_block)
            # Create the yes block.
            # yes_block = High.block(:par,&ruby_block)
            yes_block = High.block(mode,&ruby_block)
            # Creates the if statement.
            super(condition.to_expr,yes_block)
        end

        # Sets the block executed in +mode+ when the condition is not met to
        # the block generated by the execution of +ruby_block+.
        #
        # Can only be used once.
        def helse(mode = nil, &ruby_block)
            # Create the nu block if required
            # no_block = High.block(:par,&ruby_block)
            no_block = High.block(mode,&ruby_block)
            # Sets the no block.
            self.no = no_block
        end

        # Converts the if to HDLRuby::Low.
        def to_low
            # no may be nil, so treat it appart
            noL = self.no ? self.no.to_low : nil
            # Now generate the low-level if.
            return HDLRuby::Low::If.new(self.condition.to_low,
                                        self.yes.to_low,noL)
        end
    end


    ## 
    # Describes a high-level case statement.
    class Case < Base::Case
        High = HDLRuby::High

        include HStatement

        # Creates a new case statement with a +value+ that decides which
        # block to execute.
        def initialize(value)
            # Create the yes block.
            super(value.to_expr)
        end

        # Sets the block executed in +mode+ when the value matches +match+.
        # The block is generated by the execution of +ruby_block+.
        #
        # Can only be used once for the given +match+.
        def hwhen(match, mode = nil, &ruby_block)
            # Create the nu block if required
            # when_block = High.block(:par,&ruby_block)
            when_block = High.block(mode,&ruby_block)
            # Adds the case.
            self.add_when(match.to_expr,when_block)
        end

        # Sets the block executed in +mode+ when there were no match to
        # the block generated by the execution of +ruby_block+.
        #
        # Can only be used once.
        def helse(mode = nil, &ruby_block)
            # Create the nu block if required
            # no_block = High.block(:par,&ruby_block)
            default_block = High.block(mode,&ruby_block)
            # Sets the default block.
            self.default = default_block
        end

        # Converts the case to HDLRuby::Low.
        def to_low
            # Create the low level case.
            caseL = HDLRuby::Low::Case.new(@value.to_low)
            # Add each case.
            self.each_when do |match,statement|
                caseL.add_when(match.to_low, statement.to_low)
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
    class Delay < Base::Delay
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
    class TimeWait < Base::TimeWait
        include HStatement

        # Converts the wait statement to HDLRuby::Low.
        def to_low
            return HDLRuby::Low::TimeWait.new(self.delay.to_low)
        end
    end


    ## 
    # Describes a timed loop statement: not synthesizable!
    class TimeRepeat < Base::TimeRepeat
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

        # Converts to an expression.
        #
        # NOTE: to be redefined in case of non-expression class.
        def to_expr
            return self
        end

        # Adds the unary operations generation.
        [:"-@",:"@+",:"!",:"~",
         :boolean, :bit, :signed, :unsigned].each do |operator|
            define_method(operator) do
                return Unary.new(operator,self.to_expr)
            end
        end

        # Adds the binary operations generation.
        [:"+",:"-",:"*",:"/",:"%",:"**",
         :"&",:"|",:"^",:"<<",:">>",
         :"==",:"!=",:"<",:">",:"<=",:">="].each do |operator|
            define_method(operator) do |right|
                return Binary.new(operator,self.to_expr,right.to_expr)
            end
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

        # # The parent construct.
        # attr_reader :parent

        # # Sets the +parent+ construct.
        # def parent=(parent)
        #     # Check and set the type.
        #     unless ( parent.is_a?(Base::Expression) or
        #              parent.is_a?(Base::Transmit) or
        #              parent.is_a?(Base::If) or
        #              parent.is_a?(Base::Case) ) then
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
            if High.top_user.is_a?(HDLRuby::Base::Block) then
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
    # Describes a high-level unary expression
    class Unary < Base::Unary
        include HExpression

        # Converts the unary expression to HDLRuby::Low.
        def to_low
            return HDLRuby::Low::Unary.new(self.operator,self.child.to_low)
        end
    end


    ##
    # Describes a high-level binary expression
    class Binary < Base::Binary
        include HExpression

        # Converts the binary expression to HDLRuby::Low.
        def to_low
            return HDLRuby::Low::Binary.new(self.operator,
                                           self.left.to_low, self.right.to_low)
        end
    end


    # ##
    # # Describes a high-level ternary expression
    # class Ternary < Base::Ternary
    #     include HExpression
    # end

    ##
    # Describes a section operation (generalization of the ternary operator).
    #
    # NOTE: choice is using the value of +select+ as an index.
    class Select < Base::Select
        include HExpression

        # Converts the selection expression to HDLRuby::Low.
        def to_low
            return HDLRuby::Low::Select.new("?",self.select.to_low,
            *self.each_choice.map do |choice|
                choice.to_low
            end)
        end
    end


    ##
    # Describes z high-level concat expression.
    class Concat < Base::Concat
        include HExpression

        # Converts the concatenation expression to HDLRuby::Low.
        def to_low
            return HDLRuby::Low::Concat.new(*self.each_expression.map do |exp|
                exp.to_low
            end)
        end
    end


    ##
    # Describes a high-level value.
    class Value < Base::Value
        include HExpression

        # Converts the value to HDLRuby::Low.
        def to_low
            # Clone the content if possible
            content = self.content.frozen? ? self.content : self.content.clone
            # Create and return the resulting low-level value
            return HDLRuby::Low::Value.new(self.type.to_low,content)
        end
    end



    ## 
    # Module giving high-level reference properties.
    module HRef
        # Properties of expressions are also required
        def self.included(klass)
            klass.class_eval do
                include HExpression
                include HArrow
            end
        end

        # Converts to a reference.
        #
        # NOTE: to be redefined in case of non-reference class.
        def to_ref
            return self
        end

        # Converts to an event.
        def to_event
            return Event.new(:change,event)
        end

        # Creates an access to elements of range +rng+ of the signal.
        #
        # NOTE: +rng+ can be a single expression in which case it is an index.
        def [](rng)
            if rng.respond_to?(:to_expr) then
                # Number range: convert it to an expression.
                rng = rng.to_expr
            end 
            if rng.is_a?(HDLRuby::Base::Expression) then
                # Index case
                return RefIndex.new(self.to_ref,rng)
            else
                # Range case, ensure it is made among expression.
                first = rng.first.to_expr
                last = rng.last.to_expr
                # Abd create the reference.
                return RefRange.new(self.to_ref,first..last)
            end
        end
    end

    ##
    # Describes a high-level object reference: no low-level equivalent!
    class RefObject < Base::Ref
        include HRef

        # The refered object.
        attr_reader :object

        # Creates a new reference to +object+.
        def initialize(object)
            @object = object
        end

        # Converts the reference to a low-level name reference.
        def to_low
            # Build the path of the reference.
            path = []
            cur = @object
            # while(!High.low_has?(cur)) do
            # while(!High.top_user.equal?(cur)) do
            while(!High.top_user.user_deep?(cur)) do
                cur = cur.owner if cur.respond_to?(:owner)
                # puts "cur=#{cur}, name=#{cur.name}"
                path << cur.name
                cur = cur.parent
                # puts " parent=#{cur} found? #{High.top_user.equal?(cur)}"
            end
            # puts "path=#{path}"
            # Build the references from the path.
            ref = this.to_low
            path.each { |name| ref = HDLRuby::Low::RefName.new(ref,name) }
            return ref
        end
    end


    ##
    # Describes a high-level concat reference.
    class RefConcat < Base::RefConcat
        include HRef

        # Converts the concat reference to HDLRuby::Low.
        def to_low
            return HDLRuby::Low::RefConcat.new(self.each_ref.map do |ref|
                ref.to_low
            end)
        end
    end

    ##
    # Describes a high-level index reference.
    class RefIndex < Base::RefIndex
        include HRef

        # Converts the index reference to HDLRuby::Low.
        def to_low
            return HDLRuby::Low::RefIndex.new(self.ref.to_low,self.index.to_low)
        end
    end

    ##
    # Describes a high-level range reference.
    class RefRange < Base::RefRange
        include HRef

        # Converts the range reference to HDLRuby::Low.
        def to_low
            return HDLRuby::Low::RefRange.new(self.ref.to_low,self.range.to_low)
        end
    end

    ##
    # Describes a high-level name reference.
    class RefName < Base::RefName
        include HRef

        # Converts the name reference to HDLRuby::Low.
        def to_low
            return HDLRuby::Low::RefName.new(self.ref.to_low,self.name)
        end
    end

    ##
    # Describes a this reference.
    class RefThis < Base::RefThis
        High = HDLRuby::High
        include HRef
       
        # Deactivated since incompatible with the parent features.
        # # The only useful instance of RefThis.
        # This = RefThis.new

        # Gets the enclosing system type.
        def system
            return High.cur_systemT
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
    class Event < Base::Event
        # Converts to an event.
        def to_event
            return self
        end

        # Converts the event to HDLRuby::Low.
        def to_low
            return HDLRuby::Low::Event.new(self.type,self.ref.to_low)
        end
    end


    ## 
    # Decribes a transmission statement.
    class Transmit < Base::Transmit
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
            return Binary.new(:<=,self.left,self.right)
        end

        # Converts the transmit to HDLRuby::Low.
        def to_low
            return HDLRuby::Low::Transmit.new(self.left.to_low,
                                              self.right.to_low)
        end
    end

    ## 
    # Describes a connection.
    class Connection < Base::Connection
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
            behavior = Behavior.new(event) do
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
            behavior = Behavior.new() do
                (left <= right).hif(condition)
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
    class SignalI < Base::SignalI
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

            unless name.empty? then
                # Named signal, set the hdl-like access to the signal.
                obj = self # For using the right self within the proc
                High.space_reg(name) { obj }
            end

            # Hierarchical type allows access to sub references, so generate
            # the corresponding methods.
            if type.respond_to?(:each_name) then
                type.each_name do |name|
                    self.define_singleton_method(name) do
                        RefName.new(self.to_ref,name)
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

        # Converts to a reference.
        def to_ref
            # return RefName.new(this,self.name)
            return RefObject.new(self)
        end

        # Converts to an expression.
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

        # The private namespace
        attr_reader :private_namespace

        # Build the block by executing +ruby_block+.
        def build(&ruby_block)
            # # High-level blocks can include inner signals.
            # @inners ||= {}
            # And therefore require a namespace.
            @private_namespace ||= Namespace.new(self)
            # Build the block.
            # High.space_push(self)
            High.space_push(@private_namespace)
            High.top_user.instance_eval(&ruby_block)
            High.space_pop
        end

        # # Missing methods are looked up in the upper level of the namespace.
        # def method_missing(m, *args, &ruby_block)
        #     print "method_missing in class=#{self.class} with m=#{m}\n"
        #     # Is the missing method an immediate value?
        #     value = m.to_value
        #     return value if value and args.empty?
        #     # No look up in the upper level of the namespace.
        #     High.space_call(m,*args,&ruby_block)
        # end

        include Hmissing

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

        # Creates and adds a new block executed in +mode+ built by
        # executing +ruby_block+.
        def add_block(mode = nil,&ruby_block)
            # Creates and adds the block.
            block = High.block(mode,&ruby_block)
            self.add_statement(block)
        end

        # Creates a new parallel block built from +ruby_block+.
        def par(&ruby_block)
            return :par unless ruby_block
            self.add_block(:par,&ruby_block)
        end

        # Creates a new sequential block built from +ruby_block+.
        def seq(&ruby_block)
            return :seq unless ruby_block
            self.add_block(:seq,&ruby_block)
        end

        # Creates a new block with the current mode built from +ruby_block+.
        def block(&ruby_block)
            return self.mode unless ruby_block
            self.add_block(self.mode,&ruby_block)
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
            # Completes the if statement.
            statement = @statements.last
            unless statement.is_a?(If) or statement.is_a?(Case) then
                raise "Error: helse statement without hif nor hcase (#{statement.class})."
            end
            statement.helse(mode, &ruby_block)
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
            # Completes the if statement.
            statement = @statements.last
            unless statement.is_a?(Case) then
                raise "Error: hwhen statement without hcase (#{statement.class})."
            end
            statement.hwhen(match, mode, &ruby_block)
        end
    end


    ##
    # Describes a high-level block.
    class Block < Base::Block
        High = HDLRuby::High

        include HBlock
        include Hinner

        # Creates a new +mode+ sort of block and build it by executing
        # +ruby_block+.
        # def initialize(mode, extensions = [], &ruby_block)
        def initialize(mode, &ruby_block)
            # Initialize the block.
            super(mode)
            # extensions.each do |extension|
            #     self.singleton_class.class_eval(&extension)
            # end
            # puts "methods = #{self.methods.sort}"
            build(&ruby_block)

            # Creates the private namespace.
            @private_namespace = Namespace.new(self)
        end

        # Converts the block to HDLRuby::Low.
        def to_low
            # Create the resulting block
            blockL = HDLRuby::Low::Block.new(self.mode)
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


    # Describes a timed block.
    #
    # NOTE: 
    # * this is the only kind of block that can include time statements. 
    # * this kind of block is not synthesizable!
    class TimeBlock < Base::TimeBlock
        High = HDLRuby::High

        include HBlock

        # Creates a new +type+ sort of block and build it by executing
        # +ruby_block+.
        # def initialize(type, extensions = [], &ruby_block)
        def initialize(type, &ruby_block)
            # Initialize the block.
            super(type)
            # extensions.each do |extension|
            #     self.singleton_class.class_eval(&extension)
            # end
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
            # content = High.block(:par,&ruby_block)
            content = High.block(mode,&ruby_block)
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


    # Declares a block executed in +mode+, that can be timed or not depending 
    # on the enclosing object and build it by executing the enclosing
    # +ruby_block+.
    #
    # NOTE: not a method to include since it can only be used with
    # a behavior or a block. Hence set as module method.
    def self.block(mode = nil, &ruby_block)
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
            return TimeBlock.new(mode,&ruby_block)
        else
            # return Block.new(mode,from_users(:block_extensions),&ruby_block)
            return Block.new(mode,&ruby_block)
        end
    end

    # Declares a specifically timed block in +mode+ and build it by
    # executing the enclosing +ruby_block+.
    #
    # NOTE: not a method to include since it can only be used with
    # a behavior or a block. Hence set as module method.
    def self.time_block(mode = nil,&ruby_block)
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
        return TimeBlock.new(mode,&ruby_block)
    end

    ##
    # Describes a high-level behavior.
    class Behavior < Base::Behavior
        High = HDLRuby::High

        # # Creates a new behavior executing +block+ activated on a list of
        # # +events+, and built by executing +ruby_block+.
        # def initialize(*events,&ruby_block)
        #     # Initialize the behavior
        #     super()
        #     # Add the events.
        #     events.each { |event| self.add_event(event) }
        #     # Create a default par block for the behavior.
        #     block = High.block(:par,&ruby_block)
        #     self.add_block(block)
        #     # # Build the block by executing the ruby block in context.
        #     # High.space_push(block)
        #     # High.top_user.instance_eval(&ruby_block)
        #     # High.space_pop
        # end

        # Creates a new behavior executing +block+ activated on a list of
        # +events+, and built by executing +ruby_block+.
        def initialize(*events,&ruby_block)
            # Create a default par block for the behavior.
            # block = High.block(:par,&ruby_block)
            mode = nil
            if events.last.respond_to?(:to_sym) then
                # A mode is given, use it.
                mode = events.pop.to_sym
            end
            block = High.block(mode,&ruby_block)
            # Initialize the behavior with it.
            super(block)
            # Add the events.
            events.each { |event| self.add_event(event) }
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
    class TimeBehavior < Base::TimeBehavior
        High = HDLRuby::High

        # # Creates a new timed behavior built by executing +ruby_block+.
        # def initialize(&ruby_block)
        #     # Initialize the behavior
        #     super()
        #     # Create and add a default par block for the behavior.
        #     # NOTE: this block is forced to TimeBlock, so do not use
        #     # block(:par).
        #     block = High.time_block(:par,&ruby_block)
        #     # block = make_changer(TimeBlock).new(:par,&ruby_block)
        #     self.add_block(block)
        #     # # Build the block by executing the ruby block in context.
        #     # High.space_push(block)
        #     # High.top_user.instance_eval(&ruby_block)
        #     # High.space_pop
        # end

        # Creates a new timed behavior built by executing +ruby_block+.
        def initialize(mode = nil, &ruby_block)
            # Create a default par block for the behavior.
            # NOTE: this block is forced to TimeBlock, so do not use
            # block(:par).
            # block = High.time_block(:par,&ruby_block)
            block = High.time_block(mode,&ruby_block)
            # Initialize the behavior with it.
            super(block)
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
    Namespaces = [Universe.private_namespace]
    private_constant :Namespaces

    # Pushes +namespace+.
    def self.space_push(namespace)
        # Emsure namespace is really a namespace.
        namespace = namespace.to_namespace
        # Concat the current top to namespace so that it has access to the
        # existing hardware constructs.
        namespace.concat(Namespaces[-1])
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

    # Gets the enclosing system type if any.
    def self.cur_systemT
        if Namespaces.size <= 1 then
            raise "Not within a system type."
        else
            return Namespaces.reverse_each.find do |space|
                space.user.is_a?(SystemT)
            end.user
        end
    end

    # Gets the enclosing behavior if any.
    def self.cur_behavior
        # Gets the enclosing system type.
        systemT = self.cur_systemT
        # Gets the current behavior from it.
        unless systemT.each_behavior.any? then
            raise "Not within a behavior."
        end
        return systemT.each.reverse_each.first
    end

    # Gets the enclosing block if any.
    #
    # NOTE: +level+ allows to get an upper block of the currently enclosing
    #       block.
    def self.cur_block(level = 0)
        if Namespace[-1-level].user.is_a?(Block)
            return Namespaces[-1-level].user
        else
            raise "Not within a block."
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
        Namespaces[-1].add(name,&ruby_block)
    end

    # Looks up and calls method +name+ from the namespace stack with arguments
    # +args+ and block +ruby_block+.
    def self.space_call(name,*args,&ruby_block)
        # print "space_call with name=#{name}\n"
        # Ensures name is a symbol.
        name = name.to_sym
        # # Look from the top of the stack.
        # Namespaces.reverse_each do |space|
        #     if space.respond_to?(name) then
        #         # print "Found is space user with class=#{space.user.class}\n"
        #         # The method is found, call it.
        #         return space.send(name,*args)
        #     end
        # end
        # Look in the top namespace
        if Namespaces[-1].respond_to?(name) then
            # Found.
            return Namespaces[-1].send(name,*args,&ruby_block)
        end
        # Not found.
        raise NoMethodError.new("undefined local variable or method `#{name}'.")
    end




    
    # Creates the basic types.
    
    # Defines a basic type +name+.
    def self.define_type(name)
        name = name.to_sym
        type = Type.new(name)
        self.send(:define_method,name) { type }
    end

    # # The void type.
    # define_type :void

    # The bit type.
    define_type :bit

    # The signed bit type.
    define_type :signed

    # The ungisned bit type.
    define_type :unsigned

    # The numeric type (for all the Ruby Numeric types).
    define_type :numeric





    # Extends the standard classes for support of HDLRuby.


    # Extends the Numeric class for conversion to a high-level expression.
    class ::Numeric

        # Converts to a high-level expression.
        def to_expr
            return Value.new(numeric,self)
        end

        # Converts to a delay in picoseconds.
        def ps
            return Delay.new(self,:ps)
        end

        # Converts to a delay in nanoseconds.
        def ns
            return Delay.new(self,:ns)
        end

        # Converts to a delay in microseconds.
        def us
            return Delay.new(self,:us)
        end

        # Converts to a delay in milliseconds.
        def ms
            return Delay.new(self,:ms)
        end

        # Converts to a delay in seconds.
        def s
            return Delay.new(self,:s)
        end
    end


    # Extends the Hash class for declaring signals of structure types.
    class ::Hash
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

        # Converts to a high-level expression.
        def to_expr
            expr = Concat.new
            self.each {|elem| expr.add_expression(elem.to_expr) }
            expr
        end

        # Converts to a high-level reference.
        def to_ref
            expr = RefConcat.new
            self.each {|elem| expr.add_ref(elem.to_ref) }
            expr
        end

        # Converts to a type.
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

        # Create an array of instances obtained by instantiating the elements
        # using +args+ as argument and register the result to +name+.
        #
        # NOTE: the instances are unnamed since it is the resulting array
        # that is registered.
        def make(name,*args)
            # Instantiate the types.
            instances = self.map { |elem| elem.instantiate(:"",*args) }
            # Add them to the top system
            High.space_top.user.add_groupI(name,*instances)
            # Register and return the result.
            High.space_reg(name) { High.space_top.user.get_groupI(name) }
            return High.space_top.user.get_groupI(name)
        end
    end


    # Extends the symbol class for auto declaration of input or output.
    class ::Symbol
        High = HDLRuby::High

        # # Converts to a high-level expression.
        # def to_expr
        #     self.to_ref
        # end

        # # Converts to a high-level reference refering to an unbounded signal.
        # def to_ref
        #     # Create the unbounded signal and add it to the upper system type.
        #     signal = SignalI.new(self,void,:no)
        #     High.cur_systemT.add_unbound(signal)
        #     # Convert it to a reference and return the result.
        #     return signal.to_ref
        # end
        # alias :+@ :to_ref

        # Converts to a value.
        #
        # Returns nil if no value can be obtained from it.
        def to_value
            str = self.to_s
            # puts "str=#{str}"
            # Get and check the type
            type = str[0]
            # puts "type=#{type}"
            str = str[1..-1]
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
    end



    # ##
    # # Module providing methods for changing the base objects of HDLRuby::High
    # # while hiding the (highly variable in the current state) actual class
    # # and module hierarchy.
    # module Changer
    #     High = HDLRuby::High

    #     # Methods for changing locally blocks.

    #     # Get the block extensions.
    #     def block_extensions
    #         @block_extensions ||= []
    #         return @block_extensions
    #     end

    #     # Changes the behavior of the local blocks by executing
    #     # +ruby_block+.
    #     def block_open(&ruby_block)
    #         @block_extensions ||= []
    #         @block_extensions << ruby_block
    #     end
    # end


    # class SystemT
    #     include Changer
    # end

    # class Block
    #     include Changer
    # end

    # class TimeBlock
    #     include Changer
    # end


    
    # Methods for managing the conversion to HDLRuby::Low

    # # The stack of objects being converted to low.
    # LowStack = []

    # # Pushes +obj+ on the low stack.
    # def self.low_push(obj)
    #     puts "low_push with #{obj}"
    #     LowStack.push(obj)
    # end

    # # Pops from the low stack.
    # def self.low_pop
    #     puts "low_pop #{LowStack[-1]}"
    #     LowStack.pop
    # end

    # # Tells if +obj+ is in the low stack.
    # def self.low_has?(obj)
    #     puts "low_has? with #{obj}: #{LowStack.include?(obj)}"
    #     LowStack.include?(obj)
    # end

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

end

# Enters in HDLRuby::High mode.
def self.configure_high
    include HDLRuby::High
    class << self
        # For main, missing methods are looked for in the namespaces.
        def method_missing(m, *args, &ruby_block)
            # print "method_missing in class=#{self.class} with m=#{m}\n"
            # Is the missing method an immediate value?
            value = m.to_value
            return value if value and args.empty?
            # puts "Universe methods: #{Universe.private_namespace.methods}"
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
end
