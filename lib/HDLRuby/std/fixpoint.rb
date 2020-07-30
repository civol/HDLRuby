module HDLRuby::High::Std

##
# Standard HDLRuby::High library: fixed point types.
# 
########################################################################

    # Save the former included.
    class << self
        alias_method :_included_fixpoint, :included
    end

    # Redefines the include to add fixed point generation through the Type
    # class.
    def self.included(base)
        # Performs the previous included
        res = self.send(:_included_fixpoint,base)
        # Now modify the Type class if not already modified.
        unless ::HDLRuby::High::Type.instance_methods.include?(:"_[]_fixpoint") then
            ::HDLRuby::High::Type.class_eval do
                # Saves the former type generation method.
                alias_method :"_[]_fixpoint", :[]

                # Redefine the type generation method for supporting fixed point
                # type generation.
                def [](*args)
                    if args.size == 1 then
                        return self.send(:"_[]_fixpoint",*args)
                    else
                        # Handle the arguments and compute the fix point sizes.
                        arg0,arg1 = *args
                        if arg0.respond_to?(:to_i) then
                            isize = arg0
                        else
                            isize = (arg0.first-arg0.last).abs+1
                        end
                        if arg1.respond_to?(:to_i) then
                            fsize = arg1
                        else
                            fsize = (arg1.first-arg1.last).abs+1
                        end
                        # Build the type.
                        case(self.name)
                        when :bit
                            typ = bit[isize+fsize].typedef(::HDLRuby.uniq_name)
                        when :unsigned
                            typ = unsigned[isize+fsize].typedef(::HDLRuby.uniq_name)
                        when :signed
                            typ = signed[isize+fsize].typedef(::HDLRuby.uniq_name)
                        else
                            raise "Invalid type for generating a fixed point type: #{self.name}"
                        end
                        # Redefine the multiplication and division for fixed point.
                        typ.define_operator(:*) do |left,right|
                            (left.as([isize+fsize*2])*right) >> fsize
                        end
                        typ.define_operator(:/) do |left,right|
                            (left.as([isize+fsize*2]) << fsize) / right
                        end
                        typ
                    end
                end
                return res
            end
        end
    end

    # Extends the Numeric class for conversion to fixed point litteral.
    class ::Numeric
        # Convert to fixed point value with +dec+ digits after the decimal
        # point.
        def to_fix(dec)
            return (self * (2**dec.to_i)).to_i
        end
    end


end
