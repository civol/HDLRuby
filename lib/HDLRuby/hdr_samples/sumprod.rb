system :sumprod do |typ,coefs|
    typ[-coefs.size].input :ins
    typ.output :o

    o <= coefs.each_with_index.reduce(_16b0) do |sum,(coef,i)|
        sum + ins[i]*coef
    end
end


typedef :sat do |width, max|
    signed[width]
end


sat.define_operator(:+) do |width,max, x,y|
    # [width].inner :res
    # seq do
    #     tmp = x.as(bit[width]) + y.as(bit[width])
    #     res <= tmp
    #     ( res <= max ).hif(tmp > max)
    # end
    # res
    tmp = x.as(signed[width]) + y.as(signed[width])
    mux(tmp > max, tmp, max)
end


system :sumprod_sat_16_1000, sumprod(sat(16,1000),
                             [3,78,43,246, 3,67,1,8, 47,82,99,13, 5,77,2,4]) do
end

system :sumprod_bench do
    sat(16,1000)[-16].inner vals: [_16b01,_16b010,_16b011,_16b0100,
                                   _16b0101,_16b0110,_16b0111,_16b01000,
                                   _16b01001,_16b01010,_16b01011,_16b01100,
                                   _16b01101,_16b01110,_16b01111,_16b010000]
    sat(10,1000).inner :res

    sumprod_sat_16_1000.(:my_sat).(vals,res)

    timed do
        !10.ns
    end
end

