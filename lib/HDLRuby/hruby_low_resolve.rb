require "HDLRuby/hruby_error"



##
# Adds methods for finding objects through names.
#
# NOTE: For now only resolve name reference.
#
########################################################################
module HDLRuby::Low

    ##
    #  Extends SystemT with the capability of finding one of its inner object
    #  by name.
    class SystemT
        
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


    ##
    #  Extends Scope with the capability of finding one of its inner object
    #  by name.
    class Scope
        
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
        end
    end


    ##
    #  Extends SystemI with the capability of finding one of its inner object
    #  by name.
    class SystemI
        
        ## Find an inner object by +name+.
        #  NOTE: return nil if not found.
        def get_by_name(name)
            # Look into the eigen system.
            return self.systemT.get_by_name(name)
        end
    end


    ##
    #  Extends Block with the capability of finding one of its inner object
    #  by name.
    class Block
        
        ## Find an inner object by +name+.
        #  NOTE: return nil if not found.
        def get_by_name(name)
            # Ensure the name is a symbol.
            name = name.to_sym
            # Look in the signals.
            return self.get_inner(name)
        end
    end


    ##
    #  Extends RefIndex with the capability of finding the object it
    #  refered to.
    class RefIndex

        ## Tells if it is a reference to a systemI signal.
        def from_systemI?
            return self.ref.from_systemI?
        end
    end


    ##
    #  Extends RefRange with the capability of finding the object it
    #  refered to.
    class RefRange

        ## Tells if it is a reference to a systemI signal.
        def from_systemI?
            return self.ref.from_systemI?
        end
    end

    
    ##
    #  Extends RefName with the capability of finding the object it
    #  refered to.
    class RefName

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


        ## Resolves the name of the reference and return the
        #  corresponding object.
        #  NOTE: return nil if could not resolve.
        def resolve
            # puts "Resolve with #{self} and name=#{self.name}"
            # First resolve the sub reference if possible.
            if self.ref.is_a?(RefName) then
                obj = self.ref.resolve
                # Look into the object for the name.
                return obj.get_by_name(self.name)
            else
                # Look in the parent hierachy for the name.
                parent = self.parent
                # puts "parent=#{parent}"
                while parent
                    # puts "parent=#{parent}"
                    if parent.respond_to?(:get_by_name) then
                        found = parent.get_by_name(self.name)
                        return found if found
                    end
                    parent = parent.parent
                end
                # Not found.
                return nil
            end
        end
    end
end
