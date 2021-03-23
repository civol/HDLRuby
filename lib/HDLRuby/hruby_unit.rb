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
        name = name.to_s.to_sym unless name.is_a?(Symbol)
        # Check if the name is already used or not.
        if @@unit_systems.key?(name) then
            raise UnitError, "Unit test system #{name} already declared."
        end
        # @@unit_systems[name] = HDLRuby::High.system(&ruby_block)
        @@unit_systems[name] = ruby_block
    end


    # Create a system named +test_name+ executing the unit tests given from
    # +names+.
    def self.test(test_name = :test, *names)
        # If there is no name given, use all the test systems.
        names = @@unit_systems.each_key if names.empty?
        # Declare the system.
        HDLRuby::High.system test_name do

            # The timed block that contains the bench execurtion code.
            @@tester = timed {}

            # Generate the test code for each selected test units.
            names.each do |name|
                name = name.to_s.to_sym unless name.is_a?(Symbol)
                unless @@unit_systems.key?(name) then
                    raise UnitError, "Unit test #{name} does not exist."
                end
                sub(name) do
                    @@myself = self
                    instance_exec do
                        # Define the test command that insert code of
                        # the current test unit to the tester timed block.
                        def test(&ruby_block)
                            @@tester.block.open do
                                # Here the signals are to be taken from
                                # the test unit and not the timed block.
                                set_this(@@myself)
                                ruby_block.call
                                # Go back to the default current this.
                                set_this
                            end
                        end
                    end
                    # Process the test unit.
                    instance_exec(&@@unit_systems[name])
                end
            end
        end
    end
end
