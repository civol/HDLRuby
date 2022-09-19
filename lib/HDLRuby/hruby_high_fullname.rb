require "HDLRuby/hruby_high"



module HDLRuby::High

##
# Library for describing adding the fullname method to HDLRuby::High objects.
#
########################################################################

    class SystemT

        ## Returns the name of the signal with its hierarchy.
        def fullname
            @fullname ||= (self.parent ? self.parent.fullname + ":" : "") + 
                self.name.to_s
            return @fullname
        end
    end


    ##
    # Module for extending named classes with fullname (other than SystemT).
    module WithFullname

        ## Returns the name of the signal with its hierarchy.
        def fullname
            @fullname ||= self.parent.fullname + ":" + self.name.to_s
            return @fullname
        end

    end

    class Scope
        include WithFullname
    end


    class Behavior

        ## Returns the name of the signal with its hierarchy.
        def fullname
            return self.parent.fullname
        end
    end


    class TimeBehavior

        ## Returns the name of the signal with its hierarchy.
        def fullname
            return self.parent.fullname
        end
    end


    class SignalI
        include WithFullname
    end

    class SignalC
        include WithFullname
    end

    class SystemI
        include WithFullname
    end

    class Code
        # TODO
    end

    class Block
        include WithFullname
    end

    class TimeBlock
        include WithFullname
    end

end
