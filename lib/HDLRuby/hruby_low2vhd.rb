require 'HDLRuby'
require 'HDLRuby/hruby_low_with_bool'
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

        # Indicates if VHDL'08 can be generated.
        # Default: true
        #
        # NOTE: when possible, it is better to be left true since the
        # identifier does not require any mangling in VHDL'08
        @@vhdl08 = true

        ## Tells if VHDL'08 is supported or not.
        def self.vhdl08
            return @@vhdl08
        end

        ## Sets/unsets the support of VHDL'08.
        def self.vhdl08=(mode)
            @@vhdl08 = mode ? true : false
        end

        # Indicates if target toolchain is Alliance: requires a slightly
        # different VHDL syntax.
        #
        # NOTE: this syntax is not lint-compatible and should be avoided
        # unless using specifically Alliance.
        @@alliance = false

        ## Tells if Allicance toolchain is targeted.
        def self.alliance
            return @@alliance
        end

        ## Sets/unsets the Allicance toolchain targeting.
        def self.alliance=(mode)
            @@alliance = mode ? true : false
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
            if vhdl08 then
                # VHDL'08, nothing to do if the name is VHDL-compatible.
                return name.to_s if self.vhdl_name?(name)
                # Otherwise put the name between //
                return "\\#{name}\\".to_s
            else
                # Not VHDL'08, need to mangle the name.
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
                if expr.is_a?(Value) then
                    return expr.to_arith
                else
                    return expr.to_vhdl
                end
            else
                # The expression is to convert, by default convert to unsigned
                # (this is the standard interpretation of HDLRuby).
                if expr.type.to_vhdl == "std_logic" then
                    # std_logic case: must convert to vector first.
                    if alliance then
                        # Alliance toolchain case.
                        return "unsigned('0' & " + expr.to_vhdl + ")"
                    else
                        # General case.
                        return "unsigned(\"\" & " + expr.to_vhdl + ")"
                    end
                else
                    # Other case, ue the expression direction.
                    return "unsigned(" + expr.to_vhdl + ")"
                end
            end
        end

        # Moved to hruby_low_with_bool.rb
        #
        # ## Tells if an expression is a boolean.
        # def self.boolean?(expr)
        #     if expr.is_a?(Unary) && expr.operator == :~ then
        #         # NOT, boolean is the sub expr is boolean.
        #         return Low2VHDL.boolean?(expr.child)
        #     elsif expr.is_a?(Binary) then
        #         # Binary case.
        #         case(expr.operator)
        #         when :==,:!=,:>,:<,:>=,:<= then
        #             # Comparison, it is a boolean.
        #             return true
        #         when :&,:|,:^ then
        #             # AND, OR or XOR, boolean if both subs are boolean.
        #             return Low2VHDL.boolean?(expr.left) && 
        #                    Low2VHDL.boolean?(expr.right)
        #         else
        #             # Other cases: not boolean.
        #             return false
        #         end
        #     elsif expr.is_a?(Select) then
        #         # Select, binary if the choices are boolean.
        #         return !expr.each_choice.any? {|c| !Low2VHDL.boolean?(c) }
        #     else
        #         # Other cases are not considered as boolean.
        #         return false
        #     end
        # end

        ## Generates a expression converted to the boolean type.
        def self.to_boolean(expr)
            # if boolean?(expr) then
            if expr.boolean? then
                # Comparison, no conversion required.
                return expr.to_vhdl
            else
                # Conversion to boolean required.
                return "(" + expr.to_vhdl + " = '1')"
            end
        end

        ## Generates epression +expr+ while casting it to match +type+ if
        #  required.
        def self.to_type(type,expr)
            # puts "expr=#{expr.to_vhdl}" unless expr.is_a?(Concat)
            # puts "type.width=#{type.width}, expr.type.width=#{expr.type.width}"
            if type.to_vhdl == "std_logic" then
                # Conversion to std_logic required.
                if expr.is_a?(Value) then
                    # Values can simply be rewritten.
                    if expr.content.to_s.to_i(2) == 0 then
                        return "'0'"
                    else
                        return "'1'"
                    end
                elsif expr.type.to_vhdl != "std_logic"
                    # Otherwise a cast is required.
                    # if expr.type.base.name == :signed then
                    #     return "unsigned(#{expr.to_vhdl})(0)"
                    # else
                    #    # return "unsigned(#{expr.to_vhdl}(0))"
                    #    return "unsigned(#{expr.to_vhdl})(0)"
                    # end
                    if alliance then
                        # Specific syntax for casting to std_logic with Alliance
                        if expr.type.width == 1 then
                            # No cast required with alliance if bitwidth is 1.
                            return expr.to_vhdl
                        else
                            # Multi-bit, need to select a bit and possibly
                            # cast to unsigned.
                            if expr.type.signed? then
                                return "unsigned(#{expr.to_vhdl}(0))"
                            # elsif expr.is_a?(RefRange) then
                            #     # Range reference case.
                            #     return "#{expr.ref.to_vhdl}(#{expr.range.first.to_vhdl})"
                            else
                                # Other cases.
                                return "#{expr.to_vhdl}(0)"
                            end
                        end
                    else
                        # Lint-compatible casting to std_logic
                        if expr.type.signed? then
                            # Signed, cast to unsigned.
                            return "unsigned(#{expr.to_vhdl})(0)"
                        # elsif expr.is_a?(RefRange) then
                        #     # Range reference case.
                        #     return "#{expr.ref.to_vhdl}(#{expr.range.first.to_vhdl})"
                        else
                            # Other cases: for std_logic generation.
                            return expr.to_vhdl(0,true)
                        end
                    end
                else
                    # Both are std_logic, nothing to to.
                    return expr.to_vhdl
                end
            elsif expr.is_a?(Value) then
                # puts "type=#{type}, type.range=#{type.range}"
                # Value width must be adjusted.
                return expr.to_vhdl(0,false,type.width)
            elsif expr.is_a?(Concat) then
                return expr.to_vhdl(type)
            elsif expr.type.width < type.width then
                # Need to extend the type.
                return '"' + "0" * (type.width - expr.type.width) + '" & ' +
                       expr.to_vhdl
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

        ## Generates the name of a mux function by type string +tstr+ and
        #  number of arguments +num+.
        def self.mux_name(tstr,num)
            return "mux#{tstr.gsub(/[^a-zA-Z0-9_]/,"_")}#{num}"
        end

        ## Generates the VHDL code for the mux function for type string +tstr+
        #  with +num+ choices.
        #  +spaces+ is the ident for the resulting code.
        def self.mux_function(type,num,spaces)
            # Create the strin of the type.
            tstr = type.to_vhdl
            # Create the name of the function from the type.
            name = mux_name(tstr,num)
            # Create the condition.
            if num == 2 then
                cond = "cond : boolean"
            else
                # First compute the width of the condition.
                width = (num-1).width
                # Now generate the condition.
                cond = "val : std_logic_vector(#{width-1} downto 0)"
            end
            # Generate the arguments.
            args = num.times.map {|i| "arg#{i} : #{tstr}" }.join("; ")
            # Generate the body.
            if num == 2 then
                body = "#{spaces}   if(cond) then\n" +
                       "#{spaces}      return arg0;\n" +
                       "#{spaces}   else\n" +
                       "#{spaces}      return arg1;\n" +
                       "#{spaces}   end if;\n"
            else
                # First compute the type of the choices.
                vtype = TypeVector.new(:"",Bit,width-1..0)
                # Now generate the body.
                body = "#{spaces}   case(val) is\n" +
                    num.times.map do |i|
                       pos = Value.new(vtype,i).to_vhdl
                       "#{spaces}   when #{pos} => return arg#{i};\n"
                    end.join + 
                       "#{spaces}   end case;\n"
            end
            # Generate the choices.
            # Generates the function
            return "#{spaces}function #{name}" + 
                       "(#{cond}; #{args})\n" +
                   "#{spaces}return #{tstr} is\n" +
                   "#{spaces}begin\n" + body +
                   "#{spaces}end #{mux_name(tstr,num)};\n\n"
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
                        if node.is_a?(Select) then
                            mtps << [node.type,node.each_choice.to_a.size]
                        end
                    end
                end
                # Checks the statements.
                scope.each_behavior do |behavior|
                    behavior.block.each_node_deep do |node|
                        if node.is_a?(Select) then
                            mtps << [node.type,node.each_choice.to_a.size]
                        end
                    end
                end
            end
            # Generate the gathered functions (only one per type).
            mtps.uniq!
            mtps.each do |type,num|
                res << Low2VHDL.mux_function(type,num," " * level*3)
            end

            # Generate the inner signals declaration.
            self.each_inner do |inner|
                res << " " * (level * 3)
                # General signal or constant signal?
                res << (inner.is_a?(SignalC) ?  "constant " : "signal ")
                # Signal name.
                res << Low2VHDL.vhdl_name(inner.name) << ": "
                # Signal type.
                res << inner.type.to_vhdl(level) 
                # Signal value.
                if inner.value then
                    if inner.value.is_a?(Concat) then
                        # Concat are to be given the expected type of the
                        # elements for casting them equally.
                        res << " := " << inner.value.to_vhdl(inner.type.base,level)
                    else
                        res << " := " << inner.value.to_vhdl(level)
                    end
                end
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
                    res << connection.to_vhdl([],level)
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
            return self.boolean? ? "boolean" : "std_logic"
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
                if self.range.first >= self.range.last then
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
                if left >= right then
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
        #
        # NOTE: type tuples are converted to bit vector of their contents.
        def to_vhdl(level = 0)
            # raise AnyError, "Tuple types are not supported in VHDL, please convert them to Struct types using Low::tuple2struct from HDLRuby/hruby_low_witout_tuple."
            return self.to_vector.to_vhdl(level)
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
            # Gather the variables.
            # It is assumed that the inners are all in declared in the
            # direct sub block and that they represent variables, i.e.,
            # Low::to_upper_space! and Low::with_var! has been called.
            vars = self.block.each_inner.to_a 

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
                        !node.parent.is_a?(RefName) &&
                        # Also skip the variables
                        !vars.find {|var| var.name == node.name }
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
            vars.each do |var|
                res << " " * ((level+1)*3)
                res << "variable "
                res << Low2VHDL.vhdl_name(var.name) << ": " 
                res << var.type.to_vhdl << ";\n"
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
                res << self.block.to_vhdl(vars,level+2)
                # Close the edge test.
                res << " " * (level*3)
                res << "end if;\n"
                level = level - 1
            else
                # Generate the body directly.
                res << self.block.to_vhdl(vars,level+1)
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
        # +vars+ is the list of the variables and
        # +level+ is the hierachical level of the object.
        def to_vhdl(vars, level = 0)
            # Should never be here.
            raise AnyError, "Internal error: to_vhdl should be implemented in class :#{self.class}"
        end
    end

    ## Extends the Transmit class with generation of HDLRuby::High text.
    class Transmit

        # Generates the text of the equivalent HDLRuby::High code.
        # +vars+ is the list of the variables and
        # +level+ is the hierachical level of the object.
        def to_vhdl(vars,level = 0)
            # Generate the assign operator.
            assign = vars.any? do |var|
                self.left.respond_to?(:name) && var.name == self.left.name 
            end ? " := " : " <= "
            # Generate the assignment.
            return " " * (level*3) + 
                   self.left.to_vhdl(level) + assign +
                   Low2VHDL.to_type(self.left.type,self.right) + ";\n"
        end
    end
    
    ## Extends the If class with generation of HDLRuby::High text.
    class If

        # Generates the text of the equivalent HDLRuby::High code.
        # +vars+ is the list of the variables and
        # +level+ is the hierachical level of the object.
        def to_vhdl(vars,level = 0)
            # The result string.
            res = " " * (level*3)
            # Generate the test.
            res << "if (" << Low2VHDL.to_boolean(self.condition) << ") then\n"
            # Generate the yes part.
            res << self.yes.to_vhdl(vars,level+1)
            # Generate the alternate if parts.
            self.each_noif do |cond,stmnt|
                res << " " * (level*3)
                # res << "elsif (" << cond.to_vhdl(level) << ") then\n"
                res << "elsif (" << Low2VHDL.to_boolean(cond) << ") then\n"
                res << stmnt.to_vhdl(vars,level+1)
            end
            # Generate the no part if any.
            if self.no then
                res << " " * (level*3)
                res << "else\n" << self.no.to_vhdl(vars,level+1)
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

        # Generates the text of the equivalent HDLRuby::High code ensuring
        # the match is of +type+.
        # +vars+ is the list of the variables and
        # +level+ is the hierachical level of the object.
        def to_vhdl(vars,type,level = 0)
            # The result string.
            res = " " * (level*3)
            # Generate the match.
            res << "when " << Low2VHDL.to_type(type,self.match) << " =>\n"
            # Generate the statement.
            res << self.statement.to_vhdl(vars,level+1)
            # Returns the result.
            return res
        end
    end

    ## Extends the Case class with generation of HDLRuby::High text.
    class Case

        # Generates the text of the equivalent HDLRuby::High code.
        # +vars+ is the list of the variables and
        # +level+ is the hierachical level of the object.
        def to_vhdl(vars,level = 0)
            # The result string.
            res = " " * (level*3)
            # Generate the test.
            res << "case " << self.value.to_vhdl(level) << " is\n"
            # Generate the whens.
            self.each_when do |w|
                res << w.to_vhdl(vars,self.value.type,level)
            end
            # Generate teh default if any.
            if self.default then
                res << " " * (level*3)
                res << "when others =>\n"
                res << self.default.to_vhdl(vars,level+1)
            else
                # NOTE: some VHDL parsers are very picky about others,
                # even though all the cases have been treated through
                # "when" statements.
                res << " " * (level*3)
                res << "when others =>\n"
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
        # +vars+ is the list of the variables and
        # +level+ is the hierachical level of the object.
        def to_vhdl(vars,level = 0)
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
        # +vars+ is the list of the variables and
        # +level+ is the hierachical level of the object.
        def to_vhdl(vars,level = 0)
            raise AnyError, "Internal error: TimeRepeat not supported yet for conversion to VHDL."
        end
    end

    ## Extends the Block class with generation of HDLRuby::High text.
    class Block

        # Generates the text of the equivalent HDLRuby::High code.
        # +vars+ is the list of variables and
        # +level+ is the hierachical level of the object.
        #
        # NOTE: only the statements are generated, the remaining is assumed
        #       to be handled by the upper scope.
        def to_vhdl(vars, level = 0)
            # The resulting string.
            res = ""
            # Generate the statements.
            self.each_statement do |stmnt|
                res << stmnt.to_vhdl(vars,level)
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

        # Generate the text of the equivalent VHDL is case of arithmetic
        # expression.
        def to_arith
            case self.content
            when HDLRuby::BitString
                if self.content.specified? then
                    sign = self.type.signed? && self.content.to_s[-1] == "0" ?
                        -1 : 1
                    return (sign * self.content.to_s.to_i(2)).to_s
                else
                    return self.content.to_s.upcase
                end
            else
                # NOTE: in VHDL, "z" and "x" must be upcase.
                return self.content.to_s.upcase
            end
        end

        # Generates the text of the equivalent VHDL with
        # +width+ bits.
        # +level+ is the hierachical level of the object.
        def to_vhdl(level = 0, std_logic = false, width = nil)
            raise "Invalid std_logic argument: #{std_logic}." unless std_logic == true || std_logic == false
            if self.type.boolean? then
                # Boolean case
                if self.content.is_a?(HDLRuby::BitString)
                    return self.zero? ? "false" : "true"
                else
                    return self.to_i == 0 ? "false" : "true"
                end
            end
            # Other cases
            # Maybe the value is used as a range or an index.
            if self.parent.is_a?(RefIndex) or self.parent.is_a?(RefRange) then
                # Yes, convert to a simple integer.
                return self.to_i.to_s.upcase
            end
            # No, generates as a bit string.
            width = self.type.width unless width
            # puts "self.type=#{self.type} width=#{width}"
            case self.content
            # when Numeric
            #     return self.content.to_s
            when HDLRuby::BitString
                # Compute the extension: in case of signed type, the extension
                # is the last bit. Otherwise it is 0 unless the last bit
                # is not defined (Z or X).
                sign = self.type.signed? ? self.content.to_s[-1] : 
                    /[01]/ =~ self.content[-1] ? "0" : self.content[-1]
                return '"' + self.content.to_s.rjust(width,sign).upcase + '"'
            else
                # sign = self.type.signed? ? (self.content>=0 ? "0" : "1") : "0"
                sign = self.content>=0 ? "0" : "1"
                return '"' + self.content.abs.to_s(2).rjust(width,sign).upcase + '"'
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
                        (type.range.first-type.range.last+1).abs.to_s + "))"
                when :signed
                    return "resize(signed(" + 
                        self.child.to_vhdl(level) + ")," +
                        (type.range.first-type.range.last+1).abs.to_s + ")"
                when :unsigned
                    return "resize(unsigned(" + 
                        self.child.to_vhdl(level) + ")," +
                        (type.range.first-type.range.last+1).abs.to_s + ")"
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
        # +std_logic+ tells if std_logic computation is to be done.
        def to_vhdl(level = 0, std_logic = false)
            # Generate the operator string.
            operator = self.operator == :~ ? "not " : self.operator.to_s[0]
            # Is the operator arithmetic?
            if [:+@, :-@].include?(self.operator) then
                # Yes, type conversion my be required by VHDL standard.
                res = "#{Low2VHDL.unarith_cast(self)}(#{operator}" +
                             Low2VHDL.to_arith(self.child) + ")"
                res += "(0)" if std_logic
                return res
            else
                # No, generate simply the unary operation.
                # (The other unary operator is logic, no need to force
                # std_logic.)
                return "(#{operator}" + self.child.to_vhdl(level,std_logic) + ")"
            end
        end
    end

    ## Extends the Binary class with generation of HDLRuby::High text.
    class Binary

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        # +std_logic+ tells if std_logic computation is to be done.
        def to_vhdl(level = 0, std_logic = false)
            # Shifts/rotate require function call.
            if [:<<, :>>, :ls, :rs, :lr, :rr].include?(self.operator) then
                # Generate the function name.
                case self.operator
                when :<<, :ls
                    func = "shift_left"
                when :>>, :rs
                    func = "shift_right"
                when :lr
                    func = "rotate_left"
                when :rr
                    function = "rotate_right"
                else
                    raise AnyError, "Internal unexpected error."
                end
                res =  Low2VHDL.unarith_cast(self) + "(#{func}(" + 
                       Low2VHDL.to_arith(self.left) + "," + 
                       Low2VHDL.to_arith(self.right) + "))"
                res += "(0)" if std_logic # Force std_logic if required.
                return res
            end
            # Usual operators.
            # Generate the operator string.
            case self.operator
            when :&
                # puts "self.left.to_vhdl=#{self.left.to_vhdl}"
                # puts "self.right.to_vhdl=#{self.right.to_vhdl}"
                # puts "self.left.type=#{self.left.type.to_vhdl}"
                # puts "self.right.type=#{self.right.type.to_vhdl}"
                # puts "self.type=#{self.type.to_vhdl}"
                opr = " and "
            when :|
                opr = " or "
            when :^
                opr = " xor "
            when :==
                opr = " = "
            when :!=
                opr = " /= "
            else
                opr = self.operator.to_s
            end
            # Is the operator arithmetic?
            if [:+, :-, :*, :/, :%].include?(self.operator) then
                # Yes, type conversion my be required by VHDL standard.
                res = "#{Low2VHDL.unarith_cast(self)}(" +
                    Low2VHDL.to_arith(self.left) + opr +
                    Low2VHDL.to_arith(self.right) + ")"
                res += "(0)" if std_logic # Force std_logic if required.
                return res
            # Is it a comparison ?
            elsif [:>, :<, :>=, :<=, :==, :!=].include?(self.operator) then
                # Generate comparison operation
                return "(" + self.left.to_vhdl(level) + opr +
                    Low2VHDL.to_type(self.left.type,self.right) + ")"
            else
                # No, simply generate the binary operation
                if std_logic then
                    return "(" + self.left.to_vhdl(level,std_logic) + opr + 
                        self.right.to_vhdl(level,std_logic) + ")"
                else
                    return "(" + self.left.to_vhdl(level) + opr + 
                        Low2VHDL.to_type(self.left.type,self.right) + ")"
                end
            end
        end
    end

    ## Extends the Select class with generation of HDLRuby::High text.
    class Select

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        #
        # NOTE: assumes the existance of the mux function.
        def to_vhdl(level = 0, std_logic = false)
            # The resulting string.
            res = ""
            # The number of arguments.
            num = @choices.size
            # Generate the header.
            res << "#{Low2VHDL.mux_name(self.type.to_vhdl(level),num)}(" +
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
        # +type+ is the expected type of the content.
        # +level+ is the hierachical level of the object.
        def to_vhdl(type,level = 0)
            raise "Invalid class for a type: #{type.class}" unless type.is_a?(Type) 
            # The resulting string.
            res = ""
            # Generate the header.
            # Generate the expressions.
            # Depends if it is an initialization or not.
            # if self.type.is_a?(TypeTuple) then
            if self.parent.is_a?(SignalC) then
                res << "( " << self.each_expression.map do |expression|
                    Low2VHDL.to_type(type,expression)
                end.join(",\n#{" "*((level+1)*3)}") << " )"
            else
                # Compute the width of the concatenation.
                width = self.each_expression.reduce(0) do |sum,expr|
                    sum += expr.type.width
                end
                # Generate the missing bits if any.
                width = type.width - width
                res << '"' + "0" * width + '" & ' if width > 0
                # Generate the concatenation.
                res << self.each_expression.map do |expression|
                    # "(" + Low2VHDL.to_type(type,expression) + ")"
                    "(" + expression.to_vhdl(level+1) + ")"
                end.join(" & ")
            end
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
        # +std_logic+ tells if std_logic computation is to be done.
        def to_vhdl(level = 0, std_logic = false)
            if self.index.is_a?(Value) then
                return self.ref.to_vhdl(level,std_logic) + 
                    "(#{self.index.to_vhdl(level)})"
            else
                return self.ref.to_vhdl(level,std_logic) +
                    "(to_integer(unsigned(#{self.index.to_vhdl(level)})))"
            end
        end
    end

    ## Extends the RefRange class with generation of HDLRuby::High text.
    class RefRange

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        # +std_logic+ tells if std_logic computation is to be done.
        def to_vhdl(level = 0, std_logic = false)
            # Generates the direction.
            first = self.range.first
            first = first.content if first.is_a?(Value)
            last = self.range.last
            last = last.content if last.is_a?(Value)
            direction = first >= last ?  "downto " : " to "
            # Generate the reference.
            # Forced std_logic case.
            if std_logic then
                if first == last then
                    # No range, single bit access for forcing std_logic.
                    return self.ref.to_vhdl(level) +
                        "(#{self.range.first.to_vhdl(level)})"
                else
                    return self.ref.to_vhdl(level) +
                        "((#{self.range.first.to_vhdl(level)}) " +
                        direction + "(#{self.range.last.to_vhdl(level)}))(0)"
                end
            else
                return self.ref.to_vhdl(level) +
                    "((#{self.range.first.to_vhdl(level)}) " +
                    direction + "(#{self.range.last.to_vhdl(level)}))"
            end
        end
    end

    ## Extends the RefName class with generation of HDLRuby::High text.
    class RefName

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        # +std_logic+ tells if std_logic computation is to be done.
        def to_vhdl(level = 0, std_logic = false)
            # The resulting string.
            res = ""
            # Generate the sub refs if any (case of struct).
            unless self.ref.is_a?(RefThis) then
                res << self.ref.to_vhdl(level) << "."
            end
            # Generates the current reference.
            res << Low2VHDL.vhdl_name(self.name)
            res << "(0)" if std_logic # Force to std_logic if required
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
