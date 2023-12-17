## 
#  Sample testing named sub
#######################################


# A simple circuit with named sub
system :named_sub do |x|
    input  :y
    output :s, :z

    sub :somesub do
        inner :sig
    end

    seq do
        somesub.sig <= x | y
        s <= ~somesub.sig
    end

    z <= s

end

# A benchmark for the circuit.
system :named_sub_bench do
    inner :x, :y, :s, :z

    named_sub(x).(:my_named_sub).(y,s)

    z <= my_named_sub.z

    timed do
        x <= 0
        y <= 0
        !10.ns
        x <= 1
        y <= 0
        !10.ns
        x <= 0
        y <= 1
        !10.ns
        x <= 1
        y <= 1
        !10.ns
    end
end
