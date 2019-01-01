require 'HDLRuby'
require 'HDLRuby/hruby_tools'
require 'HDLRuby/hruby_low_mutable'


module HDLRuby::Low


##
# Moves the declarations to the upper namespace.
# Makes conversion to other languages easier since no namespace processing
# is required.
#
########################################################################
    
    ## Module allowing to force a name to a HDLRuby::Low object.
    module ForceName

        # Sets a name if there is no name.
        def force_name!
            @name = HDLRuby.uniq_name if self.name.empty?
        end

        # Extends the name of object +obj+ with current's one.
        def extend_name!(obj)
            obj.set_name!((self.name.to_s + "::" + obj.name.to_s).to_sym)
        end
    end

    ## Extends the SystemT class with functionality for moving the declarations
    #  to the upper namespace.
    class SystemT

        # Moves the declarations to the upper namespace.
        def to_upper_space!
            self.scope.to_upper_space!
        end
    end

    ## Extends the Scope class with functionality for moving the declarations
    #  to the upper namespace.
    class Scope

        include ForceName

        # Moves the declarations to the upper namespace.
        def to_upper_space!
            # First recurse.
            # On the sub scopes.
            self.each_scope(&:to_upper_space!)
            # On the behaviors.
            self.each_behavior(&:to_upper_space!)
            
            # Then extract the declarations from the sub scope.
            decls = self.each_scope.map(&:extract_declares!)
            # And do the same with the behaviors'.
            decls << self.each_behavior.map(&:extract_declares!)

            # Reinsert the extracted declares to self.
            decls.flatten.each do |decl|
                if decl.is_a?(SignalI) then
                    self.add_inner(decl)
                elsif decl.is_a?(SystemI) then
                    self.add_systemI(decl)
                else
                    raise AnyError, "Internal error: invalid class for a declaration: #{decl.class}"
                end
            end
        end

        # Extract the declares from the scope and returns them into an array.
        # 
        # NOTE: do not recurse into the sub scopes or behaviors!
        def extract_declares!
            # Ensure there is a name.
            self.force_name!
            # The extracted declares.
            decls = []
            # Extract the inners.
            inners = []
            self.each_inner {|inner| inners << inner }
            inners.each {|inner| self.delete_inner!(inner) }
            # Renames them with the current level.
            inners.each do |inner|
                former = inner.name
                self.extend_name!(inner)
                self.replace_names_subs!(former,inner.name)
            end
            # Adds the inners
            decls << inners
            # Extract the systemIs
            systemIs = []
            self.each_systemI {|systemI| systemIs << systemI }
            systemIs.each {|systemI| self.delete_systemI!(systemI) }
            # Renames them with the current level.
            systemIs.each do |systemI|
                former = systemI.name
                self.extend_name!(systemI)
                self.replace_names_subs!(former,systemI.name)
            end
            # Adds the systemIs
            decls << systemIs
            # Returns the extracted declares.
            return decls
        end

        # Replaces recursively +former+ name by +nname+ until it is redeclared
        # in the sub scopes and behaviors.
        def replace_names_subs!(former,nname)
            self.each_scope do |scope|
                scope.replace_names!(former,nname)
            end
            self.each_behavior do |behavior|
                behavior.replace_names!(former,nname)
            end
        end

        # Replaces recursively +former+ name by +nname+ until it is redeclared.
        def replace_names!(former,nname)
            # Stop here if the name is redeclared.
            return if self.each_inner.find {|inner| inner.name == former }
            # Recurse on the sub scopes and behaviors.
            replace_names_subs!(former,nname)
        end
    end


    ## Extends the Behavior class with functionality for moving the declarations
    #  to the upper namespace.
    class Behavior

        # Moves the declarations to the upper namespace.
        def to_upper_space!
            # Recurse on the block.
            self.block.to_upper_space!
        end

        # Extract the declares from the scope and returns them into an array.
        # 
        # NOTE: do not recurse into the sub scopes or behaviors!
        def extract_declares!
            # Recurse on the block.
            return self.block.extract_declares!
        end

        # Replaces recursively +former+ name by +nname+ until it is redeclared.
        def replace_names!(former,nname)
            # Recurse on the block.
            self.block.replace_names!(former,nname)
        end
    end

    ## Extends the Statement class with functionality for moving the
    #  declarations to the upper namespace.
    class Statement

        # Moves the declarations to the upper namespace.
        def to_upper_space!
            # By default, nothing to do.
        end

        # Extract the declares from the scope and returns them into an array.
        # 
        # NOTE: do not recurse into the sub scopes or behaviors!
        def extract_declares!
            # By default, nothing to do.
            return []
        end

        # Replaces recursively +former+ name by +nname+ until it is redeclared.
        def replace_names!(former,nname)
            # By default: try to replace the name recursively.
            self.each_node_deep do |node|
                if node.respond_to?(:name) && node.name == former then
                    node.set_name!(nname)
                end
            end
        end
    end

    ## Extends the Expression class with functionality for moving the
    #  declarations  to the upper namespace.
    class Expression

        # Replaces recursively +former+ name by +nname+ until it is redeclared.
        def replace_names!(former,nname)
            # By default: try to replace the name recursively.
            self.each_node_deep do |node|
                if node.respond_to?(:name) && node.name == former then
                    node.set_name!(nname)
                end
            end
        end
    end
    
    ## Extends the If class with functionality for moving the declarations
    #  to the upper namespace.
    class If

        # Moves the declarations to the upper namespace.
        def to_upper_space!
            # Recurse on the sub blocks.
            # Yes.
            self.yes.to_upper_space!
            # Noifs.
            self.each_noif {|cond,stmnt| stmnt.to_upper_space! }
            # No if any.
            self.no.to_upper_space! if self.no
        end

        # Extract the declares from the scope and returns them into an array.
        # 
        # NOTE: do not recurse into the sub scopes or behaviors!
        def extract_declares!
            # The extracted declares.
            decls = []
            # Recurse on the sub blocks.
            # Yes.
            decls << self.yes.extract_declares!
            # Noifs.
            decls << self.each_noif.map do |cond,stmnt|
                stmnt.extract_declares!
            end
            # No if any.
            decls << self.no.extract_declares! if self.no
            # Returns the extracted declares.
            return decls
        end

        # Replaces recursively +former+ name by +nname+ until it is redeclared.
        def replace_names!(former,nname)
            # Recurse on the condition.
            self.condition.replace_names!(former,nname)
            # Recurse on the yes.
            self.yes.replace_names!(former,nname)
            # Recurse on the alternate ifs.
            self.each_noif do |cond,stmnt| 
                cond.replace_names!(former,nname)
                stmnt.replace_names!(former,nname)
            end
        end
    end

    ## Extends the When class with functionality for moving the declarations
    #  to the upper namespace.
    class When

        # Moves the declarations to the upper namespace.
        def to_upper_space!
            # Recurse on the statement.
            self.statement.to_upper_space!
        end

        # Extract the declares from the scope and returns them into an array.
        # 
        # NOTE: do not recurse into the sub scopes or behaviors!
        def extract_declares!
            # Recurse on the statement.
            return self.statement.extract_declares!
        end

        # Replaces recursively +former+ name by +nname+ until it is redeclared.
        def replace_names!(former,nname)
            # Recurse on the match.
            self.match.replace_names!(former,nname)
            # Recurse on the statement.
            self.statement.replace_names!(former,nname)
        end
    end

    ## Extends the When class with functionality for moving the declarations
    #  to the upper namespace.
    class Case

        # Moves the declarations to the upper namespace.
        def to_upper_space!
            # Recurse on the whens.
            self.each_when(&:to_upper_space!)
        end

        # Extract the declares from the scope and returns them into an array.
        # 
        # NOTE: do not recurse into the sub scopes or behaviors!
        def extract_declares!
            # Recurse on the whens.
            return self.each_when.map(&:extract_declares!)
        end

        # Replaces recursively +former+ name by +nname+ until it is redeclared.
        def replace_names!(former,nname)
            # Recurse on the value.
            self.value.replace_names!(former,nname)
            # Recurse on the whens.
            self.each_when {|w| w.replace_names!(former,nname) }
        end
    end

    ## Extends the When class with functionality for moving the declarations
    #  to the upper namespace.
    class TimeRepeat

        # Moves the declarations to the upper namespace.
        def to_upper_space!
            # Recurse on the statement.
            self.statement.to_upper_space!
        end

        # Extract the declares from the scope and returns them into an array.
        # 
        # NOTE: do not recurse into the sub scopes or behaviors!
        def extract_declares!
            # Recurse on the statement.
            return self.statement.extract_declares!
        end

        # Replaces recursively +former+ name by +nname+ until it is redeclared.
        def replace_names!(former,nname)
            # Recurse on the statement.
            self.statement.replace_names!(former,nname)
        end
    end

    ## Extends the When class with functionality for moving the declarations
    #  to the upper namespace.
    class Block

        include ForceName

        # Moves the declarations to the upper namespace.
        def to_upper_space!
            # Recurse on the statements.
            self.each_statement(&:to_upper_space!)

            # Extract the declares from the statements.
            decls = self.each_statement.map(&:extract_declares!)

            # Reinsert the extracted declares to self.
            decls.flatten.each { |decl| self.add_inner(decl) }
        end

        # Extract the declares from the scope and returns them into an array.
        # 
        # NOTE: do not recurse into the sub scopes or behaviors!
        def extract_declares!
            # Ensure there is a name.
            self.force_name!
            # The extracted declares.
            decls = []
            # Extract the inners.
            self.each_inner {|inner| decls << inner }
            decls.each {|inner| self.delete_inner!(inner) }
            # Renames them with the current level.
            decls.each do |inner|
                former = inner.name
                self.extend_name!(inner)
                self.replace_names_subs!(former,inner.name)
            end
            # Returns the extracted declares.
            return decls
        end

        # Replaces recursively +former+ name by +nname+ until it is redeclared
        # in the sub scopes and behaviors.
        def replace_names_subs!(former,nname)
            self.each_statement do |stmnt|
                stmnt.replace_names!(former,nname)
            end
        end

        # Replaces recursively +former+ name by +nname+ until it is redeclared.
        def replace_names!(former,nname)
            # Stop here if the name is redeclared.
            return if self.each_inner.find {|inner| inner.name == former }
            # Recurse on the sub scopes and behaviors.
            replace_names_subs!(former,nname)
        end
    end

end
