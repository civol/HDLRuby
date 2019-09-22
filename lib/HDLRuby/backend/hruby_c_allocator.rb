require "HDLRuby/hruby_error"
require "HDLRuby/hruby_low_resolve"
require "HDLRuby/backend/hruby_allocator"



##
# Adds methods for allocating addresses to signals in Code objects and
# integrate the result into C code.
#
########################################################################
module HDLRuby::Low

    ## Extends the SystemT class with support for C allocation of signals.
    class SystemT

        ## Allocates signals within C code using +allocator+.
        def c_code_allocate(allocator)
            self.scope.c_code_allocate(allocator)
        end
    end


    ## Extends the scope class with support for C allocation of signals.
    class Scope

        ## Allocates signals within C code using +allocator+.
        def c_code_allocate(allocator)
            # Interrate on the sub scopes.
            self.each_scope { |scope| scope.c_code_allocate(allocator) }
            # Ally thr allocator on the codes.
            self.each_code  { |code|  code.c_code_allocate(allocator) }
        end
    end


    ## Extends the chunk class with support for self modification with
    #  allocation.
    #  NOTE: only work if the chunk is in C language.
    class Chunk

        ## Allocates signal within C code using +allocator+ and self-modify
        #  the code correspondingly.
        #  NOTE: non-C chunks are ignored.
        def c_code_allocate!(allocator)
            # Checks the chunk is actually C.
            return self unless self.name == :c
            # Process each lump.
            @lumps.map! do |lump|
                lump_r = lump.resolve if lump.respond_to?(:resolve)
                if lump_r.is_a?(SignalI) then
                    # The lump is a signal, performs the allocation and
                    # change it to an address access.
                    "*(0x#{allocator.allocate(lump_r).to_s(16)})"
                else
                    lump
                end
            end
            self
        end
    end


    ## Extends the code class with support for C allocation of signals.
    class Code

        ## Allocates signals within C code using +allocator+.
        def c_code_allocate(allocator)
            # Apply the allocator on each C chunk.
            self.each_chunk do |chunk|
                chunk.c_code_allocate!(allocator) if chunk.name == :c
            end
        end
    end

end
