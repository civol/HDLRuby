system :sumprod do |typ,coefs|
    typ[coefs.size].input :ins
    typ.output :o

    o <= coefs.each_with_index.reduce(_0) do |sum,(coef,i)|
        sum + ins[i]*coef
    end
end


typedef :sat do |width, max|
    signed[width]
end


sat.define_operator(:+) do |width,max, x,y|
    [width].inner :res
    seq do
        res <= x + y
        ( res <= max ).hif(res > max)
    end
end



system :sumprod_sat_16_1000, sumprod(sat(16,1000),
                             [3,78,43,246, 3,67,1,8, 47,82,99,13, 5,77,2,4]) do
end

