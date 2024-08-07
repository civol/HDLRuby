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


    class SystemT
        ## Extends the SystemT class with functionality for moving the
        #  declarations to the upper namespace.

        include ForceName

        # Moves the declarations to the upper namespace.
        def to_upper_space!
            self.scope.to_upper_space!
        end

        # Moves local systemTs to global.
        #
        # NOTE: assumes to_upper_space! has been called.
        def to_global_systemTs!
            # Force a name if not.
            self.force_name!
            # puts "to_global_systemTs! for #{self.name}"
            # For each local systemT
            self.scope.each_systemT.to_a.each do |systemT|
                # puts "Processing system: #{systemT}"
                # Rename it for globalization.
                former = systemT.name
                self.extend_name!(systemT)
                # Apply the renaming to all the inner objects.
                self.scope.replace_names_subs!(former,systemT.name)
                # Remove it.
                self.scope.delete_systemT!(systemT)
            end
        end

        # Replaces recursively +former+ name by +nname+ until it is redeclared.
        def replace_names!(former,nname)
            # Replace owns name if required.
            if self.name == former then
                self.set_name!(nname)
            end
            # Recurse on the interface.
            self.each_input {|input| input.replace_names!(former,nname) }
            self.each_output {|output| output.replace_names!(former,nname) }
            self.each_inout {|inout| inout.replace_names!(former,nname) }
            # Recurse on the scope.
            self.scope.replace_names!(former,nname)
        end

        # Breaks the hierarchical types into sequences of type definitions.
        def break_types!
            self.scope.break_types!
        end
    end


    class Scope
        ## Extends the Scope class with functionality for moving the declarations
        #  to the upper namespace.

        include ForceName

        # Moves the declarations to the upper namespace.
        def to_upper_space!
            # puts "to_upper_space for scope=#{self}"
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
                if decl.is_a?(Type) then
                    self.add_type(decl)
                elsif decl.is_a?(SystemT) then
                    self.add_systemT(decl)
                elsif decl.is_a?(SignalI) then
                    self.add_inner(decl)
                elsif decl.is_a?(SystemI) then
                    self.add_systemI(decl)
                else
                    raise AnyError, "Internal error: invalid class for a declaration: #{decl.class}"
                end
            end

            # Extract the behaviors of the sub scopes.
            behs = self.each_scope.map(&:extract_behaviors!).flatten
            # Reinsert them to self.
            behs.each { |beh| self.add_behavior(beh) }

            # Extract the connections of the sub scopes.
            cnxs = self.each_scope.map(&:extract_connections!).flatten
            # Reinsert them to self.
            cnxs.each { |cnx| self.add_connection(cnx) }

            # The fix the RefName using sub scopes since their target have
            # been deplaced to current scope and renamed.
            self_scopes = self.each_scope.to_a
            self.each_behavior { |beh| beh.fix_scope_refnames!(self_scopes) }
            self.each_connection { |cnx| cnx.fix_scope_refnames!(self_scopes) }

            # Now can delete the sub scopes since they are empty.
            # self.each_scope.to_a.each { |scope| self.delete_scope!(scope) }
            self_scopes.each { |scope| self.delete_scope!(scope) }
        end

        # Extract the behaviors from the scope and returns them into an array.
        # 
        # NOTE: do not recurse into the sub scopes!
        def extract_behaviors!
            # Get the behaviors.
            behs = self.each_behavior.to_a
            # Remove them from the scope.
            # behs.each { |beh| self.delete_behavior!(beh) }
            self.delete_all_behaviors!
            # Return the behaviors.
            return behs
        end

        # Extract the connections from the scope and returns them into an array.
        # 
        # NOTE: do not recurse into the sub scopes!
        def extract_connections!
            # Get the connections.
            cnxs = self.each_connection.to_a
            # Remove them from the scope.
            # cnxs.each { |cnx| self.delete_connection!(cnx) }
            # cnxs.delete_all_connections!
            self.delete_all_connections!
            # Return the connections.
            return cnxs
        end

        # Extract the declares from the scope and returns them into an array.
        # 
        # NOTE: do not recurse into the sub scopes or behaviors!
        def extract_declares!
            # Ensure there is a name.
            self.force_name!
            # The extracted declares.
            decls = []
            # Extract the types.
            types = []
            self.each_type {|type| types << type }
            types.each {|type| self.delete_type!(type) }
            # Renames them with the current level.
            types.each do |type|
                former = type.name
                self.extend_name!(type)
                self.replace_names_subs!(former,type.name)
            end
            # Adds the types
            decls << types
            # Extract the systemTs.
            systemTs = []
            self.each_systemT {|systemT| systemTs << systemT }
            systemTs.each {|systemT| self.delete_systemT!(systemT) }
            # Renames them with the current level.
            systemTs.each do |systemT|
                former = systemT.name
                self.extend_name!(systemT)
                self.replace_names_subs!(former,systemT.name)
            end
            # Adds the systemTs
            decls << systemTs
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
        # in the internals.
        def replace_names_subs!(former,nname)
            # puts "replace_names_subs! for #{self} with former=#{former} and nname=#{nname}"
            # No need? 
            # self.each_type do |type|
            #     type.replace_names!(former,nname)
            # end
            self.each_systemT do |systemT|
                systemT.replace_names!(former,nname)
            end
            self.each_scope do |scope|
                scope.replace_names!(former,nname)
            end
            self.each_inner do |inner|
                inner.replace_names!(former,nname)
            end
            self.each_systemI do |systemI|
                systemI.replace_names!(former,nname)
            end
            self.each_connection do |connection|
                connection.replace_names!(former,nname)
            end
            self.each_behavior do |behavior|
                behavior.replace_names!(former,nname)
            end
        end

        # Replaces recursively +former+ name by +nname+ until it is redeclared.
        def replace_names!(former,nname)
            # Stop here if the name is redeclared.
            return if self.each_type.find {|type| type.name == former }
            return if self.each_systemT.find {|systemT| systemT.name == former }
            return if self.each_inner.find {|inner| inner.name == former }
            # Recurse on the internals.
            replace_names_subs!(former,nname)
        end

        # Breaks the hierarchical types into sequences of type definitions.
        # Assumes to_upper_space! has been called before.
        def break_types!
            # The created types by structure.
            types = {}
            # Break the local types.
            self.each_type {|type| type.break_types!(types)}
            # Break the types in the inners.
            # self.each_inner {|inner| inner.type.break_types!(types) }
            self.each_inner do |inner|
                inner.set_type!(inner.type.break_types!(types))
            end
            # Break the types in the connections.
            self.each_connection do |connection| 
                connection.left.break_types!(types)
                connection.right.break_types!(types)
            end
            # Break the types in the behaviors.
            self.each_behavior do |behavior|
                behavior.each_event do |event|
                    event.ref.break_types!(types) 
                end
                behavior.block.break_types!(types)
            end

            # Add the resulting types.
            types.each_value {|type| self.add_type(type) }
        end
    end


    class Type
        ## Extends the Type class with functionality for breaking hierarchical
        #  types.

        # Breaks the hierarchical types into sequences of type definitions.
        # Assumes to_upper_space! has been called before.
        # +types+ include the resulting types.
        def break_types!(types)
            # By default, nothing to do.
            return self
        end
    end


    class TypeVector
        ## Extends the TypeVector class with functionality for breaking hierarchical
        #  types.

        # Breaks the hierarchical types into sequences of type definitions.
        # Assumes to_upper_space! has been called before.
        # +types+ include the resulting types.
        def break_types!(types)
            if self.base.is_a?(TypeVector) || self.base.is_a?(TypeTuple) ||
               self.base.is_a?(TypeStruct) then
                # Need to break
                # First recurse on the base.
                nbase = self.base.break_types!(types)
                # # Maybe such a type already exists.
                # ndef = types[nbase]
                # if ndef then
                #     # Yes, use it.
                #     self.set_base!(ndef.clone)
                # else
                #     # No change it to a type definition
                #     ndef = TypeDef.new(HDLRuby.uniq_name,nbase)
                #     self.set_base!(ndef)
                #     # And add it to the types by structure.
                #     types[nbase] = ndef
                # end
                # Sets the base.
                self.set_base!(nbase)
                # And create a new type from current type.
                # Maybe the new type already exists.
                ndef = types[self]
                return ndef if ndef # Yes, already exists.
                # No, create and register a new typedef.
                ndef = TypeDef.new(HDLRuby.uniq_name,self)
                types[self] = ndef
                return ndef
            end
            return self
        end
    end


    class TypeTuple
        ## Extends the TypeTuple class with functionality for breaking
        #  hierarchical types.

        # Breaks the hierarchical types into sequences of type definitions.
        # Assumes to_upper_space! has been called before.
        # +types+ include the resulting types.
        def break_types!(types)
            self.map_types! do |sub|
                if sub.is_a?(TypeVector) || sub.is_a?(TypeTuple) ||
                        sub.is_a?(TypeStruct) then
                    # Need to break
                    # First recurse on the sub.
                    nsub = sub.break_types!(types)
                    # Maybe such a type already exists.
                    ndef = types[sub]
                    if ndef then
                        # Yes, use it.
                        ndef.clone
                    else
                        # No change it to a type definition
                        ndef = TypeDef.new(HDLRuby.uniq_name,nsub)
                        # And add it to the types by structure.
                        types[nsub] = ndef
                        nsub
                    end
                end
            end
            return self
        end
    end


    class TypeStruct
        ## Extends the TypeStruct class with functionality for breaking
        #  hierarchical types.

        # Breaks the hierarchical types into sequences of type definitions.
        # Assumes to_upper_space! has been called before.
        # +types+ include the resulting types.
        def break_types!(types)
            self.map_types! do |sub|
                if sub.is_a?(TypeVector) || sub.is_a?(TypeStruct) ||
                        sub.is_a?(TypeStruct) then
                    # Need to break
                    # First recurse on the sub.
                    nsub = sub.break_types!(types)
                    # Maybe such a type already exists.
                    ndef = types[sub]
                    if ndef then
                        # Yes, use it.
                        ndef.clone
                    else
                        # No change it to a type definition
                        ndef = TypeDef.new(HDLRuby.uniq_name,nsub)
                        # And add it to the types by structure.
                        types[nsub] = ndef
                        nsub
                    end
                end
            end
            return self
        end
    end


    class SignalI
        ## Extends the SignalI class with functionality for moving the
        #  declarations to the upper namespace.

        # Replaces recursively +former+ name by +nname+ until it is redeclared.
        def replace_names!(former,nname)
            # Recurse on the type.
            self.type.each_type_deep do |type|
                if type.respond_to?(:name) && type.name == former then
                    type.set_name!(nname)
                end
            end
        end
    end


    class SystemI
        ## Extends the SystemI class with functionality for moving the
        #  declarations to the upper namespace.

        # Replaces recursively +former+ name by +nname+ until it is redeclared.
        def replace_names!(former,nname)
            # Replace owns name if required.
            if self.name == former then
                self.set_name!(nname)
            end
            # Not needed since treated through scope and systemT.
            # # Recurse on the system type.
            # self.systemT.replace_names!(former,nname)
        end
    end


    class Behavior
        ## Extends the Behavior class with functionality for moving the
        #  declarations to the upper namespace.

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

        # Fix the references names using scopes given in +scopes + list (they
        # are marked to be deleted).
        def fix_scope_refnames!(scopes)
          # puts "fix_scope_refnames for self=#{self}"
          self.block.fix_scope_refnames!(scopes)
          return self
        end
    end


    class Statement
        ## Extends the Statement class with functionality for moving the
        #  declarations to the upper namespace.

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

        # Breaks the hierarchical types into sequences of type definitions.
        # Assumes to_upper_space! has been called before.
        # +types+ include the resulting types.
        def break_types!(types)
            self.each_node do |node|
                node.break_types!(types)
            end
        end

        # Fix the references names using scopes given in +scopes + list (they
        # are marked to be deleted).
        def fix_scope_refnames!(scopes)
          # By default, does nothing.
          return self
        end
    end


    class Transmit
        # Fix the references names using scopes given in +scopes + list (they
        # are marked to be deleted).
        def fix_scope_refnames!(scopes)
            self.set_left!(self.left.fix_scope_refnames!(scopes))
            self.set_right!(self.right.fix_scope_refnames!(scopes))
            return self
        end
    end

    class Connection
        # Fix the references names using scopes given in +scopes + list (they
        # are marked to be deleted).
        def fix_scope_refnames!(scopes)
            self.set_left!(self.left.fix_scope_refnames!(scopes))
            self.set_right!(self.right.fix_scope_refnames!(scopes))
            return self
        end
    end


    class Expression
        ## Extends the Expression class with functionality for moving the
        #  declarations to the upper namespace.

        # Replaces recursively +former+ name by +nname+ until it is redeclared.
        def replace_names!(former,nname)
            # By default: try to replace the name recursively.
            self.each_node_deep do |node|
                if node.respond_to?(:name) && node.name == former then
                    node.set_name!(nname)
                end
            end
        end

        # Breaks the hierarchical types into sequences of type definitions.
        # Assumes to_upper_space! has been called before.
        # +types+ include the resulting types.
        def break_types!(types)
            self.each_node do |node|
                # Need to break only in the case of a cast.
                if node.is_a?(Cast) then
                    # node.type.break_types!(types)
                    node.set_type!(node.type.break_types!(types))
                end
            end
        end

        # Fix the references names using scopes given in +scopes + list (they
        # are marked to be deleted).
        def fix_scope_refnames!(scopes)
            # By default: recurse.
            self.map_nodes! do |node|
                node.fix_scope_refnames!(scopes)
            end
            return self
        end
    end

    
    class If
        ## Extends the If class with functionality for moving the declarations
        #  to the upper namespace.

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
            # Recurse on the no if any.
            self.no.replace_names!(former,nname) if self.no
        end

        # Fix the references names using scopes given in +scopes + list (they
        # are marked to be deleted).
        def fix_scope_refnames!(scopes)
            # Fix the condition.
            self.set_condition!(self.condition.fix_scope_refnames!(scopes))
            # Recurse on the yes.
            self.yes.fix_scope_refnames!(scopes)
            # Recurse on the alternate ifs.
            self.map_noifs! do |cond,stmnt|
                cond = cond.fix_scope_refnames!(scopes)
                stmnt = stmnt.fix_scope_refnames!(scopes)
                [cond,stmnt]
            end
            # Recruse on the no if any.
            self.no.fix_scope_refnames!(scopes) if self.no
            return self
        end
    end


    class When
        ## Extends the When class with functionality for moving the declarations
        #  to the upper namespace.

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

        # Breaks the hierarchical types into sequences of type definitions.
        # Assumes to_upper_space! has been called before.
        # +types+ include the resulting types.
        def break_types!(types)
            self.each_node do |node|
                # Need to break only in the case of a cast.
                if node.is_a?(Cast) then
                    node.type.break_types!(types)
                end
            end
        end

        # Fix the references names using scopes given in +scopes + list (they
        # are marked to be deleted).
        def fix_scope_refnames!(scopes)
            # Fix the match.
            self.set_match!(self.match.fix_scope_refnames!(scopes))
            # Recurse on the statement.
            self.statement.fix_scope_refnames!(scopes)
            return self
        end
    end


    class Case
        ## Extends the When class with functionality for moving the declarations
        #  to the upper namespace.

        # Moves the declarations to the upper namespace.
        def to_upper_space!
            # Recurse on the whens.
            self.each_when(&:to_upper_space!)
            # Recurse on the default if any.
            self.default.to_upper_space! if self.default
        end

        # Extract the declares from the scope and returns them into an array.
        # 
        # NOTE: do not recurse into the sub scopes or behaviors!
        def extract_declares!
            # # Recurse on the whens.
            # return self.each_when.map(&:extract_declares!)
            # # Recurse on the default if any.
            # self.default.extract_declares! if self.default
            res = self.each_when.map(&:extract_declares!)
            res += self.default.extract_declares! if self.default
            return res
        end

        # Replaces recursively +former+ name by +nname+ until it is redeclared.
        def replace_names!(former,nname)
            # Recurse on the value.
            self.value.replace_names!(former,nname)
            # Recurse on the whens.
            self.each_when {|w| w.replace_names!(former,nname) }
            # Recurse on the default.
            self.default.replace_names!(former,nname) if self.default
        end

        # Fix the references names using scopes given in +scopes + list (they
        # are marked to be deleted).
        def fix_scope_refnames!(scopes)
            # Fix the value.
            self.set_value!(self.value.fix_scope_refnames!(scopes))
            # Recurse on the whens.
            self.each_when {|w| w.fix_scope_refnames!(scopes) }
            # Recurse on the default.
            self.default.fix_scope_refnames!(scopes) if self.default
            return self
        end
    end


    class TimeRepeat
        ## Extends the When class with functionality for moving the declarations
        #  to the upper namespace.

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

        # Fix the references names using scopes given in +scopes + list (they
        # are marked to be deleted).
        def fix_scope_refnames!(scopes)
            # Recurse on the statement.
            self.statement.fix_scope_refnames!(scopes)
            return self
        end
    end


    class Block
        ## Extends the When class with functionality for moving the declarations
        #  to the upper namespace.

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
            # Already processed with fix_scope_refnames, so nothing to do
            # here.
            return
            # Stop here if the name is redeclared.
            # return if self.each_inner.find {|inner| inner.name == former }
            # Recurse on the sub scopes and behaviors.
            # replace_names_subs!(former,nname)
        end

        # Fix the references names using scopes given in +scopes + list (they
        # are marked to be deleted).
        def fix_scope_refnames!(scopes)
            self.each_statement {|stmnt| stmnt.fix_scope_refnames!(scopes) }
            return self
        end
    end


    class RefName
        include ForceName

        # Fix the references names using scopes given in +scopes + list (they
        # are marked to be deleted).
        def fix_scope_refnames!(scopes)
            return self unless self.ref.is_a?(RefName)
            # puts "fix_scope_refnames! with self=#{self} self.name=#{name} and self.ref=#{self.ref}"
            # Recurse on the ref.
            # self.set_ref!(self.ref.fix_scope_refnames!(scopes))
            # Rename and curt the subref if referening to one of the scopes.
            if scopes.find {|scope| scope.name == self.ref.name } then
                self.ref.extend_name!(self)
                # But need to remove the scope reference.
                self.set_ref!(RefThis.new)
            end
            # puts "Now self=#{self} self.name=#{self.name} self.ref=#{self.ref}"
            return self
        end
    end

end
