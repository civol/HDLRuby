require 'strscan'

##
# Tool for expanding template files.
#
# Used for generating files like confugaration file for given HW target
#
########################################################################


class TemplateExpander

    ## Describes an expansion rule.
    Rule = Struct.new(:match,:action)

    # Creates a new template expander with potential list of +rules+.
    def initialize(rules= [])
        # Setup the rules.
        @rules = rules.map do |match,action|
            # Ensures action is a proc.
            action = proc { |str| action.to_s } unless action.is_a?(Proc)
            # Create the rule.
            Rule.new(Regexp.new(match), action)
        end
        # The skip regexp is empty, it has to be built with finalize.
        @skip = nil
    end

    # Adds a +rule+.
    def add_rule(*rule)
        @rules << Rule.new(Regexp.new(rule[0]), rule[1])
    end

    # Finalize the expander by building the default rule.
    def finalize
        # @skip = Regexp.union(*@rules.map { |rule| rule.match })
        @skip = /(?=#{Regexp.union(*@rules.map { |rule| rule.match }).source})|\z/
    end

    # Apply the expander to +str+ and put the result in +res+.
    def expand(str,res = "")
        # Ensure the default rule is properly set up.
        self.finalize
        # Scan the string with each rule.
        scanner = StringScanner.new(str)
        until scanner.eos? do
            @rules.find do |rule|
                scanned = scanner.scan(rule.match)
                if scanned then
                    res << rule.action.call(scanned)
                else
                    false
                end
            end
            res << scanner.scan_until(@skip)
        end
        return res
    end
    

end
