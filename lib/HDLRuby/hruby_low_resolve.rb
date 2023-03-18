require "HDLRuby/hruby_error"


module HDLRuby::Low


##
# Adds methods for finding objects through names.
#
# NOTE: For now only resolve name reference.
#
########################################################################


    class SystemT
        ## Extends SystemT with the capability of finding one of its inner
        #  object by name.
        
        ## Find an inner object by +name+.
        #  NOTE: return nil if not found.
        def get_by_name(name)
            # Ensure the name is a symbol.
            name = name.to_sym
            # Look in the interface.
            found = self.get_signal(name)
            return found if found
            # Maybe it is the scope.
            return self.scope if self.scope.name == name
            # Look in the scope.
            return self.scope.get_by_name(name)
        end
    end


    class Scope
        ## Extends Scope with the capability of finding one of its inner object
        #  by name.
        
        ## Find an inner object by +name+.
        #  NOTE: return nil if not found.
        def get_by_name(name)
            # puts "getbyname for name=#{name} with self=#{self}"
            # Ensure the name is a symbol.
            name = name.to_sym
            # Look in the signals.
            found = self.get_inner(name)
            return found if found
            # Look in the instances.
            found = self.each_systemI.find { |systemI| systemI.name == name }
            return found if found
            # Maybe it is a sub scope.
            return self.each_scope.find { |scope| scope.name == name }
            # Maybe it in the behavior.
            return self.behavior.get_by_name
        end
    end


    class Behavior
        ## Extends Behavior with the capability of finding one of its inner
        #  object by name.
        
        ## Find an inner object by +name+.
        #  NOTE: return nil if not found.
        def get_by_name(name)
            if (self.block.name == name.to_sym) then
                return self.block
            end
            return self.block.get_by_name(name)
        end
    end

    
    class SystemI
        ## Extends SystemI with the capability of finding one of its inner object
        #  by name.
        
        ## Find an inner object by +name+.
        #  NOTE: return nil if not found.
        def get_by_name(name)
            # Look into the eigen system.
            return self.systemT.get_by_name(name)
        end
    end


    class Block
        ## Extends Block with the capability of finding one of its inner object
        #  by name.
        
        ## Find an inner object by +name+.
        #  NOTE: return nil if not found.
        def get_by_name(name)
            # Ensure the name is a symbol.
            name = name.to_sym
            # Look in the signals.
            found = self.get_inner(name)
            return found if found
            # Check the sub blocks names.
            self.each_block do |block|
                # puts "block=#{block.name}"
                if (block.name == name) then
                    return block
                end
            end
            return nil
        end
    end


    class SignalI
        ## Extends SignalI with the capability of finding one of its inner object
        #  by name.
        
        ## Find an inner object by +name+.
        #  NOTE: return nil if not found.
        def get_by_name(name)
            return self.get_signal(name)
        end
    end



    class Ref
        ## Extends RefIndex with the capability of finding the object it
        #  refered to.

        ## Resolves the name of the reference (if any) and return the
        #  corresponding object.
        #  NOTE: return nil if could not resolve.
        def resolve
            # By default cannot resolve.
            return nil
        end
    end


    class RefIndex
        ## Extends RefIndex with the capability of finding the object it
        #  refered to.

        ## Tells if it is a reference to a systemI signal.
        def from_systemI?
            return self.ref.from_systemI?
        end

        ## Resolves the name of the reference (if any) and return the
        #  corresponding object.
        #  NOTE: return nil if could not resolve.
        def resolve
            return self.ref.resolve
        end
    end


    class RefRange
        ## Extends RefRange with the capability of finding the object it
        #  refered to.

        ## Tells if it is a reference to a systemI signal.
        def from_systemI?
            return self.ref.from_systemI?
        end

        ## Resolves the name of the reference (if any) and return the
        #  corresponding object.
        #  NOTE: return nil if could not resolve.
        def resolve
            return self.ref.resolve
        end
    end

    
    class RefName
        ## Extends RefName with the capability of finding the object it
        #  refered to.

        ## Tells if it is a reference to a systemI signal.
        def from_systemI?
            # Look for the owner from the name hierarchy.
            if self.ref.is_a?(RefName) then
                # Look in the parent hierachy for the sub reference name.
                parent = self.parent
                # puts "self.ref.name=#{self.ref.name}"
                while parent
                    # puts "parent=#{parent}"
                    if parent.respond_to?(:get_by_name) then
                        found = parent.get_by_name(self.ref.name)
                        # puts "found is a :#{found.class}"
                        return found.is_a?(SystemI) if found
                    end
                    parent = parent.parent
                end
                # Not found, look further in the reference hierarchy.
                return self.ref.from_systemI?
            end
            # Not from a systemI.
            # puts "Not from systemI for #{self.name}"
            return false
        end

        ## Gets the systemI the reference comes from if any.
        def get_systemI
            # Look for the owner from the name hierarchy.
            if self.ref.is_a?(RefName) then
                # Look in the parent hierachy for the sub reference name.
                parent = self.parent
                # puts "self.ref.name=#{self.ref.name}"
                while parent
                    # puts "parent=#{parent}"
                    if parent.respond_to?(:get_by_name) then
                        found = parent.get_by_name(self.ref.name)
                        # puts "found is a :#{found.class}"
                        return found if found.is_a?(SystemI)
                    end
                    parent = parent.parent
                end
                # Not found, look further in the reference hierarchy.
                return self.ref.get_systemI
            end
            # Not from a systemI.
            # puts "Not from systemI for #{self.name}"
            return nil
        end


        ## Resolves the name of the reference and return the
        #  corresponding object.
        #  NOTE: return nil if could not resolve.
        def resolve
            # puts "Resolve with #{self} and name=#{self.name} and ref=#{self.ref.class}"
            # First resolve the sub reference if possible.
            if self.ref.is_a?(RefName) then
                obj = self.ref.resolve
                # puts "obj=#{obj}"
                # Look into the object for the name.
                return obj.get_by_name(self.name)
            else
                # Look in the parent hierachy for the name.
                parent = self.parent
                # puts "parent=#{parent}"
                while parent
                    # puts "parent=#{parent}"
                    if parent.respond_to?(:get_by_name) then
                        # puts "get_by_name"
                        found = parent.get_by_name(self.name)
                        # puts "found" if found
                        return found if found
                    end
                    parent = parent.parent
                end
                # Not found.
                puts "Not found!"
                return nil
            end
        end
    end
end
