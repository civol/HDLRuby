require 'HDLRuby'


module HDLRuby

    # The new field symbol_equiv is not to be dumped.
    FIELDS_TO_EXCLUDE.default << :@_symbol_equiv
end

module HDLRuby::Low


##
# Converts a HDLRuby::Low description to a uniq symbol and vice versa.
#
########################################################################

    ##
    #  Module adding the conversion to symbol feature to HDLRuby objects.
    module Low2Symbol

        # The correspondance tables between HDLRuby objects and symbols.
        Low2SymbolTable = {}
        Symbol2LowTable = {}

        # The prefix used when building symbols.
        Low2SymbolPrefix = "`"

        # Converts to a symbol.
        def to_sym
            # Get the associated symbol if any.
            @_symbol_equiv ||= Low2SymbolTable[self]
            unless @_symbol_equiv then
                # No symbol yet, create it.
                @_symbol_equiv =
                    (Low2SymbolPrefix + Symbol2LowTable.size.to_s).to_sym
                # And regiter it.
                Symbol2LowTable[@_symbol_equiv] = self
                Low2SymbolTable[self] = @_symbol_equiv
            end
            # Now there is a symbol, return it.
            return @_symbol_equiv
        end
    end

    class ::Symbol
        ## Extends the Symbol class with of equivalent HDLRuby object.

        # Convert to the equivalent HDLRuby object if any, returns nil if not.
        def to_hdr
            return Low2Symbol::Symbol2LowTable[self]
        end
    end
    

    class SystemT
        ## Extends the SystemT class with conversion to symbol.
        include Low2Symbol
    end


    class Scope
        ## Extends the Scope class with conversion to symbol.
        include Low2Symbol
    end

    
    class Type
        ## Extends the Type class with conversion to symbol.
        include Low2Symbol
    end


    class Behavior
        ## Extends the Behavior class with conversion to symbol.
        include Low2Symbol
    end


    class Event
        ## Extends the Event class with conversion to symbol.
        include Low2Symbol
    end


    class SignalI
        ## Extends the SignalI class with conversion to symbol.
        include Low2Symbol
    end


    class SystemI
        ## Extends the SystemI class with conversion to symbol.
        include Low2Symbol
    end


    class Statement
        ## Extends the Statement class with conversion to symbol.
        include Low2Symbol
    end


    class When
        ## Extends the When class with conversion to symbol.
        include Low2Symbol
    end


    class Delay
        ## Extends the Delay class with conversion to symbol.
        include Low2Symbol
    end


    class Code
        ## Extends the Code class with conversion to symbol.
        include Low2Symbol
    end


    class Expression
        ## Extends the Expression class with conversion to symbol.
        include Low2Symbol
    end

end
