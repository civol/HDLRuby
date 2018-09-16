# require 'method_source'
require 'ripper'
require 'pp'

# code.source
# method.source_location

##
#  High-level libraries for describing digital hardware.        
########################################################
module HDLRuby

    ##
    # Describes a HDLRuby code checker.
    class Checker

        # Create a new checker on +code+ string, from +filename+ file.
        # Returns a list of error and the related object and method.
        def initialize(code,filename = nil)
            @code = Ripper.sexp(code.to_s,filename ? filename : "-", 1)
            @code ||= [] # In case the parse failed
            @filename = filename
            # puts "@code=#{@code}"
        end

        # Displays the full syntax tree.
        def show(output = $stout)
            pp(@code,output)
        end

        # Tells if +name+ is included in one of the field or subfield of
        # +code+.
        def has_name_all?(code, name)
            # Checks recursively.
            return code.find do |field|
                field.is_a?(Array) ? has_name_all?(field,name) : field == name
            end
        end

        # Tells if +code+ is a require description.
        def is_require?(code)
            return code[0] && (code[0][0] == :command) &&
                   (code[0][1][1] == "require")
        end

        # Gets the required file from +code+.
        def get_require(code)
            return (code[0][2][1][0][1][1][1])
        end

        # Gets all the required files of  +code+.
        def get_all_requires(code = @code)
            return (code.select { |sub| is_require?(sub) }).map! do |sub|
                get_require(sub)
            end
        end

        # Tells if +code+ is a system description.
        def is_system?(code)
            return code.is_a?(Array) && (code[0] == :command) &&
                                        (code[1][1] == "system")
        end

        # Gets the system name in +code+.
        def get_system(code)
            return code[2][1][0][1][1][1]
        end

        # Gets all the required files of  +code+.
        def get_all_systems(code = @code)
            return [] unless code.is_a?(Array)
            return code.reduce([]) {|ar,sub| ar + get_all_systems(sub) } +
                (code.select { |sub| is_system?(sub) }).map! do |sub|
                    get_system(sub)
                end
        end

        # Tells is +code+ is an instance of one of +systems+.
        def is_instance?(code,systems)
            # Ensures systems is an array.
            systems = [*systems]
            # Check for each system.
            return systems.any? do |system|
                code.is_a?(Array) && (code[0] == :command) &&
                                     (code[1][1] == system)
            end
        end

        # Get the system of an instance in +code+.
        def get_instance_system(code)
            return code[1][1]
        end

        # Get all the instances in +code+ of +systems+.
        # NOTE: return the sub code describing the instantiation.
        def get_all_instances(systems,code = @code)
            return [] unless code.is_a?(Array)
            return code.reduce([]) do |ar,sub|
                ar + get_all_instances(systems,sub)
            end + (code.select { |sub| is_instance?(sub,systems) }).to_a
        end

        # Tells is +code+ is an include of one of +systems+.
        def is_include?(code,systems)
            # Ensures systems is an array.
            systems = [*systems]
            # Check for each system.
            return systems.any? do |system|
                code.is_a?(Array) && (code[0] == :command) &&
                                     (code[1][1] == "include") &&
                                     (code[2][1][1] == system)
            end
        end

        # Get the system of an include in +code+.
        def get_include_system(code)
            return code[2][1][1]
        end

        # Get all the include in +code+ of +systems+.
        # NOTE: return the sub code describing the include.
        def get_all_includes(systems,code = @code)
            return [] unless code.is_a?(Array)
            return code.reduce([]) do |ar,sub|
                ar + get_all_includes(systems,sub)
            end + (code.select { |sub| is_include?(sub,systems) }).to_a
        end

        # Tells is +code+ is an inheritance of one of +systems+.
        def is_inherit?(code,systems)
            # Ensures systems is an array.
            systems = [*systems]
            # Check for each system.
            return systems.any? do |system|
                code.is_a?(Array) && (code[0] == :command) &&
                                     (code[1][1] == "system") &&
                                     (has_name_all?(code[2][1][1..-1],system))
            end
        end

        # Get the inherted systems of an inheritance in +code+.
        def get_inherit_systems(code)
            res = []
            code[2][1][1..-1].each do |field|
                if (field[0] == :command) then
                    res << field[1][1]
                elsif (field[0] == :method_add_arg) then
                    res << field[1][1][1]
                end
            end
            return res
        end

        # Get all the inherited system in +code+ of +systems+.
        # NOTE: return the sub code describing the include.
        def get_all_inherits(systems,code = @code)
            return [] unless code.is_a?(Array)
            return code.reduce([]) do |ar,sub|
                ar + get_all_inherits(systems,sub)
            end + (code.select { |sub| is_inherit?(sub,systems) }).to_a
        end

        # Tells if +code+ is a variable assignment.
        def is_variable_assign?(code)
            return (code[0] == :assign) && (code[1][1][0] == :@ident)
        end

        # Gets the assigned variable in +code+.
        def get_assign_variable(code)
            return code[1][1]
        end

        # Gets the line of a code.
        def get_line(code)
            return code[2][0]
        end

        # Gets the variable name of a code.
        def get_name(code)
            return code[1]
        end

        # Check for invalid assignments in +code+.
        def assign_check(code = @code)
            system_check = false # Flag telling if the internal of a system
                                 # is reached.
            code.each do |subcode|
                if system_check then
                    # Internal of a system, do a specific check.
                    assign_check_in_system(subcode)
                    system_check = false
                elsif subcode.is_a?(Array) then
                    if self.is_system?(subcode) then
                        # The current subcode is a system, the next one will
                        # be its internal.
                        system_check = true
                    else
                        # Go on cheking recursively.
                        self.assign_check(subcode)
                    end
                end
            end
        end

        # Check for invalkid assignments in +code+ assuming being within
        # a system.
        def assign_check_in_system(code)
            if (self.is_variable_assign?(code)) then
                var = self.get_assign_variable(code)
                if @filename then
                    warn("*WARNING* In file '#{@filename}': ")
                else
                    warn("*WARNING*")
                end
                warn("Potential invalid assignment for '#{self.get_name(var)}' at line #{self.get_line(var)}")
            else
                # Go on checking recursively.
                code.each do |subcode|
                    if subcode.is_a?(Array) then
                        self.assign_check_in_system(subcode)
                    end
                end
            end
        end
    end
end


if __FILE__ == $0 then
    # Used standalone, check the files given in the standard input.
    include HDLRuby

    show = false # Tell if in show mode

    if $*[0] == "-s" || $*[0] == "--show" then
        $*.shift
        # Only shows the syntax tree.
        show = true
    end

    $*.each do |filename|
        checker = Checker.new(File.read(filename),filename)
        if show then
            checker.show
            # systems = checker.get_all_systems
            # puts "All systems are: #{systems}"
            # puts "All instances of all systems are: #{checker.get_all_instances(systems)}"
        else
            checker.assign_check
        end
    end
end
