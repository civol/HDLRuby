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
        def has_name_deep?(code, name)
            # Checks recursively.
            return code.find do |field|
                field.is_a?(Array) ? has_name_deep?(field,name) : field == name
            end
        end

        # Tells if +code+ is a require description.
        def is_require?(code)
            # return code[0] && (code[0][0] == :command) &&
            #        (code[0][1][1] == "require")
            return code && (code[0] == :command) &&
                   (code[1][1] == "require")
        end

        # Tells if +code+ is require_relative description.
        def is_require_relative?(code)
            # return code[0] && (code[0][0] == :command) &&
            #        (code[0][1][1] == "require_relative")
            return code && (code[0] == :command) &&
                   (code[1][1] == "require_relative")
        end

        # Gets the required file from +code+.
        def get_require(code)
            # return (code[0][2][1][0][1][1][1])
            return (code[2][1][0][1][1][1])
        end
        alias_method :get_require_relative, :get_require

        # Gets all the required files of  +code+.
        def get_all_requires(code = @code)
            if code.is_a?(Array) then
                requires = (code.select { |sub| is_require?(sub) }).map! do |sub|
                    get_require(sub)
                end
                code.each do |sub|
                    requires += get_all_requires(sub)
                end
                return requires
            else
                return []
            end
        end

        # Gets all the require_relative files of  +code+.
        def get_all_require_relatives(code = @code)
            if code.is_a?(Array) then
                require_relatives = (code.select { |sub| is_require_relative?(sub) }).map! do |sub|
                    get_require_relative(sub)
                end
                code.each do |sub|
                    require_relatives += get_all_require_relatives(sub)
                end
                return require_relatives
            else
                return []
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

        # Gets all the systems of  +code+.
        def get_all_systems(code = @code)
            return [] unless code.is_a?(Array)
            return code.reduce([]) {|ar,sub| ar + get_all_systems(sub) } +
                (code.select { |sub| is_system?(sub) }).map! do |sub|
                    get_system(sub)
                end
        end

        # Tells is +code+ is an instance of one of +systems+.
        def is_instance?(code,systems)
            # puts "is_instance? with #{code}"
            # Ensures systems is an array.
            systems = [*systems]
            # Check for each system.
            return systems.any? do |system|
                code.is_a?(Array) && 
                    ( (code[0] == :command) || (code[0] == :fcall) ) &&
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
                                     (has_name_deep?(code[2][1][1..-1],system))
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

        # Tells if +code+ is a signal declaration.
        def is_signal_declare?(code)
            return [:command,:command_call].include?(code[0]) &&
                ( has_name_deep?(code,"input") ||
                  has_name_deep?(code,"output") ||
                  has_name_deep?(code,"inout") ||
                  has_name_deep?(code,"inner") )
        end

        # Tells if +code+ is an instance declaration of one of +systems+.
        def is_instance_declare?(code,systems)
            return code[0] == :command &&
                systems.find {|sys| has_name_deep?(code,sys) }
        end

        # Tells if +code+ is an HDLRuby declaration of a signal or an
        # instance of one of +systems+.
        def is_hdr_declare?(code, systems)
            return is_system?(code) || is_signal_declare?(code) ||
                is_instance_declare?(code, systems)
        end

        # Gets the HDLRuby names declared from +code+.
        #
        # Note: assumes code is indeed a declaration.
        def get_hdr_declares(code)
            if code.is_a?(Array) then
                if code[0] == :@ident then
                    return [ code[1] ]
                else
                    return code.map {|elem| get_hdr_declares(elem) }.flatten
                end
            else
                return []
            end
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
            hdr_names = []       # The existing HDLRuby names, they cannot be
                                 # used as Ruby variables.
            code.each do |subcode|
                if system_check then
                    # Internal of a system, do a specific check.
                    assign_check_in_system(subcode,hdr_names.clone)
                    system_check = false
                elsif subcode.is_a?(Array) then
                    if (self.is_hdr_declare?(code,hdr_names)) then
                        # New HDLRuby name, add them to the hdr names.
                        hdr_names.concat(self.get_hdr_declares(code))
                    end
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

        # Check for invalid assignments in +code+ assuming being within
        # a system. For that purpose assigned names are look for in
        # +hdr_names+ that includes the current HDLRuby names.
        def assign_check_in_system(code, hdr_names)
            # puts "hdr_names=#{hdr_names}"
            if (self.is_hdr_declare?(code,hdr_names)) then
                # New HDLRuby names, add them to the hdr names.
                hdr_names.concat(self.get_hdr_declares(code))
            elsif (self.is_variable_assign?(code)) then
                var = self.get_assign_variable(code)
                # puts "var=#{var} and hdr_names=#{hdr_names}"
                if hdr_names.include?(var[1]) then
                    # An HDLRuby name is overwritten.
                    if @filename then
                        warn("*WARNING* In file '#{@filename}': ")
                    else
                        warn("*WARNING*")
                    end
                    warn("Potential invalid assignment for '#{self.get_name(var)}' at line #{self.get_line(var)}")
                end
            else
                # Go on checking recursively.
                code.each do |subcode|
                    if subcode.is_a?(Array) then
                        self.assign_check_in_system(subcode,hdr_names)
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
