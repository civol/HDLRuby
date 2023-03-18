require "HDLRuby/hruby_rsim"

##
# Library for enhancing the Ruby simulator with muted output support
#
########################################################################
module HDLRuby::High

    class SystemT
        # Enhance the system type class with mute support.

        ## Initializes the displayer for generating a vcd on +vcdout+
        def show_init(vcdout)
        end

        ## Displays the time.
        def show_time
        end

        ## Displays the value of signal +sig+.
        def show_signal(sig)
        end

        ## Displays value +val+.
        #  NOTE: for now displays on the standard output and NOT the vcd.
        def show_value(val)
        end

        ## Displays string +str+.
        def show_string(str)
        end
    end

end
