## 
#  Sample testing named sub
#######################################


# A simple circuit with named sub
system :named_sub do
    input  :x, :y
    output :s

    sub :somesub do
        inner :sig
    end

    seq do
        somesub.sig <= x | y
        s <= ~somesub.sig
    end

end

# A benchmark for the circuit.
system :named_sub_bench do
    inner :x, :y, :s

    named_sub(:my_named_sub).(x,y,s)

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
