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
        # Now modify the Type class
        ::HDLRuby::High::Type.class_eval do
            # Saves the former type generation method.
            alias_method :"_[]_fixpoint", :[]

            # Redefine the type generation method for supporting fixed point
            # type generation.
            def [](*args)
                if args.size == 1 then
                    return self.send(:"_[]_fixpoint",*args)
                else
                    # Handle the arguments.
                    arg0,arg1 = *args
                    if arg0.respond_to?(:to_i) then
                        arg0 = (arg0.to_i.abs-1)..0
                    end
                    if arg1.respond_to?(:to_i) then
                        arg1 = (arg1.to_i.abs-1)..0
                    end
                    # Compute the fix point sizes.
                    isize = (arg0.first-arg0.last).abs+1
                    fsize = (arg1.first-arg1.last).abs+1
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
