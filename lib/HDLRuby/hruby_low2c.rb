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

        ## Tells if a +name+ is C-compatible.
        #  To ensure compatibile, assume all the character must have the
        #  same case.
        def self.c_name?(name)
            name = name.to_s
            # First: character check.
            return false unless name =~ /^[a-zA-Z]|([a-zA-Z][a-zA-Z_0-9]*[a-zA-Z0-9])$/
            return true
        end

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

        ## Generates a uniq name for an object.
        def self.obj_name(obj)
            if obj.respond_to?(:name) then
                return Low2C.c_name(obj.name.to_s) +
                       Low2C.c_name(obj.object_id.to_s)
            else
                return "_" + Low2C.c_name(obj.object_id.to_s)
            end
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
        def self.main(top,objs,hnames)
            res = Low2C.includes(*hnames)
            res << "int main(int argc, char* argv[]) {\n"
            # Build the objects.
            objs.each { |obj| res << "   #{Low2C.make_name(obj)}();\n" }
            # Starts the simulation.
            res << "   hruby_sim_core(-1);\n"
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
            return "hw_wait(#{obj.delay.to_c(level+1)}," + 
                   "#{Low2C.behavior_access(obj)});\n" 
        end
    end


    ## Extends the SystemT class with generation of HDLRuby::High C text.
    class SystemT

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object and +hnames+
        # is the list of extra h files to include.
        def to_c(level = 0, *hnames)
            # The header
            res = Low2C.includes(*hnames)

            # Declare the global variable holding the system.
            res << "SystemT #{Low2C.obj_name(self)};\n\n"

            # Generate the signals of the system.
            self.each_signal { |signal| res << signal.to_c(level) }

            # Generate the code for all the blocks included in the system.
            self.scope.each_scope_deep do |scope|
                scope.each_behavior do |behavior|
                    res << behavior.block.to_c_code(level)
                end
            end

            # Generate the code for all the values included in the system.
            self.each_signal do |signal|
                # res << signal.value.to_c_make(level) if signal.value
                signal.value.each_node_deep do |node|
                    res << node.to_c_make(level) if node.respond_to?(:to_c_make)
                end if signal.value
            end
            self.scope.each_scope_deep do |scope|
                scope.each_inner do |signal|
                    # res << signal.value.to_c_make(level) if signal.value
                    signal.value.each_node_deep do |node|
                        res << node.to_c_make(level) if node.respond_to?(:to_c_make)
                    end if signal.value
                end
            end
            self.scope.each_block_deep do |block|
                block.each_inner do |signal|
                    # res << signal.value.to_c_make(level) if signal.value
                    signal.value.each_node_deep do |node|
                        res << node.to_c_make(level) if node.respond_to?(:to_c_make)
                    end if signal.value
                end
            end
            self.scope.each_node_deep do |node|
                res << node.to_c_make(level) if node.is_a?(Value)
            end

            # Generate the scope.
            res << self.scope.to_c(level)

            # Generate the entity
            res << "SystemT #{Low2C.make_name(self)}() {\n"
            # Creates the structure.
            res << " " * (level+1)*3
            res << "SystemT systemT = malloc(sizeof(SystemTS));\n"
            res << " " * (level+1)*3
            res << "systemT->kind = SYSTEMT;\n";

            # Sets the global variable of the system.
            res << "\n"
            res << " " * (level+1)*3
            res << "#{Low2C.obj_name(self)} = systemT;\n"

            # Set the owner if any.
            if @owner then
                res << " " * (level+1)*3
                res << "systemT->owner = (Object)" + 
                       "#{Low2C.obj_name(@owner)};\n"
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
            res << "systemT->inputs = calloc(sizeof(SignalI)," +
                   "systemT->num_inputs);\n"
            self.each_input.with_index do |input,i|
                res << " " * (level+1)*3
                res << "systemT->inputs[#{i}] = " +
                       "#{Low2C.make_name(input)}();\n"
            end
            # Outputs
            res << " " * (level+1)*3
            res << "systemT->num_outputs = #{self.each_output.to_a.size};\n"
            res << " " * (level+1)*3
            res << "systemT->outputs = calloc(sizeof(SignalI)," +
                   "systemT->num_outputs);\n"
            self.each_output.with_index do |output,i|
                res << " " * (level+1)*3
                res << "systemT->outputs[#{i}] = " +
                       "#{Low2C.make_name(output)}();\n"
            end
            # Inouts
            res << " " * (level+1)*3
            res << "systemT->num_inouts = #{self.each_inout.to_a.size};\n"
            res << " " * (level+1)*3
            res << "systemT->inouts = calloc(sizeof(SignalI)," +
                   "systemT->num_inouts);\n"
            self.each_inout.with_index do |inout,i|
                res << " " * (level+1)*3
                res << "systemT->inouts[#{i}] = " +
                       "#{Low2C.make_name(inout)}();\n"
            end

            # Adds the scope.
            res << "\n"
            res << " " * (level+1)*3
            res << "systemT->scope = #{Low2C.make_name(self.scope)}();\n"

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
        def to_c_code(level)
            res << " " * (level*3)
            res << "#{Low2C.code_name(self)}() {"
            # Launch the execution of all the time behaviors of the
            # system.
            self.each_behavior_deep do |behavior|
                if behavior.is_a?(HDLRuby::Low::TimeBehavior) then
                    res << " " * (level+1)*3
                    res << "#{Low2C.code_name(behavior.block)}();\n"
                end
            end
            # Close the execution procedure.
            res << " " * level*3
            res << "}\n"
            # Return the result.
            return res
        end


        ## Generates the content of the h file.
        def to_ch
            res = ""
            # Declare the global variable holding the signal.
            res << "extern SystemT #{Low2C.obj_name(self)};\n\n"

            # Generate the access to the function making the systemT. */
            res << "extern SystemT #{Low2C.make_name(self)}();\n\n"

            # Generate the accesses to the values.
            self.each_signal do |signal|
                # res << signal.value.to_ch if signal.value
                if signal.value then
                    signal.value.each_node_deep do |node|
                        res << node.to_ch if node.is_a?(Value)
                    end
                end
            end
            self.scope.each_scope_deep do |scope|
                scope.each_inner do |signal|
                    # res << signal.value.to_ch if signal.value
                    if signal.value then
                        signal.value.each_node_deep do |node|
                            res << node.to_ch if node.is_a?(Value)
                        end
                    end
                end
            end
            self.scope.each_block_deep do |block|
                block.each_inner do |signal|
                    res << signal.value.to_ch if signal.value
                end
                block.each_node_deep do |node|
                    res << node.to_ch if node.is_a?(Value)
                end
            end

            # Generate the accesses to the ports.
            self.each_input  { |input|  res << input.to_ch }
            self.each_output { |output| res << output.to_ch }
            self.each_inout  { |inout|  res << inout.to_ch }

            # Generate the accesses to the scope.
            res << self.scope.to_ch << "\n"


            return res;
        end

    end


    ## Extends the Scope class with generation of HDLRuby::High C text.
    class Scope

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_c(level = 0)
            # The resulting string.
            res = ""

            # Declare the global variable holding the scope.
            res << "Scope #{Low2C.obj_name(self)};\n\n"

            # Generate the code makeing the complex sub components.

            # Generates the code for making signals if any.
            self.each_signal { |signal| res << signal.to_c(level) }
            # Generates the code for making signals if any.
            self.each_systemI { |systemI| res << systemI.to_c(level) }
            # Generates the code for making sub scopes if any.
            self.each_scope { |scope| res << scope.to_c(level) }
            # Generate the code for making the behaviors.
            self.each_behavior { |behavior| res << behavior.to_c(level) }
            # Generate the code for making the non-HDLRuby codes.
            self.each_code { |code| res << code.to_c(level) }

            # Generate the code of the scope.
            
            # The header of the scope.
            res << " " * level*3
            res << "Scope #{Low2C.make_name(self)}() {\n"
            res << " " * (level+1)*3
            res << "Scope scope = malloc(sizeof(ScopeS));\n"
            res << " " * (level+1)*3
            res << "scope->kind = SCOPE;\n";

            # Sets the global variable of the scope.
            res << "\n"
            res << " " * (level+1)*3
            res << "#{Low2C.obj_name(self)} = scope;\n"

            # Set the owner if any.
            if self.parent then
                res << " " * (level+1)*3
                res << "scope->owner = (Object)" + 
                       "#{Low2C.obj_name(self.parent)};\n"
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
                res << "scope->systemIs[#{i}] = " +
                       "#{Low2C.make_name(systemI)}();\n"
            end

            # Add the inner signals declaration.
            res << " " * (level+1)*3
            res << "scope->num_inners = #{self.each_inner.to_a.size};\n"
            res << " " * (level+1)*3
            res << "scope->inners = calloc(sizeof(SignalI)," +
                   "scope->num_inners);\n"
            self.each_inner.with_index do |inner,i|
                res << " " * (level+1)*3
                res << "scope->inners[#{i}] = " +
                       "#{Low2C.make_name(inner)}();\n"
            end

            # Add the sub scopes.
            res << " " * (level+1)*3
            res << "scope->num_scopes = #{self.each_scope.to_a.size};\n"
            res << " " * (level+1)*3
            res << "scope->scopes = calloc(sizeof(Scope)," +
                   "scope->num_scopes);\n"
            self.each_scope.with_index do |scope,i|
                res << " " * (level+1)*3
                res << "scope->scopes[#{i}] = " +
                       "#{Low2C.make_name(scope)}();\n"
            end

            # Add the behaviors.
            res << " " * (level+1)*3
            res << "scope->num_behaviors = #{self.each_behavior.to_a.size};\n"
            res << " " * (level+1)*3
            res << "scope->behaviors = calloc(sizeof(Behavior)," +
                   "scope->num_behaviors);\n"
            self.each_behavior.with_index do |behavior,i|
                res << " " * (level+1)*3
                res << "scope->behaviors[#{i}] = " +
                       "#{Low2C.make_name(behavior)}();\n"
            end

            # Add the non-HDLRuby codes.
            res << " " * (level+1)*3
            res << "scope->num_codes = #{self.each_code.to_a.size};\n"
            res << " " * (level+1)*3
            res << "scope->codes = calloc(sizeof(Code)," +
                   "scope->num_codes);\n"
            self.each_code.with_index do |code,i|
                res << " " * (level+1)*3
                res << "scope->codes[#{i}] = " +
                       "#{Low2C.make_name(code)}();\n"
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
        def to_ch
            res = ""
            # Declare the global variable holding the signal.
            res << "extern Scope #{Low2C.obj_name(self)};\n\n"

            # Generate the access to the function making the scope.
            res << "extern Scope #{Low2C.make_name(self)}();\n\n"

            # Generate the accesses to the system instances.
            self.each_systemI { |systemI| res << systemI.to_ch }

            # Generate the accesses to the signals.
            self.each_inner { |inner| res << inner.to_ch }

            # Generate the access to the sub scopes.
            self.each_scope { |scope| res << scope.to_ch }

            # Generate the access to the behaviors.
            self.each_behavior { |behavior| res << behavior.to_ch }

            # Generate the access to the non-HDLRuby code.
            self.each_behavior { |code| res << code.to_ch }

            return res;
        end
    end


    ## Extends the Type class with generation of HDLRuby::High text.
    class Type

        # Generates the C text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_c(level = 0)
            # return Low2C.c_name(self.name)
            # return Low2C.type_name(Bit) + "()"
            if self.name == :bit || self.name == :unsigned then
                return "get_type_bit()"
            elsif self.name == :signed then
                return "get_type_signed()"
            else
                raise "Unknown type: #{self.name}"
            end
        end
    end

    ## Extends the TypeDef class with generation of HDLRuby::High text.
    class TypeDef

        # Generates the C text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_c(level = 0)
            # Simply use the name of the type.
            return Low2C.type_name(self.name) + "()"
        end
    end

    ## Extends the TypeVector class with generation of HDLRuby::High text.
    class TypeVector

        # Generates the C text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_c(level = 0)
            # The resulting string.
            return "get_type_vector(#{self.base.to_c(level+1)}," +
                   "#{self.size})"
        end
    end

    ## Extends the TypeTuple class with generation of HDLRuby::High text.
    class TypeTuple

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        #
        # NOTE: type tuples are converted to bit vector of their contents.
        def to_c(level = 0)
            return "get_type_tuple(#{self.each.join(",") do |type|
               type.to_c(level+1)
            end})"
        end
    end


    ## Extends the TypeStruct class with generation of HDLRuby::High text.
    class TypeStruct

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_c(level = 0)
            return "get_type_struct(#{self.each.join(",") do |key,type|
                "\"#{key.to_s}\",#{type.to_c(level+1)}"
            end})"
        end
    end


    ## Extends the Behavior class with generation of HDLRuby::High text.
    class Behavior

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object and
        # +time+ is a flag telling if the behavior is timed or not.
        def to_c(level = 0, time = false)
            # puts "For behavior: #{self}"
            # The resulting string.
            res = ""

            # Declare the global variable holding the behavior.
            res << "Behavior #{Low2C.obj_name(self)};\n\n"

            # Generate the code of the behavior.
            
            # The header of the behavior.
            res << " " * level*3
            res << "Behavior #{Low2C.make_name(self)}() {\n"
            res << " " * (level+1)*3

            # Allocate the behavior.
            res << "Behavior behavior = malloc(sizeof(BehaviorS));\n"
            res << " " * (level+1)*3
            res << "behavior->kind = BEHAVIOR;\n";

            # Sets the global variable of the behavior.
            res << "\n"
            res << " " * (level+1)*3
            res << "#{Low2C.obj_name(self)} = behavior;\n"

            # Register it as a time behavior if it is one of them. */
            if time then
                res << " " * (level+1)*3
                res << "register_timed_behavior(behavior);\n"
            end

            # Set the owner if any.
            if self.parent then
                res << " " * (level+1)*3
                res << "behavior->owner = (Object)" + 
                       "#{Low2C.obj_name(self.parent)};\n"
            else
                res << "behavior->owner = NULL;\n"
            end

            # Tells if the behavior is timed or not.
            res << " " * (level+1)*3
            res << "behavior->timed = #{time ? 1 : 0};\n"

            # Add the events and register the behavior as activable
            # on them.
            res << " " * (level+1)*3
            res << "behavior->num_events = #{self.each_event.to_a.size};\n"
            res << " " * (level+1)*3
            res << "behavior->events = calloc(sizeof(Event)," +
                   "behavior->num_events);\n"
            # Is it a clocked behavior?
            events = self.each_event.to_a
            if events.empty? then
                # No events, this is not a clock behavior.
                # Generate the events list from the right values.
                # First get the references.
                refs = self.block.each_node_deep.select do |node|
                    node.is_a?(RefName) && !node.leftvalue? && 
                        !node.parent.is_a?(RefName) 
                end.to_a
                # Keep only one ref per signal.
                refs.uniq! { |node| node.name }
                # Generate the event.
                events = refs.map {|ref| Event.new(:anyedge,ref.clone) }
                # Add them to the behavior for further processing.
                events.each {|event| self.add_event(event) }
            end
            # Finaly can process the events.
            events.each_with_index do |event,i|
                # puts "for event=#{event}"
                # Add the event.
                res << " " * (level+1)*3
                res << "behavior->events[#{i}] = #{event.to_c};\n"
                
                # Register the behavior as activable on this event.
                # Select the active field.
                field = "any"
                field = "pos" if event.type == :posedge
                field = "neg" if event.type == :negedge
                # Get the target signal access
                sigad = event.ref.resolve.to_c_signal
                # Add the behavior to the relevant field.
                res << " " * (level+1)*3
                res << "#{sigad}->num_#{field} += 1;\n"
                res << " " * (level+1)*3
                res << "#{sigad}->#{field} = realloc(#{sigad}->#{field}," +
                       "#{sigad}->num_#{field}*sizeof(Object));\n"
                res << "#{sigad}->#{field}[#{sigad}->num_#{field}-1] = " +
                       "(Object)behavior;\n"
            end

            # Adds the block.
            res << " " * (level+1)*3
            res << "behavior->block = #{Low2C.make_name(self.block)}();\n"

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
        def to_ch
            res = ""
            # Declare the global variable holding the signal.
            res << "extern Behavior #{Low2C.obj_name(self)};\n\n"

            # Generate the access to the function making the behavior.
            res << "extern Behavior #{Low2C.make_name(self)}();\n\n"

            # Generate the accesses to the block of the behavior.
            res << self.block.to_ch

            return res;
        end
    end

    ## Extends the TimeBehavior class with generation of HDLRuby::High text.
    class TimeBehavior

        # Generates the C text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_c(level = 0)
            super(level,true)
        end
    end


    ## Extends the Event class with generation of HDLRuby::High text.
    class Event

        # Generates the C text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_c(level = 0)
            edge = "ANYEDGE"
            edge = "POSEDGE" if self.type == :posedge
            edge = "NEGEDGE" if self.type == :negedge
            return "make_event(#{edge}," +
                   "#{self.ref.resolve.to_c_signal(level+1)})"
        end
    end


    ## Extends the SignalI class with generation of HDLRuby::High text.
    class SignalI

        ## Generates the C text for an access to the signal.
        #  +level+ is the hierachical level of the object.
        def to_c_signal(level = 0)
            res = Low2C.obj_name(self)
            # Accumulate the names of each parent until there is no one left.
            obj = self.parent
            while(obj) do
                res << "_" << Low2C.obj_name(obj)
                obj = obj.parent
            end
            return res
        end

        ## Generates the C text of the equivalent HDLRuby::High code.
        #  +level+ is the hierachical level of the object.
        def to_c(level = 0)
            # The resulting string.
            res = ""

            # Declare the global variable holding the signal.
            res << "SignalI #{self.to_c_signal(level+1)};\n\n"

            # The header of the signal generation.
            res << " " * level*3
            res << "SignalI #{Low2C.make_name(self)}() {\n"
            res << " " * (level+1)*3
            res << "SignalI signalI = malloc(sizeof(SignalIS));\n"
            res << " " * (level+1)*3
            res << "signalI->kind = SIGNALI;\n";

            # Sets the global variable of the signal.
            res << "\n"
            res << " " * (level+1)*3
            res << "#{self.to_c_signal(level+1)} = signalI;\n"

            # Set the owner if any.
            if self.parent then
                res << " " * (level+1)*3
                res << "signalI->owner = (Object)" + 
                       "#{Low2C.obj_name(self.parent)};\n"
            else
                res << "signalI->owner = NULL;\n"
            end

            # Set the name
            res << " " * (level+1)*3
            res << "signalI->name = \"#{self.name}\";\n"
            # Set the type.
            res << " " * (level+1)*3
            res << "signalI->type = #{self.type.to_c(level+2)};\n"
            # Set the current and the next value.
            res << " " * (level+1)*3
            res << "signalI->c_value = make_value(signalI->type);\n"
            res << " " * (level+1)*3
            res << "signalI->c_value->signal = signalI;\n"
            res << " " * (level+1)*3
            res << "signalI->f_value = make_value(signalI->type);\n"
            res << " " * (level+1)*3
            res << "signalI->f_value->signal = signalI;\n"
            if self.value then
                # There is an initial value.
                res << " " * (level+1)*3
                res << "copy_value(#{self.value.to_c(level+2)}," +
                       "signalI->c_value;\n"
            end

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
        def to_ch
            res = ""
            # Declare the global variable holding the signal.
            res << "extern SignalI #{self.to_c_signal()};\n\n"

            # Generate the access to the function making the behavior.
            res << "extern SignalI #{Low2C.make_name(self)}();\n\n"

            return res;
        end
    end


    ## Extends the SystemI class with generation of HDLRuby::High text.
    class SystemI

        ## Generates the C text of the equivalent HDLRuby::High code.
        #  +level+ is the hierachical level of the object.
        def to_c(level = 0)
            # The resulting string.
            res = ""

            # Declare the global variable holding the signal.
            res << "SystemI #{Low2C.obj_name(self)};\n\n"

            # The header of the signal generation.
            res << " " * level*3
            res << "SystemI #{Low2C.make_name(self)}() {\n"
            res << " " * (level+1)*3
            res << "SystemI systemI = malloc(sizeof(SystemIS));\n"
            res << " " * (level+1)*3
            res << "systemI->kind = SYSTEMI;\n";

            # Sets the global variable of the system instance.
            res << "\n"
            res << " " * (level+1)*3
            res << "#{Low2C.obj_name(self)} = systemI;\n"

            # Set the owner if any.
            if self.parent then
                res << " " * (level+1)*3
                res << "systemI->owner = (Object)" + 
                       "#{Low2C.obj_name(self.parent)};\n"
            else
                res << "systemI->owner = NULL;\n"
            end

            # Set the name
            res << " " * (level+1)*3
            res << "systemI->name = \"#{self.name}\";\n"
            # Set the type.
            res << " " * (level+1)*3
            res << "systemI->system = #{Low2C.obj_name(self.systemT)};\n"

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
        def to_ch
            res = ""
            # Declare the global variable holding the signal.
            res << "extern SystemI #{Low2C.obj_name(self)};\n\n"

            # Generate the access to the function making the systemT. */
            res << "extern SystemI #{Low2C.make_name(self)}();\n\n"

            return res
        end
    end


    # Extend the Chunk cass with generation of text code.
    class HDLRuby::Low::Chunk

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_c(level = 0)
            res = " " * level
            res << self.each_lump.map do |lump|
                if !lump.is_a?(String) then
                    lump.respond_to?(:to_c) ? lump.to_c(level+1) : lump.to_s
                else
                    lump
                end
            end.join
            return res
        end
    end


    ## Extends the SystemI class with generation of HDLRuby::High text.
    class Code
        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_c(level = 0)
            # puts "For behavior: #{self}"
            # The resulting string.
            res = ""

            # Declare the global variable holding the behavior.
            res << "Code #{Low2C.obj_name(self)};\n\n"

            # Generate the code of the behavior.
            
            # The header of the behavior.
            res << " " * level*3
            res << "Code #{Low2C.make_name(self)}() {\n"
            res << " " * (level+1)*3

            # Allocate the code.
            res << "Code code = malloc(sizeof(CodeS));\n"
            res << " " * (level+1)*3
            res << "code->kind = CODE;\n";

            # Sets the global variable of the code.
            res << "\n"
            res << " " * (level+1)*3
            res << "#{Low2C.obj_name(self)} = code;\n"

            # Set the owner if any.
            if self.parent then
                res << " " * (level+1)*3
                res << "code->owner = (Object)" + 
                       "#{Low2C.obj_name(self.parent)};\n"
            else
                res << "code->owner = NULL;\n"
            end

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
                res << "code->events[#{i}] = #{event.to_c};\n"
                
                # Register the behavior as activable on this event.
                # Select the active field.
                field = "any"
                field = "pos" if event.type == :posedge
                field = "neg" if event.type == :negedge
                # Get the target signal access
                sigad = event.ref.resolve.to_c_signal
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
            res << "code->function = &#{function.to_c};\n"

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
        def to_ch
            res = ""
            # Declare the global variable holding the signal.
            res << "extern Behavior #{Low2C.obj_name(self)};\n\n"

            # Generate the access to the function making the behavior.
            res << "extern Behavior #{Low2C.make_name(self)}();\n\n"

            # Generate the accesses to the block of the behavior.
            res << self.block.to_ch

            return res;
        end
    end


    ## Extends the Statement class with generation of HDLRuby::High text.
    class Statement

        # Generates the C text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_c(level = 0)
            # Should never be here.
            raise AnyError, "Internal error: to_c should be implemented in class :#{self.class}"
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
    end

    ## Extends the Transmit class with generation of HDLRuby::High text.
    class Transmit

        # Generates the C text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_c(level = 0)
            # Perform the copy and the touching only if the new content
            # is different.
            res = " " * level*3
            if (self.left.is_a?(RefName)) then
                # Direct assignment to a signal, simple transmission.
                res << "transmit_to_signal(#{self.right.to_c(level)},"+
                    "#{self.left.to_c_signal(level)});\n"
            else
                # Assignment inside a signal (RefIndex or RefRange).
                res << "transmit_to_signal_range(#{self.right.to_c(level)},"+
                    "#{self.left.to_c_signal(level)});\n"
            end
            return res
        end
    end
    
    ## Extends the If class with generation of HDLRuby::High text.
    class If

        # Generates the C text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_c(level = 0)
            # The result string.
            res = " " * level*3
            # Generate the test.
            res << "if (" << self.condition.to_c(level+1) << ") {\n"
            # Generate the yes part.
            res << self.yes.to_c(level+1)
            res << " " * level*3
            res << "}\n"
            # Generate the alternate if parts.
            self.each_noif do |cond,stmnt|
                res << " " * level*3
                res << "else if (" << cond.to_c(level+1) << ") {\n"
                res << stmnt.to_c(level+1)
                res << " " * level*3
                res << "}\n"
            end
            # Generate the no part if any.
            if self.no then
                res << " " * level*3
                res << "else {\n" << self.no.to_c(level+1)
                res << " " * level*3
                res << "}\n"
            end
            # Return the result.
            return res
        end
    end

    ## Extends the When class with generation of HDLRuby::High text.
    class When

        # Generates the C text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_c(level = 0)
            # The result string.
            res = " " * level*3
            # Generate the match.
            res << "case " << self.match.to_c(level+1) << ": {\n"
            # Generate the statement.
            res << self.statement.to_c(level+1)
            # Adds a break
            res << " " * (level+1)*3 << "break;\n"
            res << " " * level*3 << "}\n"
            # Returns the result.
            return res
        end

        # Adds the c code of the blocks to +res+ at +level+
        def add_blocks_code(res,level)
            self.statement.add_blocks_code(res,level)
        end
    end

    ## Extends the Case class with generation of HDLRuby::High text.
    class Case

        # Generates the text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_c(level = 0)
            # The result string.
            # res = " " * level*3
            # # Generate the test.
            # res << "switch(value2int(" << self.value.to_c(level) << ")) {\n"
            # # Generate the whens.
            # self.each_when do |w|
            #     res << w.to_c(level+1)
            # end
            # # Generate the default if any.
            # if self.default then
            #     res << " " * (level+1)*3
            #     res << "default:\n"
            #     res << self.default.to_c(level+2)
            # end
            # # Close the case.
            # res << " " * level*3
            # res << "};\n"
            res = ""
            # Generate the case as a succession of if statements.
            first = true
            self.each_when do |w|
                res << " " * level*3
                if first then
                    first = false
                else
                    res << "else "
                end
                res << "if (value2int(" << self.value.to_c(level) << ") == "
                res << "value2int(" << w.match.to_c(level) << ")) {\n"
                res << w.statement.to_c(level+1)
                res << " " * level*3
                res << "}\n"
            end
            if self.default then
                res << " " * level*3
                res << "else {\n"
                res << self.default.to_c(level+1)
                res << " " * level*3
                res << "}\n"
            end
            # Return the resulting string.
            return res
        end
    end


    ## Extends the Delay class with generation of HDLRuby::High text.
    class Delay

        # Generates the C text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_c(level = 0)
            return "make_delay(#{self.value.to_s}," +
                   "#{Low2C.unit_name(self.unit)})"
        end
    end


    ## Extends the TimeWait class with generation of HDLRuby::High text.
    class TimeWait

        # Generates the C text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_c(level = 0)
            # The resulting string.
            res = " " * level*3
            # Generate the wait.
            res << "hw_wait(#{self.delay.to_c(level+1)}," +
                "#{Low2C.behavior_access(self)});\n"
            # Return the resulting string.
            return res
        end
    end

    ## Extends the TimeRepeat class with generation of HDLRuby::High text.
    class TimeRepeat

        # Generates the C text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_c(level = 0)
            # The resulting string.
            res = " " * level*3
            # Generate an infinite loop executing the block and waiting.
            res << "for(;;) {\n"
            res << "#{self.to_c(level+1)}\n"
            res = " " * (level+1)*3
            res << Low2C.wait_code(self,level)
            # Return the resulting string.
            return res
        end
    end

    ## Extends the Block class with generation of HDLRuby::High text.
    class Block

        # Adds the c code of the blocks to +res+ at +level+
        def add_blocks_code(res,level)
            res << self.to_c_code(level)
        end

        # Generates the C text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_c_code(level = 0)
            # The resulting string.
            res = ""
            # puts "generating self=#{self.object_id}"

            # Declare the global variable holding the block.
            res << "Block #{Low2C.obj_name(self)};\n\n"

            # Generate the c code of the sub blocks if any.
            self.each_statement do |stmnt|
                stmnt.add_blocks_code(res,level)
            end

            # Generate the execution function.
            res << " " * level*3
            res << "void #{Low2C.code_name(self)}() {\n"
            # Generate the statements.
            self.each_statement do |stmnt|
                res << stmnt.to_c(level+1)
            end
            # Close the execution function.
            res << " " * level*3
            res << "}\n\n"


            # Generate the signals.
            self.each_signal { |signal| res << signal.to_c(level) }

            # The header of the block.
            res << " " * level*3
            res << "Block #{Low2C.make_name(self)}() {\n"
            res << " " * (level+1)*3
            res << "Block block = malloc(sizeof(BlockS));\n"
            res << " " * (level+1)*3
            res << "block->kind = BLOCK;\n";

            # Sets the global variable of the block.
            res << "\n"
            res << " " * (level+1)*3
            res << "#{Low2C.obj_name(self)} = block;\n"

            # Set the owner if any.
            if self.parent then
                # Look for a block or behavior parent.
                true_parent = self.parent
                until true_parent.is_a?(Block) || true_parent.is_a?(Behavior)
                       true_parent = true_parent.parent
                end
                # Set it as the real parent.
                res << " " * (level+1)*3
                res << "block->owner = (Object)" + 
                       "#{Low2C.obj_name(true_parent)};\n"
            else
                res << "block->owner = NULL;\n"
            end

            # Add the inner signals declaration.
            res << " " * (level+1)*3
            res << "block->num_inners = #{self.each_inner.to_a.size};\n"
            res << " " * (level+1)*3
            res << "block->inners = calloc(sizeof(SignalI)," +
                   "block->num_inners);\n"
            self.each_inner.with_index do |inner,i|
                res << " " * (level+1)*3
                res << "block->inners[#{i}] = " +
                       "#{Low2C.make_name(inner)}();\n"
            end

            # Sets the execution function.
            res << " " * (level+1)*3
            res << "block->function = &#{Low2C.code_name(self)};\n"

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
        # HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_c(level = 0)
            res = " " * (level)
            res << "#{Low2C.code_name(self)}();\n"
            return res
        end

        ## Generates the content of the h file.
        def to_ch
            res = ""
            # Declare the global variable holding the block.
            res << "extern Block #{Low2C.obj_name(self)};\n\n"

            # Generate the access to the function making the block. */
            res << "extern Block #{Low2C.make_name(self)}();\n\n"

            # Generate the accesses to the ports.
            self.each_inner  { |inner|  res << inner.to_ch }

            return res
        end
    end


    ## Extends the Block class with generation of HDLRuby::High text.
    class TimeBlock
        # TimeBlock is identical to Block in C
    end


    ## Extends the Connection class with generation of HDLRuby::High text.
    class Connection
        # Nothing required, Transmit is generated identically.
    end


    ## Extends the Expression class with generation of HDLRuby::High text.
    class Expression

        # Generates the C text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_c(level = 0)
            # Should never be here.
            raise AnyError, "Internal error: to_c should be implemented in class :#{self.class}"
        end
    end


    ## Extends the Value class with generation of HDLRuby::High text.
    class Value

        ## Generates the C text for an access to the value.
        #  +level+ is the hierachical level of the object.
        def to_c(level = 0)
            return "#{Low2C.make_name(self)}()"
        end
    
        ## Generates the content of the h file.
        def to_ch
            res = ""
            return "extern Value #{Low2C.make_name(self)}();"
        end

        # Generates the text of the equivalent c.
        # +level+ is the hierachical level of the object.
        def to_c_make(level = 0)
            # The resulting string.
            res = ""

            # The header of the value generation.
            res << " " * level*3
            res << "Value #{Low2C.make_name(self)}() {\n"

            # Declares the data.
            # Create the bit string.
            str = self.content.is_a?(BitString) ?
                self.content.to_s : self.content.to_s(2).rjust(32,"0")
            # Sign extend.
            str = str.rjust(self.type.width, self.type.signed ? str[-1] : "0")
            # Is it a fully defined number?
            if str =~ /^[01]+$/ then
                # Yes, generate a numeral value.
                res << " " * (level+1)*3
                res << "static unsigned int data[] = { "
                res << str.scan(/.{1,#{Low2C.int_width}}/m).map do |sub|
                    sub.to_i(2).to_s + "U"
                end.join(",")
                res << " };\n"
                # Create the value.
                res << " " * (level+1)*3
                res << "return make_set_value(#{self.type.to_c(level+1)},1," +
                       "&data);\n" 
            else
                # No, generate a bit string value.
                res << " " * (level+1)*3
                res << "static unsigned char data[] = \"#{str}\";\n"
                # Create the value.
                res << " " * (level+1)*3
                res << "return make_set_value(#{self.type.to_c(level+1)},0," +
                       "&data);\n" 
            end

            # Close the value.
            res << " " * level*3
            res << "}\n\n"
            # Return the result.
            return res
        end
    end

    ## Extends the Cast class with generation of HDLRuby::High text.
    class Cast

        # Generates the C text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_c(level = 0)
            return "cast_value(#{self.type.to_c(level+1)}," +
                   "#{self.child.to_c(level+1)})"
        end
    end

    ## Extends the Operation class with generation of HDLRuby::High text.
    class Operation

        # Generates the C text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_c(level = 0)
            # Should never be here.
            raise AnyError, "Internal error: to_c should be implemented in class :#{self.class}"
        end
    end

    ## Extends the Unary class with generation of HDLRuby::High text.
    class Unary

        # # Generates the C text of the equivalent HDLRuby::High code.
        # # +level+ is the hierachical level of the object.
        # def to_c(level = 0)
        #     case self.operator
        #     when :~ then
        #         return "not_value(#{self.child.to_c(level)})"
        #     when :-@ then
        #         return "neg_value(#{self.child.to_c(level)})"
        #     when :+@ then
        #         return self.child.to_c(level)
        #     else
        #         raise "Invalid unary operator: #{self.operator}."
        #     end
        # end

        # Generates the C text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_c(level = 0)
            # res = " " * (level*3)
            res = "({\n"
            # Overrides the upper src0 and dst...
            res << (" " * ((level+1)*3))
            res << "Value src0, dst;\n"
            if (self.operator != :+@) then
                # And allocates a new value for dst unless the operator
                # is +@ that does not compute anything.
                res << (" " * ((level+1)*3))
                res << "dst = get_value();\n"
            end
            # Save the state of the value pool.
            res << (" " * ((level+1)*3))
            res << "unsigned int pool_state = get_value_pos();\n"
            # Compute the child.
            res << (" " * ((level+1)*3))
            res << "src0 = #{self.child.to_c(level+2)};\n"
            case self.operator
            when :~ then
                res += "dst = not_value(src0,dst);\n"
            when :-@ then
                res += "dst = neg_value(src0,dst);\n"
            when :+@ then
                res += "dst = #{self.child.to_c(level)};\n"
            else
                raise "Invalid unary operator: #{self.operator}."
            end
            # # Free src0 unless the operator is +@
            # if operator != :+@ then
            #     res << (" " * ((level+1)*3))
            #     res << "free_value();\n"
            # end
            # Restore the value pool state.
            res << (" " * ((level+1)*3))
            res << "set_value_pos(pool_state);\n"
            # Close the computation
            res << (" " * (level*3))
            res << "dst; })"

            return res
        end
    end


    ## Extends the Binary class with generation of HDLRuby::High text.
    class Binary

        # # Generates the C text of the equivalent HDLRuby::High code.
        # # +level+ is the hierachical level of the object.
        # def to_c(level = 0)
        #     res = ""
        #     case self.operator
        #     when :+ then
        #         return "add_value(#{self.left.to_c(level)}," + 
        #                "#{self.right.to_c(level)})"
        #     when :- then
        #         return "sub_value(#{self.left.to_c(level)}," +
        #                "#{self.right.to_c(level)})"
        #     when :* then
        #         return "mul_value(#{self.left.to_c(level)}," +
        #                "#{self.right.to_c(level)})"
        #     when :/ then
        #         return "div_value(#{self.left.to_c(level)}," +
        #                "#{self.right.to_c(level)})"
        #     when :% then
        #         return "mod_value(#{self.left.to_c(level)}," +
        #                "#{self.right.to_c(level)})"
        #     when :** then
        #         return "pow_value(#{self.left.to_c(level)}," +
        #                "#{self.right.to_c(level)})"
        #     when :& then
        #         return "and_value(#{self.left.to_c(level)}," +
        #                "#{self.right.to_c(level)})"
        #     when :| then
        #         return "or_value(#{self.left.to_c(level)}," +
        #                "#{self.right.to_c(level)})"
        #     when :^ then
        #         return "xor_value(#{self.left.to_c(level)}," +
        #                "#{self.right.to_c(level)})"
        #     when :<<,:ls then
        #         return "shift_left_value(#{self.left.to_c(level)}," +
        #                "#{self.right.to_c(level)})"
        #     when :>>,:rs then
        #         return "shift_right_value(#{self.left.to_c(level)}," +
        #                "#{self.right.to_c(level)})"
        #     when :lr then
        #         return "rotate_left_value(#{self.left.to_c(level)}," +
        #                "#{self.right.to_c(level)})"
        #     when :rr then
        #         return "rotate_right_value(#{self.left.to_c(level)}," +
        #                "#{self.right.to_c(level)})"
        #     when :== then
        #         return "equal_value(#{self.left.to_c(level)}," +
        #                "#{self.right.to_c(level)})"
        #     when :!= then
        #         return "not_equal_value(#{self.left.to_c(level)}," +
        #                "#{self.right.to_c(level)})"
        #     when :> then
        #         return "greater_value(#{self.left.to_c(level)}," +
        #                "#{self.right.to_c(level)})"
        #     when :< then
        #         return "lesser_value(#{self.left.to_c(level)}," +
        #                "#{self.right.to_c(level)})"
        #     when :>= then
        #         return "greater_equal_value(#{self.left.to_c(level)}," +
        #                "#{self.right.to_c(level)})"
        #     when :<= then
        #         return "lesser_equal_value(#{self.left.to_c(level)}," +
        #                "#{self.right.to_c(level)})"
        #     else
        #         raise "Invalid binary operator: #{self.operator}."
        #     end
        #     return res
        # end

        # Generates the C text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_c(level = 0)
            # res = " " * (level*3)
            res = "({\n"
            # Overrides the upper src0, src1 and dst...
            # And allocates a new value for dst.
            res << (" " * ((level+1)*3))
            res << "Value src0,src1,dst = get_value();\n"
            # Save the state of the value pool.
            res << (" " * ((level+1)*3))
            res << "unsigned int pool_state = get_value_pos();\n"
            # Compute the left.
            res << (" " * ((level+1)*3))
            res << "src0 = #{self.left.to_c(level+2)};\n"
            # Compute the right.
            res << (" " * ((level+1)*3))
            res << "src1 = #{self.right.to_c(level+2)};\n"
            res << (" " * ((level+1)*3))

            # Compute the current binary operation.
            case self.operator
            when :+ then
                res += "dst = add_value(src0,src1,dst);\n"
            when :- then
                res += "dst = sub_value(src0,src1,dst);\n"
            when :* then
                res += "dst = mul_value(src0,src1,dst);\n"
            when :/ then
                res += "dst = div_value(src0,src1,dst);\n"
            when :% then
                res += "dst = mod_value(src0,src1,dst);\n"
            when :** then
                res += "dst = pow_value(src0,src1,dst);\n"
            when :& then
                res += "dst = and_value(src0,src1,dst);\n"
            when :| then
                res += "dst = or_value(src0,src1,dst);\n"
            when :^ then
                res += "dst = xor_value(src0,src1,dst);\n"
            when :<<,:ls then
                res += "dst = shift_left_value(src0,src1,dst);\n"
            when :>>,:rs then
                res += "dst = shift_right_value(src0,src1,dst);\n"
            when :lr then
                res += "dst = rotate_left_value(src0,src1,dst);\n"
            when :rr then
                res += "dst = rotate_right_value(src0,src1,dst);\n"
            when :== then
                res += "dst = equal_value(src0,src1,dst);\n"
            when :!= then
                res += "dst = not_equal_value(src0,src1,dst);\n"
            when :> then
                res += "dst = greater_value(src0,src1,dst);\n"
            when :< then
                res += "dst = lesser_value(src0,src1,dst);\n"
            when :>= then
                res += "dst = greater_equal_value(src0,src1,dst);\n"
            when :<= then
                res += "dst = lesser_equal_value(src0,src1,dst);\n"
            else
                raise "Invalid binary operator: #{self.operator}."
            end
            # # Free src0 and src1.
            # res << (" " * ((level+1)*3))
            # res << "free_value();\n"
            # res << (" " * ((level+1)*3))
            # res << "free_value();\n"
            # Restore the state of the value pool.
            res << (" " * ((level+1)*3))
            res << "set_value_pos(pool_state);\n"
            # Close the computation.
            res << (" " * (level*3))
            res << "dst; })"

            return res
        end
    end

    ## Extends the Select class with generation of HDLRuby::High text.
    class Select

        # Generates the C text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_c(level = 0)
            res = "select_value(#{self.select.to_c(level)}," + 
                  "#{self.each_choice.to_a.size}"
            self.each_choice { |choice| res << ",#{choice.to_c(level)}" }
            res << ")"
            return res
        end
    end

    ## Extends the Concat class with generation of HDLRuby::High text.
    class Concat

        # # Generates the C text of the equivalent HDLRuby::High code.
        # # +level+ is the hierachical level of the object.
        # def to_c(level = 0)
        #     # The resulting string.
        #     res = "concat_value(#{self.each_expression.to_a.size}"
        #     self.each_expression do |expression|
        #         res << ",#{expression.to_c(level)}"
        #     end
        #     res << ")"
        #     return res
        # end
        # Generates the C text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object.
        def to_c(level = 0)
            # Gather the content to concat.
            expressions = self.each_expression.to_a
            # Create the resulting string.
            # res = " " * (level*3)
            res = "({\n"
            # Overrides the upper src0, src1, ..., and dst...
            # And allocates a new value for dst.
            res << (" " * ((level+1)*3))
            res << "Value #{expressions.size.times.map do |i| 
                "src#{i}"
            end.join(",")};\n"
            res << (" " * ((level+1)*3))
            res << "Value dst = get_value();\n"
            # Save the state of the value pool.
            res << (" " * ((level+1)*3))
            res << "unsigned int pool_state = get_value_pos();\n"
            # Compute each sub expression.
            expressions.each_with_index do |expr,i|
                res << (" " * ((level+1)*3))
                res << "src#{i} = #{expr.to_c(level+2)};\n"
            end
            # Compute the resulting concatenation.
            res << (" " * ((level+1)*3))
            res << "concat_value(#{expressions.size},dst,"
            res << "#{expressions.size.times.map { |i| "src#{i}" }.join(",")}"
            res << ");\n"
            # # Free the src
            # expressions.size.times do
            #     res << (" " * ((level+1)*3))
            #     res << "free_value();\n"
            # end
            # Restore the state of the value pool.
            res << (" " * ((level+1)*3))
            res << "set_value_pos(pool_state);\n"
            # Close the computation.
            res << (" " * (level*3))
            res << "dst; })"

            return res

        end
    end


    ## Extends the Ref class with generation of HDLRuby::High text.
    class Ref

        # Generates the C text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object and
        # +left+ tells if it is a left value or not.
        def to_c(level = 0, left = false)
            # Should never be here.
            raise AnyError, "Internal error: to_c should be implemented in class :#{self.class}"
        end
    end

    ## Extends the RefConcat class with generation of HDLRuby::High text.
    class RefConcat

        # Generates the C text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object and
        # +left+ tells if it is a left value or not.
        def to_c(level = 0, left = false)
            # The resulting string.
            res = "ref_concat(#{self.each_ref.to_a.size}"
            self.each_ref do |ref|
                res << ",#{ref.to_c(level,left)}"
            end
            res << ")"
            return res
        end

        # Generates the C text for reference as left value to a signal.
        # +level+ is the hierarchical level of the object.
        def to_c_signal(level = 0)
            # The resulting string.
            res = "sig_concat(#{self.each_ref.to_a.size}"
            self.each_ref do |ref|
                res << ",#{ref.to_c_signal(level)}"
            end
            res << ")"
            return res
        end
    end


    ## Extends the RefIndex class with generation of HDLRuby::High text.
    class RefIndex

        # Generates the C text of the equivalent HDLRuby::High code.
        # +level+ is thehierachical level of the object and
        # +left+ tells if it is a left value or not.
        def to_c(level = 0, left = false)
            # return "ref_index(#{self.ref.to_c(level,left)}," +
            #        "#{self.index.to_c(level)})"
            return "read_range(#{self.ref.to_c(level)}," +
                   "#{self.index.to_c(level)},1," +
                   "#{self.ref.type.base.to_c(level)})"
        end

        # Generates the C text for reference as left value to a signal.
        # +level+ is the hierarchical level of the object.
        def to_c_signal(level = 0)
            return "make_ref_rangeS(#{self.ref.to_c_signal(level)}," +
                "value2longlong(#{self.index.to_c(level)}),value2longlong(#{self.index.to_c(level)}))"
        end
    end


    ## Extends the RefRange class with generation of HDLRuby::High text.
    class RefRange

        # Generates the C text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object and
        # +left+ tells if it is a left value or not.
        def to_c(level = 0, left = false)
            if left then
                res = "write_range(#{self.ref.to_c(level,left)},"
            else
                res = "read_range(#{self.ref.to_c(level,left)},"
            end
            res << "read64(#{self.range.first.to_c(level)})," +
                   "read64(#{self.range.last.to_c(level)})," +
                   "#{self.type.base.to_c(level)})"
            return res
        end

        # Generates the C text for reference as left value to a signal.
        # +level+ is the hierarchical level of the object.
        def to_c_signal(level = 0)
            return to_c(level,true)
        end
    end

    ## Extends the RefName class with generation of HDLRuby::High text.
    class RefName

        # Generates the C text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object and
        # +left+ tells if it is a left value or not.
        def to_c(level = 0, left = false)
            # puts "RefName to_c for #{self.name}"
            return "#{self.resolve.to_c_signal(level+1)}->" +
                   (left ? "f_value" : "c_value")
        end

        # Generates the C text for reference as left value to a signal.
        # +level+ is the hierarchical level of the object.
        def to_c_signal(level = 0)
            return "#{self.resolve.to_c_signal(level+1)}"
        end
    end

    ## Extends the RefThis class with generation of HDLRuby::High text.
    class RefThis 
        # Generates the C text of the equivalent HDLRuby::High code.
        # +level+ is the hierachical level of the object and
        # +left+ tells if it is a left value or not.
        def to_c(level = 0, left = false)
            return "this()"
        end

        # Generates the C text for reference as left value to a signal.
        # +level+ is the hierarchical level of the object.
        def to_c_signal(level = 0)
            return "this()"
        end
    end

    # ## Extends the Numeric class with generation of HDLRuby::High text.
    # class ::Numeric

    #     # Generates the text of the equivalent HDLRuby::High code.
    #     # +level+ is the hierachical level of the object.
    #     def to_c(level = 0)
    #         return self.to_s
    #     end
    # end

end
