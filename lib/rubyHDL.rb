require 'hruby_sim/hruby_sim'

##
# Module for accessing HDLRuby hardware from a ruby program excuted on
# an embedded processor: HDLRuby simulator version.
########################################################################
module RubyHDL

    # Wrapper for array signal accesses.
    class ArrayWrapper
        # Create a new memory wrapper for signal +sig+
        def initialize(sig)
            @signal = sig 
        end

        # Read the array.
        def [](idx)
          return RCSim.rcsim_read_index_fixnum(@signal,idx)
        end

        # Write to the array.
        def []=(idx,val)
          return RCSim.rcsim_write_index_fixnum_seq(@signal,idx,val)
        end
    end

    # Creates a new array port 'name' assigned to signal 'sig'.
    def self.arrayport(name,sig)
      # Creating the accessing method.
      define_singleton_method(name.to_sym) do
        ArrayWrapper.new(sig)
      end
    end

    # Creates a new port 'name' assigned to signal 'sig' for reading.
    def self.inport(name,sig)
        # Create the accessing methods.
        # For reading.
        define_singleton_method(name.to_sym) do
            RCSim.rcsim_get_signal_fixnum(sig)
        end
    end

    # Creates a new wport 'name' assigned to signal 'sig' for writing.
    def self.outport(name,sig)
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
