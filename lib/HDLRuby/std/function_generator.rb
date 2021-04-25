##
# Standard HDLRuby::High library: universal generic function generator
# based on the work of Ryota Sakai from NN4H
# 
########################################################################


module HDLRuby::High::Std

    # Module describing a function generator using linear approximation between
    # fixed precalculated values.
    # Generic parameters:
    # +func+   procedure generating the discret values of the functions.
    # +ityp+   the type of the input
    # +otyp+   the type of the output
    # +awidth+ width of the address bus for accessing the discret values
    # +xrange+ the range for x values when computing the function
    # +yrange+ the range for y values when computing the function
    system :function_generator do |func, ityp, otyp, awidth, xrange, yrange|
        # Check the generic parameters.
        func = func.to_proc
        ityp = ityp.to_type
        otyp = otyp.to_type
        awidth = awidth.to_i
        xrange = xrange.first.to_f..xrange.last.to_f
        yrange = yrange.first.to_f..yrange.last.to_f

        # Declare the interface of the generator.
        ityp.input :x
        otyp.output :y

        # Discrete values used for interpolating.
        otyp.inner :base, :next_data

        # Address
        [awidth].inner :address
        # Remainder
        ityp.inner :remaining
        x
        # Compute the address and the remainder from the input.
        address <= x[(ityp.width-1)..(ityp.width-awidth)]
        remaining <= [[_b1b0] * awidth, x[(ityp.width-1-awidth)..0]]

        # Instantiate the lut holding the discrete values.
        lut(func,ityp,otyp,awidth,xrange,yrange).(:my_lut).(address,base,next_data)

        # Instantiate the interpolator.
        interpolator(ityp,otyp,awidth).(:my_iterpolator).(base,next_data, remaining, y)
    end


    # The LUT containing the discre values.
    system :lut do |func,ityp, otyp, awidth, xrange, yrange|
        # Check the generic arguments.
        func = func.to_proc
        ityp = ityp.to_type
        otyp = otyp.to_type
        awidth = awidth.to_i
        xrange = xrange.first.to_f..xrange.last.to_f
        yrange = yrange.first.to_f..yrange.last.to_f

        # lut_size = 2 ** address_width
        # Compute the size of the lut.
        lut_size = 2 ** awidth

        # Declare the input and output of the lut.
        [awidth].input :address
        otyp.output :base, :next_data

        # Declare the lut
        otyp[-lut_size].constant lut: 
            initialize_lut(func,otyp,awidth,xrange,yrange)

        # Assign the base discret value.
        base <= lut[address]

        # Assign the next_data discrete value.
        next_data <= lut[address+1]
    end


    # compute tanh
    # LUTの点の間の値を計算するモジュール
    # system :interpolator do |typ, integer_width, address_width|
    # Module making linear interpolation between two discrete values.
    # Generic parameters:
    # +ityp+: the function input value type
    # +otyp+: the function output value type
    # +width+: the step width between discrete values
    system :interpolator do |ityp,otyp,width|
        # Check the generic arguments
        ityp = ityp.to_type
        otyp = otyp.to_type
        width = width.to_i
        # Compute the scale factor and convert it to a shift value.
        shift_bits = ityp.width - width

        # Declare the input and outputs.
        otyp.input :base, :next_data
        ityp.input :remaining
        otyp.output :interpolated_value

        if (otyp.signed?) then
            signed[otyp.width+ityp.width].inner :diff
        else
            bit[otyp.width+ityp.width].inner :diff
        end

        # Make the interpolation.
        diff <= (next_data-base).as(diff.type) * remaining
        if(otyp.signed?) then
            interpolated_value <= base + 
                ([[diff[diff.type.width-1]]*shift_bits,
                  diff[diff.type.width-1..shift_bits]]).to_expr
        else
            interpolated_value <= base + (diff >> shift_bits)
        end
    end

    # Make an array consists of a point of any activation function.
    # @param [Integer] lut_size the lut_size of LUT
    # @return [Array] table an array consists of a point of tanh
    def initialize_lut(func, otyp, awidth, xrange, yrange)
        # Compute the x step between discret values.
        xstep = (xrange.last-xrange.first)/(2 ** awidth)

        # Generate the discrete set of x values.
        x_values = xrange.step(xstep)
        # Generate the table.
        table = x_values.map do |x_value|
            ((func.call(x_value)-yrange.first)/(yrange.last-yrange.first)*
             2**otyp.width).to_i.to_expr.as(otyp)
        end

        return table
    end


end
