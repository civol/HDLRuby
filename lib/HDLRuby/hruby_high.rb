require "HDLRuby/hruby_low"
require "HDLRuby/hruby_tools"
require "HDLRuby/hruby_types"
require "HDLRuby/hruby_values"
require "HDLRuby/hruby_bstr"
require "HDLRuby/hruby_low_mutable"

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
                puts "name=#{name}"
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

        # Clones (safely) the namespace.
        def clone
            # Create the new namespace.
            res = Namespace.new(@user)
            # Adds the concats.
            @concats.each do |concat|
                res.concat_namespace(concat)
            end
            return res
        end

        # Adds method +name+ provided the name is not empty and the method
        # is not already defined in the current namespace.
        def add_method(name,&ruby_block)
            # puts "add_method with name=#{name} and parameters=#{ruby_block.parameters}"
            unless name.empty? then
                if RESERVED.include?(name.to_sym) then
                    raise AnyError, 
                          "Resevered name #{name} cannot be overridden."
                end
                # Deactivated: overriding is now accepted.
                # if self.respond_to?(name) then
                #     raise AnyError,
                #           "Symbol #{name} is already defined."
                # end
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

        NAMES = { }

        # Missing methods may be immediate values, if not, they are looked up
        # in the upper level of the namespace if any.
        def method_missing(m, *args, &ruby_block)
            # puts "method_missing in class=#{self.class} with m=#{m}"
            # Is the missing method an immediate value?
            value = m.to_value
            return value if value and args.empty?
            # Or is it a uniq name generator?
            if (m[-1] == '?') then
                # Yes
                m = m[0..-2]
                return NAMES[m] = HDLRuby.uniq_name(m)
            end
            # Is in a previous uniq name?
            if (m[-1] == '!') then
                pm = m[0..-2]
                if NAMES.key?(pm) then
                    # Yes, returns the current corresponding uniq name.
                    return self.send(NAMES[pm],*args,&ruby_block)
                end
            end
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
                end
            elsif self.respond_to?(:public_namespace) and
                  High.space_index(self.public_namespace) then
                # Yes, the private namespace is in it, can try the methods in
                # the space.
                High.space_call(m,*args,&ruby_block)
            else
                # No, this is a true error.
                raise NotDefinedError, "undefined HDLRuby construct, local variable or method `#{m}'."
            end
        end
    end

    module HScope_missing

        include Hmissing

        alias_method :h_missing, :method_missing

        # Missing methods are looked for in the private namespace.
        # 
        # NOTE: it is ok to use the private namespace because the scope
        # can only be accessed if it is available from its systemT.
        def method_missing(m, *args, &ruby_block)
            # puts "looking for #{m} in #{self}"
            # Is the scope currently opened?
            # if High.space_top.user_deep?(self) then
            if High.space_index(self.namespace) then
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
        end
    end


    ##
    # Module providing methods for declaring select expressions.
    module Hmux
        # Creates an operator selecting from +select+ one of the +choices+.
        #
        # NOTE: * +choices+ can either be a list of arguments or an array.
        #         If +choices+ has only two entries (and it is not a hash),
        #         +value+ will be converted to a boolean.
        #       * The type of the select is computed as the largest no
        #         integer-constant choice. If only constant integer choices,
        #         use the largest type of them.
        def mux(select,*choices)
            # Process the choices.
            choices = choices.flatten(1) if choices.size == 1
            choices.map! { |choice| choice.to_expr }
            # Compute the type of the select as the largest no 
            # integer-constant type.
            # If only such constants, use the largest type of them.
            type = choices.reduce(Bit) do |type,choice|
                unless choice.is_a?(Value) && choice.type == Integer then
                    type.width >= choice.type.width ? type : choice.type
                else
                    type
                end
            end
            unless type then
                type = choices.reduce(Bit) do |type,choice|
                    type.width >= choice.type.width ? type : choice.type
                end
            end
            # Generate the select expression.
            return Select.new(type,"?",select.to_expr,*choices)
        end
    end


    ##
    # Module providing declaration of inner signal (assumes inner signals
    # are present.
    module Hinner

        # Only adds the methods if not present.
        def self.included(klass)
            klass.class_eval do
                unless instance_methods.include?(:make_inners) then
                    # Creates and adds a set of inners typed +type+ from a
                    # list of +names+.
                    #
                    # NOTE: * a name can also be a signal, is which case it is
                    #         duplicated. 
                    #       * a name can also be a hash containing names
                    #         associated with an initial value.
                    def make_inners(type, *names)
                        res = nil
                        names.each do |name|
                            if name.respond_to?(:to_sym) then
                                # Adds the inner signal
                                res = self.add_inner(
                                    SignalI.new(name,type,:inner))
                            elsif name.is_a?(Hash) then
                                # Names associated with values.
                                name.each do |key,value|
                                    res = self.add_inner(
                                        SignalI.new(key,type,:inner,value))
                                end
                            else
                                raise AnyError,
                                      "Invalid class for a name: #{name.class}"
                            end
                        end
                        return res
                    end
                end

                unless instance_methods.include?(:make_constants) then
                    # Creates and adds a set of contants typed +type+ from a 
                    # hsh given names and corresponding values.
                    def make_constants(type, hsh)
                        res = nil
                        hsh.each do |name,value|
                            # Adds the Constant signal
                            res = self.add_inner(SignalC.new(name,type,value))
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

                unless instance_methods.include?(:constant) then
                    # Declares high-level untyped constant signals by name and
                    # value given by +hsh+ of the current type.
                    def constant(hsh)
                        self.make_constants(bit,hsh)
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
            super(name,Scope.new(name,self))
            # puts "new systemT=#{self}"

            # Initialize the set of extensions to transmit to the instances'
            # eigen class
            @singleton_instanceO = Namespace.new(self.scope)

            # Create the public namespace.
            @public_namespace = Namespace.new(self.scope)

            # Initialize the list of tasks to execute on the instance.
            @on_instances = []

            # Check and set the mixins.
            mixins.each do |mixin|
                unless mixin.is_a?(SystemT) then
                    raise AnyError,
                          "Invalid class for inheriting: #{mixin.class}."
                end
            end
            @to_includes = mixins

            # The list of systems the current system is expanded from if any.
            # The first one is the main system, the other ones are the
            # mixins.
            @generators = []

            # Prepare the instantiation methods
            make_instantiater(name,SystemI,&ruby_block)
        end


        # Tell if the current system is a descedent of +system+
        def of?(system)
            # Maybe self is system.
            if (self == system) then
                # Yes, consider it is adescendent of system.
                return true
            else
                # Look into the generators.
                @generators.each do |generator|
                    return true if generator.of?(system)
                end
                # Look into the included systems.
                @to_includes.each do |included|
                    return true if included.of?(system)
                end
            end
            # Not found.
            return false
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
            # Check if called within the top scope of the block.
            if High.top_user != @scope then
                # No, cannot make an input from here.
                raise AnyError,
                      "Input signals can only be declared in the top scope of a system."
            end
            res = nil
            names.each do |name|
                if name.respond_to?(:to_sym) then
                    res = self.add_input(SignalI.new(name,type,:input))
                elsif name.is_a?(Hash) then
                    # Names associated with values.
                    names.each do |name,value|
                        res = self.add_inner(
                            SignalI.new(name,type,:inner,value))
                    end
                else
                    raise AnyError, "Invalid class for a name: #{name.class}"
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
                elsif name.is_a?(Hash) then
                    # Names associated with values.
                    name.each do |key,value|
                        res = self.add_output(
                            SignalI.new(key,type,:output,value))
                    end
                else
                    raise AnyError, "Invalid class for a name: #{name.class}"
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
                elsif name.is_a?(Hash) then
                    # Names associated with values.
                    names.each do |name,value|
                        res = self.add_inner(
                            SignalI.new(name,type,:inner,value))
                    end
                else
                    raise AnyError, "Invalid class for a name: #{name.class}"
                end
            end
            return res
        end


        # Gets an input signal by +name+ considering also the included
        # systems
        def get_input_with_included(name)
            # Look in self.
            found = self.get_input(name)
            return found if found
            # Not in self, look in the included systems.
            self.scope.each_included do |included|
                found = included.get_input_with_included(name)
                return found if found
            end
            # Not found
            return nil
        end

        # Gets an output signal by +name+ considering also the included
        # systems
        def get_output_with_included(name)
            # Look in self.
            found = self.get_output(name)
            return found if found
            # Not in self, look in the included systems.
            self.scope.each_included do |included|
                found = included.get_output_with_included(name)
                return found if found
            end
            # Not found
            return nil
        end

        # Gets an inout signal by +name+ considering also the included
        # systems
        def get_inout_with_included(name)
            # Look in self.
            found = self.get_inout(name)
            return found if found
            # Not in self, look in the included systems.
            self.scope.each_included do |included|
                found = included.get_inout_with_included(name)
                return found if found
            end
            # Not found
            return nil
        end

        # Iterates over the all signals (input, output, inout, inner, constant),
        # i.e, also the ones of the included systems.
        #
        # Returns an enumerator if no ruby block is given.
        def each_signal_all_with_included(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_signal_all_with_included) unless ruby_block
            # Iterate on all the signals of the current system.
            self.each_signal_all(&ruby_block)
            # Recurse on the included systems.
            self.scope.each_included do |included|
                included.each_signal_all_with_included(&ruby_block)
            end
        end

        # Iterates over the all interface signals, i.e, also the ones of
        # the included systems.
        #
        # Returns an enumerator if no ruby block is given.
        def each_signal_with_included(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_signal_with_included) unless ruby_block
            # Iterate on all the signals of the current system.
            self.each_signal(&ruby_block)
            # Recurse on the included systems.
            self.scope.each_included do |included|
                included.each_signal_with_included(&ruby_block)
            end
        end

        # Get one of all the interface signal by index, i.e., also the ones
        # of the included systems.
        def get_interface_with_included(i)
            return each_signal_with_included.to_a[i]
        end

        # Gets a signal by +name+ considering also the included
        # systems
        def get_signal_with_included(name)
            return get_input_with_included(name) ||
                   get_output_with_included(name) ||
                   get_inout_with_included(name)
        end

        # Iterates over the exported constructs
        #
        # NOTE: look into the scope.
        def each_export(&ruby_block)
            @scope.each_export(&ruby_block)
        end

        # Adds a generator system.
        def add_generator(gen) 
            unless gen.is_a?(SystemT) then
                raise "Invalid class for a generator system"
            end
            @generators << gen
        end

        # Iterates over the origin systems.
        #
        # Returns an enumerator if no ruby block is given.
        def each_generator(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_generator) unless ruby_block
            # A block? Apply it on each generator.
            @generators.each(&ruby_block)
        end

        # Gets class containing the extension for the instances.
        def singleton_instance
            @singleton_instanceO.singleton_class
        end

        # Gets the private namespace of the system.
        def namespace
            return self.scope.namespace
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
        
        # The instantiation target class.
        attr_reader :instance_class

        # Iterates over the instance procedures.
        #
        # Returns an enumerator if no ruby block is given.
        def each_instance_proc(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_instance_proc) unless ruby_block
            # A block? Apply it on each input signal instance.
            @instance_procs.each(&ruby_block)
        end

        # Expands the system with possible arugments +args+ to a new system
        # named +name+.
        def expand(name, *args)
            # puts "expand #{self.name} to #{name}"
            # Create the new system.
            expanded = self.class.new(name.to_s) {}
            # Include the mixin systems given when declaring the system.
            @to_includes.each { |system| expanded.scope.include(system) }
            # Include the previously includeds. */
            self.scope.each_included { |system| expanded.scope.include(system) }

            # Sets the generators of the expanded result.
            expanded.add_generator(self)
            # puts "expanded=#{expanded}"
            @to_includes.each { |system| expanded.add_generator(system) }
            # Also for the previously includeds. */
            self.scope.each_included.each { |system| expanded.add_generator(system) }

            # Fills the scope of the expanded class.
            # puts "Build top with #{self.name} for #{name}"
            expanded.scope.build_top(self.scope,*args)
            # puts "Top built with #{self.name} for #{name}"
            return expanded
        end

        # Make a system eigen of a given +instance+.
        def eigenize(instance)
            unless instance.systemT == self then
                raise "Cannot eigenize system #{self.name} to instance #{instance.name}"
            end
            # The instance becames the owner.
            @owner = instance
            # Fill the public namespace
            space = self.public_namespace
            # Interface signals
            self.each_signal do |signal|
                # puts "signal=#{signal.name}"
                space.send(:define_singleton_method,signal.name) do
                    RefObject.new(instance.to_ref,signal)
                end
            end
            # Exported objects
            self.each_export do |export|
                # puts "export=#{export.name}"
                space.send(:define_singleton_method,export.name) do
                    RefObject.new(instance.to_ref,export)
                end
            end

            return self
        end


        # Adds a task to apply on the instances of the system.
        def on_instance(&ruby_block)
            @on_instances << ruby_block
        end

        # Iterate over the task to apply on the instances of the system.
        def each_on_instance(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_on_instance) unless ruby_block
            # A block? Apply it on each overload if any.
            @on_instances.each(&ruby_block)
        end


        # Instantiate the system type to an instance named +i_name+ with
        # possible arguments +args+.
        def instantiate(i_name,*args)
            # Create the eigen type.
            # eigen = self.expand(High.names_create(i_name.to_s + ":T"), *args)
            eigen = self.expand(HDLRuby.uniq_name(i_name.to_s + ":T"), *args)

            # Create the instance and sets its eigen system to +eigen+.
            instance = @instance_class.new(i_name,eigen)
            # puts "instance=#{instance}"
            eigen.eigenize(instance)

            # Extend the instance.
            instance.eigen_extend(@singleton_instanceO)
            # puts "instance scope= #{instance.systemT.scope}"
            # Add the instance if instantiating within another system.
            High.top_user.send(:add_systemI,instance) if High.top_user
            
            # Execute the post instantiation tasks.
            eigen.each_on_instance { |task| task.(instance) }

            # Return the resulting instance
            return instance
        end

        # Instantiation can also be done throw the call operator.
        alias_method :call, :instantiate

        # Generates the instantiation capabilities including an instantiation
        # method +name+ for hdl-like instantiation, target instantiation as
        # +klass+, added to the calling object, and
        # whose eigen type is initialized by +ruby_block+.
        #
        # NOTE: actually creates two instantiater, a general one, being
        #       registered in the namespace stack, and one for creating an
        #       array of instances being registered in the Array class.
        def make_instantiater(name,klass,&ruby_block)
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
                # puts "Instantiating #{name} with args=#{args.size}"
                # If no arguments, return the system as is
                return obj if args.empty?
                # Are there any generic arguments?
                if ruby_block.arity > 0 then
                    # Yes, must specialize the system with the arguments.
                    # If arguments, create a new system specialized with them
                    return SystemT.new(:"") { include(obj,*args) }
                end
                # It is the case where it is an instantiation
                # Get the names from the arguments.
                i_names = args.shift
                # puts "i_names=#{i_names}(#{i_names.class})"
                i_names = [*i_names]
                instance = nil # The current instance
                i_names.each do |i_name|
                    # Instantiate.
                    instance = obj.instantiate(i_name,*args)
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
        #
        # Retuns the last declared input.
        def input(*names)
            self.make_inputs(bit,*names)
        end

        # Declares high-level bit output signals named +names+.
        #
        # Retuns the last declared input.
        def output(*names)
            self.make_outputs(bit,*names)
        end

        # Declares high-level bit inout signals named +names+.
        #
        # Retuns the last declared input.
        def inout(*names)
            self.make_inouts(bit,*names)
        end

        # Extend the class according to another +system+.
        def extend(system)
            # Adds the singleton methods
            self.eigen_extend(system)
            # Adds the singleton methods for the instances.
            @singleton_instanceO.eigen_extend(system.singleton_instance)
        end

        # Casts as an included +system+.
        #
        # NOTE: use the includes of the scope.
        def as(system)
            # return self.scope.as(system.scope)
            return self.scope.as(system)
        end

        include Hmux


        # Merge the included systems interface in current system.
        # NOTE: incompatible with further to_low transformation.
        def merge_included!
            # puts "merge_included! for system=#{self.name}"
            # Recurse on the system instances.
            self.scope.merge_included!
            # Merge for current system.
            self.scope.merge_included(self)
        end


        # Fills the interface of a low level system.
        def fill_interface_low(systemTlow)
            # Adds its input signals.
            self.each_input { |input|  systemTlow.add_input(input.to_low) }
            # Adds its output signals.
            self.each_output { |output| systemTlow.add_output(output.to_low) }
            # Adds its inout signals.
            self.each_inout { |inout|  systemTlow.add_inout(inout.to_low) }
            # Adds the interface of its included systems.
            self.scope.each_included do |included|
                included.fill_interface_low(systemTlow)
            end
        end

        # Fills a low level system with self's contents.
        #
        # NOTE: name conflicts are treated in the current NameStack state.
        def fill_low(systemTlow)
            # Fills the interface
            self.fill_interface_low(systemTlow)
        end

        # Converts the system to HDLRuby::Low and set its +name+.
        def to_low(name = self.name)
            name = name.to_s
            if name.empty? then
                raise AnyError, 
                      "Cannot convert a system without a name to HDLRuby::Low."
            end
            # Create the resulting low system type.
            # systemTL = HDLRuby::Low::SystemT.new(High.names_create(name),
            systemTL = HDLRuby::Low::SystemT.new(HDLRuby.uniq_name(name),
                                                   self.scope.to_low)
            # puts "New low from system #{self.name}: #{systemTL.name}"
            # # For debugging: set the source high object 
            # systemTL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = systemTL

            # Fills the interface of the new system 
            # from the included systems.
            self.fill_low(systemTL)
            # Return theresulting system.
            return systemTL
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
            # Initialize the set of included systems.
            # @includes = {}
            @includes = []

            # Builds the scope if a ruby block is provided.
            self.build(&ruby_block) if block_given?
        end

        # Converts to a namespace user.
        def to_user
            # Already a user.
            return self
        end

        # Adds a group of system +instances+ named +name+.
        def add_groupI(name, *instances)
            # Ensure name is a symbol and is not already used for another
            # group.
            name = name.to_sym
            if @groupIs.key?(name)
                raise AnyError,
                      "Group of system instances named #{name} already exist."
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
            raise AnyError, "Invalid name for export: #{name}"
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
            # A block? Apply it on each included system.
            # @includes.each_value(&ruby_block)
            @includes.each(&ruby_block)
            # And apply on the sub scopes if any.
            @scopes.each {|scope| scope.each_included(&ruby_block) }
        end


        # Opens for extension.
        #
        # NOTE: actually executes +ruby_block+ in the context.
        def open(&ruby_block)
            High.space_push(@namespace)
            res = High.top_user.instance_eval(&ruby_block)
            High.space_pop
            # Return the result of the execution so that it can be used
            # as an expression
            res
        end


        # Build the scope by executing +ruby_block+.
        #
        # NOTE: used when the scope is not the top of a system.
        def build(&ruby_block)
            # Set the namespace for buidling the scope.
            High.space_push(@namespace)
            # Build the scope.
            @return_value = High.top_user.instance_eval(&ruby_block)
            # res = High.top_user.instance_eval(&ruby_block)
            High.space_pop
            # # Now gain access to the result within the sub scope.
            # # if (res.is_a?(HRef)) then
            # if (res.is_a?(HExpression)) then
            #     High.space_push(@namespace)
            #     @return_value = res.type.inner(HDLRuby.uniq_name)
            #     @return_value <= res
            #     High.space_pop
            #     @return_value = RefObject.new(self,@return_value)
            # else
            #     @return_value = res
            # end
            # This will be the return value.
            @return_value
        end


        # Builds the scope using +base+ as model scope with possible arguments
        # +args+.
        #
        # NOTE: Used by the instantiation procedure of a system.
        def build_top(base,*args)
            # Fills its namespace with the content of the base scope
            # (this latter may already contains access points if it has been
            #  opended for extension previously).
            @namespace.concat_namespace(base.namespace)
            High.space_push(@namespace)
            # Execute the instantiation block
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

        # Declares a non-HDLRuby set of code chunks described by +content+ and
        # completed from +ruby_block+ execution result.
        # NOTE: content includes the events to activate the code on and
        #       a description of the code as a hash assotiating names
        #       to code text.
        def code(*content, &ruby_block)
            # Process the content.
            # Separate events from code chunks descriptions.
            events, chunks = content.partition {|elem| elem.is_a?(Event) }
            # Generates a large hash from the code.
            chunks = chunks.reduce(:merge)
            # Adds the result of the ruby block if any.
            if ruby_block then
                chunks.merge(HDLRuby::High.top_user.instance_eval(&ruby_block))
            end
            # Create the chunk objects.
            chunks = chunks.each.map do |name,content|
                content = [*content]
                # Process the lumps
                content.map! do |lump|
                    lump.respond_to?(:to_expr) ? lump.to_expr : lump
                end
                Chunk.new(name,*content)
            end
            # Create the code object.
            res = Code.new
            # Adds the events.
            events.each(&res.method(:add_event))
            # Adds the chunks.
            chunks.each(&res.method(:add_chunk))
            # Adds the resulting code to the current scope.
            HDLRuby::High.top_user.add_code(res)
            # Return the resulting code
            return res
        end

        # Declares a sub scope with possible +name+ and built from +ruby_block+.
        def sub(name = :"", &ruby_block)
            # Ensure there is a block.
            ruby_block = proc {} unless block_given?
            # Creates the new scope.
            # scope = Scope.new(name,&ruby_block)
            scope = Scope.new(name)
            # Add it
            self.add_scope(scope)
            # Build it.
            scope.build(&ruby_block)
            # puts "self=#{self}"
            # puts "self scopes=#{self.each_scope.to_a.join(",")}"
            # Use its return value
            return scope.return_value
        end

        # Declares a high-level sequential behavior activated on a list of
        # +events+, and built by executing +ruby_block+.
        def seq(*events, &ruby_block)
            # Ensure there is a block.
            ruby_block = proc {} unless block_given?
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
            # Ensure there is a block.
            ruby_block = proc {} unless block_given?
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
            # Ensure there is a block.
            ruby_block = proc {} unless block_given?
            # Create and add the resulting behavior.
            self.add_behavior(TimeBehavior.new(:seq,&ruby_block))
        end

        # Statements automatically enclosed in a behavior.
        
        # Creates a new if statement with a +condition+ that when met lead
        # to the execution of the block in +mode+ generated by the +ruby_block+.
        #
        # NOTE:
        #  * the else part is defined through the helse method.
        #  * a behavior is created to enclose the hif.
        def hif(condition, mode = nil, &ruby_block)
            # Ensure there is a block.
            ruby_block = proc {} unless block_given?
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
            # Ensure there is a block.
            ruby_block = proc {} unless block_given?
            # There is a ruby_block: the helse is assumed to be with
            # the last statement of the last behavior.
            statement = self.last_behavior.last_statement
            # Completes the hif or the hcase statement.
            unless statement.is_a?(If) or statement.is_a?(Case) then
                raise AnyError, "Error: helse statement without hif nor hcase (#{statement.class})."
            end
            statement.helse(mode, &ruby_block)
        end

        # Sets the condition check when the condition is not met to the block,
        # with a +condition+ that when met lead
        # to the execution of the block in +mode+ generated by the +ruby_block+.
        def helsif(condition, mode = nil, &ruby_block)
            # Ensure there is a block.
            ruby_block = proc {} unless block_given?
            # There is a ruby_block: the helse is assumed to be with
            # the last statement of the last behavior.
            statement = self.last_behavior.last_statement
            # Completes the hif statement.
            unless statement.is_a?(If) then
                raise AnyError, "Error: helsif statement without hif (#{statement.class})."
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
            # Ensure there is a block.
            ruby_block = proc {} unless block_given?
            # There is a ruby_block: the helse is assumed to be with
            # the last statement of the last behavior.
            statement = @behaviors.last.last_statement
            # Completes the hcase statement.
            unless statement.is_a?(Case) then
                raise AnyError, "Error: hwhen statement without hcase (#{statement.class})."
            end
            statement.hwhen(match, mode, &ruby_block)
        end
        

        # Sets the constructs corresponding to +names+ as exports.
        def export(*names)
            names.each {|name| self.add_export(name) }
        end

        # Include a +system+ type with possible +args+ instanciation
        # arguments.
        def include(system,*args)
            # if @includes.key?(system.name) then
            #     raise AnyError, "Cannot include twice the same system: #{system}"
            # end
            if @includes.include?(system) then
                raise AnyError, "Cannot include twice the same system: #{system}"
            end
            # # puts "Include system=#{system.name}"
            # # Save the name of the included system, it will serve as key
            # # for looking for the included expanded version.
            # include_name = system.name
            # Expand the system to include
            system = system.expand(:"",*args)
            # Add the included system interface to the current one.
            if self.parent.is_a?(SystemT) then
                space = self.namespace
                # Interface signals
                # puts "i_name=#{i_name} @to_includes=#{@to_includes.size}"
                # system.each_signal_with_included do |signal|
                system.each_signal_all_with_included do |signal|
                    # puts "signal=#{signal.name}"
                    space.send(:define_singleton_method,signal.name) do
                        signal
                    end
                end
                # Exported objects
                system.each_export do |export|
                    # puts "export=#{export.name}"
                    space.send(:define_singleton_method,export.name) do
                        export
                    end
                end
                # Adds the task to execute on the instance.
                system.each_on_instance do |task|
                    self.parent.on_instance(&task)
                end
            end
            # Adds it the list of includeds
            # @includes[include_name] = system
            @includes << system

            # puts "@includes=#{@includes}"
            
        end

        # Obsolete
        # # Casts as an included +system+.
        # def as(system)
        #     # puts "as with name: #{system.name}"
        #     system = system.name if system.respond_to?(:name)
        #     return @includes[system].namespace
        # end


        # Gets the current system.
        def cur_system
            return HDLRuby::High.cur_system
        end

        include Hmux



        # Merge the included systems interface in +systemT+
        # NOTE: incompatible with further to_low transformation.
        def merge_included(systemT)
            # Recurse on the sub.
            self.each_scope {|scope| scope.merge_included(systemT) }
            # Include for current scope.
            self.each_included do |included|
                included.merge_included!
                # Adds its interface signals.
                included.each_input do |input|
                    input.no_parent!
                    systemT.add_input(input)
                end
                included.each_output do |output|  
                    output.no_parent!
                    systemT.add_output(output)
                end
                included.each_inout do |inout|  
                    inout.no_parent!
                    systemT.add_inout(inout)
                end
                # Adds its behaviors.
                included.scope.each_behavior do |beh|
                    beh.no_parent!
                    systemT.scope.add_behavior(beh)
                end
                # Adds its connections.
                included.scope.each_connection do |cx|
                    cx.no_parent!
                    systemT.scope.add_connection(cx)
                end
                # Adds its sytem instances.
                included.scope.each_systemI do |sys|
                    sys.no_parent!
                    systemT.scope.add_systemI(sys)
                end
                # Adds its code.
                included.scope.each_code do |code|
                    code.no_parent!
                    systemT.scope.add_code(code)
                end
                # Adds its subscopes.
                included.scope.each_scope do |scope|
                    scope.no_parent!
                    systemT.scope.add_scope(scope)
                end
                # Add its inner signals.
                included.scope.each_inner do |inner|
                    inner.no_parent!
                    systemT.scope.add_inner(inner)
                end
            end
        end

        # Merge the included systems interface in system instances.
        # NOTE: incompatible with further to_low transformation.
        def merge_included!
            # Recurse on the sub.
            self.each_scope {|scope| scope.merge_included! }
            # Merge in the system instances.
            self.each_systemI {|systemI| systemI.systemT.merge_included! }
        end


        # Fills a low level scope with self's contents.
        #
        # NOTE: name conflicts are treated in the current NameStack state.
        def fill_low(scopeL)
            # Adds the content of its included systems.
            # @includes.each_value {|system| system.scope.fill_low(scopeL) }
            @includes.each {|system| system.scope.fill_low(scopeL) }
            # Adds the declared local system types.
            # NOTE: in the current version of HDLRuby::High, there should not
            # be any of them (only eigen systems are real system types).
            self.each_systemT { |systemT| scopeL.add_systemT(systemT.to_low) }
            # Adds the local types.
            self.each_type { |type| scopeL.add_type(type.to_low) }
            # Adds the inner scopes.
            self.each_scope { |scope| scopeL.add_scope(scope.to_low) }
            # Adds the inner signals.
            self.each_inner { |inner| scopeL.add_inner(inner.to_low) }
            # Adds the instances.
            # Single ones.
            self.each_systemI do |systemI|
                # puts "Filling with systemI=#{systemI.name}"
                systemI_low = scopeL.add_systemI(systemI.to_low)
                # Also add the eigen system to the list of local systems.
                scopeL.add_systemT(systemI_low.systemT)
            end
            # Grouped ones.
            self.each_groupI do |name,systemIs|
                systemIs.each.with_index { |systemI,i|
                    # Sets the name of the system instance
                    # (required for conversion of further accesses).
                    # puts "systemI.respond_to?=#{systemI.respond_to?(:name=)}"
                    systemI.name = name.to_s + "[#{i}]"
                    # And convert it to low
                    systemI_low = scopeL.add_systemI(systemI.to_low())
                    # Also add the eigen system to the list of local systems.
                    scopeL.add_systemT(systemI_low.systemT)
                }
            end
            # Adds the code chunks.
            self.each_code { |code| scopeL.add_code(code.to_low) }
            # Adds the connections.
            self.each_connection { |connection|
                # puts "connection=#{connection}"
                scopeL.add_connection(connection.to_low)
            }
            # Adds the behaviors.
            self.each_behavior { |behavior|
                scopeL.add_behavior(behavior.to_low)
            }
        end

        # Converts the scope to HDLRuby::Low.
        def to_low()
            # Create the resulting low scope.
            # scopeL = HDLRuby::Low::Scope.new()
            scopeL = HDLRuby::Low::Scope.new(self.name)
            # # For debugging: set the source high object 
            # scopeL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = scopeL

            # Push the private namespace for the low generation.
            High.space_push(@namespace)
            # Pushes on the name stack for converting the internals of
            # the system.
            High.names_push
            # Adds the content of the actual system.
            self.fill_low(scopeL)
            # Restores the name stack.
            High.names_pop
            # Restores the namespace stack.
            High.space_pop
            # Return theresulting system.
            return scopeL
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

        # Converts to a type.
        # Returns self since it is already a type.
        def to_type
            return self
        end

        # Sets the +name+.
        #
        # NOTE: can only be done if the name is not already set.
        def name=(name)
            unless @name.empty? then
                raise AnyError, "Name of type already set to: #{@name}."
            end
            # Checks and sets the name.
            name = name.to_sym
            if name.empty? then
                raise AnyError, "Cannot set an empty name."
            end
            @name = name
            # Registers the name.
            self.register(name)
        end

        # Register the +name+ of the type.
        def register(name)
            if self.name.empty? then
                raise AnyError, "Cannot register with empty name."
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
            High.top_user.make_inners(self,*names)
        end

        # Declares high-level untyped constant signals by name and
        # value given by +hsh+ of the current type.
        def constant(hsh)
            High.top_user.make_constants(self,hsh)
        end

        # Computations of expressions
        
        # Gets the computation method for +operator+.
        def comp_operator(op)
            return (op.to_s + ":C").to_sym
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
            # Ensure there is a block.
            ruby_block = proc {} unless block_given?
            # Register the operator as overloaded.
            @overloads ||= {}
            @overloads[operator] = ruby_block
            # Set the new method for the operator.
            self.define_singleton_method(comp_operator(operator)) do |*args|
                # puts "Top user=#{HDLRuby::High.top_user}"
                HDLRuby::High.top_user.instance_exec do
                   sub do
                        HDLRuby::High.top_user.instance_exec(*args,&ruby_block)
                   end
                end
            end
        end

        # Interates over the overloaded operators.
        def each_overload(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_overload) unless ruby_block
            # A block? Apply it on each overload if any.
            @overloads.each(&ruby_block) if @overloads
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
        end

        # Converts the type to HDLRuby::Low and set its +name+.
        #
        # NOTE: should be overridden by other type classes.
        def to_low(name = self.name)
            # return HDLRuby::Low::Type.new(name)
            typeL = HDLRuby::Low::Type.new(name)
            # # For debugging: set the source high object 
            # typeL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = typeL
            return typeL
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
        # Converts the type to HDLRuby::Low.
        def to_low
            return Low::Bit
        end

        include HbasicType
    end

    # The signed bit type.
    Signed = define_type(:signed)
    class << Signed 
        # Converts the type to HDLRuby::Low.
        def to_low
            return Low::Signed
        end

        include HbasicType
    end

    # The unsigned bit type.
    Unsigned = define_type(:unsigned)
    class << Unsigned
        # Converts the type to HDLRuby::Low.
        def to_low
            return Low::Unsigned
        end

        include HbasicType
    end

    # The float bit type
    Float = define_type(:float)
    class << Float
        # Converts the type to HDLRuby::Low.
        def to_low
            return Low::Float
        end

        include HbasicType
    end

    # The string type
    StringT = define_type(:string)
    class << StringT
        # Converts the type to HDLRuby::Low.
        def to_low
            return Low::StringT
        end

        include HbasicType
    end


    # # The infer type.
    # # Unspecified, but automatically infered when connected.
    # Infer = define_type(:infer)
    # class << Infer
    #     # The specified type.
    #     attr_reader :type

    #     # Sets the specifed type to typ.
    #     def type=(typ)
    #         # Ensure typ is a type.
    #         typ = typ.to_type
    #         unless @type
    #             @type = typ
    #         else
    #             unless @type.eql(typ)
    #                 raise AnyError.new("Invalid type for connection to auto type: expecting #{@type} but got #{typ}")
    #             end
    #         end
    #         return self
    #     end

    #     # Converts the type to HDLRuby::low.
    #     # Actually returns the HDLRuby::low version of the specified type.
    #     def to_low
    #         return type.to_low
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
            # return HDLRuby::Low::TypeDef.new(name,self.def.to_low)
            typeDefL = HDLRuby::Low::TypeDef.new(name,self.def.to_low)
            # # For debugging: set the source high object 
            # typeDefL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = typeDefL
            return typeDefL
        end
    end


    ##
    # Describes a high-level generic type definition.
    #
    # NOTE: this type does not correspond to any low-level type
    class TypeGen< Type
        High = HDLRuby::High

        # Type creation.

        # Creates a new generic type definition producing a new type by
        # executing +ruby_block+.
        def initialize(name,&ruby_block)
            # Initialize the type structure.
            super(name)

            # Sets the block to execute when instantiating the type.
            @instance_proc = ruby_block
        end

        # Generates the type with +args+ generic parameters.
        def generate(*args)
            # Generate the resulting type.
            gtype = High.top_user.instance_exec(*args,&@instance_proc)
            # Ensures a type has been produced.
            gtype = gtype.to_type if gtype.respond_to?(:to_type)
            unless gtype.is_a?(HDLRuby::Low::Type) then
                raise AnyError, "Generic type #{self.name} did not produce a valid type: #{gtype.class}"
            end
            # Create a new type definition from it.
            gtype = TypeDef.new(self.name.to_s + "_#{args.join(":")}",
                                   gtype)
            # Adds the possible overloaded operators.
            self.each_overload do |op,ruby_block|
                gtype.define_operator(op,&(ruby_block.curry[*args]))
            end
            # Returns the resulting type
            return gtype
        end

        # Converts the type to HDLRuby::Low and set its +name+.
        #
        # NOTE: should be overridden by other type classes.
        def to_low(name = self.name)
            # return HDLRuby::Low::TypeDef.new(name,self.def.to_low)
            typeDefL = HDLRuby::Low::TypeDef.new(name,self.def.to_low)
            # # For debugging: set the source high object 
            # typeDefL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = typeDefL
            return typeDefL
        end
    end



    # Methods for vector types.
    module HvectorType
        # Converts the type to HDLRuby::Low and set its +name+.
        def to_low(name = self.name)
            # Generate and return the new type.
            # return HDLRuby::Low::TypeVector.new(name,self.base.to_low,
            #                                     self.range.to_low)
            typeVectorL = HDLRuby::Low::TypeVector.new(name,self.base.to_low,
                                                self.range.to_low)
            # # For debugging: set the source high object 
            # typeVectorL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = typeVectorL
            return typeVectorL
        end
    end


    ##
    # Describes a vector type.
    # class TypeVector < TypeExtend
    class TypeVector < Low::TypeVector
        High = HDLRuby::High
        include Htype
        include HvectorType
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
            # return HDLRuby::Low::TypeTuple.new(name,self.direction,
            #                    *@types.map { |type| type.to_low } )
            typeTupleL = HDLRuby::Low::TypeTuple.new(name,self.direction,
                               *@types.map { |type| type.to_low } )
            # # For debugging: set the source high object 
            # typeTupleL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = typeTupleL
            return typeTupleL
        end
    end


    ##
    # Describes a structure type.
    class TypeStruct < Low::TypeStruct
        High = HDLRuby::High

        include Htype

        # Converts the type to HDLRuby::Low and set its +name+.
        def to_low(name = self.name)
            # return HDLRuby::Low::TypeStruct.new(name,self.direction,
            #                     @types.map { |name,type| [name,type.to_low] } )
            typeStructL = HDLRuby::Low::TypeStruct.new(name,self.direction,
                                @types.map { |name,type| [name,type.to_low] } )
            # # For debugging: set the source high object 
            # typeStructL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = typeStructL
            return typeStructL
        end
    end



    ## Methods for declaring system types and functions.

    # The type constructors.

    # Creates an unnamed structure type from a +content+.
    def struct(content)
        return TypeStruct.new(:"",:little,content)
    end

    # Methods for declaring types

    # Declares a high-level generic type named +name+, and using +ruby_block+
    # for construction.
    def typedef(name, &ruby_block)
        # Ensure there is a block.
        ruby_block = proc {} unless block_given?
        type = TypeGen.new(name,&ruby_block)
        if HDLRuby::High.in_system? then
            # Must be inside a scope.
            unless HDLRuby::High.top_user.is_a?(Scope) then
                raise AnyError, "A local type cannot be declared within a #{HDLRuby::High.top_user.class}."
            end
            define_singleton_method(name.to_sym) do |*args|
                if (args.size < ruby_block.arity) then
                    # Not enough arguments get generic type as is.
                    type
                else
                    # There are arguments, specialize the type.
                    gtype = type.generate(*args)
                    # And add it as a local type of the system.
                    HDLRuby::High.top_user.add_type(gtype)
                end
            end
        else
            define_method(name.to_sym) do |*args|
                if (args.size < ruby_block.arity) then
                    # Not enough arguments, get generic type as is.
                    type
                else
                    # There are arguments, specialize the type.
                    type.generate(*args)
                end
            end
        end
    end

    # Methods for declaring systems

    # Declares a high-level system type named +name+, with +includes+ mixins
    # system types and using +ruby_block+ for instantiating.
    def system(name = :"", *includes, &ruby_block)
        # Ensure there is a block.
        ruby_block = proc {} unless block_given?
        # print "system ruby_block=#{ruby_block}\n"
        # Creates the resulting system.
        return SystemT.new(name,*includes,&ruby_block)
    end

    # Declares a high-level system instance named +name+, with +includes+
    # mixins system types and using +ruby_block+ for instantiating.
    #
    # NOTE: this is for generating directly an instance without declaring
    #       it system type.
    def instance(name, *includes, &ruby_block)
        # Ensure there is a block.
        ruby_block = proc {} unless block_given?
        # Creates the system type.
        systemT = system(:"",*includes,&ruby_block)
        # Instantiate it with +name+.
        return systemT.instantiate(name) 
    end

    # Methods for declaring functions

    # Declares a function named +name+ using +ruby_block+ as body.
    #
    # NOTE: a function is a short-cut for a method that creates a scope.
    def function(name, &ruby_block)
        # Ensure there is a block.
        ruby_block = proc {} unless block_given?
        if HDLRuby::High.in_system? then
            define_singleton_method(name.to_sym) do |*args,&other_block|
                # sub do
                sub(HDLRuby.uniq_name(name)) do
                    HDLRuby::High.top_user.instance_exec(*args,*other_block,
                                                         &ruby_block)
                    # ruby_block.call(*args)
                end
            end
        else
            define_method(name.to_sym) do |*args,&other_block|
                # sub do
                sub(HDLRuby.uniq_name(name)) do
                    HDLRuby::High.top_user.instance_exec(*args,*other_block,
                                                         &ruby_block)
                    # ruby_block.call(*args,*other_block)
                end
            end
        end
    end




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
            if connects.size == 1 and connects[0].respond_to?(:to_h) and
                !connects[0].is_a?(HRef) then
                # Yes, perform a connection by name
                connects = connects[0].to_h
                # Performs the connections.
                connects.each do |key,value|
                    # Gets the signal corresponding to connect.
                    # signal = self.get_signal(key)
                    # unless signal then
                    #     # Look into the included systems.
                    #     self.systemT.scope.each_included do |included|
                    #         signal = included.get_signal(key)
                    #         break if signal
                    #     end
                    # end
                    signal = self.systemT.get_signal_with_included(key)
                    # Check if it is an output.
                    # isout = self.get_output(key)
                    # unless isout then
                    #     # Look into the inlucded systems.
                    #     self.systemT.scope.each_included do |included|
                    #         isout = included.get_output(key)
                    #         break if isout
                    #     end
                    # end
                    isout = self.systemT.get_output_with_included(key)
                    # Convert it to a reference.
                    # puts "key=#{key} value=#{value} signal=#{signal}"
                    ref = RefObject.new(self.to_ref,signal)
                    # Make the connection.
                    if isout then
                        value <= ref
                    else
                        ref <= value
                    end
                end
            else
                # No, perform a connection is order of declaration
                connects.each.with_index do |csig,i|
                    # puts "systemT inputs=#{systemT.each_input.to_a.size}"
                    # Gets i-est signal to connect
                    ssig = self.systemT.get_interface_with_included(i)
                    # Check if it is an output.
                    isout = self.systemT.get_output_with_included(ssig.name)
                    # puts "ssig=#{ssig.name} isout=#{isout}"
                    # Convert it to a reference.
                    ssig = RefObject.new(self.to_ref,ssig)
                    # Make the connection.
                    if isout then
                        csig <= ssig
                        # csig.to_ref <= ssig
                    else
                        ssig <= csig
                        # ssig <= csig.to_expr
                    end
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
            # Ensure there is a block.
            ruby_block = proc {} unless block_given?
            # Extend the eigen system.
            @systemT.run(&ruby_block)
            # Update the methods.
            @systemT.eigenize(self)
            self.eigen_extend(@systemT.public_namespace)
        end

        # Adds alternative system +systemT+
        def choice(configuration = {})
            # Process the argument.
            configuration.each do |k,v|
                k = k.to_sym
                unless v.is_a?(SystemT) then
                    raise "Invalid class for a system type: #{v.class}"
                end
                # Create an eigen system.
                eigen = v.instantiate(HDLRuby.uniq_name(self.name)).systemT
                # Ensure its interface corresponds.
                my_signals = self.each_signal.to_a
                if (eigen.each_signal.with_index.find { |sig,i|
                    !sig.eql?(my_signals[i])
                }) then
                raise "Invalid system for configuration: #{systemT.name}." 
                end
                # Add it.
                # At the HDLRuby::High level
                @choices = { self.name => self.systemT } unless @choices
                @choices[k] = eigen
                # At the HDLRuby::Low level
                self.add_systemT(eigen)
            end
        end

        # (Re)Configuration of system instance to systemT designated by +sys+.
        # +sys+ may be the index or the name of the configuration, the first
        # configuration being named by the systemI name.
        def configure(sys)
            if sys.respond_to?(:to_i) then
                # The argument is an index.
                # Create the (re)configuration node.
                High.top_user.add_statement(
                    Configure.new(RefObject.new(RefThis.new,self),sys.to_i))
            else
                # The argument is a name (should be).
                # Get the index corresponding to the name.
                num = @choices.find_index { |k,_| k == sys.to_sym }
                unless num then
                    raise "Invalid name for configuration: #{sys.to_s}"
                end
                # Create the (re)configuration node.
                High.top_user.add_statement(
                    Configure.new(RefObject.new(RefThis.new,self),num))
            end
        end

        # include Hmissing

        # Missing methods are looked for in the public namespace of the
        # system type.
        def method_missing(m, *args, &ruby_block)
            # print "method_missing in class=#{self.class} with m=#{m}\n"
            # Maybe its a signal reference.
            signal = self.systemT.get_signal_with_included(m)
            if signal then
                # Yes, create the reference.
                return RefObject.new(self.to_ref,signal)
            else
                # No try elsewhere
                self.public_namespace.send(m,*args,&ruby_block)
            end
        end


        # Methods to transmit to the systemT
        
        # Gets the public namespace.
        def public_namespace
            self.systemT.public_namespace
        end

        # Gets the private namespace.
        def namespace
            # self.systemT.scope.namespace
            self.systemT.namespace
        end


        # Converts the instance to HDLRuby::Low and set its +name+.
        def to_low(name = self.name)
            # puts "to_low with #{self} (#{self.name}) #{self.systemT}"
            # Converts the system of the instance to HDLRuby::Low
            systemTL = self.systemT.to_low
            # Creates the resulting HDLRuby::Low instance
            systemIL = HDLRuby::Low::SystemI.new(High.names_create(name),
                                             systemTL)
            # # For debugging: set the source high object 
            # systemIL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = systemIL
            # Adds the other systemTs.
            self.each_systemT do |systemTc|
                if systemTc != self.systemT
                    systemTcL = systemTc.to_low
                    systemIL.add_systemT(systemTcL)
                end
            end
            return systemIL
        end
    end



    ##
    # Describes a non-HDLRuby code chunk.
    class Chunk < HDLRuby::Low::Chunk
        # Converts the if to HDLRuby::Low.
        def to_low
            # return HDLRuby::Low::Chunk.new(self.name,
            #                                *self.each_lump.map do |lump|
            #     lump = lump.respond_to?(:to_low) ? lump.to_low : lump.to_s
            #     lump
            # end)
            chunkL = HDLRuby::Low::Chunk.new(self.name,
                                           *self.each_lump.map do |lump|
                lump = lump.respond_to?(:to_low) ? lump.to_low : lump.to_s
                lump
            end)
            # # For debugging: set the source high object 
            # chunkL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = chunkL
            return chunkL
        end
    end

    ##
    # Decribes a set of non-HDLRuby code chunks.
    class Code < HDLRuby::Low::Code
        # Converts the if to HDLRuby::Low.
        def to_low
            # Create the resulting code.
            codeL = HDLRuby::Low::Code.new
            # # For debugging: set the source high object 
            # codeL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = codeL
            # Add the low-level events.
            self.each_event { |event| codeL.add_event(event.to_low) }
            # Add the low-level code chunks.
            self.each_chunk { |chunk| codeL.add_chunk(chunk.to_low) }
            # Return the resulting code.
            return codeL
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
            # # Creates the if statement.
            # return If.new(condition) { self }
            # Remove self from the current block.
            obj = self
            ::HDLRuby::High.cur_block.delete_statement!(obj)
            # Creates the if statement.
            stmnt = If.new(condition) { add_statement(obj) }
            # Add it to the current block.
            ::HDLRuby::High.cur_block.add_statement(stmnt)
            # Returns the result.
            return stmnt
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
            yes_block = High.make_block(mode,&ruby_block)
            # Creates the if statement.
            super(condition.to_expr,yes_block)
        end

        # Sets the block executed in +mode+ when the condition is not met to
        # the block generated by the execution of +ruby_block+.
        #
        # Can only be used once.
        def helse(mode = nil, &ruby_block)
            # Ensure there is a block.
            ruby_block = proc {} unless block_given?
            # If there is a no block, it is an error.
            raise AnyError, "Cannot have two helse for a single if statement." if self.no
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
            # Ensure there is a block.
            ruby_block = proc {} unless block_given?
            # If there is a no block, it is an error.
            raise AnyError, "Cannot have an helsif after an helse." if self.no
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
            ifL = HDLRuby::Low::If.new(self.condition.to_low,
                                       self.yes.to_low,noL)
            self.each_noif {|cond,block| ifL.add_noif(cond.to_low,block.to_low)}
            # # For debugging: set the source high object 
            # ifL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = ifL
            return ifL
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
        end

        # Converts the if to HDLRuby::Low.
        def to_low
            # return HDLRuby::Low::When.new(self.match.to_low,
            #                               self.statement.to_low)
            whenL = HDLRuby::Low::When.new(self.match.to_low,
                                          self.statement.to_low)
            # # For debugging: set the source high object 
            # whenL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = whenL
            return whenL
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
        end

        # Sets the block executed in +mode+ when the value matches +match+.
        # The block is generated by the execution of +ruby_block+.
        #
        # Can only be used once for the given +match+.
        def hwhen(match, mode = nil, &ruby_block)
            # Ensure there is a block.
            ruby_block = proc {} unless block_given?
            # Create the nu block if required
            when_block = High.make_block(mode,&ruby_block)
            # Adds the case.
            self.add_when(When.new(match.to_expr,when_block))
        end

        # Sets the block executed in +mode+ when there were no match to
        # the block generated by the execution of +ruby_block+.
        #
        # Can only be used once.
        def helse(mode = nil, &ruby_block)
            # Ensure there is a block.
            ruby_block = proc {} unless block_given?
            # Create the nu block if required
            default_block = High.make_block(mode,&ruby_block)
            # Sets the default block.
            self.default = default_block
        end

        # Converts the case to HDLRuby::Low.
        def to_low
            # Create the low level case.
            caseL = HDLRuby::Low::Case.new(@value.to_low)
            # # For debugging: set the source high object 
            # caseL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = caseL
            # Add each when case.
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
            # return HDLRuby::Low::Delay.new(self.value, self.unit)
            delayL = HDLRuby::Low::Delay.new(self.value, self.unit)
            # # For debugging: set the source high object 
            # delayL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = delayL
            return delayL
        end
    end

    ##
    # Describes a high-level wait delay statement.
    class TimeWait < Low::TimeWait
        include HStatement

        # Converts the wait statement to HDLRuby::Low.
        def to_low
            # return HDLRuby::Low::TimeWait.new(self.delay.to_low)
            timeWaitL = HDLRuby::Low::TimeWait.new(self.delay.to_low)
            # # For debugging: set the source high object 
            # timeWaitL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = timeWaitL
            return timeWaitL
        end
    end


    ## 
    # Describes a timed loop statement: not synthesizable!
    class TimeRepeat < Low::TimeRepeat
        include HStatement

        # Converts the repeat statement to HDLRuby::Low.
        def to_low
            timeRepeatL = HDLRuby::Low::TimeRepeat.new(self.statement.to_low,
                                                # self.delay.to_low)
                                                self.number)
            # # For debugging: set the source high object 
            # timeRepeatL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = timeRepeatL
            return timeRepeatL
        end
    end

    ## 
    # Describes a timed terminate statement: not synthesizable!
    class TimeTerminate < Low::TimeTerminate
        include HStatement

        # Converts the repeat statement to HDLRuby::Low.
        def to_low
            return HDLRuby::Low::TimeTerminate.new
        end
    end



    ##
    # Module giving high-level expression properties
    module HExpression
        # The system type the expression has been resolved in, if any.
        attr_reader :systemT
        # The type of the expression if resolved.
        attr_reader :type

        # Creates input port +name+ and connect it to the expression.
        def input(name)
            # Ensures the name is a symbol.
            name = name.to_sym
            # Get access to the current expression
            obj = self
            # Create the input.
            port = nil
            HDLRuby::High.cur_system.open do
                port = obj.type.input(name)
            end
            # Make the connection when the instance is ready.
            HDLRuby::High.cur_system.on_instance do |inst|
                obj.scope.open do
                    RefObject.new(inst,port.to_ref) <= obj
                end
            end
            return port
        end

        # Creates output port +name+ and connect it to the expression.
        def output(name)
            # Ensures the name is a symbol.
            name = name.to_sym
            # Get access to the current expression
            obj = self
            # Create the output.
            port = nil
            HDLRuby::High.cur_system.open do
                port = obj.type.output(name)
            end
            # Make the connection when the instance is ready.
            HDLRuby::High.cur_system.on_instance do |inst|
                obj.scope.open do
                    obj <= RefObject.new(inst,port.to_ref)
                end
            end
            return port
        end

        # Creates inout port +name+ and connect it to the expression.
        def inout(name)
            # Ensures the name is a symbol.
            name = name.to_sym
            # Get access to the current expression
            obj = self
            # Create the inout.
            port = nil
            HDLRuby::High.cur_system.open do
                port = obj.type.inout(name)
            end
            # Make the connection when the instance is ready.
            HDLRuby::High.cur_system.on_instance do |inst|
                obj.scope.open do
                    RefObject.new(inst,port.to_ref) <= obj
                end
            end
            return port
        end

        # Tell if the expression can be converted to a value.
        def to_value?
            return false
        end

        # Converts to a new value.
        #
        # NOTE: to be redefined.
        def to_value
            raise AnyError,
                  "Expression cannot be converted to a value: #{self.class}"
        end

        # Tell if the expression is constant.
        def constant?
            # By default not constant.
            return false unless self.each_node.any?
            # If any sub node, check if all of them are constants.
            self.each_node { |node| return false unless node.constant? }
            return true
        end


        # Converts to a new expression.
        #
        # NOTE: to be redefined in case of non-expression class.
        def to_expr
            raise AnyError, "Internal error: to_expr not defined yet for class: #{self.class}"
        end

        # # Converts to a new ref.
        # def to_ref
        #     return RefObject.new(this,self)
        # end

        # Casts as +type+.
        def as(type)
            if (self.parent)
                return Cast.new(type.to_type,self.to_expr)
            else
                return Cast.new(type.to_type,self)
            end
        end

        # Casts to a bit vector type.
        def to_bit
            return self.as(bit[self.width])
        end

        # Casts to an unsigned bit vector type.
        def to_unsigned
            return self.as(unsigned[self.width])
        end

        # Casts to a signed bit vector type.
        def to_unsigned
            return self.as(signed[self.width])
        end

        # Extends on the left to +n+ bits filling with +v+ bit values.
        def ljust(n,v)
            return [(v.to_s * (n-self.width)).to_expr, self]
        end

        # Extends on the right to +n+ bits filling with +v+ bit values.
        def rjust(n,v)
            return [self, (v.to_s * (n-self.width)).to_expr]
        end

        # Extends on the left to +n+ bits filling with 0.
        def zext(n)
            return self.ljust(n,0)
        end

        # Extends on the left to +n+ bits preserving the signe.
        def sext(n)
            return self.ljust(self[-1])
        end

        # # Match the type with +typ+:
        # # - Recurse on the sub expr if hierachical type, raising an error
        # #   if the expression is not hierarchical.
        # # - Directly cast otherwise.
        # def match_type(typ)
        #     # Has the type sub types?
        #     if typ.types? then
        #         unless self.is_a?(Concat) then
        #             raise AnyError,
        #                 "Invalid class for assignment to hierarchical: #{self.class}."
        #         end
        #         return Concat.new(typ,
        #           self.each_expression.zip(typ.each_type).map do |e,t|
        #             e.match_type(t)
        #         end)
        #     elsif typ.vector? && typ.base.hierarchical? then
        #         unless self.is_a?(Concat) then
        #             raise AnyError,
        #                 "Invalid class for assignment to hierarchical: #{self.class}."
        #         end
        #         return Concat.new(typ,
        #           self.each_expression.map do |e|
        #             e.match_type(typ.base)
        #         end)
        #     else
        #         return self.as(typ)
        #     end
        # end

        # Match the type with +typ+: cast if different type.
        def match_type(typ)
            if self.type.eql?(typ) then
                return self
            else
                return self.as(typ)
            end
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
                expr = self.to_expr
                return expr.type.unary(operator,expr)
            end
            # Defines the operator method.
            define_method(operator,&meth) 
            # And save it so that it can still be accessed if overidden.
            define_method(orig_operator(operator),&meth)
        end

        # Left shift of +n+ bits.
        def ls(n)
            return self << n
        end

        # Right shift of +n+ bits.
        def rs(n)
            return self >> n
        end

        # Left rotate of +n+ bits.
        def lr(n)
            w = self.type.width
            return [self[w-(n+1)..0], self[w-1..w-(n)]]
        end

        # Right rotate of +n+ bits.
        def rr(n)
            w = self.type.width
            return [self[(n-1)..0], self[w-1..n]]
        end

        # Coerce by forcing convertion of obj to expression.
        def coerce(obj)
            if obj.is_a?(HDLRuby::Low::Expression) then
                # Already an expression, nothing to do.
                return [obj,self]
            elsif obj.respond_to?(:to_expr) then
                # Can be converted to an expression, do it.
                return [obj.to_expr, self]
            else
                return [obj,self]
            end
        end

        # Adds the binary operations generation.
        [:"+",:"-",:"*",:"/",:"%",:"**",
         :"&",:"|",:"^",
         :"<<",:">>",# :ls,:rs,:lr,:rr, # ls, rs lr and rr are treated separately
         :"==",:"!=",:"<",:">",:"<=",:">="].each do |operator|
             meth = proc do |right|
                 expr = self.to_expr
                 return expr.type.binary(operator,expr,right.to_expr)
             end
             # Defines the operator method.
             define_method(operator,&meth) 
             # And save it so that it can still be accessed if overidden.
             define_method(orig_operator(operator),&meth)
         end


         # Creates an access to elements of range +rng+ of the signal.
         #
         # NOTE: +rng+ can be a single expression in which case it is an index.
         def [](rng)
             if rng.is_a?(::Range) then
                 first = rng.first
                 if (first.is_a?(::Integer)) then
                     first = self.type.size+first if first < 0
                 end
                 last = rng.last
                 if (last.is_a?(::Integer)) then
                     last = self.type.size+last if last < 0
                 end
                 rng = first..last
             end
             if rng.is_a?(::Integer) && rng < 0 then
                 rng = self.type.size+rng
             end
             if rng.respond_to?(:to_expr) then
                 # Number range: convert it to an expression.
                 rng = rng.to_expr
             end 
             if rng.is_a?(HDLRuby::Low::Expression) then
                 # Index case
                 return RefIndex.new(self.type.base,self.to_expr,rng)
             else
                 # Range case, ensure it is made among expression.
                 first = rng.first.to_expr
                 last = rng.last.to_expr
                 # Abd create the reference.
                 return RefRange.new(self.type.slice(first..last),
                                     self.to_expr,first..last)
             end
         end

         # And save it so that it can still be accessed if overidden.
         alias_method orig_operator(:[]), :[]

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
            unless type.respond_to?(:htype?) then
                raise AnyError, "Invalid class for a type: #{type.class}."
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

    end


    ##
    # Module giving high-level properties for handling the arrow (<=) operator.
    module HArrow
        High = HDLRuby::High

        # Creates a transmit, or connection with an +expr+.
        #
        # NOTE: it is converted afterward to an expression if required.
        def <=(expr)
            # Generate a ref from self for the left of the transmit.
            left = self.to_ref
            # Cast expr to self if required.
            expr = expr.to_expr.match_type(left.type)
            # Ensure expr is an expression.
            expr = expr.to_expr
            # Cast it to left if necessary.
            expr = expr.as(left.type) unless expr.type.eql?(left.type)
            # Generate the transmit.
            if High.top_user.is_a?(HDLRuby::Low::Block) then
                # We are in a block, so generate and add a Transmit.
                High.top_user.
                    # add_statement(Transmit.new(self.to_ref,expr))
                    add_statement(Transmit.new(left,expr))
            else
                # We are in a system type, so generate and add a Connection.
                High.top_user.
                    # add_connection(Connection.new(self.to_ref,expr))
                    add_connection(Connection.new(left,expr))
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
            # return HDLRuby::Low::Cast.new(self.type.to_low,self.child.to_low)
            castL =HDLRuby::Low::Cast.new(self.type.to_low,self.child.to_low)
            # # For debugging: set the source high object 
            # castL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = castL
            return castL
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
            # return HDLRuby::Low::Unary.new(self.type.to_low, self.operator,
            #                                self.child.to_low)
            unaryL = HDLRuby::Low::Unary.new(self.type.to_low, self.operator,
                                           self.child.to_low)
            # # For debugging: set the source high object 
            # unaryL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = unaryL
            return unaryL
        end
    end


    ##
    # Describes a high-level binary expression
    class Binary < Low::Binary
        include HExpression

        # Converts to a new expression.
        def to_expr
            return Binary.new(self.type, self.operator,
                              self.left.to_expr, self.right.to_expr)
        end

        # Converts the binary expression to HDLRuby::Low.
        def to_low
            # return HDLRuby::Low::Binary.new(self.type.to_low, self.operator,
            #                                self.left.to_low, self.right.to_low)
            binaryL = HDLRuby::Low::Binary.new(self.type.to_low, self.operator,
                                           self.left.to_low, self.right.to_low)
            # # For debugging: set the source high object 
            # binaryL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = binaryL
            return binaryL
        end
    end


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
            # return HDLRuby::Low::Select.new(self.type.to_low,"?",
            #                                 self.select.to_low,
            # *self.each_choice.map do |choice|
            #     choice.to_low
            # end)
            selectL = HDLRuby::Low::Select.new(self.type.to_low,"?",
                                            self.select.to_low,
            *self.each_choice.map do |choice|
                choice.to_low
            end)
            # # For debugging: set the source high object 
            # selectL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = selectL
            return selectL
        end
    end


    ##
    # Describes z high-level concat expression.
    class Concat < Low::Concat
        include HExpression

        # Converts to a new expression.
        def to_expr
            return Concat.new(self.type,
                self.each_expression.map do |expr|
                    expr.to_expr
                end
            )
        end

        # Converts the concatenation expression to HDLRuby::Low.
        def to_low
            # return HDLRuby::Low::Concat.new(self.type.to_low,
            #     self.each_expression.map do |expr|
            #         expr.to_low
            #     end
            # )
            concatL = HDLRuby::Low::Concat.new(self.type.to_low,
                self.each_expression.map do |expr|
                    expr.to_low
                end
            )
            # # For debugging: set the source high object 
            # concatL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = concatL
            return concatL
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

        # Tell if the expression is constant.
        def constant?
            # A value is a constant.
            return true
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
            # return HDLRuby::Low::Value.new(self.type.to_low,self.content)
            valueL = HDLRuby::Low::Value.new(self.type.to_low,self.content)
            # # For debugging: set the source high object 
            # valueL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = valueL
            return valueL
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
            raise AnyError, "Internal error: to_ref not defined yet for class: #{self.class}"
        end

        # Converts to a new event.
        def to_event
            return Event.new(:change,self.to_ref)
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
            # puts "New RefObjet with base=#{base}, object=#{object}"
            if object.respond_to?(:type) then
                # Typed object, so typed reference.
                super(object.type)
            else
                # Untyped object, so untyped reference.
                super(void)
            end
            # Check and set the base (it must be convertible to a reference).
            unless base.respond_to?(:to_ref)
                raise AnyError, "Invalid base for a RefObject: #{base}"
            end
            @base = base
            # Set the object
            @object = object
        end

        # Clones.
        def clone
            return RefObject.new(self.base.clone,self.object)
        end

        # Tell if the expression is constant.
        def constant?
            return self.base.constant?
        end

        # Converts to a new reference.
        def to_ref
            return RefObject.new(@base,@object)
        end

        # Comparison for hash: structural comparison.
        def eql?(obj)
            return false unless obj.is_a?(RefObject)
            return false unless @base.eql?(obj.base)
            return false unless @object.eql?(obj.object)
            return true
        end

        # Converts the name reference to a HDLRuby::Low::RefName.
        def to_low
            # puts "to_low with base=#{@base} @object=#{@object}"
            # puts "@object.name=#{@object.name}"
            refNameL = HDLRuby::Low::RefName.new(self.type.to_low,
                                             @base.to_ref.to_low,@object.name)
            # # For debugging: set the source high object 
            # refNameL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = refNameL
            return refNameL
        end

        # Missing methods are looked for into the refered object.
        def method_missing(m, *args, &ruby_block)
            @object.send(m,*args,&ruby_block)
        end

    end


    ##
    # Describes a high-level concat reference.
    class RefConcat < Low::RefConcat
        include HRef

        # Converts to a new reference.
        def to_ref
            return RefConcat.new(self.type,
                self.each_ref.map do |ref|
                    ref.to_ref
                end
            )
        end

        # Converts the concat reference to HDLRuby::Low.
        def to_low
            # return HDLRuby::Low::RefConcat.new(self.type.to_low,
            #     self.each_ref.map do |ref|
            #         ref.to_low
            #     end
            # )
            refConcatL = HDLRuby::Low::RefConcat.new(self.type.to_low,
                self.each_ref.map do |ref|
                    ref.to_low
                end
            )
            # # For debugging: set the source high object 
            # refConcatL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = refConcatL
            return refConcatL
        end
    end

    ##
    # Describes a high-level index reference.
    class RefIndex < Low::RefIndex
        include HRef

        # Converts to a new reference.
        def to_ref
            return RefIndex.new(self.type,
                                # self.ref.to_ref,self.index.to_expr)
                                self.ref.to_expr,self.index.to_expr)
        end

        # Converts the index reference to HDLRuby::Low.
        def to_low
            # return HDLRuby::Low::RefIndex.new(self.type.to_low,
            #                                 self.ref.to_low,self.index.to_low)
            refIndexL = HDLRuby::Low::RefIndex.new(self.type.to_low,
                                            self.ref.to_low,self.index.to_low)
            # # For debugging: set the source high object 
            # refIndexL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = refIndexL
            return refIndexL
        end
    end

    ##
    # Describes a high-level range reference.
    class RefRange < Low::RefRange
        include HRef

        # Converts to a new reference.
        def to_ref
            return RefRange.new(self.type,self.ref.to_expr,
                              self.range.first.to_expr..self.range.last.to_expr)
        end

        # Converts the range reference to HDLRuby::Low.
        def to_low
            # return HDLRuby::Low::RefRange.new(self.type.to_low,
            #     self.ref.to_low,self.range.to_low)
            refRangeL = HDLRuby::Low::RefRange.new(self.type.to_low,
                self.ref.to_low,self.range.to_low)
            # # For debugging: set the source high object 
            # refRangeL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = refRangeL
            return refRangeL
        end
    end

    ##
    # Describes a high-level name reference.
    class RefName < Low::RefName
        include HRef

        # Converts to a new reference.
        def to_ref
            return RefName.new(self.type,self.ref.to_ref,self.name)
        end

        # Converts the name reference to HDLRuby::Low.
        def to_low
            # return HDLRuby::Low::RefName.new(self.type.to_low,
            #                                  self.ref.to_low,self.name)
            refNameL = HDLRuby::Low::RefName.new(self.type.to_low,
                                             self.ref.to_low,self.name)
            # # For debugging: set the source high object 
            # refNameL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = refNameL
            return refNameL
        end
    end

    ##
    # Describes a this reference.
    class RefThis < Low::RefThis
        High = HDLRuby::High
        include HRef

        # Clones.
        def clone
            return RefThis.new
        end

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

        # # Gets the enclosing block if any.
        # def block
        #     return High.cur_block
        # end

        # Converts the this reference to HDLRuby::Low.
        def to_low
            # return HDLRuby::Low::RefThis.new
            refThisL = HDLRuby::Low::RefThis.new
            # # For debugging: set the source high object 
            # refThisL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = refThisL
            return refThisL
        end
    end

    ##
    # Describes a string.
    #
    # NOTE: This is not synthesizable!
    class StringE < Low::StringE
        include HExpression

        # Converts to an expression.
        def to_expr
            return StringE.new(self.content,*self.each_arg.map(&:to_expr))
        end

        # Converts the connection to HDLRuby::Low.
        def to_low
            return HDLRuby::Low::StringE.new(self.content,
                                             *self.each_arg.map(&:to_low))
        end
    end



    
    # Sets the current this to +obj+.
    #
    # NOTE: do not use a this= style to avoid confusion.
    def set_this(obj = proc { RefThis.new })
        if (obj.is_a?(Proc)) then
            @@this = obj
        else
            @@this = proc { RefObject.new(RefThis.new,obj) }
        end
    end


    # Gives access to the *this* reference.
    def this
        # RefThis.new
        @@this.call
    end


    ##
    # Describes a high-level event.
    class Event < Low::Event
        # Converts to a new event.
        def to_event
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
                raise AnyError, "Event cannot be inverted: #{self.type}"
            end
        end

        # Converts the event to HDLRuby::Low.
        def to_low
            # return HDLRuby::Low::Event.new(self.type,self.ref.to_low)
            eventL = HDLRuby::Low::Event.new(self.type,self.ref.to_low)
            # # For debugging: set the source high object 
            # eventL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = eventL
            return eventL
        end
    end


    ## 
    # Decribes a transmission statement.
    class Transmit < Low::Transmit
        High = HDLRuby::High

        include HStatement

        # Creates a new transmission from a +right+ expression to a +left+
        # reference, ensuring left is not a constant.
        def initialize(left,right)
            if left.constant? then
                raise AnyError, "Cannot assign to constant: #{left}"
            end
            super(left,right)
        end

        # Converts the transmission to a comparison expression.
        #
        # NOTE: required because the <= operator is ambigous and by
        # default produces a Transmit or a Connection.
        def to_expr
            # Remove the transission from the block.
            High.top_user.delete_statement!(self)
            # Generate an expression.
            return Binary.new(
                self.left.to_expr.type.send(:<=,self.right.to_expr.type),
                :<=,self.left.to_expr,self.right.to_expr)
        end

        # Converts the transmit to HDLRuby::Low.
        def to_low
            # return HDLRuby::Low::Transmit.new(self.left.to_low,
            #                                   self.right.to_low)
            transmitL = HDLRuby::Low::Transmit.new(self.left.to_low,
                                              self.right.to_low)
            # # For debugging: set the source high object 
            # transmitL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = transmitL
            return transmitL
        end
    end


    ## 
    # Describes a print statement: not synthesizable!
    class Print < Low::Print
        High = HDLRuby::High

        include HStatement

        # Creates a new statement for printing +args+.
        def initialize(*args)
            # Process the arguments.
            super(*args.map(&:to_expr))
        end

        # Converts the connection to HDLRuby::Low.
        def to_low
            return HDLRuby::Low::Print.new(*self.each_arg.map(&:to_low))
        end

    end


    ## 
    # Describes a systemI (re)configure statement: not synthesizable!
    class Configure < Low::Configure
        High = HDLRuby::High

        include HStatement

        # Creates a new (re)configure statement for system instance refered
        # by +ref+ with system number +num+.
        def initialize(ref,num)
            super(ref,num)
        end

        # Converts the connection to HDLRuby::Low.
        def to_low
            return HDLRuby::Low::Configure.new(self.ref.to_low, self.index)
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
            High.top_user.delete_connection!(self)
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
            High.top_user.delete_connection!(self)
        end

        # Converts the connection to HDLRuby::Low.
        def to_low
            # return HDLRuby::Low::Connection.new(self.left.to_low,
            #                                     self.right.to_low)
            connectionL = HDLRuby::Low::Connection.new(self.left.to_low,
                                                self.right.to_low)
            # # For debugging: set the source high object 
            # connectionL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = connectionL
            return connectionL
        end
    end


    ##
    # Describes a high-level signal.
    class SignalI < Low::SignalI
        High = HDLRuby::High

        include HRef

        # The valid bounding directions.
        DIRS = [ :no, :input, :output, :inout, :inner ]

        # The bounding direction.
        attr_reader :dir

        # Tells if the signal can be read.
        attr_reader :can_read

        # Tells if the signal can be written.
        attr_reader :can_write

        # Creates a new signal named +name+ typed as +type+ with
        # +dir+ as bounding direction and possible +value+.
        #
        # NOTE: +dir+ can be :input, :output, :inout or :inner
        def initialize(name,type,dir,value =  nil)
            # Check the value.
            value = value.to_expr.match_type(type) if value
            # Initialize the type structure.
            super(name,type,value)

            unless name.empty? then
                # Named signal, set the hdl-like access to the signal.
                obj = self # For using the right self within the proc
                High.space_reg(name) { obj }
            end

            # Hierarchical type allows access to sub references, so generate
            # the corresponding methods.
            if type.struct? then
                type.each_name do |name|
                    self.define_singleton_method(name) do
                        RefObject.new(self.to_ref,
                                    SignalI.new(name,type.get_type(name),dir))
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

        # Sets the direction to +dir+.
        def dir=(dir)
            unless DIRS.include?(dir) then
                raise AnyError, "Invalid bounding for signal #{self.name} direction: #{dir}."
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

        # Converts to a new reference.
        def to_ref
            return RefObject.new(this,self)
        end

        # Converts to a new expression.
        def to_expr
            return self.to_ref
        end

        # Coerce by converting signal to an expression.
        def coerce(obj)
            return [obj,self.to_expr]
        end

        # Converts the system to HDLRuby::Low and set its +name+.
        def to_low(name = self.name)
            # return HDLRuby::Low::SignalI.new(name,self.type.to_low)
            valueL = self.value ? self.value.to_low : nil
            signalIL = HDLRuby::Low::SignalI.new(name,self.type.to_low,valueL)
            # # For debugging: set the source high object 
            # signalIL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = signalIL
            return signalIL
        end
    end


    ##
    # Describes a high-level constant signal.
    class SignalC < Low::SignalC
        High = HDLRuby::High

        include HRef

        # Creates a new constant signal named +name+ typed as +type+
        # and +value+.
        def initialize(name,type,value)
            # Check the value is a constant.
            value = value.to_expr.match_type(type)
            unless value.constant? then
                raise AnyError,"Non-constant value assignment to constant."
            end
            # Initialize the type structure.
            super(name,type,value)

            unless name.empty? then
                # Named signal, set the hdl-like access to the signal.
                obj = self # For using the right self within the proc
                High.space_reg(name) { obj }
            end

            # Hierarchical type allows access to sub references, so generate
            # the corresponding methods.
            if type.struct? then
                type.each_name do |name|
                    self.define_singleton_method(name) do
                        RefObject.new(self.to_ref,
                                    SignalC.new(name,type.get_type(name),
                                                value[name]))
                    end
                end
            end
        end

        # Converts to a new reference.
        def to_ref
            return RefObject.new(this,self)
        end

        # Converts to a new expression.
        def to_expr
            return self.to_ref
        end

        # Coerce by converting signal to an expression.
        def coerce(obj)
            return [obj,self.to_expr]
        end

        # Converts the system to HDLRuby::Low and set its +name+.
        def to_low(name = self.name)
            # return HDLRuby::Low::SignalC.new(name,self.type.to_low,
            #                                  self.value.to_low)
            signalCL = HDLRuby::Low::SignalC.new(name,self.type.to_low,
                                             self.value.to_low)
            # # For debugging: set the source high object 
            # signalCL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = signalCL
            return signalCL
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
            High.space_push(@namespace)
            @return_value = High.top_user.instance_eval(&ruby_block)
            High.space_pop
            # if @return_value.is_a?(HExpression) then
            #     res = @return_value
            #     High.space_push(@namespace)
            #     @return_value = res.type.inner(HDLRuby.uniq_name)
            #     puts "@return_value name=#{@return_value.name}"
            #     @return_value <= res
            #     High.space_pop
            #     @return_value = RefObject.new(self,@return_value)
            # end
            @return_value
        end

        # Opens the block.
        alias_method :open, :build

        # Converts to a new reference.
        def to_ref
            return RefObject.new(this,self)
        end

        include HScope_missing

        # Creates and adds a new block executed in +mode+, with possible
        # +name+ and built by executing +ruby_block+.
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
            # Ensure there is a block.
            ruby_block = proc {} unless block_given?
            self.add_block(self.mode,name,&ruby_block)
        end

        # Adds statements at the top of the block.
        def unshift(&ruby_block)
            # Ensure there is a block.
            ruby_block = proc {} unless block_given?
            # Create a sub block for the statements.
            block = High.make_block(self.mode,:"",&ruby_block)
            # Unshifts it.
            self.unshift_statement(block)
            # Use its return value.
            return block.return_value
        end
        
        # Gets the current block.
        def cur_block
            return HDLRuby::High.cur_block
        end

        # Gets the top block of the current behavior.
        def top_block
            return HDLRuby::High.top_block
        end

        # Gets the current behavior.
        def cur_behavior
            return HDLRuby::High.cur_behavior
        end

        # Gets the current scope.
        def cur_scope
            return HDLRuby::High.cur_scope
        end

        # Gets the current system.
        def cur_system
            return HDLRuby::High.cur_system
        end



        # Need to be able to declare select operators
        include Hmux

        # Creates a new if statement with a +condition+ that when met lead
        # to the execution of the block in +mode+ generated by the
        # +ruby_block+.
        #
        # NOTE: the else part is defined through the helse method.
        def hif(condition, mode = nil, &ruby_block)
            # Ensure there is a block.
            ruby_block = proc {} unless block_given?
            # Creates the if statement.
            self.add_statement(If.new(condition,mode,&ruby_block))
        end

        # Sets the block executed when the condition is not met to the block
        # in +mode+ generated by the execution of +ruby_block+.
        #
        # Can only be used once.
        def helse(mode = nil, &ruby_block)
            # Ensure there is a block.
            ruby_block = proc {} unless block_given?
            # There is a ruby_block: the helse is assumed to be with
            # the hif in the same block.
            # Completes the hif or the hcase statement.
            statement = @statements.last
            unless statement.is_a?(If) or statement.is_a?(Case) then
                raise AnyError, "Error: helse statement without hif nor hcase (#{statement.class})."
            end
            statement.helse(mode, &ruby_block)
        end

        # Sets the condition check when the condition is not met to the block,
        # with a +condition+ that when met lead
        # to the execution of the block in +mode+ generated by the +ruby_block+.
        def helsif(condition, mode = nil, &ruby_block)
            # Ensure there is a block.
            ruby_block = proc {} unless block_given?
            # There is a ruby_block: the helse is assumed to be with
            # the hif in the same block.
            # Completes the hif statement.
            statement = @statements.last
            unless statement.is_a?(If) then
                raise AnyError,
                     "Error: helsif statement without hif (#{statement.class})."
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
            # Ensure there is a block.
            ruby_block = proc {} unless block_given?
            # There is a ruby_block: the helse is assumed to be with
            # the hif in the same block.
            # Completes the hcase statement.
            statement = @statements.last
            unless statement.is_a?(Case) then
                raise AnyError,
                    "Error: hwhen statement without hcase (#{statement.class})."
            end
            statement.hwhen(match, mode, &ruby_block)
        end


        # Prints.
        def hprint(*args)
            self.add_statement(Print.new(*args))
        end

        # Terminate the simulation.
        def terminate
            self.add_statement(TimeTerminate.new)
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
            blockL = HDLRuby::Low::Block.new(self.mode,self.name)
            # # For debugging: set the source high object 
            # blockL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = blockL
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

        # # Adds a loop until +delay+ statement in the block in +mode+ whose
        # # loop content is built using +ruby_block+.
        # def repeat(delay, mode = nil, &ruby_block)
        # Adds a +number+ times loop statement in the block in +mode+ whose
        # loop content is built using +ruby_block+.
        # NOTE: if +number+ is negative, the number of iteration is infinite.
        def repeat(number = -1, mode = nil, &ruby_block)
            # Ensure there is a block.
            ruby_block = proc {} unless block_given?
            # Build the content block.
            content = High.make_block(mode,&ruby_block)
            # Create and add the statement.
            # self.add_statement(TimeRepeat.new(content,delay))
            self.add_statement(TimeRepeat.new(content,number))
        end

        # Converts the time block to HDLRuby::Low.
        def to_low
            # Create the resulting block
            blockL = HDLRuby::Low::TimeBlock.new(self.mode)
            # # For debugging: set the source high object 
            # blockL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = blockL
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
            return TimeBlock.new(mode,name,&ruby_block)
        else
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
        return TimeBlock.new(mode,name,&ruby_block)
    end

    ##
    # Describes a high-level behavior.
    class Behavior < Low::Behavior
        High = HDLRuby::High

        # Creates a new behavior executing +block+ activated on a list of
        # +events+, and built by executing +ruby_block+.
        # +mode+ can be either :seq or :par for respectively sequential or
        # parallel.
        def initialize(mode,*events,&ruby_block)
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

        # Sets an event to the behavior.
        # NOTE: currently actually adds an event if there are already some!
        alias_method :at, :add_event

        # Converts the time behavior to HDLRuby::Low.
        def to_low
            # Create the low level block.
            blockL = self.block.to_low
            # Create the low level events.
            eventLs = self.each_event.map { |event| event.to_low }
            # Create and return the resulting low level behavior.
            behaviorL = HDLRuby::Low::Behavior.new(blockL)
            # # For debugging: set the source high object 
            # behaviorL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = behaviorL
            eventLs.each(&behaviorL.method(:add_event))
            return behaviorL
        end
    end

    ##
    # Describes a high-level timed behavior.
    class TimeBehavior < Low::TimeBehavior
        High = HDLRuby::High

        # Creates a new timed behavior built by executing +ruby_block+.
        # +mode+ can be either :seq or :par for respectively sequential or
        def initialize(mode, &ruby_block)
            # Create a default par block for the behavior.
            block = High.make_time_block(mode,&ruby_block)
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
            timeBehaviorL = HDLRuby::Low::TimeBehavior.new(blockL)
            # # For debugging: set the source high object 
            # timeBehaviorL.properties[:low2high] = self.hdr_id
            # self.properties[:high2low] = timeBehaviorL
            eventLs.each(&timeBehaviorL.method(:add_event))
            return timeBehaviorL
        end
    end





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
            raise AnyError, "Internal error: cannot pop further namespaces."
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

    # sets the top namespace.
    def self.space_top=(top)
        unless top.is_a?(Namespace) then
            raise "Invalid class for a Namspace: #{top.class}"
        end
        Namespaces[-1] = top
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
            raise AnyError, "Not within a system type."
        else
            return Namespaces.reverse_each.find do |space|
                space.user.is_a?(Scope) and space.user.parent.is_a?(SystemT)
            end.user.parent
        end
    end

    # The current behavior: by default none.
    @@cur_behavior = nil

    # Gets the enclosing behavior if any.
    def self.cur_behavior
        return @@cur_behavior
    end

    # Tell if we are in a behavior.
    def self.in_behavior?
        top_user.is_a?(Block)
    end

    # Gets the enclosing scope if any.
    #
    # NOTE: +level+ allows to get an upper scope of the currently enclosing
    #       scope.
    def self.cur_scope(level = 0)
        if level < 0 then
            raise AnyError, "Not within a scope: #{Namespaces[-1].user.class}"
        end
        if Namespaces[-1-level].user.is_a?(Scope) then
            return Namespaces[-1-level].user
        else
            return cur_scope(level+1)
        end
    end

    # Gets the enclosing block if any.
    #
    # NOTE: +level+ allows to get an upper block of the currently enclosing
    #       block.
    def self.cur_block(level = 0)
        if Namespaces[-1-level].user.is_a?(Scope) then
            raise AnyError, 
                  "Not within a block: #{Namespaces[-1-level].user.class}"
        elsif Namespaces[-1-level].user.is_a?(Block) then
            return Namespaces[-1-level].user
        else
            return cur_block(level+1)
        end
    end

    # Gets the top enclosing block if any.
    def self.top_block(level = 0)
        blk = cur_block(level)
        unless blk.is_a?(Block)
            raise AnyError,
                "Not within a block: #{blk.user.class}"
        end
        if Namespaces[-1-level-1].user.is_a?(Scope) then
            return blk
        else
            return top_block(level+1)
        end
    end

    # Registers hardware referencing method +name+ to the current namespace.
    def self.space_reg(name,&ruby_block)
        # print "registering #{name} in #{Namespaces[-1]}\n"
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
            # puts "space=#{space.singleton_methods}"
            if space.respond_to?(name) then
                # print "Found is space user with class=#{space.user.class}\n"
                # The method is found, call it.
                return space.send(name,*args,&ruby_block)
            elsif space.user.respond_to?(name) then
                # The method is found in the user, call it.
                return space.user.send(name,*args,&ruby_block)
            end
        end
        # Look in the global methods.
        if HDLRuby::High.respond_to?(name) then
            # Found.
            return HDLRuby::High.send(name,*args,&ruby_block)
        end
        # Not found.
        raise NotDefinedError,
              "undefined HDLRuby construct, local variable or method `#{name}'."
    end




    


    # Extends the standard classes for support of HDLRuby.


    # Extends the Numeric class for conversion to a high-level expression.
    class ::Numeric

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

    # # Extends the Fixnum class for computing for conversion to expression.
    # class ::Fixnum
    #     # Converts to a new high-level expression.
    #     def to_expr
    #         return Value.new(Integer,self)
    #     end
    # end

    # # Extends the Bignum class for computing for conversion to expression.
    # class ::Bignum
    #     # Converts to a new high-level expression.
    #     def to_expr
    #         return Value.new(Bignum,self)
    #     end
    # end
    
    # Extends the TrueClass class for computing for conversion to expression.
    class ::TrueClass
        # Converts to a new high-level expression.
        def to_expr
            return Value.new(Integer,1)
        end
    end
    
    # Extends the FalseClass class for computing for conversion to expression.
    class ::FalseClass
        # Converts to a new high-level expression.
        def to_expr
            return Value.new(Integer,0)
        end
    end
    
    # Extends the Integer class for computing for conversion to expression.
    class ::Integer
        # Converts to a new high-level expression.
        def to_expr
            return Value.new(Integer,self)
        end
    end
    
    # Extends the Float class for computing for conversion to expression.
    class ::Float
        # Converts to a new high-level expression.
        def to_expr
            return Value.new(Float,self)
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

    # Extends the String class for computing conversion to expression.
    class ::String
        # # Converts to a new high-level expression.
        # def to_expr
        #     # Convert the string to a bit string.
        #     bstr = BitString.new(self)
        #     # Use it to create the new value.
        #     return Value.new(Bit[bstr.width],self)
        # end
        
        # Tell if the expression can be converted to a value.
        def to_value?
            return true
        end

        # Converts to a new high-level value.
        def to_value
            # Convert the string to a bit string.
            bstr = BitString.new(self)
            # Use it to create the new value.
            # return Value.new(Bit[bstr.width],bstr)
            return Value.new(Bit[self.length],bstr)
        end
        
        # Convert to a new high-level string expression
        def to_expr
            return StringE.new(self)
        end

        # For now deactivated, needs rethinking.
        # # Rework format to generate HDLRuby string.
        # alias_method :__format_old__, :%
        # def %(args)
        #     # Is there any HW argument?
        #     if args.any? { |arg| arg.is_a?(HDLRuby::Low::Hparent) } then
        #         # Yes generate a HDLRuby string.
        #         return StringE.new(self,*args)
        #     else
        #         # No process the format normally.
        #         self.__format_old__(args)
        #     end
        # end
    end


    # Extends the Hash class for declaring signals of structure types.
    class ::Hash

        # Converts to a new type.
        def to_type
            return TypeStruct.new(:"",:little,self)
        end

        # Declares a new type definition with +name+ equivalent to current one.
        def typedef(name)
            return self.to_type.typedef(name)
        end

        # Declares high-level input signals named +names+ of the current type.
        #
        # Retuns the last declared input.
        def input(*names)
            res = nil
            names.each do |name|
                res = HDLRuby::High.top_user.
                    add_input(SignalI.new(name,
                                    TypeStruct.new(:"",:little,self),:input))
            end
            return res
        end

        # Declares high-level untyped output signals named +names+ of the
        # current type.
        #
        # Retuns the last declared output.
        def output(*names)
            res = nil
            names.each do |name|
                res = HDLRuby::High.top_user.
                    add_output(SignalI.new(name,
                                    TypeStruct.new(:"",:little,self),:output))
            end
            return res
        end

        # Declares high-level untyped inout signals named +names+ of the
        # current type.
        #
        # Retuns the last declared inout.
        def inout(*names)
            res = nil
            names.each do |name|
                res = HDLRuby::High.top_user.
                    add_inout(SignalI.new(name,
                                    TypeStruct.new(:"",:little,self),:inout))
            end
            return res
        end

        # Declares high-level untyped inner signals named +names+ of the
        # current type.
        #
        # Retuns the last declared inner.
        def inner(*names)
            res = nil
            names.each do |name|
                res = HDLRuby::High.top_user.
                    add_inner(SignalI.new(name,
                                    TypeStruct.new(:"",:little,self),:inner))
            end
            return res
        end

        # Declares high-level untyped constant signals by name and value given
        # by +hsh+ of the current type.
        #
        # Retuns the last declared constant.
        def constant(hsh)
            res = nil
            hsh.each do |name,value|
                res = HDLRuby::High.top_user.
                    add_inner(SignalC.new(name,
                              TypeStruct.new(:"",:little,self),:inner,value))
            end
            return res
        end
    end


    # Extends the Array class for conversion to a high-level expression.
    class ::Array
        include HArrow

        # Converts to a new high-level expression.
        def to_expr
            elems = self.map {|elem| elem.to_expr }
            typ= TypeTuple.new(:"",:little)
            elems.each {|elem| typ.add_type(elem.type) }
            expr = Concat.new(typ)
            elems.each {|elem| expr.add_expression(elem) }
            expr
        end

        # Converts to a new high-level reference.
        def to_ref
            expr = RefConcat.new(TypeTuple.new(:"",:little,*self.map do |elem|
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
                return TypeTuple.new(:"",:little,*self)
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

        # Declares high-level inner signals named +names+ of the
        # current type.
        def inner(*names)
            High.top_user.make_inners(self.to_type,*names)
        end

        # Declares high-level inner constants named from +hsh+ with names
        # and corresponding values.
        def constant(hsh)
            High.top_user.make_constants(self.to_type,hsh)
        end

        # Creates a hcase statement executing +ruby_block+ on the element of
        # the array selected by +value+
        def hcase(value,&ruby_block)
            # Ensure there is a block.
            ruby_block = proc {} unless block_given?
            High.cur_block.hcase(value)
            self.each.with_index do |elem,i|
                High.cur_block.hwhen(i) { ruby_block.call(elem) }
            end
        end

        # Moved to HArrow.
        # # Add support of the left arrow operator.
        # def <=(expr)
        #     self.to_expr <= expr
        # end

        # Array construction shortcuts

        # Create an array whose number of elements is given by the content
        # of the current array, filled by +obj+ objects.
        # If +obj+ is nil, +ruby_block+ is used instead for filling the array.
        def call(obj = nil, &ruby_block)
            unless self.size == 1 then
                raise AnyError, "Invalid array for call opertor."
            end
            number = self[0].to_i
            if obj then
                return Array.new(number,obj)
            else
                return Array.new(number,&ruby_block)
            end
        end

        # Create an array of instances of system +name+, using +args+ as
        # arguments.
        #
        # NOTE: the array must have a single element that is an integer.
        def make(name,*args)
            # Check the array and get the number of elements.
            size = self[0]
            unless self.size == 1 and size.is_a?(::Integer)
                raise AnyError,
                      "Invalid array for declaring a list of instances."
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

        # Tell if the expression can be converted to a value.
        def to_value?
            return true
        end

        # Converts to a new value.
        #
        # Returns nil if no value can be obtained from it.
        def to_value
            str = self.to_s
            return nil if str[0] != "_" # Bit string are prefixed by "_"
            # Remove the "_" not needed any longer.
            str = str[1..-1]
            # Get and check the type
            type = str[0]
            if type == "0" or type == "1" or type == "z" or type == "Z" then
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
                # Check the value
                return nil unless value.match(/^[0-1zxZX]+$/)
            when "o" then
                # base 8, compute the width
                width = width ? width.to_i : value.size * 3
                # Check the value
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
            # puts "type.width=#{type.width}, value=#{value}"
            # Create and return the value.
            return Value.new(type,value)
        end

        alias_method :to_expr, :to_value
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
        if self.names_has?(base) then
            count = 0
            while (self.names_has?(base + count.to_s)) do
                count += 1
            end
            base << count.to_s
        end
        # Add and return it
        self.names_add(base)
        # puts "created name: #{base}"
        return base.to_sym
    end




    # Standard vector types.
    Integer = TypeSigned.new(:integer)
    Char    = TypeSigned.new(:char,7..0)
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
                # puts "here: #{m}"
                # No, true error
                raise NotDefinedError, "undefined HDLRuby construct, local variable or method `#{m}'."
            end
        end
    end

    # Initialize the this.
    set_this

    # Generate the standard signals
    $clk = Universe.scope.inner :__universe__clk__
    $rst = Universe.scope.inner :__universe__rst__



    # Tells HDLRuby has finised booting.
    def self.booting?
        false
    end
end
