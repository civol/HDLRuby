# A simple generic adder
system :adder do |w|
    [(w-1)..0].input :i,:j
    [w..0].output :k

    k <= i.as(bit[w+1]) + j
end

# A module embedding two generic adders.
system :two_adders do |w|
    [w*2].input :x, :y
    [(w+1)*2].output :z

    adder(w).(:adderI0).(x[(w-1)..0],y[(w-1)..0],z[w..0])
    adder(w).(:adderI1).(x[(w*2-1)..w],y[(w*2-1)..w],z[(w*2+1)..(w+1)])
end


# Testing the generic adder.
system :adder_bench do
    width = 4
    [width*2].inner :a,:b
    [(width+1)*2].inner :c

    two_adders(width).(:my_adders).(a,b,c)

    timed do
        a <= 0
        b <= 0
        !10.ns
        a <= 1
        !10.ns
        b <= 1
        !10.ns
        a <= 255
        !10.ns
        b <= 128
        !10.ns
    end
end
