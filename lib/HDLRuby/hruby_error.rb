module HDLRuby


    ## The HDLRuby general error class.
    class AnyError < ::StandardError
    end

    module High
        ## The HDLRuby::High error class.
        class AnyError < HDLRuby::AnyError
        end

        ## The HDLRuby error class replacing the standard Ruby NoMethodError
        class NotDefinedError < AnyError
        end
    end

    module Low
        ## The HDLRuby::Low error class.
        class AnyError < HDLRuby::AnyError
        end
    end
end
