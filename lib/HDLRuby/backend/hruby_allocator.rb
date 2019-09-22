require "HDLRuby/hruby_error"



##
# Adds methods for allocating addresses to signals in Code objects.
#
########################################################################
module HDLRuby::Low

    ## An allocator.
    class Allocator

        # The space range for the allocation.
        attr_reader :range

        # The word size.
        attr_reader :word

        ## Creates a new allocator within +range+ memory space whose word
        #  size is +word+.
        def initialize(range, word = 8)
            # Check and set the range.
            first = range.first.to_i
            last = range.last.to_i
            @range = first < last ? first..last : last..first
            # Check and set the word size.
            @word = word.to_i
            # Initialize the allocation counter.
            @head = first
        end

        ## Allocates space for +signal+.
        def allocate(signal)
            # Get the size to allocate in word.
            size = signal.type.width / @word
            size += 1 unless signal.type.width % word == 0
            # Is there any room left?
            if @head + size > @range.last then
                raise AnyError, "Address range overflow."
            end
            # Ok, performs the allocation.
            res = @head
            @head += size
            return res
        end
    end

end
