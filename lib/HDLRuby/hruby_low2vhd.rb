require 'HDLRuby'
require 'HDLRuby/hruby_low_without_namespace'
require 'HDLRuby/hruby_low_with_var'


module HDLRuby::Low


##
# Converts a HDLRuby::Low description to a VHDL text 
# description
#
########################################################################

    ## Provides tools for converting HDLRuby::Low objects to VHDL.
    module Low2VHDL

        # Indicates if VHDL'93 can be generated.
        # Default: true
        #
        # NOTE: when possible, it is better to be left true since the
        # identifier does not require any mangling in VHDL'93
        @@vhdl93 = true

        ## Tells if VHDL'93 is supported or not.
        def self.vhdl93
            return @@vhdl93
        end

        ## Sets/unsets the support of VHDL'93.
        def self.vhdl93=(mode)
            @@vhdl93 = mode ? true : false
        end

        ## Generates the pakage requirement for an entity.
        #  +spaces+ are the spaces to put before each line.
        def self.packages(spaces)
            return "#{spaces}library ieee;\n" +
                   "#{spaces}use ieee.std_logic_1164.all;\n" +
                   "#{spaces}use ieee.numeric_std.all;\n\n"
        end

        ## Tells if a +name+ is VHDL-compatible.
        #  To ensure compatibile, assume all the character must have the
        #  same case.
        def self.vhdl_name?(name)
            name = name.to_s
            # First: character check.
            return false unless name =~ /^[a-zA-Z]|([a-zA-Z][a-zA-Z_0-9]*[a-zA-Z0-9])$/
            # Then character sequence check.
            return false if name.include?("__")
            # Then case check.
            return (name == name.upcase || name == name.downcase)
        end

        ## Converts a +name+ to a VHDL-compatible name.
        def self.vhdl_name(name)
            if vhdl93 then
                # VHDL'93, nothing to do if the name is VHDL-compatible.
                return name.to_s if self.vhdl_name?(name)
                # Otherwise put the name between //
                return "\\#{name}\\".to_s
            else
                # Not VHDL'93, need to mangle the name.
                # For safety also force downcase.
                name = name.to_s
                # Other letters: convert special characters.
                name = name.each_char.map do |c|
                    if c=~ /[a-uw-z0-9]/ then
                        c
                    elsif c == "v" then
                        "vv"
                    else
                        "v" + c.ord.to_s
                    end
                end.join
                # First character: only letter is possible.
                unless name[0] =~ /[a-z]/ then
                    name = "v" + name
                end
                return name
            end
        end

        ## Converts a +name+ to a VHDL entity name.
        #
        # NOTE: assume names have been converted to VHDL-compatible ones.
        def self.entity_name(name)
            return self.vhdl_name(name.to_s + "_e")
        end

        ## Converts a +name+ to a VHDL architecture name.
        #
        # NOTE: assume names have been converted to VHDL-compatible ones.
        def self.architecture_name(name)
            return self.vhdl_name(name.to_s + "_a")
        end

        ## Tells if a +type+ is arithmetic-compatible.
        def self.arith?(type)
            return type.is_a?(TypeVector) && 
                [:signed,:unsigned,:float].include?(type.base.name)
        end

        ## Generates expression +expr+ while casting it to
        #  arithmetic-compatible type if required.
        def self.to_arith(expr)
            if arith?(expr.type) then
                # The expression is arithmetic-compatible, just generate it.
                return expr.to_vhdl
            else
                # The expression is to convert, by default convert to unsigned
                # (this is the standard interpretation of HDLRuby).
                if expr.type.to_vhdl == "std_logic" then
                    # std_logic case: must convert to vector first.
                    return "unsigned('0' & " + expr.to_vhdl + ")"
                else
                    # Other case, ue the expression direction.
                    return "unsigned(" + expr.to_vhdl + ")"
                end
            end
        end

        ## Generates a expression converted to the boolean type.
        def self.to_boolean(expr)
            if expr.is_a?(Binary) and expr.operator == :== then
                # Equality comparison, no conversion required.
                return expr.to_vhdl
            else
                # Conversion to boolean required.
                return "(" + expr.to_vhdl + " = '1')"
            end
        end

        ## Generates epression +expr+ while casting it to match +type+ if
        #  required.
        def self.to_type(type,expr)
            if expr.type.to_vhdl != "std_logic" &&
               type.to_vhdl == "std_logic" then
                # Conversion to std_logic required.
                if expr.is_a?(Value) then
                    # Values can simply be rewritten.
                    if expr.content.to_s.to_i(2) == 0 then
                        return "'0'"
                    else
                        return "'1'"
                    end
                else
                    # Otherwise a cast is required.
                    return "unsigned(#{expr.to_vhdl})(0)"
                end
            else
                # No conversion required.
                return expr.to_vhdl
            end
        end

        ## Cast a +type+ to undo arithmetic conversion if necessary.
        def self.unarith_cast(type)
            # Is the type arithmetic?
            if arith?(type) then
                # Yes, no undo required.
                return ""
            else
                # No, undo required.
                return "std_logic_vector"
            end
        end

        ## Generates the name of a mux function by type string +tstr+.
        def self.mux_name(tstr)
            return "mux#{tstr.gsub(/[^a-zA-Z0-9_]/,"_")}"
        end

        ## Generates the VHDL code for the mux function for type string +tstr+.
        #  +spaces+ is the ident for the resulting code.
        def self.mux_function(tstr,spaces)
            # Create the name of the function from the type.
            # Generates the function
            return "#{spaces}function #{mux_name(tstr)}" + 
                       "(cond : boolean, left : #{tstr}, right : #{tstr})\n" +
                   "#{spaces}return #{tstr} is\n" +
                   "#{spaces}begin\n" +
                   "#{spaces}   if(cond) then\n" +
                   "#{spaces}      return left;\n" +
                   "#{spaces}   else\n" +
                   "#{spaces}      return right;\n" +
                   "#{spaces}   end if;\n" +
                   "#{spaces}end mux#{tstr};\n\n"
        end

    end


    ## Extends the SystemT class with generation of HDLRuby::High text.
    class SystemT

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            # The resulting string.
            res = ""
            # Generate the entity
            # The header
            res << Low2VHDL.packages(" " * (level*3))
            res << " " * (level*3)
            res << "entity #{Low2VHDL.entity_name(self.name)} is\n"
            # The ports
            res << " " * ((level+1)*3)
            res << "port (\n"
            # Inputs
            self.each_input do |input|
                res << " " * ((level+2)*3)
                res << Low2VHDL.vhdl_name(input.name) << ": in " 
                res << input.type.to_vhdl << ";\n"
            end
            # Outputs
            self.each_output do |output|
                res << " " * ((level+2)*3)
                res << Low2VHDL.vhdl_name(output.name) << ": out " 
                res << output.type.to_vhdl << ";\n"
            end
            # Inouts
            self.each_inout do |inout|
                res << " " * ((level+2)*3)
                res << Low2VHDL.vhdl_name(inout.name) << ": inout " 
                res << inout.type.to_vhdl << ";\n"
            end
            # Remove the last ";" for conforming with VHDL syntax.
            res[-2..-1] = "\n" if res[-2] == ";"
            res << " " * ((level+1)*3)
            # Close the port declaration.
            res << ");\n"
            # Close the entity
            res << " " * (level*3)
            res << "end #{Low2VHDL.entity_name(self.name)};\n\n"


            # Generate the architecture.
            res << " " * (level*3)
            res << "architecture #{Low2VHDL.architecture_name(self.name)} "
            res << "of #{Low2VHDL.entity_name(self.name)} is\n"
            # Generate the scope.
            res << "\n"
            res << self.scope.to_vhdl(level+1)
            # End of the system.
            res << " " * (level*3)
            res << "end #{Low2VHDL.architecture_name(self.name)};\n\n"
            # Return the result.
            return res
        end
    end


    ## Extends the Scope class with generation of HDLRuby::High text.
    class Scope

        ## Tells if an expression is a reference to port +systemI.signal+.
        def port_assign?(expr, systemI, signal)
            return expr.is_a?(RefName) && expr.name == signal.name &&
                expr.ref.is_a?(RefName) && expr.ref.name == systemI.name
        end

        ## Extracts the assignments to port +systemI.signal+ and returns
        #  the resulting reference to a port wire.
        #
        #  NOTE: assumes to_upper_space! and with_port! has been called.
        def extract_port_assign!(systemI,signal)
            # Extract the assignment.
            assign = nil
            self.each_connection.to_a.each do |connection|
                if self.port_assign?(connection.left,systemI,signal) then
                    # The left is the port.
                    # Delete the connection.
                    self.delete_connection!(connection)
                    # And return a copy of the right.
                    return connection.right.clone
                elsif self.port_assign?(connection.right,systemI,signal) then
                    # The right is the port.
                    # Delete the connection.
                    self.delete_connection!(connection)
                    # And return a copy of the left.
                    return connection.left.clone
                end
            end
            # No port found, nothing to do
            return nil
        end

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object and
        def to_vhdl(level = 0)
            # The resulting string.
            res = ""

            # Generate the architecture's header
            # The instances' headers
            self.each_systemI do |systemI|
                systemT = systemI.systemT
                # Its entity
                res << (" " * level*3)
                res << "component #{Low2VHDL.entity_name(systemT.name)}\n"
                res << (" " * (level+1)*3)
                # Its ports
                res << "port(\n"
                # Inputs
                systemT.each_input do |input|
                    res << " " * ((level+2)*3)
                    res << Low2VHDL.vhdl_name(input.name) << ": in " 
                    res << input.type.to_vhdl << ";\n"
                end
                # Outputs
                systemT.each_output do |output|
                    res << " " * ((level+2)*3)
                    res << Low2VHDL.vhdl_name(output.name) << ": out " 
                    res << output.type.to_vhdl << ";\n"
                end
                # Inouts
                systemT.each_inout do |inout|
                    res << " " * ((level+2)*3)
                    res << Low2VHDL.vhdl_name(inout.name) << ": inout " 
                    res << inout.type.to_vhdl << ";\n"
                end
                # Remove the last ";" for conforming with VHDL syntax.
                res[-2..-1] = "\n" if res[-2] == ";"
                res << " " * ((level+1)*3)
                # Close the port declaration.
                res << ");\n"
                # Close the component.
                res << " " * (level*3)
                res << "end component;\n\n" 
            end

            # Generate the architecture's type definition.
            # It is assumed that these types are all TypeDef.
            self.each_type do |type|
                res << (" " * level*3)
                res << "type #{Low2VHDL.vhdl_name(type.name)} is "
                res << type.def.to_vhdl(level+1)
                res << ";\n"
            end

            ## Generates the required mux functions.
            mtps = [] # The mux functions to generate by type.
            # Gather the mux functions to generate.
            self.each_scope_deep do |scope|
                # Checks the connections.
                scope.each_connection do |connection|
                    connection.right.each_node_deep do |node|
                        mtps << node.type.to_vhdl(level) if node.is_a?(Select)
                    end
                end
                # Checks the statements.
                scope.each_behavior do |behavior|
                    behavior.block.each_node_deep do |node|
                        mtps << node.type.to_vhdl(level) if node.is_a?(Select)
                    end
                end
            end
            # Generate the gathered functions (only one per type).
            mtps.uniq!
            mtps.each do |tstr|
                res << Low2VHDL.mux_function(tstr," " * level*3)
            end

            # Generate the inner signals declaration.
            self.each_inner do |inner|
                res << " " * (level * 3)
                res << "signal " << Low2VHDL.vhdl_name(inner.name) << ": "
                res << inner.type.to_vhdl(level) 
                res << ";\n"
            end

            # Generate the architecture's content.
            res << " " * ((level-1)*3) << "begin\n"

            # Generate the instances connections.
            self.each_systemI do |systemI| 
                # Its Declaration.
                res << " " * (level*3)
                res << Low2VHDL.vhdl_name(systemI.name) << ": "
                systemT = systemI.systemT
                res << Low2VHDL.entity_name(systemT.name).to_s << "\n"
                res << " " * ((level+1)*3)
                # Its ports
                res << "port map(\n"
                # Inputs
                systemT.each_input do |input|
                    ref = self.extract_port_assign!(systemI,input)
                    if ref then
                        res << " " * ((level+2)*3)
                        res << Low2VHDL.vhdl_name(input.name) << " => " 
                        res << ref.to_vhdl(level) 
                        res << ",\n"
                    end
                end
                # Outputs
                systemT.each_output do |output|
                    ref = self.extract_port_assign!(systemI,output)
                    if ref then
                        res << " " * ((level+2)*3)
                        res << Low2VHDL.vhdl_name(output.name) << " => " 
                        res << ref.to_vhdl(level) 
                        res << ",\n"
                    end
                end
                # Inouts
                systemT.each_inout do |inout|
                    ref = self.extract_port_assign!(systemI,inout)
                    if ref then
                        res << " " * ((level+2)*3)
                        res << Low2VHDL.vhdl_name(inout.name) << " => " 
                        res << ref.to_vhdl(level) 
                        res << ",\n"
                    end
                end
                # Remove the last ";" for conforming with VHDL syntax.
                res[-2..-1] = "\n" if res[-2] == ","
                # Close the port map declaration.
                res << " " * ((level+1)*3)
                res << ");\n"
            end
            # Generate the connections.
            res << "\n" if self.each_scope.any?
            self.each_scope_deep do |scope|
                scope.each_connection do |connection|
                    res << connection.to_vhdl(level)
                end
            end

            # Generate the behaviors.
            # Current scope's
            res << "\n" if self.each_connection.any?
            self.each_scope_deep do |scope|
                scope.each_behavior do |behavior|
                    res << behavior.to_vhdl(level)
                end
            end
            return res
        end
    end


    ## Extends the Type class with generation of HDLRuby::High text.
    class Type

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            return "std_logic"
        end
    end

    ## Extends the TypeDef class with generation of HDLRuby::High text.
    class TypeDef

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            # # Simply generates the redefined type.
            # return self.def.to_vhdl(level)
            # Simply use the name of the type.
            return Low2VHDL.vhdl_name(self.name)
        end
    end

    ## Extends the TypeVector class with generation of HDLRuby::High text.
    class TypeVector

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            # The resulting string.
            res = ""
            # Depending on the base.
            if self.base.class < Type then
                # The base is not a leaf, therefore the type is a VHDL array.
                # NOTE: array are always valid if used in type definition,
                # it is assumed that break_types! from
                # hruby_low_without_namespace.rb is used.
                res << "array ("
                res << self.range.first.to_vhdl(level)
                if self.range.first > self.range.last then
                    res << " downto "
                else
                    res << " to "
                end
                res << self.range.last.to_vhdl(level)
                res << ") of "
                # Now generate the base.
                res << base.to_vhdl(level+1)
            else
                # The base is a leaf, therefore the type is VHDL vector.
                # Depending on the base name.
                case(base.name)
                when :bit
                    # std_logic_vector.
                    res << "std_logic_vector"
                when :signed
                    res << "signed"
                when :unsigned
                    res << "unsigned"
                else
                    res << Low2VHDL.vhdl_name(self.base.name)
                end
                # Now the range
                res << "("
                res << self.range.first.to_vhdl(level)
                left = self.range.first
                right = self.range.last
                left = left.content if left.is_a?(Value)
                right = right.content if right.is_a?(Value)
                if left > right then
                    res << " downto "
                else
                    res << " to "
                end
                res << self.range.last.to_vhdl(level)
                res << ")"
            end
            # Return the result.
            return res
        end
    end

    ## Extends the TypeTuple class with generation of HDLRuby::High text.
    class TypeTuple

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            raise AnyError, "Tuple types are not supported in VHDL, please convert them to Struct types using Low::tuple2struct from HDLRuby/hruby_low_witout_tuple."
        end
    end

    ## Extends the TypeStruct class with generation of HDLRuby::High text.
    class TypeStruct

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            # The resulting string.
            res = "record \n"
            # Generate each sub type.
            self.each do |key,type|
                res << " " * ((level+1)*3)
                res << Low2VHDL.vhdl_name(key)
                res << ": " << type.to_vhdl(level+1)
                res << ";\n"
            end
            res << " " * (level*3)
            # Close the record.
            res << "end record"
            # Return the result.
            return res
        end
    end


    ## Extends the Behavior class with generation of HDLRuby::High text.
    class Behavior

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            # The resulting string.
            res = " " * (level*3)
            # Generate the header.
            unless  self.block.name.empty? then
                res << Low2VHDL.vhdl_name(self.block.name) << ": "
            end
            res << "process "
            # Generate the senitivity list.
            if self.each_event.any? then
                # If there is a clock.
                res << "("
                res << self.each_event.map do |event|
                    event.ref.to_vhdl(level)
                end.join(", ")
                res << ")"
            else
                # If no clock, generate the sensitivity list from the right
                # values.
                list = self.block.each_node_deep.select do |node|
                    node.is_a?(RefName) && !node.leftvalue? && 
                        !node.parent.is_a?(RefName)
                end.to_a
                # Keep only one ref per signal.
                list.uniq! { |node| node.name }
                # Generate the sensitivity list from it.
                res << "("
                res << list.map {|node| node.to_vhdl(level) }.join(", ")
                res << ")"
            end
            res << "\n"
            # Generate the variables.
            # It is assumed that the inners are all in declared in the
            # direct sub block and that they represent variables, i.e.,
            # Low::to_upper_space! and Low::with_var! has been called.
            self.block.each_inner do |inner|
                res << " " * ((level+1)*3)
                res << "variable "
                res << Low2VHDL.vhdl_name(inner.name) << ": " 
                res << inner.type.to_vhdl << ";\n"
            end

            # Generate the content.
            res << " " * (level*3)
            res << "begin\n"
            # Generate the edges if any.
            if self.each_event.find {|event| event.type != :change} then
                # Generate the edge test.
                level = level + 1
                res << " " * (level*3)
                res << "if ("
                res << self.each_event.map do |event|
                    if event.type == :posedge then
                        "rising_edge(" << event.ref.to_vhdl(level) << ")"
                    else
                        "falling_edge(" << event.ref.to_vhdl(level)<< ")"
                    end
                    # The change mode is not an edge!
                end.join(" and ")
                res << ") then\n"
                # Generate the body.
                res << self.block.to_vhdl(level+2)
                # Close the edge test.
                res << " " * (level*3)
                res << "end if;\n"
                level = level - 1
            else
                # Generate the body directly.
                res << self.block.to_vhdl(level+1)
            end
            # Close the process.
            res << " " * (level*3)
            res << "end process;\n\n"
            # Return the result.
            return res
        end
    end

    ## Extends the TimeBehavior class with generation of HDLRuby::High text.
    class TimeBehavior
        # TimeBehavior is identical to Behavior in VHDL
    end


    ## Extends the Event class with generation of HDLRuby::High text.
    class Event
        # Events are not directly generated.
    end


    ## Extends the SignalI class with generation of HDLRuby::High text.
    class SignalI
        # Signals are not directly generated.

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            # Should never be here.
            raise AnyError, "Internal error: to_vhdl should be implemented in class :#{self.class}"
        end
    end


    ## Extends the SystemI class with generation of HDLRuby::High text.
    class SystemI
        # Instances are not directly generated.

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            # Should never be here.
            raise AnyError, "Internal error: to_vhdl should be implemented in class :#{self.class}"
        end
    end


    ## Extends the Statement class with generation of HDLRuby::High text.
    class Statement

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            # Should never be here.
            raise AnyError, "Internal error: to_vhdl should be implemented in class :#{self.class}"
        end
    end

    ## Extends the Transmit class with generation of HDLRuby::High text.
    class Transmit

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            return " " * (level*3 ) + 
                   self.left.to_vhdl(level) + " <= " +
                   Low2VHDL.to_type(self.left.type,self.right) + ";\n"
        end
    end
    
    ## Extends the If class with generation of HDLRuby::High text.
    class If

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            # The result string.
            res = " " * (level*3)
            # Generate the test.
            res << "if (" << Low2VHDL.to_boolean(self.condition) << ") then\n"
            # Generate the yes part.
            res << self.yes.to_vhdl(level+1)
            # Generate the alternate if parts.
            self.each_noif do |cond,stmnt|
                res << " " * (level*3)
                res << "elsif (" << cond.to_vhdl(level) << ") then\n"
                res << stmnt.to_vhdl(level+1)
            end
            # Generate the no part if any.
            if self.no then
                res << " " * (level*3)
                res << "else\n" << self.no.to_vhdl(level+1)
            end
            # Close the if.
            res << " " * (level*3)
            res << "end if;\n"
            # Return the result.
            return res
        end
    end

    ## Extends the When class with generation of HDLRuby::High text.
    class When

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            # The result string.
            res = " " * (level*3)
            # Generate the match.
            res << "when " << self.match.to_vhdl(level+1) << " =>\n"
            # Generate the statement.
            res << self.statement.to_vhdl(level+1)
            # Returns the result.
            return res
        end
    end

    ## Extends the Case class with generation of HDLRuby::High text.
    class Case

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            # The result string.
            res = " " * (level*3)
            # Generate the test.
            res << "case " << self.value.to_vhdl(level) << " is\n"
            # Generate the whens.
            self.each_when do |w|
                res << w.to_vhdl(level)
            end
            # Generate teh default if any.
            if self.default then
                res << " " * (level*3)
                res << "when others =>\n"
                res << self.default.to_vhdl(level+1)
            end
            # Close the case.
            res << " " * (level*3)
            res << "end case;\n"
            # Return the resulting string.
            return res
        end
    end


    ## Extends the Delay class with generation of HDLRuby::High text.
    class Delay

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            return self.value.to_vhdl(level) + " #{self.unit}"
        end
    end


    ## Extends the TimeWait class with generation of HDLRuby::High text.
    class TimeWait

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            # The resulting string.
            res = " " * (level*3)
            # Generate the wait.
            res << "wait for " << self.delay.to_vhdl(level) << ";\n" 
            # Return the resulting string.
            return res
        end
    end

    ## Extends the TimeRepeat class with generation of HDLRuby::High text.
    class TimeRepeat

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            raise AnyError, "Internal error: TimeRepeat not supported yet for conversion to VHDL."
        end
    end

    ## Extends the Block class with generation of HDLRuby::High text.
    class Block

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        #
        # NOTE: only the statements are generated, the remaining is assumed
        #       to be handled by the upper scope.
        def to_vhdl(level = 0)
            # The resulting string.
            res = ""
            # Generate the statements.
            self.each_statement do |stmnt|
                res << stmnt.to_vhdl(level)
            end
            # Return the result.
            return res
        end
    end

    ## Extends the TimeBlock class with generation of HDLRuby::High text.
    class TimeBlock
        # TimeBlock is identical to Block in VHDL
    end


    ## Extends the Code class with generation of HDLRuby::High text.
    class Code

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            raise "Code constructs cannot be converted into VHDL."
        end
    end

    ## Extends the Connection class with generation of HDLRuby::High text.
    class Connection
        # Nothing required, Transmit is generated identically.
    end


    ## Extends the Expression class with generation of HDLRuby::High text.
    class Expression

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            # Should never be here.
            raise AnyError, "Internal error: to_vhdl should be implemented in class :#{self.class}"
        end
    end

    ## Extends the Value class with generation of HDLRuby::High text.
    class Value

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            case self.content
            # when Numeric
            #     return self.content.to_s
            when HDLRuby::BitString
                return '"' + self.content.to_s + '"'
            else
                return '"' + self.content.to_s(2) + '"'
            end
        end
    end

    ## Extends the Cast class with generation of HDLRuby::High text.
    class Cast

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            if type.class == TypeVector then
                case type.base.name
                when :bit
                    return "std_logic_vector(resize(unsigned(" + 
                        self.child.to_vhdl(level) + ")," +
                        (type.range.first-type.range.last).abs.to_s + "))"
                when :signed
                    return "resize(signed(" + 
                        self.child.to_vhdl(level) + ")," +
                        (type.range.first-type.range.last).abs.to_s + ")"
                when :unsigned
                    return "resize(unsigned(" + 
                        self.child.to_vhdl(level) + ")," +
                        (type.range.first-type.range.last).abs.to_s + ")"
                else
                    raise "Intenal error: convertion to #{type.class} not supported yet for VHDL conversion."
                end
            elsif [:bit,:signed,:unsigned].include?(type.name) then
                # No conversion required.
                return self.child.to_vhdl(level)
            else
                raise "Intenal error: convertion to #{type.class} not supported yet for VHDL conversion."
            end
        end
    end

    ## Extends the Operation class with generation of HDLRuby::High text.
    class Operation

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            # Should never be here.
            raise AnyError, "Internal error: to_vhdl should be implemented in class :#{self.class}"
        end
    end

    ## Extends the Unary class with generation of HDLRuby::High text.
    class Unary

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            # Generate the operator string.
            operator = self.operator == :~ ? "not " : self.operator.to_s[0]
            # Is the operator arithmetic?
            if [:+@, :-@].include?(self.operator) then
                # Yes, type conversion my be required by VHDL standard.
                return "#{Low2VHDL.unarith_cast(self)}(#{operator}" +
                             Low2VHDL.to_arith(self.child) + ")"
            else
                # No, generate simply the unary operation.
                return "(#{operator}" + self.child.to_vhdl(level) + ")"
            end
        end
    end

    ## Extends the Binary class with generation of HDLRuby::High text.
    class Binary

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            # Generate the operator string.
            case self.operator
            when :&
                operator = " and "
            when :|
                operator = " or "
            when :^
                operator = " xor "
            when :==
                operator = " = "
            else
                operator = self.operator.to_s
            end
            # Is the operator arithmetic?
            if [:+, :-, :*, :/, :%].include?(self.operator) then
                # Yes, type conversion my be required by VHDL standard.
                return "#{Low2VHDL.unarith_cast(self)}(" +
                    Low2VHDL.to_arith(self.left) + operator +
                    Low2VHDL.to_arith(self.right) + ")"
            else
                # No, simply generate the binary operation.
                return "(" + self.left.to_vhdl(level) + operator + 
                             self.right.to_vhdl(level) + ")"
            end
        end
    end

    ## Extends the Select class with generation of HDLRuby::High text.
    class Select

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        #
        # NOTE: assumes the existance of the mux function.
        def to_vhdl(level = 0)
            # The resulting string.
            res = ""
            # Generate the header.
            res << "#{Low2VHDL.mux_name(self.type.to_vhdl(level))}(" +
                    self.select.to_vhdl(level) << ", "
            # Generate the choices
            res << self.each_choice.map do |choice|
                choice.to_vhdl(level+1)
            end.join(", ")
            # Close the select.
            res << ")"
            # Return the resulting string.
            return res
        end
    end

    ## Extends the Concat class with generation of HDLRuby::High text.
    class Concat

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            # The resulting string.
            res = ""
            # Generate the header.
            # Generate the expressions.
            res << self.each_expression.map do |expression|
                "(" + expression.to_vhdl(level+1) + ")"
            end.join(" & ")
            # Return the resulting string.
            return res
        end
    end


    ## Extends the Ref class with generation of HDLRuby::High text.
    class Ref

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            # Should never be here.
            raise AnyError, "Internal error: to_vhdl should be implemented in class :#{self.class}"
        end
    end

    ## Extends the RefConcat class with generation of HDLRuby::High text.
    class RefConcat

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            # The resulting string.
            res = ""
            # Generate the header.
            res << "( "
            # Generate the references.
            res << self.each_ref.map do |ref|
                ref.to_vhdl(level+1)
            end.join(", ")
            # Close the select.
            res << " )"
            # Return the resulting string.
            return res
        end
    end

    ## Extends the RefIndex class with generation of HDLRuby::High text.
    class RefIndex

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            return self.ref.to_vhdl(level) + "(#{self.index.to_vhdl(level)})"
        end
    end

    ## Extends the RefRange class with generation of HDLRuby::High text.
    class RefRange

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            # Generates the direction.
            first = self.range.first
            first = first.content if first.is_a?(Value)
            last = self.range.last
            last = last.content if last.is_a?(Value)
            direction = first > last ?  "downto " : " to "
            # Generate the reference.
            return self.ref.to_vhdl(level) +
                "((#{self.range.first.to_vhdl(level)}) " +
                direction + "(#{self.range.last.to_vhdl(level)}))"
        end
    end

    ## Extends the RefName class with generation of HDLRuby::High text.
    class RefName

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            # The resulting string.
            res = ""
            # Generate the sub refs if any (case of struct).
            unless self.ref.is_a?(RefThis) then
                res << self.ref.to_vhdl(level) << "."
            end
            # Generates the current reference.
            res << Low2VHDL.vhdl_name(self.name)
            # Returns the resulting string.
            return res
        end
    end

    ## Extends the RefThis class with generation of HDLRuby::High text.
    class RefThis 
        # Nothing to generate.
    end

    ## Extends the Numeric class with generation of HDLRuby::High text.
    class ::Numeric

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0)
            return self.to_s
        end
    end

end
