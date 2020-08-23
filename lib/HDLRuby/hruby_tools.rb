
module HDLRuby

##
# General tools for handling HDLRuby objects
#######################################################


    # Method and attribute for generating an absolute uniq name.
    # Such names cannot be used in HDLRuby::High code, but can be used
    # to generate such code.

    @@absoluteCounter = -1 # The absolute name counter.

    # Generates an absolute uniq name.
    def self.uniq_name(base = "")
        @@absoluteCounter += 1
        name = base.to_s + ":#{@@absoluteCounter}"
        if Symbol.all_symbols.find {|symbol| symbol.to_s == name } then
            # The symbol exists, try again.
            return self.uniq_name
        else
            return name.to_sym
        end
    end


    # Extends the Integer class for computing the bit width.
    class ::Integer

        # Gets the bit width
        def width
            return Math.log2(self+1).ceil
        end
    end

end
