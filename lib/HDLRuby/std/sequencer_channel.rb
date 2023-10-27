require 'std/sequencer'

module HDLRuby::High::Std

    ##
    # Standard HDLRuby::High library: channel generator.
    # The idea is to have abstract communication interface whose
    # implementation can be seamlessly modified.
    # 
    ########################################################################
    




    # Creates an abstract channel over an accessing method.
    # NOTE: Works like an enumerator, but can be passed as generic arguments and
    # generates a different enumerator per sequencer.
    # - +typ+ is the data type of the elements.
    # - +size+ is the number of elements.
    # - +access+ is the block implementing the access method.
    class SequencerChannel < SEnumerator

        # Create a new channel for +size+ elements of type +type+ with an JW
        # array-like accesser +access+.
        def initialize(typ,size,&access)
            @type = typ
            @size = size
            @access = access
            @enums  = {} # The enumerator per sequencer.
        end

        # Get the enumerator for current sequencer.
        # If does not exist create a new one.
        def senumerator
            unless SequencerT.current then
                raise "Cannot get a channel enumerator from outside a sequencer."
            end
            enum = @enums[SequencerT.current]
            unless enum then
                enum = @enums[SequencerT.current] =
                    senumerator(@type,@size,&@access)
            end
            return enum
        end

        # Clones is ambigous here, so deactivated.
        def clone
            raise "clone not supported for channels."
        end

        # The array read accesses.
        def [](addr)
            return @access.call(addr)
        end

        # The array write access.
        def []=(addr,val)
            return @access.call(addr,val)
        end

        # Delegate the enumeration methods to the enumerator of the current
        # system.
        
        [:size,:type,:result,:index,:access,:speek,
         :snext,:snext?,:snext!,:srewind].each do |sym|
            define_method(sym) do |*args,&ruby_block|
                self.senumerator.send(sym,*args,&ruby_block)
            end
        end
    end



    # Creates an abstract channel over an accessing method.
    # NOTE: Works like an enumerator or a memory access, but can be passed as
    # generic arguments and generates a different enumerator per sequencer
    # (memory access is identical for now though).
    # - +typ+ is the data type of the elements.
    # - +size+ is the number of elements.
    # - +access+ is the block implementing the access method.
    def channel(typ,size,&access)
        return SequencerChannel.new(typ,size,&access)
    end

end
