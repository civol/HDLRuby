require 'HDLRuby'


module HDLRuby

    # The new field symbol_equiv is not to be dumped.
    FIELDS_TO_EXCLUDE.default << :@_symbol_equiv
end

module HDLRuby::Low


##
# Converts an HDLRuby::Low description to a uniq symbol and vice versa.
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

    ## Extends the Symbol class with retrival of equivalent HDLRuby object.
    class ::Symbol
        # Convert to the equivalent HDLRuby object if any, returns nil if not.
        def to_hdr
            return Low2Symbol::Symbol2LowTable[self]
        end
    end
    

    ## Extends the SystemT class with retrival conversion to symbol.
    class SystemT
        include Low2Symbol
    end


    ## Extends the Scope class with retrival conversion to symbol.
    class Scope
        include Low2Symbol
    end

    
    ## Extends the Type class with retrival conversion to symbol.
    class Type
        include Low2Symbol
    end


    ## Extends the Behavior class with retrival conversion to symbol.
    class Behavior
        include Low2Symbol
    end


    ## Extends the Event class with retrival conversion to symbol.
    class Event
        include Low2Symbol
    end


    ## Extends the SignalI class with retrival conversion to symbol.
    class SignalI
        include Low2Symbol
    end


    ## Extends the SystemI class with retrival conversion to symbol.
    class SystemI
        include Low2Symbol
    end


    ## Extends the Statement class with retrival conversion to symbol.
    class Statement
        include Low2Symbol
    end


    ## Extends the When class with retrival conversion to symbol.
    class When
        include Low2Symbol
    end


    ## Extends the Delay class with retrival conversion to symbol.
    class Delay
        include Low2Symbol
    end


    ## Extends the Code class with retrival conversion to symbol.
    class Code
        include Low2Symbol
    end


    ## Extends the Expression class with retrival conversion to symbol.
    class Expression
        include Low2Symbol
    end

end
