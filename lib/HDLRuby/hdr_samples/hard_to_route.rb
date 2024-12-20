# A benchmark for testing the router of SVG generation with hard to
# handle patterns.
# Note that the circuit is not synthesizable here, it is just for
# testing difficult routing patterns, even if they are illegal in practice.

system :adder do |typ|
    typ.input :x, :y
    typ.output :z

    z <= x + y
end


system :hard_to_route do

    [8].inner :x, :y, :z, :c

    adder(bit[8]).(:adderI0).(x,y,z)
    adder(bit[8]).(:adderI1).(x: x, y: y, z: z)

    timed do
        !10.ns
        x <= 0
        y <= 0
        !10.ns
        x <= 1
        y <= 1
        !10.ns
    end
end
