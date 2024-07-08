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
        def make(name,base,range)
            # Generate a vector or a scalar type depending on the range.
            # First for checking the rangem ensures the bounds are Ruby
            # values.
            first = range.first
            last = range.last
            first = first.content if first.is_a?(Value)
            last = last.content if last.is_a?(Value)
            # Necessarily a TypeVector, since [0..0] has actually a
            # different meaning from [0]!
            # # Now can compare at Ruby level (and not HDLRuby level).
            # if first == last then
            #     # Single-element, return the base.
            #     return base
            # else
            #     # Multiple elements, create a new type vector.
            #     return TypeVector.new(name,base,range)
            # end
            return TypeVector.new(name,base,range)
        end

        # Type resolution: decide which class to use for representing
        # a computating result with +type+.
        def resolve(type)
            # puts "self=#{self} type=#{type}"
            if self.float? then
                return self
            elsif type.float? then
                return type
            elsif self.signed? then
                if type.signed? then
                    return self.width >= type.width ? self : type
                else
                    return self
                end
            elsif type.signed? then
                return type
            elsif self.width >= type.width then
                return self
            else
                return type
            end
        end

        # Range access with +idx+
        # NOTE: 
        #  - +idx+ may be a range.
        #  - Do not use the [] operator for this since it is used for
        #    defining vector types!
        def slice(idx)
            if idx.is_a?(Range) then
                # Make a resized vector.
                return make(:"",self.base,idx)
            else
                # Return the base type.
                return self.base
            end
        end


        # Arithmetic operations

        # Addition.
        def +(type)
            # # Resolve the type class.
            # resolved = self.resolve(type)
            # # New type range: largest range + 1
            # bounds = [ self.range.first.to_i, type.range.first.to_i,
            #            self.range.last.to_i, type.range.last.to_i ]
            # res_lsb =  bounds.min
            # res_msb = bounds.max + 1
            # # Create and return the new type: its endianess is the one of self
            # if self.range.first.to_i > self.range.last.to_i then
            #     return resolved.make(:"",resolved.base,res_msb..res_lsb)
            # else
            #     return resolved.make(:"",resolved.base,res_lsb..res_msb)
            # end
            # The result is the resolve result now!
            return self.resolve(type)
        end

        # Subtraction
        alias_method :-, :+

        # Multiplication
        def *(type)
            # # Resolve the type class.
            # resolved = self.resolve(type)
            # # New type range: largest range * 2
            # bounds = [ self.range.first.to_i, type.range.first.to_i,
            #            self.range.last.to_i, type.range.last.to_i ]
            # res_lsb =  bounds.min
            # res_msb = bounds.max * 2
            # # Create and return the new type: its endianess is the one of self
            # if self.range.first.to_i > self.range.last.to_i then
            #     return resolved.make(:"",resolved.base,res_msb..res_lsb)
            # else
            #     return resolved.make(:"",resolved.base,res_lsb..res_msb)
            # end
            # The result is the resolve result now!
            return self.resolve(type)
        end

        # Division
        def /(type)
            # # Resolve the type class.
            # resolved = self.resolve(type)
            # # New type range: largest range 
            # bounds = [ self.range.first.to_i, type.range.first.to_i,
            #            self.range.last.to_i, type.range.last.to_i ]
            # res_lsb =  bounds.min
            # res_msb = bounds.max 
            # # Create and return the new type: its endianess is the one of self
            # if self.range.first.to_i > self.range.last.to_i then
            #     return resolved.make(:"",resolved.base,res_msb..res_lsb)
            # else
            #     return resolved.make(:"",resolved.base,res_lsb..res_msb)
            # end
            # The result is the resolve result now!
            return self.resolve(type)
        end

        # Modulo
        alias_method :%, :/

        # Positive
        def +@()
            return self
        end

        # Negative
        def -@()
            return self
        end

        # Absolute value
        def abs()
            return self
        end

        # Logical operations and comparisons
        

        # And
        def &(type)
            # # puts "compute types with=#{self} and #{type}"
            # # Resolve the type class.
            # resolved = self.resolve(type)
            # 
            # # Logical operation on non-vector types are kept as is.
            # return resolved unless resolved.is_a?(TypeVector)

            # # Otherwise the range is computed.
            # # New type range: largest range 
            # bounds = [ self.range.first.to_i, type.range.first.to_i,
            #            self.range.last.to_i, type.range.last.to_i ]
            # # puts "bounds=#{bounds}"
            # res_lsb =  bounds.min
            # res_msb = bounds.max 
            # # Create and return the new type: its endianess is the one of self
            # if self.range.first.to_i > self.range.last.to_i then
            #     return resolved.make(:"",resolved.base,res_msb..res_lsb)
            # else
            #     return resolved.make(:"",resolved.base,res_lsb..res_msb)
            # end
            # The result is the resolve result now!
            return self.resolve(type)
        end

        # Or
        alias_method :|, :&

        # Xor
        alias_method :^, :&

        # Not
        def ~()
            return self
        end

        # Equals
        # alias_method :==, :&
        def ==(type)
            return Bit
        end
        alias_method :!=, :==

        # Inferior
        alias_method :<, :&

        # Superior
        alias_method :>, :&

        # Inferior or equal
        alias_method :<=, :&

        # Superior or equal
        alias_method :>=, :&

        # Comparison
        alias_method :<=>, :&


        # Shifts

        # Shift left
        def <<(type)
            # # The result type is the type of left.
            # resolved = self
            # # New type range: 2**(type width) times self range
            # bounds = [ self.range.first.to_i, self.range.last.to_i ]
            # res_lsb =  bounds.min
            # res_msb = bounds.max +
            #     (2 ** ((type.range.last-type.range.first).abs))
            # # Create and return the new type: its endianess is the one of self
            # if self.range.first.to_i > self.range.last.to_i then
            #     return resolved.make(:"",resolved.base,res_msb..res_lsb)
            # else
            #     return resolved.make(:"",resolved.base,res_lsb..res_msb)
            # end
            # The result is the resolve result now!
            return self.resolve(type)
        end

        alias_method :ls, :<<

        # Shift right
        alias_method :>>, :<<
        alias_method :rs, :<<

        # Rotate left.
        def lr(type)
            return self
        end

        # Rotate right.
        alias_method :rr, :lr
        

    end





end
