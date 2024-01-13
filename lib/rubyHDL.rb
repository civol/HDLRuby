require 'hruby_sim/hruby_sim'

##
# Module for accessing HDLRuby hardware from a ruby program excuted on
# an embedded processor: HDLRuby simulator version.
########################################################################
module RubyHDL

    # Creates a new port 'name' assigned to signal 'sig'.
    def self.port(name,sig)
        # Create the accessing methods.
        # For reading.
        define_singleton_method(name.to_sym) do
            RCSim.rcsim_get_signal_fixnum(sig)
        end

        # For writing.
        define_singleton_method(:"#{name}=") do |val|
            RCSim.rcsim_transmit_fixnum_to_signal_seq(sig,val)
        end
    end

    # Creates a new program 'name' assign to simulator code 'code'.
    def self.program(name,code)
        # Create the accessing method.
        define_singleton_method(name.to_sym) do
            code
        end
    end
end
