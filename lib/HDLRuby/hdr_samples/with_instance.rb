


# A benchmark for testing the instantiations.

system :adder do |typ|
    typ.input :x, :y
    typ.output :z

    z <= x + y
end

system :truc do
    [8].input :u, :v
    [8].output :q
end



system :with_instance do

    [8].inner :x0, :y0, :z0, :x1, :y1, :z1

    truc(:montruc).(x0,y0,z0)

    adder(bit[8]).(:adderI0).(x0,y0,z0)
    adder(bit[8]).(:adderI1).(x: x1, y: y1, z: z1)

    timed do
        !10.ns
        x0 <= 0
        y0 <= 0
        x1 <= 1
        y1 <= 1
        !10.ns
        x0 <= 1
        y0 <= 1
        x1 <= 2
        y1 <= 2
        !10.ns
    end
end
