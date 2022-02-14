require 'set'
require 'HDLRuby'
require 'HDLRuby/hruby_low_resolve'


module HDLRuby::Low


##
# Converts a HDLRuby::Low description to a C text description.
# When compiled, the description is executable an can be used for
# simulation.
#
########################################################################

    ## Provides tools for converting HDLRuby::Low objects to C.
    module Low2C

        ## Generates the includes for a C file, with +names+ for extra
        #  h files.
        def self.includes(*names)
            res =  '#include <stdlib.h>' + "\n" + 
                   '#include "hruby_sim.h"' + "\n"
            names.each { |name| res << "#include \"#{name}\"\n" }
            res << "\n"
            return res
        end

        ## Gives the width of an int in the current computer.
        def self.int_width
            # puts "int_width=#{[1.to_i].pack("i").size*8}"
            return [1.to_i].pack("i").size*8
        end

        ## Converts string +str+ to a C-compatible string.
        def self.c_string(str)
            str = str.gsub(/\n/,"\\n")
            str.gsub!(/\t/,"\\t")
            return str
        end

        # ## Tells if a +name+ is C-compatible.
        # #  To ensure compatibile, assume all the character must have the
        # #  same case.
        # def self.c_name?(name)
        #     name = name.to_s
        #     # First: character check.
        #     return false unless name =~ /^[a-zA-Z]|([a-zA-Z][a-zA-Z_0-9]*[a-zA-Z0-9])$/
        #     return true
        # end

        ## Converts a +name+ to a C-compatible name.
        def self.c_name(name)
            name = name.to_s
            # Convert special characters.
            name = name.each_char.map do |c|
                if c=~ /[a-z0-9]/ then
                    c
                elsif c == "_" then
                    "__"
                else
                    "_" + c.ord.to_s
                end
            end.join
            # First character: only letter is possible.
            unless name[0] =~ /[a-z_]/ then
                name = "_" + name
            end
            return name
        end

        # ## Generates a uniq name for an object.
        # def self.obj_name(obj)
        #     if obj.respond_to?(:name) then
        #         return Low2C.c_name(obj.name.to_s) +
        #                Low2C.c_name(obj.object_id.to_s)
        #     else
        #         return "_" + Low2C.c_name(obj.object_id.to_s)
        #     end
        # end

        @@hdrobj2c = {}

        ## Generates a uniq name for an object.
        def self.obj_name(obj)
            id = obj.hierarchy.map! {|obj| obj.object_id}
            oname = @@hdrobj2c[id]
            unless oname then
                # name = obj.respond_to?(:name) ? "_#{self.c_name(obj.name)}" : ""
                # oname = "_c#{@@hdrobj2c.size}#{name}"
                oname = "_" << @@hdrobj2c.size.to_s(36)
                @@hdrobj2c[id] = oname
            end
            return oname
        end

        ## Generates the name of a makeer for an object.
        def self.make_name(obj)
            return "make#{Low2C.obj_name(obj)}"
        end

        ## Generates the name of a executable function for an object.
        def self.code_name(obj)
            return "code#{Low2C.obj_name(obj)}"
        end

        ## Generates the name of a type.
        def self.type_name(obj)
            return "type#{Low2C.obj_name(obj)}"
        end

        ## Generates the name of a unit.
        def self.unit_name(obj)
            return "#{obj.to_s.upcase}"
        end

        ## Generates a prototype from a function +name+.
        def self.prototype(name)
            return "void #{name}();\n"
        end

        ## Generates the code of a thread calling +name+ function
        #  and register it to the simulator.
        def self.thread(name)

        end


        ## Generates the main for making the objects of +objs+ and
        #  for starting the simulation and including the files from +hnames+
        def self.main(name,init_visualizer,top,objs,hnames)
            res = Low2C.includes(*hnames)
            res << "int main(int argc, char* argv[]) {\n"
            # Build the objects.
            objs.each { |obj| res << "   " << Low2C.make_name(obj) << "();\n" }
            # Sets the top systemT.
            res << "   top_system = " << Low2C.obj_name(top) << ";\n"
            # Starts the simulation.
            res<< "   hruby_sim_core(\"#{name}\",#{init_visualizer},-1);\n"
            # Close the main.
            res << "}\n"
            return res
        end


        ## Gets the structure of the behavior containing object +obj+.
        def self.behavior_access(obj)
            until obj.is_a?(Behavior)
                obj = obj.parent
            end
            return Low2C.obj_name(obj)
        end


        ## Generates the code for a wait for time object +obj+ with +level+
        #  identation.
        def self.wait(obj,level)
            res = "hw_wait(#{obj.delay.to_c(level+1)},"
            res << Low2C.behavior_access(obj) << ");\n" 
            return res
        end
    end


    ## Extends the SystemT class with generation of C text.
    class SystemT

        # Generates the text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object and +hnames+
        # is the list of extra h files to include.
        # def to_c(level = 0, *hnames)
        def to_c(res, level = 0, *hnames)
            # The header
            # res = Low2C.includes(*hnames)
            res << Low2C.includes(*hnames)

            # Declare the global variable holding the system.
            res << "SystemT " << Low2C.obj_name(self) << ";\n\n"

            # Generate the signals of the system.
            # self.each_signal { |signal| signal.to_c(level) }
            self.each_signal { |signal| signal.to_c(res,level) }

            # Generate the code for all the blocks included in the system.
            self.scope.each_scope_deep do |scope|
                scope.each_behavior do |behavior|
                    # res << behavior.block.to_c_code(level)
                    behavior.block.to_c_code(res,level)
                end
            end

            # Generate the code for all the values included in the system.
            self.each_signal do |signal|
                # res << signal.value.to_c_make(level) if signal.value
                signal.value.each_node_deep do |node|
                    # res << node.to_c_make(level) if node.respond_to?(:to_c_make)
                    node.to_c_make(res,level) if node.respond_to?(:to_c_make)
                end if signal.value
            end
            self.scope.each_scope_deep do |scope|
                scope.each_inner do |signal|
                    signal.value.each_node_deep do |node|
                        # res << node.to_c_make(level) if node.respond_to?(:to_c_make)
                        node.to_c_make(res,level) if node.respond_to?(:to_c_make)
                    end if signal.value
                end
            end
            self.scope.each_block_deep do |block|
            # puts "treating for block=#{Low2C.obj_name(block)} with=#{block.each_inner.count} inners"
                block.each_inner do |signal|
                    signal.value.each_node_deep do |node|
                        # res << node.to_c_make(level) if node.respond_to?(:to_c_make)
                        node.to_c_make(res,level) if node.respond_to?(:to_c_make)
                    end if signal.value
                end
            end
            self.scope.each_node_deep do |node|
                # res << node.to_c_make(level) if node.is_a?(Value)
                node.to_c_make(res,level) if node.is_a?(Value)
            end

            # Generate the scope.
            # res << self.scope.to_c(level)
            self.scope.to_c(res,level)

            # Generate the entity
            res << "SystemT " << Low2C.make_name(self) << "() {\n"
            # Creates the structure.
            res << " " * (level+1)*3
            res << "SystemT systemT = malloc(sizeof(SystemTS));\n"
            res << " " * (level+1)*3
            res << "systemT->kind = SYSTEMT;\n";

            # Sets the global variable of the system.
            res << "\n"
            res << " " * (level+1)*3
            res << Low2C.obj_name(self) << " = systemT;\n"

            # Set the owner if any.
            if @owner then
                res << " " * (level+1)*3
                res << "systemT->owner = (Object)"
                res << Low2C.obj_name(@owner) << ";\n"
            else
                res << "systemT->owner = NULL;\n"
            end

            # The name
            res << " " * (level+1)*3
            res << "systemT->name = \"#{self.name}\";\n"

            # The ports
            # Inputs
            res << " " * (level+1)*3
            res << "systemT->num_inputs = #{self.each_input.to_a.size};\n"
            res << " " * (level+1)*3
            res << "systemT->inputs = calloc(sizeof(SignalI),"
            res << "systemT->num_inputs);\n"
            self.each_input.with_index do |input,i|
                res << " " * (level+1)*3
                res << "systemT->inputs[#{i}] = "
                res << Low2C.make_name(input) << "();\n"
            end
            # Outputs
            res << " " * (level+1)*3
            res << "systemT->num_outputs = #{self.each_output.to_a.size};\n"
            res << " " * (level+1)*3
            res << "systemT->outputs = calloc(sizeof(SignalI),"
            res << "systemT->num_outputs);\n"
            self.each_output.with_index do |output,i|
                res << " " * (level+1)*3
                res << "systemT->outputs[#{i}] = "
                res << Low2C.make_name(output) << "();\n"
            end
            # Inouts
            res << " " * (level+1)*3
            res << "systemT->num_inouts = #{self.each_inout.to_a.size};\n"
            res << " " * (level+1)*3
            res << "systemT->inouts = calloc(sizeof(SignalI)," +
                   "systemT->num_inouts);\n"
            self.each_inout.with_index do |inout,i|
                res << " " * (level+1)*3
                res << "systemT->inouts[#{i}] = "
                res << Low2C.make_name(inout) << "();\n"
            end

            # Adds the scope.
            res << "\n"
            res << " " * (level+1)*3
            res << "systemT->scope = " << Low2C.make_name(self.scope) << "();\n"

            # Generate the Returns of the result.
            res << "\n"
            res << " " * (level+1)*3
            res << "return systemT;\n"
            # End of the system.
            res << " " * level*3
            res << "}"
            # Return the result.
            return res
        end


        ## Generates the code for an execution starting from the system.
        # +level+ is the hierachical level of the object.
        # def to_c_code(level)
        def to_c_code(res,level)
            res << " " * (level*3)
            res << Low2C.code_name(self) << "() {\n"
            # res << "printf(\"Executing #{Low2C.code_name(self)}...\\n\");"
            # Launch the execution of all the time behaviors of the
            # system.
            self.each_behavior_deep do |behavior|
                if behavior.is_a?(HDLRuby::Low::TimeBehavior) then
                    res << " " * (level+1)*3
                    res << Low2C.code_name(behavior.block) << "();\n"
                end
            end
            # Close the execution procedure.
            res << " " * level*3
            res << "}\n"
            # Return the result.
            return res
        end


        ## Generates the content of the h file.
        # def to_ch
        def to_ch(res)
            # res = ""
            # Declare the global variable holding the signal.
            res << "extern SystemT " << Low2C.obj_name(self) << ";\n\n"

            # Generate the access to the function making the systemT. */
            res << "extern SystemT " << Low2C.make_name(self) << "();\n\n"

            # Generate the accesses to the values.
            self.each_signal do |signal|
                # res << signal.value.to_ch if signal.value
                if signal.value then
                    signal.value.each_node_deep do |node|
                        # res << node.to_ch if node.is_a?(Value)
                        node.to_ch(res) if node.is_a?(Value)
                    end
                end
            end
            self.scope.each_scope_deep do |scope|
                scope.each_inner do |signal|
                    if signal.value then
                        signal.value.each_node_deep do |node|
                            # res << node.to_ch if node.is_a?(Value)
                            node.to_ch(res) if node.is_a?(Value)
                        end
                    end
                end
            end
            self.scope.each_block_deep do |block|
                block.each_inner do |signal|
                    # signal.value.to_ch(res) if signal.value
                    if signal.value then
                        signal.value.each_node_deep do |node|
                            # res << node.to_ch if node.is_a?(Value)
                            node.to_ch(res) if node.is_a?(Value)
                        end
                    end
                end
                block.each_node_deep do |node|
                    # res << node.to_ch if node.is_a?(Value)
                    node.to_ch(res) if node.is_a?(Value)
                end
            end

            # Generate the accesses to the ports.
            # self.each_input  { |input|  res << input.to_ch }
            self.each_input  { |input|  input.to_ch(res) }
            # self.each_output { |output| res << output.to_ch }
            self.each_output { |output| output.to_ch(res) }
            # self.each_inout  { |inout|  res << inout.to_ch }
            self.each_inout  { |inout|  inout.to_ch(res) }

            # Generate the accesses to the scope.
            # res << self.scope.to_ch << "\n"
            self.scope.to_ch(res)
            res << "\n"

            return res;
        end

    end


    ## Extends the Scope class with generation of C text.
    class Scope

        # Generates the C text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object.
        # def to_c(level = 0)
        def to_c(res,level = 0)
            # The resulting string.
            # res = ""

            # Declare the global variable holding the scope.
            res << "Scope " << Low2C.obj_name(self) << ";\n\n"

            # Generate the code makeing the complex sub components.

            # Generates the code for making signals if any.
            # self.each_signal { |signal| res << signal.to_c(level) }
            self.each_signal { |signal| signal.to_c(res,level) }
            # Generates the code for making signals if any.
            # self.each_systemI { |systemI| res << systemI.to_c(level) }
            self.each_systemI { |systemI| systemI.to_c(res,level) }
            # Generates the code for making sub scopes if any.
            # self.each_scope { |scope| res << scope.to_c(level) }
            self.each_scope { |scope| scope.to_c(res,level) }
            # Generate the code for making the behaviors.
            # self.each_behavior { |behavior| res << behavior.to_c(level) }
            self.each_behavior { |behavior| behavior.to_c(res,level) }
            # Generate the code for making the non-HDLRuby codes.
            # self.each_code { |code| res << code.to_c(level) }
            self.each_code { |code| code.to_c(res,level) }

            # Generate the code of the scope.
            
            # The header of the scope.
            res << " " * level*3
            res << "Scope " << Low2C.make_name(self) << "() {\n"
            res << " " * (level+1)*3
            res << "Scope scope = malloc(sizeof(ScopeS));\n"
            res << " " * (level+1)*3
            res << "scope->kind = SCOPE;\n";

            # Sets the global variable of the scope.
            res << "\n"
            res << " " * (level+1)*3
            res << Low2C.obj_name(self) << " = scope;\n"

            # Set the owner if any.
            if self.parent then
                res << " " * (level+1)*3
                res << "scope->owner = (Object)"
                res << Low2C.obj_name(self.parent) << ";\n"
            else
                res << "scope->owner = NULL;\n"
            end

            # The name
            res << " " * (level+1)*3
            res << "scope->name = \"#{self.name}\";\n"

            # Add the system instances declaration.
            res << " " * (level+1)*3
            res << "scope->num_systemIs = #{self.each_systemI.to_a.size};\n"
            res << " " * (level+1)*3
            res << "scope->systemIs = calloc(sizeof(SystemI)," +
                   "scope->num_systemIs);\n"
            self.each_systemI.with_index do |systemI,i|
                res << " " * (level+1)*3
                res << "scope->systemIs[#{i}] = "
                res << Low2C.make_name(systemI) << "();\n"
            end

            # Add the inner signals declaration.
            res << " " * (level+1)*3
            res << "scope->num_inners = #{self.each_inner.to_a.size};\n"
            res << " " * (level+1)*3
            res << "scope->inners = calloc(sizeof(SignalI),"
            res << "scope->num_inners);\n"
            self.each_inner.with_index do |inner,i|
                res << " " * (level+1)*3
                res << "scope->inners[#{i}] = "
                res << Low2C.make_name(inner) << "();\n"
            end

            # Add the sub scopes.
            res << " " * (level+1)*3
            res << "scope->num_scopes = #{self.each_scope.to_a.size};\n"
            res << " " * (level+1)*3
            res << "scope->scopes = calloc(sizeof(Scope),"
            res << "scope->num_scopes);\n"
            self.each_scope.with_index do |scope,i|
                res << " " * (level+1)*3
                res << "scope->scopes[#{i}] = "
                res << Low2C.make_name(scope) << "();\n"
            end

            # Add the behaviors.
            res << " " * (level+1)*3
            res << "scope->num_behaviors = #{self.each_behavior.to_a.size};\n"
            res << " " * (level+1)*3
            res << "scope->behaviors = calloc(sizeof(Behavior),"
            res << "scope->num_behaviors);\n"
            self.each_behavior.with_index do |behavior,i|
                res << " " * (level+1)*3
                res << "scope->behaviors[#{i}] = "
                res << Low2C.make_name(behavior) << "();\n"
            end

            # Add the non-HDLRuby codes.
            res << " " * (level+1)*3
            res << "scope->num_codes = #{self.each_code.to_a.size};\n"
            res << " " * (level+1)*3
            res << "scope->codes = calloc(sizeof(Code)," +
                   "scope->num_codes);\n"
            self.each_code.with_index do |code,i|
                res << " " * (level+1)*3
                res << "scope->codes[#{i}] = "
                res << Low2C.make_name(code) << "();\n"
            end

            # Generate the Returns of the result.
            res << "\n"
            res << " " * (level+1)*3
            res << "return scope;\n"

            # Close the scope.
            res << " " * level*3
            res << "}\n\n"
            return res
        end

        ## Generates the content of the h file.
        # def to_ch
        def to_ch(res)
            # res = ""
            # Declare the global variable holding the signal.
            res << "extern Scope " << Low2C.obj_name(self) << ";\n\n"

            # Generate the access to the function making the scope.
            res << "extern Scope " << Low2C.make_name(self) << "();\n\n"

            # Generate the accesses to the system instances.
            # self.each_systemI { |systemI| res << systemI.to_ch }
            self.each_systemI { |systemI| systemI.to_ch(res) }

            # Generate the accesses to the signals.
            # self.each_inner { |inner| res << inner.to_ch }
            self.each_inner { |inner| inner.to_ch(res) }

            # Generate the access to the sub scopes.
            # self.each_scope { |scope| res << scope.to_ch }
            self.each_scope { |scope| scope.to_ch(res) }

            # Generate the access to the behaviors.
            # self.each_behavior { |behavior| res << behavior.to_ch }
            self.each_behavior { |behavior| behavior.to_ch(res) }

            # Generate the access to the non-HDLRuby code.
            # self.each_behavior { |code| res << code.to_ch }
            self.each_behavior { |code| code.to_ch(res) }

            return res;
        end
    end


    ## Extends the Type class with generation of C text.
    class Type

        # Generates the C text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object.
        # def to_c(level = 0)
        def to_c(res,level = 0)
            if self.name == :bit || self.name == :unsigned then
                # return "get_type_bit()"
                res << "get_type_bit()"
            elsif self.name == :signed then
                # return "get_type_signed()"
                res << "get_type_signed()"
            else
                raise "Unknown type: #{self.name}"
            end
            return res
        end
    end

    ## Extends the TypeDef class with generation of C text.
    class TypeDef

        # Generates the C text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object.
        # def to_c(level = 0)
        def to_c(res,level = 0)
            # Simply return the defined type.
            # return self.def.to_c(level)
            self.def.to_c(res,level)
            return res
        end
    end

    ## Extends the TypeVector class with generation of C text.
    class TypeVector

        # Generates the C text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object.
        # def to_c(level = 0)
        def to_c(res,level = 0)
            # The resulting string.
            # return "get_type_vector(#{self.base.to_c(level+1)}," +
            #        "#{self.size})"
            res << "get_type_vector("
            self.base.to_c(res,level+1)
            res << ",#{self.size})"
            return res
        end
    end

    ## Extends the TypeTuple class with generation of C text.
    class TypeTuple

        # Generates the C text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object.
        #
        # NOTE: type tuples are converted to bit vector of their contents.
        # def to_c(level = 0)
        def to_c(res,level = 0)
            # return self.to_vector.to_c(level)
            self.to_vector.to_c(res,level)
            return res
        end
    end


    ## Extends the TypeStruct class with generation of C text.
    class TypeStruct

        # Generates the text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object.
        # def to_c(level = 0)
        def to_c(res,level = 0)
            # return "get_type_struct(#{self.each.join(",") do |key,type|
            #     "\"#{key.to_s}\",#{type.to_c(level+1)}"
            # end})"
            res << "get_type_struct(#{self.each.join(",") do |key,type|
                "\"#{key.to_s}\",#{type.to_c("",level+1)}"
            end})"
            return res
        end
    end


    ## Extends the Behavior class with generation of C text.
    class Behavior

        # Generates the text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object and
        # +time+ is a flag telling if the behavior is timed or not.
        # def to_c(level = 0, time = false)
        def to_c(res, level = 0, time = false)
            # puts "For behavior: #{self}"
            # # The resulting string.
            # res = ""

            # Declare the global variable holding the behavior.
            res << "Behavior " << Low2C.obj_name(self) << ";\n\n"

            # Generate the code of the behavior.
            
            # The header of the behavior.
            res << " " * level*3
            res << "Behavior " << Low2C.make_name(self) << "() {\n"
            res << " " * (level+1)*3

            # Allocate the behavior.
            res << "Behavior behavior = malloc(sizeof(BehaviorS));\n"
            res << " " * (level+1)*3
            res << "behavior->kind = BEHAVIOR;\n";

            # Sets the global variable of the behavior.
            res << "\n"
            res << " " * (level+1)*3
            res << Low2C.obj_name(self) << " = behavior;\n"

            # Register it as a time behavior if it is one of them. */
            if time then
                res << " " * (level+1)*3
                res << "register_timed_behavior(behavior);\n"
            end

            # Set the owner if any.
            if self.parent then
                res << " " * (level+1)*3
                res << "behavior->owner = (Object)"
                res << Low2C.obj_name(self.parent) << ";\n"
            else
                res << "behavior->owner = NULL;\n"
            end

            # Set the behavior as inactive. */
            res << " " * (level+1)*3
            res << "behavior->activated = 0;\n"

            # Tells if the behavior is timed or not.
            res << " " * (level+1)*3
            res << "behavior->timed = #{time ? 1 : 0};\n"

            # Is it a clocked behavior?
            events = self.each_event.to_a
            if events.empty? && !self.is_a?(TimeBehavior) then
                # No events, this is not a clock behavior.
                # And it is not a time behavior neigther.
                # Generate the events list from the right values.
                # First get the references.
                refs = self.block.each_node_deep.select do |node|
                    node.is_a?(RefName) && !node.leftvalue? && 
                        !node.parent.is_a?(RefName) 
                end.to_a
                # Keep only one ref per signal.
                refs.uniq! { |node| node.full_name }
                # Generate the event.
                events = refs.map {|ref| Event.new(:anyedge,ref.clone) }
                # Add them to the behavior for further processing.
                events.each {|event| self.add_event(event) }
            end
            # Add the events and register the behavior as activable
            # on them.
            # First allocates the array containing the events.
            res << " " * (level+1)*3
            res << "behavior->num_events = #{events.size};\n"
            res << " " * (level+1)*3
            res << "behavior->events = calloc(sizeof(Event),"
            res << "behavior->num_events);\n"
            # Then, create and add them.
            events.each_with_index do |event,i|
                # puts "for event=#{event}"
                # Add the event.
                res << " " * (level+1)*3
                # res << "behavior->events[#{i}] = #{event.to_c};\n"
                res << "behavior->events[#{i}] = "
                event.to_c(res)
                res << ";\n"
                
                # Register the behavior as activable on this event.
                # Select the active field.
                field = "any"
                field = "pos" if event.type == :posedge
                field = "neg" if event.type == :negedge
                # puts "Adding #{field} event: #{event}\n"
                # Get the target signal access
                # sigad = event.ref.resolve.to_c_signal
                sigad = ""
                event.ref.resolve.to_c_signal(sigad)
                # Add the behavior to the relevant field.
                res << " " * (level+1)*3
                res << "#{sigad}->num_#{field} += 1;\n"
                res << " " * (level+1)*3
                res << "#{sigad}->#{field} = realloc(#{sigad}->#{field},"
                res << "#{sigad}->num_#{field}*sizeof(Object));\n"
                res << "#{sigad}->#{field}[#{sigad}->num_#{field}-1] = "
                res << "(Object)behavior;\n"
            end

            # Adds the block.
            res << " " * (level+1)*3
            res << "behavior->block = " << Low2C.make_name(self.block) << "();\n"

            # Generate the Returns of the result.
            res << "\n"
            res << " " * (level+1)*3
            res << "return behavior;\n"

            # Close the behavior makeing.
            res << " " * level*3
            res << "}\n\n"
            return res
        end

        ## Generates the content of the h file.
        # def to_ch
        def to_ch(res)
            # res = ""
            # Declare the global variable holding the signal.
            res << "extern Behavior " << Low2C.obj_name(self) << ";\n\n"

            # Generate the access to the function making the behavior.
            res << "extern Behavior " << Low2C.make_name(self) << "();\n\n"

            # Generate the accesses to the block of the behavior.
            # res << self.block.to_ch
            self.block.to_ch(res)

            return res;
        end
    end

    ## Extends the TimeBehavior class with generation of C text.
    class TimeBehavior

        # Generates the C text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object.
        # def to_c(level = 0)
        def to_c(res,level = 0)
            # super(level,true)
            super(res,level,true)
        end
    end


    ## Extends the Event class with generation of C text.
    class Event

        # Generates the C text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object.
        # def to_c(level = 0)
        def to_c(res,level = 0)
            edge = "ANYEDGE"
            edge = "POSEDGE" if self.type == :posedge
            edge = "NEGEDGE" if self.type == :negedge
            # return "make_event(#{edge}," +
            #        "#{self.ref.resolve.to_c_signal(level+1)})"
            res << "make_event(#{edge},"
            self.ref.resolve.to_c_signal(res,level+1)
            res << ")"
            return res
        end
    end


    ## Extends the SignalI class with generation of C text.
    class SignalI

        ## Generates the C text for an access to the signal.
        #  +level+ is the hierachical level of the object.
        # def to_c_signal(level = 0)
        def to_c_signal(res,level = 0)
            # res = Low2C.obj_name(self)
            res << Low2C.obj_name(self)
            # # Accumulate the names of each parent until there is no one left.
            # obj = self.parent
            # while(obj) do
            #     res << "_" << Low2C.obj_name(obj)
            #     obj = obj.parent
            # end
            return res
        end

        ## Generates the C text of the equivalent HDLRuby code.
        #  +level+ is the hierachical level of the object.
        # def to_c(level = 0)
        def to_c(res,level = 0)
            # The resulting string.
            # res = ""

            # Declare the global variable holding the signal.
            # res << "SignalI #{self.to_c_signal(level+1)};\n\n"
            res << "SignalI "
            self.to_c_signal(res,level+1)
            res << ";\n\n"

            # The header of the signal generation.
            res << " " * level*3
            res << "SignalI " << Low2C.make_name(self) << "() {\n"
            # res << " " * level*3
            # res << "Value l,r,d;\n"
            # res << " " * (level+1)*3
            # res << "unsigned long long i;\n"
            res << " " * (level+1)*3
            res << "SignalI signalI = malloc(sizeof(SignalIS));\n"
            res << " " * (level+1)*3
            res << "signalI->kind = SIGNALI;\n";

            # Sets the global variable of the signal.
            res << "\n"
            res << " " * (level+1)*3
            # res << "#{self.to_c_signal(level+1)} = signalI;\n"
            self.to_c_signal(res,level+1)
            res << " = signalI;\n"

            # Set the owner if any.
            if self.parent then
                res << " " * (level+1)*3
                res << "signalI->owner = (Object)"
                res << Low2C.obj_name(self.parent) << ";\n"
            else
                res << "signalI->owner = NULL;\n"
            end

            # Set the name
            res << " " * (level+1)*3
            res << "signalI->name = \"#{self.name}\";\n"
            # Set the type.
            res << " " * (level+1)*3
            # res << "signalI->type = #{self.type.to_c(level+2)};\n"
            res << "signalI->type = "
            self.type.to_c(res,level+2)
            res << ";\n"
            # Set the current and the next value.
            res << " " * (level+1)*3
            res << "signalI->c_value = make_value(signalI->type,0);\n"
            res << " " * (level+1)*3
            res << "signalI->c_value->signal = signalI;\n"
            res << " " * (level+1)*3
            res << "signalI->f_value = make_value(signalI->type,0);\n"
            res << " " * (level+1)*3
            res << "signalI->f_value->signal = signalI;\n"
            if self.value then
                # There is an initial value.
                res << " " * (level+1)*3
                # res << "copy_value(#{self.value.to_c(level+2)}," +
                #        "signalI->c_value);\n"
                res << "copy_value("
                self.value.to_c_expr(res,level+2)
                res << ",signalI->c_value);\n"
            end

            # Initially the signal can be overwritten by anything.
            res << " " * (level+1)*3
            res << "signalI->fading = 1;\n"

            # Initialize the lists of behavior activated on this signal to 0.
            res << " " * (level+1)*3
            res << "signalI->num_any = 0;\n"
            res << " " * (level+1)*3
            res << "signalI->any = NULL;\n"
            res << " " * (level+1)*3
            res << "signalI->num_pos = 0;\n"
            res << " " * (level+1)*3
            res << "signalI->pos = NULL;\n"
            res << " " * (level+1)*3
            res << "signalI->num_neg = 0;\n"
            res << " " * (level+1)*3
            res << "signalI->neg = NULL;\n"

            # Register the signal for global processing.
            res << " " * (level+1)*3
            res << "register_signal(signalI);\n"


            # Generate the return of the signal.
            res << "\n"
            res << " " * (level+1)*3
            res << "return signalI;\n"

            # Close the signal.
            res << " " * level*3
            res << "};\n\n"
            return res
        end

        ## Generates the content of the h file.
        # def to_ch
        def to_ch(res)
            # res = ""
            # puts "to_ch for SignalI: #{self.to_c_signal()}"
            # Declare the global variable holding the signal.
            # res << "extern SignalI #{self.to_c_signal()};\n\n"
            res << "extern SignalI "
            self.to_c_signal(res)
            res << ";\n\n"

            # Generate the access to the function making the behavior.
            res << "extern SignalI " << Low2C.make_name(self) << "();\n\n"

            return res;
        end
    end


    ## Extends the SystemI class with generation of C text.
    class SystemI

        ## Generates the C text of the equivalent HDLRuby code.
        #  +level+ is the hierachical level of the object.
        # def to_c(level = 0)
        def to_c(res,level = 0)
            # The resulting string.
            # res = ""

            # Declare the global variable holding the signal.
            res << "SystemI " << Low2C.obj_name(self) << ";\n\n"

            # The header of the signal generation.
            res << " " * level*3
            res << "SystemI " << Low2C.make_name(self) << "() {\n"
            res << " " * (level+1)*3
            res << "SystemI systemI = malloc(sizeof(SystemIS));\n"
            res << " " * (level+1)*3
            res << "systemI->kind = SYSTEMI;\n";

            # Sets the global variable of the system instance.
            res << "\n"
            res << " " * (level+1)*3
            res << Low2C.obj_name(self) << " = systemI;\n"

            # Set the owner if any.
            if self.parent then
                res << " " * (level+1)*3
                res << "systemI->owner = (Object)"
                res << Low2C.obj_name(self.parent) << ";\n"
            else
                res << "systemI->owner = NULL;\n"
            end

            # Set the name
            res << " " * (level+1)*3
            res << "systemI->name = \"#{self.name}\";\n"
            # Set the type.
            res << " " * (level+1)*3
            res << "systemI->system = " << Low2C.obj_name(self.systemT) << ";\n"

            # Generate the return of the signal.
            res << "\n"
            res << " " * (level+1)*3
            res << "return systemI;\n"

            # Close the signal.
            res << " " * level*3
            res << "};\n\n"
            return res
        end

        ## Generates the content of the h file.
        # def to_ch
        def to_ch(res)
            # res = ""
            # Declare the global variable holding the signal.
            res << "extern SystemI " << Low2C.obj_name(self) << ";\n\n"

            # Generate the access to the function making the systemT. */
            res << "extern SystemI " << Low2C.make_name(self) << "();\n\n"

            return res
        end
    end


    # Extend the Chunk cass with generation of text code.
    class HDLRuby::Low::Chunk

        # Generates the C text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object.
        # def to_c(level = 0)
        def to_c(res,level = 0)
            # res = " " * level
            res << " " * level
            # res << self.each_lump.map do |lump|
            #     if !lump.is_a?(String) then
            #         lump.respond_to?(:to_c) ? lump.to_c(level+1) : lump.to_s
            #     else
            #         lump
            #     end
            # end.join
            self.each_lump do |lump|
                if !lump.is_a?(String) then
                    if lump.respond_to?(:to_c) then
                        lump.to_c(res,level+1)
                    else
                        res << lump.to_s
                    end
                else
                    res << lump
                end
            end
            return res
        end
    end


    ## Extends the SystemI class with generation of C text.
    class Code
        # Generates the C text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object.
        # def to_c(level = 0)
        def to_c(res,level = 0)
            # puts "For behavior: #{self}"
            # The resulting string.
            # res = ""

            # Declare the global variable holding the behavior.
            res << "Code " << Low2C.obj_name(self) << ";\n\n"

            # Generate the code of the behavior.
            
            # The header of the behavior.
            res << " " * level*3
            res << "Code " << Low2C.make_name(self) << "() {\n"
            res << " " * (level+1)*3

            # Allocate the code.
            res << "Code code = malloc(sizeof(CodeS));\n"
            res << " " * (level+1)*3
            res << "code->kind = CODE;\n";

            # Sets the global variable of the code.
            res << "\n"
            res << " " * (level+1)*3
            res << Low2C.obj_name(self) << " = code;\n"

            # Set the owner if any.
            if self.parent then
                res << " " * (level+1)*3
                res << "code->owner = (Object)"
                res << Low2C.obj_name(self.parent) << ";\n"
            else
                res << "code->owner = NULL;\n"
            end

            # Set the code as inactive. */
            res << " " * (level+1)*3
            res << "code->activated = 0;\n"

            # Add the events and register the code as activable
            # on them.
            res << " " * (level+1)*3
            res << "code->num_events = #{self.each_event.to_a.size};\n"
            res << " " * (level+1)*3
            res << "code->events = calloc(sizeof(Event)," +
                   "code->num_events);\n"
            # Process the events.
            events = self.each_event.to_a
            events.each_with_index do |event,i|
                # puts "for event=#{event}"
                # Add the event.
                res << " " * (level+1)*3
                # res << "code->events[#{i}] = #{event.to_c};\n"
                res << "code->events[#{i}] = "
                event.to_c(res)
                res << ";\n"
                
                # Register the behavior as activable on this event.
                # Select the active field.
                field = "any"
                field = "pos" if event.type == :posedge
                field = "neg" if event.type == :negedge
                # Get the target signal access
                # sigad = event.ref.resolve.to_c_signal
                sigad = ""
                event.ref.resolve.to_c_signal(sigad)
                # Add the code to the relevant field.
                res << " " * (level+1)*3
                res << "#{sigad}->num_#{field} += 1;\n"
                res << " " * (level+1)*3
                res << "#{sigad}->#{field} = realloc(#{sigad}->#{field}," +
                       "#{sigad}->num_#{field}*sizeof(Object));\n"
                res << "#{sigad}->#{field}[#{sigad}->num_#{field}-1] = " +
                       "(Object)code;\n"
            end

            # Adds the function to execute.
            function = self.each_chunk.find { |chunk| chunk.name == :sim }
            res << " " * (level+1)*3
            # res << "code->function = &#{function.to_c};\n"
            res << "code->function = &"
            function.to_c(res)
            res << ";\n"

            # Generate the Returns of the result.
            res << "\n"
            res << " " * (level+1)*3
            res << "return code;\n"

            # Close the behavior makeing.
            res << " " * level*3
            res << "}\n\n"
            return res
        end

        ## Generates the content of the h file.
        # def to_ch
        def to_ch(res)
            # res = ""
            # Declare the global variable holding the signal.
            res << "extern Behavior " << Low2C.obj_name(self) << ";\n\n"

            # Generate the access to the function making the behavior.
            res << "extern Behavior " << Low2C.make_name(self) << "();\n\n"

            # Generate the accesses to the block of the behavior.
            # res << self.block.to_ch
            self.block.to_ch(res)

            return res;
        end
    end


    ## Extends the Statement class with generation of C text.
    class Statement

        # Generates the C text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object.
        # def to_c(level = 0)
        def to_c(res,level = 0)
            # Should never be here.
            raise AnyError, "Internal error: to_c should be implemented in class :#{self.class}"
        end

        ## Generates the content of the h file.
        # def to_ch
        def to_ch(res)
            # By default nothing to generate.
            # return ""
            return res
        end

        # Adds the c code of the blocks to +res+ at +level+
        def add_blocks_code(res,level)
            if self.respond_to?(:each_node) then
                self.each_node do |node|
                    if node.respond_to?(:add_blocks_code) then
                        node.add_blocks_code(res,level)
                    end
                end
            end
        end
        
        # Adds the creation of the blocks to +res+ at +level+.
        def add_make_block(res,level)
            if self.respond_to?(:each_node) then
                self.each_node do |node|
                    if node.respond_to?(:add_blocks_code) then
                        node.add_make_block(res,level)
                    end
                end
            end
        end
    end

    ## Extends the Transmit class with generation of C text.
    class Transmit

        # # Generates the C text of the equivalent HDLRuby code.
        # # +level+ is the hierachical level of the object.
        # # def to_c(level = 0)
        # def to_c(res,level = 0)
        #     # Save the state of the value pool.
        #     # res = (" " * ((level)*3))
        #     res << (" " * ((level)*3))
        #     res << "{\n"
        #     res << (" " * ((level+1)*3))
        #     res << "unsigned int pool_state = get_value_pos();\n"
        #     # Perform the copy and the touching only if the new content
        #     # is different.
        #     # res << (" " * ((level+1)*3))
        #     # Is it a sequential execution model?
        #     seq = self.block.mode == :seq ? "_seq" : ""
        #     # # Generate the assignment.
        #     # if (self.left.is_a?(RefName)) then
        #     #     # Direct assignment to a signal, simple transmission.
        #     #     res << "transmit_to_signal#{seq}("
        #     #     self.right.to_c(res,level)
        #     #     res << ","
        #     #     self.left.to_c_signal(res,level)
        #     #     res << ");\n"
        #     # else
        #     #     # Assignment inside a signal (RefIndex or RefRange).
        #     #     res << "transmit_to_signal_range#{seq}("
        #     #     self.right.to_c(res,level)
        #     #     res << ","
        #     #     self.left.to_c_signal(res,level)
        #     #     res << ");\n"
        #     #     ### Why twice ???
        #     #     res << "transmit_to_signal_range#{seq}("
        #     #     self.right.to_c(res,level)
        #     #     res << ","
        #     #     self.left.to_c_signal(res,level)
        #     #     res << ");\n"
        #     # end
        #     # Generate the assignment.
        #     if (self.left.is_a?(RefName)) then
        #         # Generate the right value.
        #         self.right.to_c(res,level+1)
        #         # Direct assignment to a signal, simple transmission.
        #         res << (" " * ((level+1)*3))
        #         res << "transmit_to_signal#{seq}(d,"
        #         # Generate the left value (target signal).
        #         self.left.to_c_signal(res,level+1)
        #         res << ");\n"
        #     else
        #         # Generate the right value.
        #         self.right.to_c(res,level+1)
        #         # Assignment inside a signal (RefIndex or RefRange).
        #         res << "transmit_to_signal_range#{seq}(d,"
        #         # Generate the left value (target signal).
        #         self.left.to_c_signal(res,level+1)
        #         res << ");\n"
        #     end
        #     # Restore the value pool state.
        #     res << (" " * ((level+1)*3))
        #     res << "set_value_pos(pool_state);\n"
        #     res << (" " * ((level)*3))
        #     res << "}\n"
        #     return res
        # end
        # Generates the C text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object.
        # def to_c(level = 0)
        def to_c(res,level = 0)
            # Save the value pool state.
            res << (" " * (level*3)) << "SV;\n"
            # Perform the copy and the touching only if the new content
            # is different.
            # Is it a sequential execution model?
            seq = self.block.mode == :seq ? "_seq" : ""
            # Generate the assignment.
            if (self.left.is_a?(RefName)) then
                # Generate the right value.
                self.right.to_c(res,level)
                # Direct assignment to a signal, simple transmission.
                res << (" " * (level*3))
                res << "transmit#{seq}("
                # Generate the left value (target signal).
                self.left.to_c_signal(res,level+1)
                res << ");\n"
            else
                # Generate the right value.
                self.right.to_c(res,level)
                # Assignment inside a signal (RefIndex or RefRange).
                res << "transmitR#{seq}("
                # Generate the left value (target signal).
                self.left.to_c_signal(res,level+1)
                res << ");\n"
            end
            # Restore the value pool state.
            res << (" " * (level*3)) << "RV;\n"
            return res
        end
    end


    ## Extends the Print class with generation of C text.
    class Print

        # # Generates the C text of the equivalent HDLRuby code.
        # # +level+ is the hierachical level of the object.
        # # def to_c(level = 0)
        # def to_c(res,level = 0)
        #     # Save the state of the value pool.
        #     # res = (" " * ((level)*3))
        #     res << (" " * ((level)*3))
        #     res << "{\n"
        #     res << (" " * ((level+1)*3))
        #     res << "unsigned int pool_state = get_value_pos();\n"
        #     # Perform the copy and the touching only if the new content
        #     # is different.
        #     res << (" " * ((level+1)*3))
        #     # Is it a sequential execution model?
        #     seq = self.block.mode == :seq ? "_seq" : ""
        #     # Generate the print.
        #     self.each_arg do |arg|
        #         if (arg.is_a?(StringE)) then
        #             res << "printer.print_string(\"" + 
        #                 Low2C.c_string(arg.content) + "\");\n"
        #         elsif (arg.is_a?(Expression)) then
        #             # res << "printer.print_string_value(" + arg.to_c + ");\n"
        #             res << "printer.print_string_value("
        #             arg.to_c(res)
        #             res << ");\n"
        #         else
        #             # res << "printer.print_string_name(" + arg.to_c + ");\n"
        #             res << "printer.print_string_name("
        #             arg.to_c(res)
        #             res << ");\n"
        #         end
        #     end
        #     # Restore the value pool state.
        #     res << (" " * ((level+1)*3))
        #     res << "set_value_pos(pool_state);\n"
        #     res << (" " * ((level)*3))
        #     res << "}\n"
        #     return res
        # end
        # Generates the C text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object.
        # def to_c(level = 0)
        def to_c(res,level = 0)
            # Save the value pool state.
            res << (" " * (level*3)) << "PV;\n"
            # Generate the print for each argument.
            self.each_arg do |arg|
                if (arg.is_a?(StringE)) then
                    res << (" " * (level*3))
                    res << "printer.print_string(\"" + 
                        Low2C.c_string(arg.content) + "\");\n"
                elsif (arg.is_a?(Expression)) then
                    arg.to_c(res)
                    res << (" " * (level*3))
                    res << "printer.print_string_value(pop());\n"
                else
                    arg.to_c(res)
                    res << "printer.print_string_name(pop());\n"
                end
            end
            # Restore the value pool state.
            res << (" " * (level*3)) << "RV;\n"
            return res
        end
    end

    
    ## Extends the If class with generation of C text.
    class If

        # # Generates the C text of the equivalent HDLRuby code.
        # # +level+ is the hierachical level of the object.
        # # def to_c(level = 0)
        # def to_c(res,level = 0)
        #     # The result string.
        #     # res = " " * level*3
        #     res << " " * level*3
        #     # Compute the condition.
        #     res << "{\n"
        #     res << " " * (level+1)*3
        #     # res << "Value cond = " << self.condition.to_c(level+1) << ";\n"
        #     res << "Value cond = "
        #     self.condition.to_c(res,level+1)
        #     res << ";\n"
        #     # Ensure the condition is testable.
        #     res << " " * (level+1)*3
        #     res << "if (is_defined_value(cond)) {\n"
        #     # The condition is testable.
        #     res << " " * (level+2)*3
        #     res << "if (value2integer(cond)) {\n"
        #     # Generate the yes part.
        #     # res << self.yes.to_c(level+3)
        #     self.yes.to_c(res,level+3)
        #     res << " " * level*3
        #     res << "}\n"
        #     # Generate the alternate if parts.
        #     self.each_noif do |cond,stmnt|
        #         res << " " * level*3
        #         # res << "else if (value2integer(" << cond.to_c(level+1) << ")) {\n"
        #         res << "else if (value2integer("
        #         cond.to_c(res,level+1)
        #         res << ")) {\n"
        #         # res << stmnt.to_c(level+1)
        #         stmnt.to_c(res,level+1)
        #         res << " " * level*3
        #         res << "}\n"
        #     end
        #     # Generate the no part if any.
        #     if self.no then
        #         res << " " * level*3
        #         # res << "else {\n" << self.no.to_c(level+1)
        #         res << "else {\n"
        #         self.no.to_c(res,level+1)
        #         res << " " * level*3
        #         res << "}\n"
        #     end
        #     # Close the if.
        #     res << " " * (level+1)*3
        #     res << "}\n"
        #     res << " " * (level)*3
        #     res << "}\n"
        #     # Return the result.
        #     return res
        # end
        # Generates the C text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object.
        def to_c(res,level = 0)
            res << " " * level*3
            # Compute the condition.
            self.condition.to_c(res,level)
            # Check is the value is true.
            res << " " * level*3
            res << "if (is_true()) {\n"
            # Generate the yes part.
            self.yes.to_c(res,level+1)
            res << " " * level*3
            res << "}\n"
            # Generate the alternate if parts.
            self.each_noif do |cond,stmnt|
                res << " " * (level*3)
                res << "else {\n"
                cond.to_c(res,level+1)
                # Check is the value is true.
                res << " " * (level+1)*3
                res << "if (is_true()) {\n"
                stmnt.to_c(res,level+2)
                res << " " * ((level+1)*3)
                res << "}\n"
            end
            # Generate the no part if any.
            if self.no then
                res << " " * (level*3)
                res << "else {\n"
                self.no.to_c(res,level+1)
                res << " " * level*3
                res << "}\n"
            end
            # Close the noifs.
            self.each_noif do |cond,stmnt|
                res << " " * (level*3)
                res << "}\n"
            end
            # # Close the if.
            # res << " " * ((level+1)*3)
            # res << "}\n"
            # res << " " * (level*3)
            # res << "}\n"
            # Return the result.
            return res
        end

        ## Generates the content of the h file.
        # def to_ch
        def to_ch(res)
            # res = ""
            # Recurse on the sub statements.
            # res << self.yes.to_ch
            self.yes.to_ch(res)
            self.each_noif do |cond,stmnt|
                # res << stmnt.to_ch
                stmnt.to_ch(res)
            end
            # res << self.no.to_ch if self.no
            self.no.to_ch(res) if self.no
            return res
        end
    end

    ## Extends the When class with generation of C text.
    class When

        # Generates the C text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object.
        # def to_c(level = 0)
        def to_c(res,level = 0)
            # The result string.
            # res = " " * level*3
            res << " " * level*3
            # Generate the match.
            # res << "case " << self.match.to_c(level+1) << ": {\n"
            res << "case "
            self.match.to_c(res,level+1)
            res << ": {\n"
            # Generate the statement.
            # res << self.statement.to_c(level+1)
            self.statement.to_c(res,level+1)
            # Adds a break
            res << " " * (level+1)*3 << "break;\n"
            res << " " * level*3 << "}\n"
            # Returns the result.
            return res
        end

        ## Generates the content of the h file.
        # def to_ch
        def to_ch(res)
            # return self.statement.to_ch
            self.statement.to_ch(res)
            return res
        end

        # Adds the c code of the blocks to +res+ at +level+
        def add_blocks_code(res,level)
            self.statement.add_blocks_code(res,level)
        end

        # Adds the creation of the blocks to +res+ at +level+.
        def add_make_block(res,level)
            self.statement.add_make_block(res,level)
        end
    end

    ## Extends the Case class with generation of C text.
    class Case

        # # Generates the text of the equivalent HDLRuby code.
        # # +level+ is the hierachical level of the object.
        # # def to_c(level = 0)
        # def to_c(res,level = 0)
        #     # res = ""
        #     # Compute the selection value.
        #     res << "{\n"
        #     res << " " * (level+1)*3
        #     # res << "Value value = " << self.value.to_c(level+1) << ";\n"
        #     res << "Value value = "
        #     self.value.to_c(res,level+1)
        #     res << ";\n"
        #     # Ensure the selection value is testable.
        #     res << " " * (level+1)*3
        #     res << "if (is_defined_value(value)) {\n"
        #     # The condition is testable.
        #     # Generate the case as a succession of if statements.
        #     first = true
        #     self.each_when do |w|
        #         res << " " * (level+2)*3
        #         if first then
        #             first = false
        #         else
        #             res << "else "
        #         end
        #         res << "if (value2integer(value) == "
        #         # res << "value2integer(" << w.match.to_c(level+2) << ")) {\n"
        #         res << "value2integer("
        #         w.match.to_c(res,level+2)
        #         res << ")) {\n"
        #         # res << w.statement.to_c(level+3)
        #         w.statement.to_c(res,level+3)
        #         res << " " * (level+2)*3
        #         res << "}\n"
        #     end
        #     if self.default then
        #         res << " " * (level+2)*3
        #         res << "else {\n"
        #         # res << self.default.to_c(level+3)
        #         self.default.to_c(res,level+3)
        #         res << " " * (level+2)*3
        #         res << "}\n"
        #     end
        #     # Close the case.
        #     res << " " * (level+1)*3
        #     res << "}\n"
        #     res << " " * (level)*3
        #     res << "}\n"
        #     # Return the resulting string.
        #     return res
        # end
        # Generates the text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object.
        # def to_c(level = 0)
        def to_c(res,level = 0)
            # Compute the selection value.
            res << "{\n"
            self.value.to_c(res,level+1)
            res << " " * ((level+1)*3)
            res << "dup();\n"
            # Ensure the selection value is testable.
            res << " " * ((level+1)*3)
            res << "if (is_defined()) {\n"
            # The condition is testable.
            # Generate the case as a succession of if statements.
            self.each_when do |w|
                res << " " * ((level+2)*3)
                res << "dup();\n"
                res << " " * ((level+2)*3)
                w.match.to_c(res,level+2)
                res << "if (to_integer() == to_integer()) {\n"
                w.statement.to_c(res,level+3)
                res << " " * (level+2)*3
                res << "}\n"
            end
            if self.default then
                res << " " * (level+2)*3
                res << "else {\n"
                self.default.to_c(res,level+3)
                res << " " * (level+2)*3
                res << "}\n"
            end
            # Close the case.
            res << " " * (level+1)*3
            res << "pop();\n" # Remove the testing value.
            res << " " * (level+1)*3
            res << "}\n"
            res << " " * (level)*3
            res << "}\n"
            # Return the resulting string.
            return res
        end

        ## Generates the content of the h file.
        # def to_ch
        def to_ch(res)
            # res = ""
            # Recurse on the whens.
            # self.each_when {|w| res << w.to_ch }
            self.each_when {|w| w.to_ch(res) }
            # Recurse on the default statement.
            # res << self.default.to_ch if self.default
            self.default.to_ch(res) if self.default
            return res
        end
    end


    ## Extends the Delay class with generation of C text.
    class Delay

        # Generates the C text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object.
        # def to_c(level = 0)
        def to_c(res,level = 0)
            # return "make_delay(#{self.value.to_s}," +
            #        "#{Low2C.unit_name(self.unit)})"
            res << "make_delay(#{self.value.to_s},"
            res << Low2C.unit_name(self.unit) << ")"
            return res
        end
    end


    ## Extends the TimeWait class with generation of C text.
    class TimeWait

        # Generates the C text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object.
        # def to_c(level = 0)
        def to_c(res,level = 0)
            # The resulting string.
            # res = " " * level*3
            res << " " * level*3
            # Generate the wait.
            # res << "hw_wait(#{self.delay.to_c(level+1)}," +
            #     "#{Low2C.behavior_access(self)});\n"
            res << "hw_wait("
            self.delay.to_c(res,level+1)
            res << "," << Low2C.behavior_access(self) << ");\n"
            # Return the resulting string.
            return res
        end
    end

    ## Extends the TimeRepeat class with generation of C text.
    class TimeRepeat

        # Generates the C text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object.
        # def to_c(level = 0)
        def to_c(res,level = 0)
            # The resulting string.
            # res = " " * level*3
            res << " " * level*3
            # Generate an infinite loop executing the block and waiting.
            res << "for(;;) {\n"
            # res << "#{self.statement.to_c(level+1)}\n"
            self.statement.to_c(res,level+1)
            res << "\n"
            res << " " * (level+1)*3
            res << Low2C.wait_code(self,level)
            # Return the resulting string.
            return res
        end
    end

    ## Extends the Block class with generation of C text.
    class Block

        # Adds the c code of the blocks to +res+ at +level+
        def add_blocks_code(res,level)
            # res << self.to_c_code(level)
            self.to_c_code(res,level)
            return res
        end

        # Adds the creation of the blocks to +res+ at +level+.
        def add_make_block(res,level)
            res << " " * level*3
            res << Low2C.make_name(self) << "();\n"
        end

        # Generates the C text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object.
        # def to_c_code(level = 0)
        def to_c_code(res,level = 0)
            # The resulting string.
            # res = ""
            # puts "generating self=#{self.object_id}"

            # Declare the global variable holding the block.
            res << "Block " << Low2C.obj_name(self) << ";\n\n"

            # Generate the c code of the sub blocks if any.
            self.each_statement do |stmnt|
                stmnt.add_blocks_code(res,level)
            end

            # Generate the execution function.
            res << " " * level*3
            res << "void " << Low2C.code_name(self) << "() {\n"
            res << " " * (level+1)*3
            # res << "Value l,r,d;\n"
            # res << " " * (level+1)*3
            # res << "unsigned long long i;\n"
            # res << "printf(\"Executing #{Low2C.code_name(self)}...\\n\");"
            # Generate the statements.
            self.each_statement do |stmnt|
                # res << stmnt.to_c(level+1)
                stmnt.to_c(res,level+1)
            end
            # Close the execution function.
            res << " " * level*3
            res << "}\n\n"


            # Generate the signals.
            # self.each_signal { |signal| res << signal.to_c(level) }
            self.each_signal { |signal| signal.to_c(res,level) }

            # The header of the block.
            res << " " * level*3
            res << "Block " << Low2C.make_name(self) << "() {\n"
            res << " " * (level+1)*3
            res << "Block block = malloc(sizeof(BlockS));\n"
            res << " " * (level+1)*3
            res << "block->kind = BLOCK;\n";

            # Sets the global variable of the block.
            res << "\n"
            res << " " * (level+1)*3
            res << Low2C.obj_name(self) << " = block;\n"

            # Set the owner if any.
            if self.parent then
                # Look for a block or behavior parent.
                true_parent = self.parent
                until true_parent.is_a?(Block) || true_parent.is_a?(Behavior)
                       true_parent = true_parent.parent
                end
                # Set it as the real parent.
                res << " " * (level+1)*3
                res << "block->owner = (Object)" 
                res << Low2C.obj_name(true_parent) << ";\n"
            else
                res << "block->owner = NULL;\n"
            end

            # The name
            res << " " * (level+1)*3
            res << "block->name = \"#{self.name}\";\n"

            # Add the inner signals declaration.
            res << " " * (level+1)*3
            res << "block->num_inners = #{self.each_inner.to_a.size};\n"
            res << " " * (level+1)*3
            res << "block->inners = calloc(sizeof(SignalI)," +
                   "block->num_inners);\n"
            self.each_inner.with_index do |inner,i|
                res << " " * (level+1)*3
                res << "block->inners[#{i}] = "
                res << Low2C.make_name(inner) << "();\n"
            end

            # Sets the execution function.
            res << " " * (level+1)*3
            res << "block->function = &" << Low2C.code_name(self) << ";\n"

            # Generate creation of the sub blocks.
            self.each_statement do |stmnt|
                stmnt.add_make_block(res,level+1)
            end

            # Generate the Returns of the result.
            res << "\n"
            res << " " * (level+1)*3
            res << "return block;\n"

            # Close the block.
            res << " " * level*3
            res << "};\n\n"
            return res
        end

        # Generates the execution of the block C text of the equivalent
        # HDLRuby code.
        # +level+ is the hierachical level of the object.
        # def to_c(level = 0)
        def to_c(res,level = 0)
            # res = " " * (level*3)
            res << " " * (level*3)
            res << Low2C.code_name(self) << "();\n"
            return res
        end

        ## Generates the content of the h file.
        # def to_ch
        def to_ch(res)
            # puts "to_ch for block=#{Low2C.obj_name(self)} with=#{self.each_inner.count} inners"
            # res = ""
            # Declare the global variable holding the block.
            res << "extern Block " << Low2C.obj_name(self) << ";\n\n"

            # Generate the access to the function making the block. */
            res << "extern Block " << Low2C.make_name(self) << "();\n\n"

            # Generate the accesses to the ports.
            # self.each_inner  { |inner|  res << inner.to_ch }
            self.each_inner  { |inner|  inner.to_ch(res) }

            # Recurse on the statements.
            # self.each_statement { |stmnt| res << stmnt.to_ch }
            self.each_statement { |stmnt| stmnt.to_ch(res) }

            return res
        end
    end


    ## Extends the Block class with generation of C text.
    class TimeBlock
        # TimeBlock is identical to Block in C
    end


    ## Extends the Connection class with generation of C text.
    class Connection
        # Nothing required, Transmit is generated identically.
    end


    ## Extends the Expression class with generation of C text.
    class Expression

        # Generates the C text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object.
        # def to_c(level = 0)
        def to_c(res,level = 0)
            # Should never be here.
            raise AnyError, "Internal error: to_c should be implemented in class :#{self.class}"
        end
    end


    ## Extends the Value class with generation of C text.
    class Value

        ## Generates the C text for an access to the value.
        #  +level+ is the hierachical level of the object.
        def to_c(res,level = 0)
            # res << Low2C.make_name(self) << "()"
            # return res
            res << (" " * (level*3))
            # res << "d=" << Low2C.make_name(self) << "();\n"
            res << "push(" << Low2C.make_name(self) << "());\n"
            return res
        end

        ## Generates the C text for an expression access to the value.
        #  +level+ is the hierachical level of the object.
        def to_c_expr(res,level = 0)
            res << Low2C.make_name(self) << "()"
            return res
        end
    
        ## Generates the content of the h file.
        # def to_ch
        def to_ch(res)
            # res = ""
            # return "extern Value #{Low2C.make_name(self)}();"
            res << "extern Value " << Low2C.make_name(self) << "();"
            return res
        end

        @@made_values = Set.new

        # Generates the text of the equivalent c.
        # +level+ is the hierachical level of the object.
        # def to_c_make(level = 0)
        def to_c_make(res,level = 0)
            # Check is the value maker is already present.
            maker = Low2C.make_name(self);
            # return "" if @@made_values.include?(maker)
            return res if @@made_values.include?(maker)
            @@made_values.add(maker)

            # The resulting string.
            # res = ""

            # The header of the value generation.
            res << " " * level*3
            # res << "Value " << Low2C.make_name(self) << "() {\n"
            res << "Value " << maker << "() {\n"

            # Declares the data.
            # Create the bit string.
            # str = self.content.is_a?(BitString) ?
            #     self.content.to_s : self.content.to_s(2).rjust(32,"0")
            if self.content.is_a?(BitString) then
                str = self.content.is_a?(BitString) ?
                    self.content.to_s : self.content.to_s(2).rjust(32,"0")
            else
                # sign = self.content>=0 ? "0" : "1"
                # str = self.content.abs.to_s(2).rjust(width,sign).upcase
                if self.content >= 0 then
                    str = self.content.to_s(2).rjust(width,"0").upcase
                else
                    # Compute the extension to the next multiple
                    # of int_width
                    ext_width = (((width-1) / Low2C.int_width)+1)*Low2C.int_width
                    # Convert the string.
                    str = (2**ext_width+self.content).to_s(2).upcase
                end
                # puts "content=#{self.content} str=#{str}"
            end
            # Is it a fully defined number?
            # NOTE: bignum values are not supported by the simulation engine
            #       yet, therefore numeric values are limited to 64 max.
            if str =~ /^[01]+$/ && str.length <= 64 then
                # Yes, generate a numeral value.
                res << " " * (level+1)*3
                # res << "static unsigned long long data[] = { "
                res << "static unsigned int data[] = { "
                res << str.scan(/.{1,#{Low2C.int_width}}/m).reverse.map do |sub|
                    sub.to_i(2).to_s # + "ULL"
                end.join(",")
                res << " };\n"
                # Create the value.
                res << " " * (level+1)*3
                # puts "str=#{str} type width=#{self.type.width} signed? #{type.signed?}"
                # res << "return make_set_value(#{self.type.to_c(level+1)},1," +
                #        "data);\n" 
                res << "return make_set_value("
                self.type.to_c(res,level+1)
                res << ",1,data);\n" 
            else
                # No, generate a bit string value.
                res << " " * (level+1)*3
                # res << "static unsigned char data[] = \"#{str}\";\n"
                res << "static unsigned char data[] = \"#{str.reverse}\";\n"
                # Create the value.
                res << " " * (level+1)*3
                # res << "return make_set_value(#{self.type.to_c(level+1)},0," +
                #        "data);\n" 
                res << "return make_set_value("
                self.type.to_c(res,level+1)
                res << ",0,data);\n" 
            end

            # Close the value.
            res << " " * level*3
            res << "}\n\n"
            # Return the result.
            return res
        end
    end

    ## Extends the Cast class with generation of C text.
    class Cast

        # # Generates the C text of the equivalent HDLRuby code.
        # # +level+ is the hierachical level of the object.
        # # def to_c(level = 0)
        # def to_c(res,level = 0)
        #     # res = "({\n"
        #     res << "({\n"
        #     # Overrides the upper src0 and dst...
        #     res << (" " * ((level+1)*3))
        #     res << "Value src0, dst = get_value();\n"
        #     # Save the state of the value pool.
        #     res << (" " * ((level+1)*3))
        #     res << "unsigned int pool_state = get_value_pos();\n"
        #     # Compute the child.
        #     res << (" " * ((level+1)*3))
        #     # res << "src0 = #{self.child.to_c(level+2)};\n"
        #     res << "src0 = "
        #     self.child.to_c(res,level+2)
        #     res << ";\n"
        #     res << (" " * ((level+1)*3))
        #     # res += "dst = cast_value(src0," +
        #     #     "#{self.type.to_c(level+1)},dst);\n"
        #     res << "dst = cast_value(src0,"
        #     self.type.to_c(res,level+1)
        #     res << ",dst);\n"
        #     # Restore the value pool state.
        #     res << (" " * ((level+1)*3))
        #     res << "set_value_pos(pool_state);\n"
        #     # Close the computation
        #     res << (" " * (level*3))
        #     res << "dst; })"

        #     return res
        # end
        # Generates the C text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object.
        # def to_c(level = 0)
        def to_c(res,level = 0)
            # Save the value pool state.
            res << (" " * (level*3)) << "PV;\n"
            # Generate the child.
            self.child.to_c(res,level)
            res << (" " * (level*3))
            # res << "d=cast(d,"
            res << "cast("
            self.type.to_c(res,level+1)
            res << ");\n"
            # Restore the value pool state.
            res << (" " * (level*3)) << "RV;\n"
            return res
        end
    end


    ## Extends the Operation class with generation of C text.
    class Operation

        # Generates the C text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object.
        # def to_c(level = 0)
        def to_c(res,level = 0)
            # Should never be here.
            raise AnyError, "Internal error: to_c should be implemented in class :#{self.class}"
        end
    end

    ## Extends the Unary class with generation of C text.
    class Unary

        # # Generates the C text of the equivalent HDLRuby code.
        # # +level+ is the hierachical level of the object.
        # # def to_c(level = 0)
        # def to_c(res,level = 0)
        #     # res = "({\n"
        #     res << "({\n"
        #     # Overrides the upper src0 and dst...
        #     res << (" " * ((level+1)*3))
        #     res << "Value src0, dst;\n"
        #     if (self.operator != :+@) then
        #         # And allocates a new value for dst unless the operator
        #         # is +@ that does not compute anything.
        #         res << (" " * ((level+1)*3))
        #         res << "dst = get_value();\n"
        #     end
        #     # Save the state of the value pool.
        #     res << (" " * ((level+1)*3))
        #     res << "unsigned int pool_state = get_value_pos();\n"
        #     # Compute the child.
        #     res << (" " * ((level+1)*3))
        #     # res << "src0 = #{self.child.to_c(level+2)};\n"
        #     res << "src0 = "
        #     self.child.to_c(res,level+2)
        #     res << ";\n"
        #     res << (" " * ((level+1)*3))
        #     case self.operator
        #     when :~ then
        #         res << "dst = not_value(src0,dst);\n"
        #     when :-@ then
        #         res << "dst = neg_value(src0,dst);\n"
        #     when :+@ then
        #         # res << "dst = #{self.child.to_c(level)};\n"
        #         res << "dst = "
        #         self.child.to_c(res,level)
        #         res << ";\n"
        #     else
        #         raise "Invalid unary operator: #{self.operator}."
        #     end
        #     # Restore the value pool state.
        #     res << (" " * ((level+1)*3))
        #     res << "set_value_pos(pool_state);\n"
        #     # Close the computation
        #     res << (" " * (level*3))
        #     res << "dst; })"

        #     return res
        # end
        # Generates the C text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object.
        # def to_c(level = 0)
        def to_c(res,level = 0)
            if (self.operator == :+@) then
                # No computation required.
                self.child.to_c(res,level)
                return res
            end
            # Some computation required.
            # Save the value pool state.
            res << (" " * (level*3)) << "PV;\n"
            # Generate the child.
            self.child.to_c(res,level)
            res << (" " * (level*3))
            res << "unary("
            # Adds the operation
            case self.operator
            when :~ then
                res << "&not_value"
            when :-@ then
                res << "&neg_value"
            else
                raise "Invalid unary operator: #{self.operator}."
            end
            res << ");\n"
            # Restore the value pool state.
            res << (" " * (level*3)) << "RV;\n"

            return res
        end
    end


    ## Extends the Binary class with generation of C text.
    class Binary

        # # Generates the C text of the equivalent HDLRuby code.
        # # +level+ is the hierachical level of the object.
        # # def to_c(level = 0)
        # def to_c(res, level = 0)
        #     # res = "({\n"
        #     res << "({\n"
        #     # Overrides the upper src0, src1 and dst...
        #     # And allocates a new value for dst.
        #     res << (" " * ((level+1)*3))
        #     res << "Value src0,src1,dst = get_value();\n"
        #     # Save the state of the value pool.
        #     res << (" " * ((level+1)*3))
        #     res << "unsigned int pool_state = get_value_pos();\n"
        #     # Compute the left.
        #     res << (" " * ((level+1)*3))
        #     # res << "src0 = " << self.left.to_c(level+2) << ";\n"
        #     res << "src0 = "
        #     self.left.to_c(res,level+2)
        #     res << ";\n"
        #     # Compute the right.
        #     res << (" " * ((level+1)*3))
        #     # res << "src1 = " << self.right.to_c(level+2) << ";\n"
        #     res << "src1 = "
        #     self.right.to_c(res,level+2)
        #     res << ";\n"
        #     res << (" " * ((level+1)*3))

        #     # Compute the current binary operation.
        #     case self.operator
        #     when :+ then
        #         res << "dst = add_value(src0,src1,dst);\n"
        #     when :- then
        #         res << "dst = sub_value(src0,src1,dst);\n"
        #     when :* then
        #         res << "dst = mul_value(src0,src1,dst);\n"
        #     when :/ then
        #         res << "dst = div_value(src0,src1,dst);\n"
        #     when :% then
        #         res << "dst = mod_value(src0,src1,dst);\n"
        #     when :** then
        #         res << "dst = pow_value(src0,src1,dst);\n"
        #     when :& then
        #         res << "dst = and_value(src0,src1,dst);\n"
        #     when :| then
        #         res << "dst = or_value(src0,src1,dst);\n"
        #     when :^ then
        #         res << "dst = xor_value(src0,src1,dst);\n"
        #     when :<<,:ls then
        #         res << "dst = shift_left_value(src0,src1,dst);\n"
        #     when :>>,:rs then
        #         res << "dst = shift_right_value(src0,src1,dst);\n"
        #     when :lr then
        #         res << "dst = rotate_left_value(src0,src1,dst);\n"
        #     when :rr then
        #         res << "dst = rotate_right_value(src0,src1,dst);\n"
        #     when :== then
        #         res << "dst = equal_value(src0,src1,dst);\n"
        #         res << "dst = reduce_or_value(dst,dst);"
        #     when :!= then
        #         res << "dst = xor_value(src0,src1,dst);\n"
        #         res << "dst = reduce_or_value(dst,dst);"
        #     when :> then
        #         res << "dst = greater_value(src0,src1,dst);\n"
        #     when :< then
        #         res << "dst = lesser_value(src0,src1,dst);\n"
        #     when :>= then
        #         res << "dst = greater_equal_value(src0,src1,dst);\n"
        #     when :<= then
        #         res << "dst = lesser_equal_value(src0,src1,dst);\n"
        #     else
        #         raise "Invalid binary operator: #{self.operator}."
        #     end
        #     # Restore the state of the value pool.
        #     res << (" " * ((level+1)*3))
        #     res << "set_value_pos(pool_state);\n"
        #     # Close the computation.
        #     res << (" " * (level*3))
        #     res << "dst;})"

        #     return res
        # end
        # Generates the C text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object.
        # def to_c(level = 0)
        def to_c(res, level = 0)
            # Save the value pool state.
            res << (" " * (level*3)) << "PV;\n"
            # Generate the left computation.
            self.left.to_c(res,level)
            # Generate the right computation.
            self.right.to_c(res,level)
            # Generate the binary.
            res << (" " * (level*3))
            res << "binary("
            # Set the operation.
            case self.operator
            when :+ then
                res << "&add_value"
            when :- then
                res << "&sub_value"
            when :* then
                res << "&mul_value"
            when :/ then
                res << "&div_value"
            when :% then
                res << "&mod_value"
            when :** then
                res << "&pow_value"
            when :& then
                res << "&and_value"
            when :| then
                res << "&or_value"
            when :^ then
                res << "&xor_value"
            when :<<,:ls then
                res << "&shift_left_value"
            when :>>,:rs then
                res << "&shift_right_value"
            when :lr then
                res << "&rotate_left_value"
            when :rr then
                res << "&rotate_right_value"
            when :== then
                res << "&equal_value_c"
            when :!= then
                res << "&not_equal_value_c"
            when :> then
                res << "&greater_value"
            when :< then
                res << "&lesser_value"
            when :>= then
                res << "&greater_equal_value"
            when :<= then
                res << "&lesser_equal_value"
            else
                raise "Invalid binary operator: #{self.operator}."
            end
            # Close the computation.
            res << ");\n"
            # Restore the value pool state.
            res << (" " * (level*3)) << "RV;\n"

            return res
        end
    end

    ## Extends the Select class with generation of C text.
    class Select

        # # Generates the C text of the equivalent HDLRuby code.
        # # +level+ is the hierachical level of the object.
        # # def to_c(level = 0)
        # def to_c(res,level = 0)
        #     # Gather the possible selection choices.
        #     expressions = self.each_choice.to_a
        #     # Create the resulting string.
        #     # res = "({\n"
        #     res << "({\n"
        #     # Overrides the upper sel, src0, src1, ..., and dst...
        #     # And allocates a new value for dst.
        #     res << (" " * ((level+1)*3))
        #     res << "Value sel;\n"
        #     res << (" " * ((level+1)*3))
        #     res << "Value "
        #     res << expressions.size.times.map do |i| 
        #         "src#{i}"
        #     end.join(",")
        #     res << ";\n"
        #     res << (" " * ((level+1)*3))
        #     res << "Value dst = get_value();\n"
        #     # Save the state of the value pool.
        #     res << (" " * ((level+1)*3))
        #     res << "unsigned int pool_state = get_value_pos();\n"
        #     # Compute the selection.
        #     res << (" " * ((level+1)*3))
        #     # res << "sel = #{self.select.to_c(level+2)};\n"
        #     res << "sel = "
        #     self.select.to_c(res,level+2)
        #     res << ";\n"
        #     # Compute each choice expression.
        #     expressions.each_with_index do |expr,i|
        #         res << (" " * ((level+1)*3))
        #         # res << "src#{i} = #{expr.to_c(level+2)};\n"
        #         res << "src#{i} = "
        #         expr.to_c(res,level+2)
        #         res << ";\n"
        #     end
        #     # Compute the resulting selection.
        #     res << (" " * ((level+1)*3))
        #     res << "select_value(sel,dst,#{expressions.size},"
        #     # res << "#{expressions.size.times.map { |i| "src#{i}" }.join(",")}"
        #     res << expressions.size.times.map { |i| "src#{i}" }.join(",")
        #     res << ");\n"
        #     # Restore the state of the value pool.
        #     res << (" " * ((level+1)*3))
        #     res << "set_value_pos(pool_state);\n"
        #     # Close the computation.
        #     res << (" " * (level*3))
        #     res << "dst; })"
        #     return res
        # end
        # Generates the C text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object.
        def to_c(res,level = 0)
            # Save the value pool state.
            res << (" " * (level*3)) << "PV;\n"
            # Gather the possible selection choices.
            expressions = self.each_choice.to_a
            # Create the resulting string.
            # Compute the selection.
            self.select.to_c(res,level)
            # Compute each choice expression.
            expressions.each_with_index do |expr,i|
                expr.to_c(res,level)
            end
            # Compute the resulting selection.
            res << (" " * (level*3))
            res << "select(#{expressions.size});\n"
            # Restore the value pool state.
            res << (" " * (level*3)) << "RV;\n"
            return res
        end
    end

    ## Extends the Concat class with generation of C text.
    class Concat


        # # Generates the C text for the equivalent HDLRuby code.
        # # +level+ is the hierachical level of the object.
        # def to_c(res,level = 0)
        #     # Gather the content to concat.
        #     expressions = self.each_expression.to_a
        #     # Create the resulting string.
        #     res << "({\n"
        #     # Overrides the upper src0, src1, ..., and dst...
        #     # And allocates a new value for dst.
        #     res << (" " * ((level+1)*3))
        #     res << "Value "
        #     res << expressions.size.times.map do |i| 
        #         "src#{i}"
        #     end.join(",")
        #     res << ";\n"
        #     res << (" " * ((level+1)*3))
        #     res << "Value dst = get_value();\n"
        #     # Save the state of the value pool.
        #     res << (" " * ((level+1)*3))
        #     res << "unsigned int pool_state = get_value_pos();\n"
        #     # Compute each sub expression.
        #     expressions.each_with_index do |expr,i|
        #         res << (" " * ((level+1)*3))
        #         res << "src#{i} = "
        #         expr.to_c_expr(res,level+2)
        #         res << ";\n"
        #     end
        #     # Compute the direction.
        #     # Compute the resulting concatenation.
        #     res << (" " * ((level+1)*3))
        #     res << "concat_value(#{expressions.size},"
        #     res << "#{self.type.direction == :little ? 1 : 0},dst,"
        #     res << expressions.size.times.map { |i| "src#{i}" }.join(",")
        #     res << ");\n"
        #     # Restore the state of the value pool.
        #     res << (" " * ((level+1)*3))
        #     res << "set_value_pos(pool_state);\n"
        #     # Close the computation.
        #     res << (" " * (level*3))
        #     res << "dst; })"
        #     return res
        # end
        # Generates the C text for the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object.
        def to_c(res,level = 0)
            # Save the value pool state.
            res << (" " * (level*3)) << "PV;\n"
            # Gather the content to concat.
            expressions = self.each_expression.to_a
            # Compute each sub expression.
            expressions.each_with_index do |expr,i|
                expr.to_c(res,level+2)
            end
            # Compute the resulting concatenation.
            res << (" " * ((level+1)*3))
            res << "sconcat(#{expressions.size},"
            res << (self.type.direction == :little ? "1" : "0")
            res << ");\n"
            # Restore the value pool state.
            res << (" " * (level*3)) << "RV;\n"
            return res
        end
        alias_method :to_c_expr, :to_c

        # # Generates the C text of expression for the equivalent HDLRuby code.
        # # +level+ is the hierachical level of the object.
        # def to_c_expr(res,level = 0)
        #     # Gather the content to concat.
        #     expressions = self.each_expression.to_a
        #     # Create the resulting string.
        #     res << "({\n"
        #     # Overrides the upper src0, src1, ..., and dst...
        #     # And allocates a new value for dst.
        #     res << (" " * ((level+1)*3))
        #     res << "Value "
        #     res << expressions.size.times.map do |i| 
        #         "src#{i}"
        #     end.join(",")
        #     res << ";\n"
        #     res << (" " * ((level+1)*3))
        #     res << "Value dst = get_value();\n"
        #     # Save the value pool state.
        #     res << (" " * (level*3)) << "SV;\n"
        #     # Compute each sub expression.
        #     expressions.each_with_index do |expr,i|
        #         res << (" " * ((level+1)*3))
        #         res << "src#{i} = "
        #         expr.to_c_expr(res,level+2)
        #         res << ";\n"
        #     end
        #     # Compute the direction.
        #     # Compute the resulting concatenation.
        #     res << (" " * ((level+1)*3))
        #     res << "concat_value(#{expressions.size},"
        #     res << "#{self.type.direction == :little ? 1 : 0},dst,"
        #     res << expressions.size.times.map { |i| "src#{i}" }.join(",")
        #     res << ");\n"
        #     # Save the value pool state.
        #     res << (" " * (level*3)) << "SV;\n"
        #     # Close the computation.
        #     res << (" " * (level*3))
        #     res << "dst; })"
        #     return res
        # end
    end



    ## Extends the Ref class with generation of C text.
    class Ref

        # Generates the C text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object and
        # +left+ tells if it is a left value or not.
        # def to_c(level = 0, left = false)
        def to_c(res,level = 0, left = false)
            # Should never be here.
            raise AnyError, "Internal error: to_c should be implemented in class :#{self.class}"
        end
    end


    ## Extends the RefConcat class with generation of C text.
    class RefConcat

        # Generates the C text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object and
        # +left+ tells if it is a left value or not.
        # def to_c(level = 0, left = false)
        def to_c(res,level = 0, left = false)
            raise "RefConcat cannot be converted to C directly, please use break_concat_assign!."
            # # The resulting string.
            # res = "ref_concat(#{self.each_ref.to_a.size}"
            # self.each_ref do |ref|
            #     res << ",#{ref.to_c(level,left)}"
            # end
            # res << ")"
            # return res
        end

        # Generates the C text for reference as left value to a signal.
        # +level+ is the hierarchical level of the object.
        # def to_c_signal(level = 0)
        def to_c_signal(res,level = 0)
            raise "RefConcat cannot be converted to C directly, please use break_concat_assign!."
            # # The resulting string.
            # res = "sig_concat(#{self.each_ref.to_a.size}"
            # self.each_ref do |ref|
            #     res << ",#{ref.to_c_signal(level)}"
            # end
            # res << ")"
            # return res
        end
    end


    ## Extends the RefIndex class with generation of C text.
    class RefIndex

        # # Generates the C text of the equivalent HDLRuby code.
        # # +level+ is thehierachical level of the object and
        # # +left+ tells if it is a left value or not.
        # # def to_c(level = 0, left = false)
        # def to_c(res,level = 0, left = false)
        #     # res = "({\n"
        #     res << "({\n"
        #     # And allocates a new value for dst.
        #     res << (" " * ((level+1)*3))
        #     res << "Value ref,dst = get_value();\n"
        #     res << (" " * ((level+1)*3))
        #     res << "unsigned long long idx;\n"
        #     # Save the state of the value pool.
        #     res << (" " * ((level+1)*3))
        #     res << "unsigned int pool_state = get_value_pos();\n"
        #     # Compute the reference.
        #     res << (" " * ((level+1)*3))
        #     # res << "ref = #{self.ref.to_c(level+2)};\n"
        #     res << "ref = "
        #     self.ref.to_c(res,level+2)
        #     res << ";\n"
        #     # Compute the index.
        #     res << (" " * ((level+1)*3))
        #     # res << "idx = value2integer(#{self.index.to_c(level+2)});\n"
        #     res << "idx = value2integer("
        #     self.index.to_c(res,level+2)
        #     res << ");\n"
        #     # Make the access.
        #     res << (" " * ((level+1)*3))
        #     # puts "self.type.width=#{self.type.width}"
        #     # res << "dst = read_range(ref,idx,idx,#{self.type.to_c(level)},dst);\n"
        #     res << "dst = read_range(ref,idx,idx,"
        #     # res << self.type.to_c(level)
        #     self.type.to_c(res,level)
        #     res << ",dst);\n"
        #     # Restore the state of the value pool.
        #     res << (" " * ((level+1)*3))
        #     res << "set_value_pos(pool_state);\n"
        #     # Close the computation.
        #     res << (" " * (level*3))
        #     res << "dst; })"
        #     return res
        # end
        # Generates the C text of the equivalent HDLRuby code.
        # +level+ is thehierachical level of the object and
        # +left+ tells if it is a left value or not.
        def to_c(res,level = 0, left = false)
            # Save the value pool state.
            res << (" " * (level*3)) << "PV;\n"
            # Compute the reference.
            self.ref.to_c(res,level)
            # Compute the index.
            self.index.to_c(res,level)
            res << (" " * (level*3))
            # Make the access.
            res << (" " * (level*3))
            if (left) then
                res << "swriteI("
            else
                res << "sreadI("
            end
            self.type.to_c(res,level)
            res << ");\n"
            # Restore the value pool state.
            res << (" " * (level*3)) << "RV;\n"
            return res
        end

        # # Generates the C text for reference as left value to a signal.
        # # +level+ is the hierarchical level of the object.
        # # def to_c_signal(level = 0)
        # def to_c_signal(res,level = 0)
        #     # puts "to_c_signal for RefIndex"
        #     res << "make_ref_rangeS("
        #     self.ref.to_c_signal(res,level)
        #     res << ","
        #     self.type.to_c(res,level)
        #     res << ",value2integer("
        #     self.index.to_c(res,level)
        #     res << "),value2integer("
        #     self.index.to_c(res,level)
        #     res << "))"
        #     return res
        # end
        # Generates the C text for reference as left value to a signal.
        # +level+ is the hierarchical level of the object.
        # def to_c_signal(level = 0)
        def to_c_signal(res,level = 0)
            # puts "to_c_signal for RefIndex"
            res << "make_ref_rangeS("
            self.ref.to_c_signal(res,level)
            res << ","
            self.type.to_c(res,level)
            res << ",value2integer(({\n"
            self.index.to_c(res,level)
            res << " " * ((level+1)*3)
            res << "pop();})"
            res << "),value2integer(({\n"
            self.index.to_c(res,level)
            res << " " * ((level+1)*3)
            res << "pop();})"
            res << "))"
            return res
        end
    end


    ## Extends the RefRange class with generation of C text.
    class RefRange

        # # Generates the C text of the equivalent HDLRuby code.
        # # +level+ is the hierachical level of the object and
        # # +left+ tells if it is a left value or not.
        # # def to_c(level = 0, left = false)
        # def to_c(res,level = 0, left = false)
        #     # Decide if it is a read or a write
        #     command = left ? "write" : "read"
        #     # res = "({\n"
        #     res << "({\n"
        #     # Overrides the upper ref and dst...
        #     # And allocates a new value for dst.
        #     res << (" " * ((level+1)*3))
        #     res << "Value ref,dst = get_value();\n"
        #     res << (" " * ((level+1)*3))
        #     res << "unsigned long long first,last;\n"
        #     # Save the state of the value pool.
        #     res << (" " * ((level+1)*3))
        #     res << "unsigned int pool_state = get_value_pos();\n"
        #     # Compute the reference.
        #     res << (" " * ((level+1)*3))
        #     # res << "ref = #{self.ref.to_c(level+2)};\n"
        #     res << "ref = "
        #     self.ref.to_c(res,level+2)
        #     res << ";\n"
        #     # Compute the range.
        #     res << (" " * ((level+1)*3))
        #     # res << "first = value2integer(#{self.range.first.to_c(level+2)});\n"
        #     res << "first = value2integer("
        #     self.range.first.to_c(res,level+2)
        #     res << ");\n"
        #     res << (" " * ((level+1)*3))
        #     # res << "last = value2integer(#{self.range.last.to_c(level+2)});\n"
        #     res << "last = value2integer("
        #     self.range.last.to_c(res,level+2)
        #     res << ");\n"
        #     # Make the access.
        #     res << (" " * ((level+1)*3))
        #     # puts "#{command}_range with first=#{self.range.first} and last=#{self.range.last}"
        #     # res << "dst = #{command}_range(ref,first,last,#{self.type.base.to_c(level)},dst);\n"
        #     res << "dst = #{command}_range(ref,first,last,"
        #     self.type.base.to_c(res,level)
        #     res << ",dst);\n"
        #     # Restore the state of the value pool.
        #     res << (" " * ((level+1)*3))
        #     res << "set_value_pos(pool_state);\n"
        #     # Close the computation.
        #     res << (" " * (level*3))
        #     res << "dst; })"
        #     return res
        # end
        def to_c(res,level = 0, left = false)
            # Save the value pool state.
            res << (" " * (level*3)) << "PV;\n"
            # Compute the reference.
            self.ref.to_c(res,level)
            # res << (" " * (level*3))
            # Compute the range.
            self.range.first.to_c(res,level)
            self.range.last.to_c(res,level)
            # Make the access.
            res << (" " * (level*3))
            if left then
                res << "swriteR("
            else
                res << "sreadR("
            end
            self.type.base.to_c(res,level)
            res << ");\n"
            # Restore the value pool state.
            res << (" " * (level*3)) << "RV;\n"
            return res
        end

        # # Generates the C text for reference as left value to a signal.
        # # +level+ is the hierarchical level of the object.
        # # def to_c_signal(level = 0)
        # def to_c_signal(res,level = 0)
        #     # return "make_ref_rangeS(#{self.ref.to_c_signal(level)}," +
        #     #     "value2integer(#{self.range.first.to_c(level)}),value2integer(#{self.range.last.to_c(level)}))"
        #     res << "make_ref_rangeS("
        #     self.ref.to_c_signal(res,level)
        #     res << ",value2integer("
        #     self.range.first.to_c(res,level)
        #     res << "),value2integer("
        #     self.range.last.to_c(res,level)
        #     res << "))"
        #     return res
        # end
        # Generates the C text for reference as left value to a signal.
        # +level+ is the hierarchical level of the object.
        # def to_c_signal(level = 0)
        def to_c_signal(res,level = 0)
            res << "make_ref_rangeS("
            self.ref.to_c_signal(res,level)
            res << ","
            self.type.base.to_c(res,level)
            res << ",value2integer(({\n"
            self.range.first.to_c(res,level)
            res << " " * ((level+1)*3)
            res << "pop();})"
            res << "),value2integer(({\n"
            self.range.last.to_c(res,level)
            res << " " * ((level+1)*3)
            res << "pop();})"
            res << "))"
            return res
        end
    end


    ## Extends the RefName class with generation of C text.
    class RefName

        # Generates the C text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object and
        # +left+ tells if it is a left value or not.
        # def to_c(level = 0, left = false)
        def to_c(res,level = 0, left = false)
            # # puts "RefName to_c for #{self.name}"
            # self.resolve.to_c_signal(res,level+1)
            # res << "->" << (left ? "f_value" : "c_value")
            # return res
            # puts "RefName to_c for #{self.name}"
            res << (" " * (level*3))
            # res << "d="
            res << "push("
            self.resolve.to_c_signal(res,level+1)
            res << "->" << (left ? "f_value" : "c_value")
            # res << ";\n"
            res << ");\n"
            return res
        end

        # Generates the C text for reference as left value to a signal.
        # +level+ is the hierarchical level of the object.
        # def to_c_signal(level = 0)
        def to_c_signal(res,level = 0)
            # puts "to_c_signal with self=#{self.name}, resolve=#{self.resolve}"
            # return "#{self.resolve.to_c_signal(level+1)}"
            self.resolve.to_c_signal(res,level+1)
            return res
        end
    end


    ## Extends the RefThis class with generation of C text.
    class RefThis 
        # Generates the C text of the equivalent HDLRuby code.
        # +level+ is the hierachical level of the object and
        # +left+ tells if it is a left value or not.
        # def to_c(level = 0, left = false)
        def to_c(res,level = 0, left = false)
            # return "this()"
            res << "this()"
            return res
        end

        # Generates the C text for reference as left value to a signal.
        # +level+ is the hierarchical level of the object.
        # def to_c_signal(level = 0)
        def to_c_signal(res,level = 0)
            # return "this()"
            res << "this()"
            return res
        end
    end


end
