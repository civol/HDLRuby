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
            @code = Ripper.sexp(code.to_s)
            @filename = filename
            # puts "@code=#{@code}"
        end

        # Tells if +code+ is a system description.
        def is_system?(code)
            return (code[0] == :command) && (code[1][1] == "system")
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
                warn("*WARNING* In file '#{@filename}': ") if @filename
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

    $*.each do |filename|
        checker = Checker.new(File.read(filename),filename)
        checker.assign_check
    end
end
