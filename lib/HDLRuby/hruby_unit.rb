require "HDLRuby/hruby_high"



##
# Library for building unit test systems.
#
########################################################################
module HDLRuby::Unit

    ## The HDLRuby unit test error class.
    class UnitError < ::StandardError
    end

    # The set of the unit systems by name.
    @@unit_systems = {}

    # Declares system +name+ for unit testing.
    # The system is built by executing +ruby_block+.
    #
    # NOTE: the name of the system is not registered within the HDLRuby
    #       namespace since it is not meant to be used directly.
    def self.system(name,&ruby_block)
        # Ensure name is a symbol.
        name = name.to_s.to_sym
        # Check if the name is already used or not.
        if @@unit_systems.key?(name) then
            raise UnitError, "Unit test system #{name} already declared."
        end
        @@unit_systems[name] = HDLRuby::High.system(&ruby_block)
    end


    # Create a system named +test_name+ executing all the unit tests.
    def self.test(test_name = "test")
        # Declare the system.
        HDLRuby::High.system test_name do
            @@unit_systems.each do |name,sys|
                sys.instantiate(name)
            end
        end
    end
end
