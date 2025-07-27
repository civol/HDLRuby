require 'HDLRuby'


module HDLRuby::Low


##
# Converts a HDLRuby::Low description to hdr text description.
#
########################################################################
    
    ## Provides tools for converting HDLRuby::Low objects to hdr text.
    module Low2HDR

        ## Tells if an HDLRuby::Low +name+ syntax is compatible for
        #  hdr text.
        def self.hdr_name?(name)
            return name =~ /^[a-zA-Z_][a-zA-Z_0-9]*$/
        end

        ## Converts a HDLRuby::Low +name+ for declaration to hdr tex.
        def self.hdr_decl_name(name)
            if hdr_name?(name) then
                # Compatible name return it as is.
                return name.to_s
            else
                # Incompatible, use quotes.
                return "\"#{name}\""
            end
        end

        ## Converts a HDLRuby::Low +name+ for usage to hdr text.
        def self.hdr_use_name(name)
            if hdr_name?(name) then
                # Compatible name return it as is.
                return name.to_s
            else
                # Incompatible, use the hdr "send" operator.
                # return "(+:\"#{name}\")"
                return "send(:\"#{name}\")"
            end
        end

        ## Convert a HDLRuby::Low +name+ for instantiation to hdr text
        #  with args as argument.
        def self.hdr_call_name(name,args)
            if hdr_name?(name) then
                # Compatible name return it as is.
                return "#{name} #{[*args].join(",")}"
            else
                # Incompatible, use the ruby "send" operator.
                return "send(:\"#{name}\",#{[*args].join(",")})"
            end
        end
    end



    class SystemT
        ## Extends the SystemT class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            # The resulting string.
            res = ""
            # Generate the header.
            res << " " * (level*3)
            res << "system :#{Low2HDR.hdr_decl_name(self.name)} do\n"
            # Generate the interface.
            # Inputs.
            self.each_input do |input|
                res << " " * ((level+1)*3)
                res << input.type.to_hdr(level+1) 
                res << ".input :" << Low2HDR.hdr_decl_name(input.name)
                res << "\n"
            end
            # Outputs.
            self.each_output do |output|
                res << " " * ((level+1)*3)
                res << output.type.to_hdr(level+1) 
                res << ".output :" << Low2HDR.hdr_decl_name(output.name)
                res << "\n"
            end
            # Inouts.
            self.each_inout do |inout|
                res << " " * ((level+1)*3)
                res << inout.type.to_hdr(level+1) 
                res << ".inout :" << Low2HDR.hdr_decl_name(inout.name)
                res << "\n"
            end
            # Generate the scope.
            res << " " * (level*3)
            res << "\n"
            res << self.scope.to_hdr(level+1,false)
            # End of the system.
            res << " " * (level*3)
            res << "end\n\n"
            # Return the result.
            return res
        end
    end


    class Scope
        ## Extends the Scope class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object and
        # +header+ tells if the header is to generate or not.
        def to_hdr(level = 0,header = true)
            # The resulting string.
            res = ""
            # Generate the header if required.
            if header then
                res << (" " * (level*3)) << "sub "
                unless self.name.empty? then
                    res << ":" << Low2HDR.hdr_decl_name(self.name) << " "
                end
                res << "do\n"
            end
            level = level + 1 if header
            # Generate the sub types.
            # Assume the types are TypeDef.
            self.each_type do |type|
                res << " " * (level*3)
                res << "typedef :#{type.name} do\n"
                res << " " * ((level+1)*3) << type.def.to_hdr(level)
                res << " " * (level*3) << "end\n"
            end
            # Generaste the sub system types.
            self.each_systemT { |systemT| res << systemT.to_hdr(level) }
            # Generate the inners declaration.
            self.each_inner do |inner|
                res << " " * (level*3)
                res << inner.type.to_hdr(level) 
                res << ".inner :" << Low2HDR.hdr_decl_name(inner.name) << "\n"
            end
            # Generate the instances.
            res << "\n" if self.each_inner.any?
            self.each_systemI do |systemI| 
                res << " " * (level*3)
                res << systemI.to_hdr(level) << "\n"
            end
            # Generate the sub scopes.
            self.each_scope do |scope|
                res << scope.to_hdr(level)
            end
            # Generate the connections.
            res << "\n" if self.each_scope.any?
            self.each_connection do |connection|
                res << connection.to_hdr(level)
            end
            # Generate the behaviors.
            res << "\n" if self.each_connection.any?
            self.each_behavior do |behavior|
                res << behavior.to_hdr(level)
            end
            # Close the scope if required.
            if header then
                res << " " * ((level-1)*3) << "end\n"
            end
            # Return the result.
            return res
        end
    end


    class Type
        ## Extends the Type class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            return Low2HDR.hdr_use_name(self.name)
        end
    end


    class TypeDef
        ## Extends the TypeDef class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            # Simply generates the redefined type.
            self.def.to_hdr(level)
        end
    end


    class TypeVector
        ## Extends the TypeVector class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            # The resulting string.
            res = ""
            # Generate the base.
            res << self.base.to_hdr(level)
            # Generate the range.
            res << "[" << self.range.first.to_hdr(level) << ".." <<
            self.range.last.to_hdr(level) << "]"
            # Return the result.
            return res
        end
    end


    class TypeTuple
        ## Extends the TypeTuple class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            # The resulting string.
            res = "["
            # Generate each sub type.
            res << self.each_type.map { |type| type.to_hdr(level) }.join(", ")
            # Close the tuple.
            res << "]"
            # Return the result.
            return res
        end
    end


    class TypeStruct
        ## Extends the TypeStruct class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            # The resulting string.
            res = "{ "
            # Generate each sub type.
            res << self.each.map do |key,type|
                "#{key}: " + type.to_hdr(level)
            end.join(", ")
            # Close the struct.
            res << " }"
            # Return the result.
            return res
        end
    end


    class Behavior
        ## Extends the Behavior class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object and +timed+
        # tells if the behavior is a time behavior or not.
        def to_hdr(level = 0,timed = false)
            # The resulting string.
            res = " " * (level*3)
            # Generate the header.
            if timed then
                res << "timed"
            else
                res << self.block.mode.to_s
            end
            if self.each_event.any? then
                res << "( "
                res << self.each_event.map do |event|
                    event.to_hdr(level)
                end.join(", ")
                res << " )"
            end
            res << " do\n"
            # Generate the content.
            res << self.block.to_hdr(level+1,false)
            # Close the behavior.
            res << " " * (level*3) << "end\n"
            # Return the result.
            return res
        end
    end


    class TimeBehavior
        ## Extends the TimeBehavior class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            super(level,true)
        end
    end


    class Event
        ## Extends the Event class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            return self.ref.to_hdr(level) + ".#{self.type}"
        end
    end


    class SignalI
        ## Extends the SignalI class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            return Low2HDR.hdr_use_name(self.name)
        end
    end


    class SystemI
        ## Extends the SystemI class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            return Low2HDR.hdr_call_name(self.systemT.name,
                   ":" + Low2HDR.hdr_decl_name(self.name))
        end
    end


    class Statement
        ## Extends the Statement class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            # Should never be here.
            raise AnyError, "Internal error: to_hdr should be implemented in class :#{self.class}"
        end
    end


    class Transmit
        ## Extends the Transmit class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            return " " * (level*3) + 
                   self.left.to_hdr(level) + " <= " +
                   self.right.to_hdr(level) + "\n"
        end
    end
  

    class If
        ## Extends the If class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            # The result string.
            res = " " * (level*3)
            # Generate the test.
            res << "hif " << self.condition.to_hdr(level) << " do\n"
            # Generate the yes part.
            res << self.yes.to_hdr(level+1)
            res << " " * (level*3) << "end\n"
            # Generate the alternate if parts.
            self.each_noif do |cond,stmnt|
                res << " " * (level*3)
                res << "helsif " << cond.to_hdr(level) << " do\n"
                res << stmnt.to_hdr(level+1)
                res << " " * (level*3) << "end\n"
            end
            # Generate the no part if any.
            if self.no then
                res << " " * (level*3)
                res << "helse do\n" << self.no.to_hdr(level+1)
                res << " " * (level*3) << "end\n"
            end
            # Return the result.
            return res
        end
    end


    class When
        ## Extends the When class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            # The result string.
            res = " " * (level*3)
            # Generate the match.
            res << "hwhen " << self.match.to_hdr(level+1) << " do\n"
            # Generate the statement.
            res << self.statement.to_hdr(level+1)
            # Close the when.
            res << " " * (level*3) << "end\n"
            # Returns the result.
            return res
        end
    end


    class Case
        ## Extends the Case class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            # The result string.
            res = " " * (level*3)
            # Generate the test.
            res << "hcase " << self.value.to_hdr(level) << "\n"
            # Generate the whens.
            self.each_when do |w|
                res << w.to_hdr(level)
            end
            # Generatethe default.
            if self.default then
                res << " " * (level*3)
                res << "helse do\n"
                res << self.default.to_hdr(level+1)
                res << " " * (level*3)
                res << "end\n"
            end
            # Return the resulting string.
            return res
        end
    end


    class Delay
        ## Extends the Delay class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            return self.value.to_hdr(level) + ".#{self.unit}"
        end
    end


    class TimeWait
        ## Extends the TimeWait class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            # The resulting string.
            res = " " * (level*3)
            # Generate the wait.
            res << "!" << self.delay.to_hdr(level) << "\n" 
            # Return the resulting string.
            return res
        end
    end


    class TimeRepeat
        ## Extends the TimeRepeat class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            # The resulting string.
            res = " " * (level*3)
            # Generate the header.
            # res << "repeat " << self.delay.to_hdr(level) << " do\n"
            res << "repeat " << self.number.to_hdr(level) << " do\n"
            # Generate the statement to repeat.
            res << self.statement.to_hdr(level+1)
            # Close the repeat.
            res << " " * (level*3) << "end\n"
            # Return the resulting string.
            return res
        end
    end


    class Block
        ## Extends the Block class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        # +header+ tells if the header is to generate or not.
        # +timed+ tells if its a timed block.
        def to_hdr(level = 0, header = true, timed = false)
            # The resulting string.
            res = ""
            # Generate the header if required.
            if header then
                if timed then
                    res << " " * (level*3) << "timed "
                else
                    res << " " * (level*3) << "#{self.mode} "
                end
                unless self.name.empty? then
                    res << ":" << Low2HDR.hdr_decl_name(self.name) << " "
                end
                res << "do\n"
            end
            level = level + 1 if header
            # Generate the inners declaration.
            self.each_inner do |inner|
                res << " " * (level*3)
                res << inner.type.to_hdr(level) 
                res << ".inner :" << Low2HDR.hdr_decl_name(inner.name) << "\n"
            end
            # Generate the statements.
            self.each_statement do |stmnt|
                res << stmnt.to_hdr(level)
            end
            # Close the block.
            if header then
                res << " " * ((level-1)*3) << "end\n"
            end
            # Return the result.
            return res
        end
    end


    class TimeBlock
        ## Extends the TimeBlock class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0, header = true)
            super(level,header,true)
        end
    end


    class Code
        ## Extends the Code class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            return self.content.to_s
        end
    end


    class Connection
        ## Extends the Connection class with generation of hdr text.
        # Nothing required, Transmit is generated identically.
    end


    class Expression
        ## Extends the Expression class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            # Should never be here.
            raise AnyError, "Internal error: to_hdr should be implemented in class :#{self.class}"
        end
    end


    class Value
        ## Extends the Value class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            if self.content.is_a?(HDLRuby::BitString) then
                return "_b#{self.content}"
            else
                return self.content.to_s
            end
        end
    end


    class Cast
        ## Extends the Cast class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            return self.child.to_hdr(level) + 
                ".as(" + self.type.to_hdr(level) + ")"
        end
    end


    class Operation
        ## Extends the Operation class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            # Should never be here.
            raise AnyError, "Internal error: to_hdr should be implemented in class :#{self.class}"
        end
    end


    class Unary
        ## Extends the Unary class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            return "(#{self.operator.to_s[0]}" + self.child.to_hdr(level) + ")"
        end
    end


    class Binary
        ## Extends the Binary class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            return "(" + self.left.to_hdr(level) + self.operator.to_s + 
                         self.right.to_hdr(level) + ")"
        end
    end


    class Select
        ## Extends the Select class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            # The resulting string.
            res = ""
            # Generate the header.
            res << "mux(" + self.select.to_hdr(level) << ", "
            # Generate the choices
            res << self.each_choice.map do |choice|
                choice.to_hdr(level+1)
            end.join(", ")
            # Close the select.
            res << ")"
            # Return the resulting string.
            return res
        end
    end


    class Concat
        ## Extends the Concat class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            # The resulting string.
            res = ""
            # Generate the header.
            res << "[ "
            # Generate the expressions.
            res << self.each_expression.map do |expression|
                expression.to_hdr(level+1)
            end.join(", ")
            # Close the select.
            res << " ]"
            # Return the resulting string.
            return res
        end
    end


    class Ref
        ## Extends the Ref class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            # Should never be here.
            raise AnyError, "Internal error: to_hdr should be implemented in class :#{self.class}"
        end
    end


    class RefConcat
        ## Extends the RefConcat class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            # The resulting string.
            res = ""
            # Generate the header.
            res << "[ "
            # Generate the references.
            res << self.each_ref.map do |ref|
                ref.to_hdr(level+1)
            end.join(", ")
            # Close the select.
            res << " ]"
            # Return the resulting string.
            return res
        end
    end


    class RefIndex
        ## Extends the RefIndex class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            return self.ref.to_hdr(level) + "[#{self.index.to_hdr(level)}]"
        end
    end


    class RefRange
        ## Extends the RefRange class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            return self.ref.to_hdr(level) +
                "[(#{self.range.first.to_hdr(level)})..(#{self.range.last.to_hdr(level)})]"
        end
    end


    class RefName
        ## Extends the RefName class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            # The resulting string.
            res = ""
            # Generates the sub reference if any.
            res << self.ref.to_hdr(level) << "." unless self.ref.is_a?(RefThis)
            # Generates the current reference.
            res << Low2HDR.hdr_use_name(self.name)
            # Returns the resulting string.
            return res
        end
    end


    class RefThis 
        ## Extends the RefThis class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            return ""
        end
    end


    class ::Numeric
        ## Extends the Numeric class with generation of hdr text.

        # Generates the text of the equivalent hdr text.
        # +level+ is the hierachical level of the object.
        def to_hdr(level = 0)
            return self.to_s
        end
    end

end
