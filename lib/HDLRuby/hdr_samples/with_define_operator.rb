# A sample for testing define operator.

typedef :sat100 do |width|
    signed[width]
end

sat100.define_operator(:+) do |width, x,y|
    tmp = x.as(bit[width]) + y.as(bit[width])
    mux(tmp > 100,tmp,100)
end

typedef :sat do |width, max|
    signed[width]
end

sat.define_operator(:+) do |width,max, x,y|
    tmp = x.as(bit[width]) + y.as(bit[width])
    mux(tmp > max, tmp, max)
end


system :bench_sat do
    sat100(8).inner :x,:y,:z
    sat(8,55).inner :u,:v,:w

    timed do
        x <= 40
        y <= 32
        z <= x+y
        !10.ns
        u <= 20
        v <= 24
        w <= u+v
        !10.ns
        x <= 70
        y <= 32
        z <= x+y
        !10.ns
        u <= 50
        v <= 24
        w <= u+v
        !10.ns
    end
end
