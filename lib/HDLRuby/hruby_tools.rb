require 'set'

module HDLRuby

##
# General tools for handling HDLRuby objects
#######################################################


    # Method and attribute for generating an absolute uniq name.
    # Such names cannot be used in HDLRuby::High code, but can be used
    # to generate such code.

    @@absoluteCounter = -1 # The absolute name counter.

    @@uniq_names = Set.new(Symbol.all_symbols.map {|sym| sym.to_s})

    # Generates an absolute uniq name.
    def self.uniq_name(base = "")
        @@absoluteCounter += 1
        name = base.to_s + ":#{@@absoluteCounter}"
        # if Symbol.all_symbols.find {|symbol| symbol.to_s == name } then
        if @@uniq_names.include?(name) then
            # The symbol exists, try again.
            return self.uniq_name
        else
            @@uniq_names.add(name)
            return name.to_sym
        end
        # return base.to_s + ":#{@@absoluteCounter}"
    end


    # Extends the Integer class for computing the bit width.
    class ::Integer

        # Gets the bit width
        # NOTE: returns infinity if the number is negative.
        def width
            return self >= 0 ? Math.log2(self+1).ceil : 1.0/0.0
        end

        # Tells if the value is a power of 2.
        def pow2?
            return self > 0 && (self & (self - 1) == 0)
        end
    end


    # Module for adding prefixes to names.
    module HDLRuby::Prefix

        # Get the prefix 
        def prefix
            return self.name + "#"
        end

    end


    # Display some messages depending on the verbosity mode.
    @@verbosity = 1 # The verbosity level: default 1, only critical messages.

    # Sets the verbosity.
    def self.verbosity=(val)
        @@verbosity = val.to_i
    end
    
    # Display a critical message.
    def self.show!(*args)
        puts(*args) if @@verbosity > 0
    end

    # Display a common message.
    def self.show(*args)
        puts(*args) if @@verbosity > 1
    end

    # Display a minor message.
    def self.show?(*args)
        puts(*args) if @@verbosity > 2
    end

end
