module HDLRuby

##
# Library for imnplementing the type processing
#
########################################################################
    

    # To include to classes for type processing support.
    module Tprocess

        # Creates a new generic vector type named +name+ from +base+ type and
        # with +range+.
        # NOTE: used for type processing.
        def make(*args)
            res = TypeVector.new(*args)
        end

        # Type resolution: decide which class to use for representing
        # a computating result with +type+.
        def resolve(type)
            if self.float? then
                return self
            elsif type.float? then
                return type
            elsif self.signed? then
                return self
            elsif type.signed? then
                return type
            elsif self.unsigned? then
                return self
            elsif type.unsigned? then
                return type
            elsif self.width >= type.width
                return self
            else
                return type
            end
        end

        # Arithmetic operations

        # Addition.
        def +(type)
            # Resolve the type class.
            resolved = self.resolve(type)
            # New type range: largest range + 1
            bounds = [ self.range.first, type.range.first,
                       self.range.last, type.range.last ]
            res_lsb =  bounds.min
            res_msb = bounds.max + 1
            # Create and return the new type: its endianess is the one of self
            if self.range.first > self.range.last then
                return resolved.make(:"",resolved.base,res_msb..res_lsb)
            else
                return resolved.make(:"",resolved.base,res_lsb..res_msb)
            end
        end

        # Subtraction
        alias :- :+

        # Multiplication
        def *(type)
            # Resolve the type class.
            resolved = self.resolve(type)
            # New type range: largest range * 2
            bounds = [ self.range.first, type.range.first,
                       self.range.last, type.range.last ]
            res_lsb =  bounds.min
            res_msb = bounds.max * 2
            # Create and return the new type: its endianess is the one of self
            if self.range.first > self.range.last then
                return resolved.make(:"",resolved.base,res_msb..res_lsb)
            else
                return resolved.make(:"",resolved.base,res_lsb..res_msb)
            end
        end

        # Division
        def /(type)
            # Resolve the type class.
            resolved = self.resolve(type)
            # New type range: largest range 
            bounds = [ self.range.first, type.range.first,
                       self.range.last, type.range.last ]
            res_lsb =  bounds.min
            res_msb = bounds.max 
            # Create and return the new type: its endianess is the one of self
            if self.range.first > self.range.last then
                return resolved.make(:"",resolved.base,res_msb..res_lsb)
            else
                return resolved.make(:"",resolved.base,res_lsb..res_msb)
            end
        end

        # Modulo
        alias :% :/

        # Positive
        def +@()
            return self
        end

        # Negative
        def -@()
            return self
        end

        # Logical operations and comparisons
        

        # And
        def &(type)
            # Resolve the type class.
            resolved = self.resolve(type)
            # New type range: largest range 
            bounds = [ self.range.first, type.range.first,
                       self.range.last, type.range.last ]
            res_lsb =  bounds.min
            res_msb = bounds.max 
            # Create and return the new type: its endianess is the one of self
            if self.range.first > self.range.last then
                return resolved.make(:"",resolved.base,res_msb..res_lsb)
            else
                return resolved.make(:"",resolved.base,res_lsb..res_msb)
            end
        end

        # Or
        alias :| :&

        # Xor
        alias :^ :&

        # Not
        def ~()
            return self
        end

        # Equals
        alias :== :&

        # Inferior
        alias :< :&

        # Superior
        alias :> :&

        # Inferior or equal
        alias :<= :&

        # Superior or equal
        alias :>= :&

        # Comparison
        alias :<=> :&


        # Shifts: TODO
        

    end





end
