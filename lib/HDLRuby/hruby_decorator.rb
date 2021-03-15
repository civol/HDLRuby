require 'yaml'
require 'set'

module HDLRuby

##
# Library for describing a decorator used for adding properties to
# HDLRuby objects that are persistent and can be used for back annotation
########################################################################

    ##
    # Gives a decorator the HDLRuby object.
    module Hdecorator
        # The decorator requires that each HDLRuby object has a uniq
        # persistent id

        # The id
        attr_reader :hdr_id

        # The id to object table
        @@id_map = {}

        # Generate the ID
        @@id_gen = 0

        # Ensures the ID is generated when object is initialized
        def self.included(base) # built-in Ruby hook for modules
            base.class_eval do    
                original_method = instance_method(:initialize)
                define_method(:initialize) do |*args, &block|
                    original_method.bind(self).call(*args, &block)
                    # Generate the id.
                    @hdr_id = @@id_gen
                    @@id_gen += 1
                    # Update the id to object table
                    @@id_map[@hdr_id] = self
                end
            end
        end

        # Get an object by id.
        def self.get(id)
            return @@id_map[id]
        end

        # Iterate over all the id with their object.
        #
        # Returns an enumerator if no ruby block is given.
        def self.each(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each) unless ruby_block
            # A ruby block? Apply it on each object.
            @@id_map.each(&ruby_block)
        end

        # The decorator also need to add properties to the HDLRuby objects.

        # Access the set of properties
        def properties
            # Create the properties if not present.
            unless @properties then
                @properties = Properties.new(self)
            end
            return @properties
        end

        # Iterate over all the objects from +top+ with +prop+ property.
        #
        # Returns an enumerator if no ruby block is given.
        # NOTE: if +top+ is not given, iterate over all the objects.
        def self.each_with_property(prop, top = nil, &ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_with_property) unless ruby_block
            # A ruby block? Apply the ruby_block...
            if (top) then
                # A top... on each object from it.
                top.each_deep do |obj|
                    if (obj.properties.key?(prop)) then
                        ruby_block.call(obj, *obj.properties[prop])
                    end
                end
            else
                # No top... on all the objects.
                self.each do |id,obj|
                    if (obj.properties.key?(prop)) then
                        ruby_block.call(obj, *obj.properties[prop])
                    end
                end
            end
        end

        # # Access the set of properties and the inherited properties from
        # # the high objects.
        # def all_properties
        #     high_id = self.properties[:low2high]
        #     if high_id && high_id >= 0 then
        #         return properties.merge(Hdecorator.get(high_id))
        #     else
        #         return properties.clone
        #     end
        # end

        # Saves properties +key+ of all the object associated with
        # their id to +target+.
        def self.dump(key, target = "")
            # Build the table to dump
            tbl = {}
            self.each do |id,obj|
                value = obj.properties[key]
                if value.any? then
                    tbl[id] = value
                end
            end
            # Dump the table.
            target << YAML.dump(tbl)
            return target
        end

        # Loads properties to +key+ for all objects from +source+.
        def self.load(source,key)
            # Load the id to property table.
            tbl = YAML.load(source)
            # Adds the property of each object according to tbl
            tbl.each do |id,value|
                @@id_map[id].properties[key] = value
            end
        end

        # Some predefined properties to set.

        def self.decorate_parent_id
            @@id_map.each do |id, obj|
                parent = obj.parent
                if parent then
                    obj.properties[:parent_id] = obj.parent.hdr_id
                else
                    obj.properties[:parent_id] = -1
                end
            end
        end

    end


    ## A HDLRuby set of properties
    class Properties

        # The set of all the property keys
        @@property_keys = Set.new

        # The HDLRuby object owning of the set of properties
        attr_reader :owner

        # Create a new set of properties and attach it to HDLRuby object
        # +owner+.
        def initialize(owner)
            # Attach the owner.
            @owner = owner
            # Create the set.
            @content = {}
        end

        # Clones the properties: also clone the contents.
        def clone
            result = Properties.new(owner)
            @contents.each do |k,vals|
                vals.each { |v| result[k] = v }
            end
            return result
        end

        # Create a new set of properties by merging with +prop+
        def merge(prop)
            result = self.clone
            prop.each do |k,vals|
                vals.each { |v| result[k] = v }
            end
            return result
        end

        # Tells if +key+ is present.
        def key?(key)
           @content.key?(key)
        end

        # Add a property
        def []=(key,value)
            @@property_keys << key
            # Add an entry if not present.
            @content[key] = [] unless @content.key?(key)
            # Add the value to the entry.
            @content[key] << value
        end

        # Get a property
        def [](key)
            return @content[key]
        end

        # Iterate over each value associated with +key+.
        def each_with_key(key,&ruby_block)
            return unless @content.key?(key)
            @content[key].each(&ruby_block)
        end

        # Iterate over the properties of the current set.
        #
        # Returns an enumerator if no ruby block is given.
        def each(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each) unless ruby_block
            # A ruby block? Apply it on each input signal instance.
            @content.each(&ruby_block)
        end

        # Iterator over all the property keys
        #
        # Returns an enumerator if no ruby block is given.
        def self.each_key(&ruby_block)
            # No ruby block? Return an enumerator.
            return to_enum(:each_key) unless ruby_block
            # A ruby block? Apply it on each input signal instance.
            @@property_keys.each(&ruby_block)
        end

        # # Iterate over the property set of all the objects from current owner.
        # #
        # # Returns an enumerator if no ruby block is given.
        # def each_properties(&ruby_block)
        #     # No ruby block? Return an enumerator.
        #     return to_enum(:each_properties) unless ruby_block
        #     # A ruby block? Apply it.
        #     # On current property set
        #     ruby_block.call(self)
        #     # And on the properties set of sub objects of the owner.
        #     self.owner.instance_variables.each do |var|
        #         obj = owner.instance_variable_get(var)
        #         if (obj.is_a?(Hproperties)) then
        #             # obj has properties, recurse on them.
        #             obj.properties.each_properties(&ruby_block)
        #         end
        #     end
        # end

    end

    
end
