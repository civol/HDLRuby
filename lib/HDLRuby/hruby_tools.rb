
module HDLRuby

##
# General tools for handling HDLRuby objects
#######################################################


    # Method and attribute for generating an absolute uniq name.
    # Such names cannot be used in HDLRuby::High code, but can be used
    # to generate such code.

    @@absoluteCounter = -1 # The absolute name counter.

    # Generates an absolute uniq name.
    def self.uniq_name
        @@absoluteCounter += 1
        return ":#{@@absoluteCounter}".to_sym
    end

end
