
def connect8(i0,i1,i2,i3,i4,i5,i6,i7,
             o0,o1,o2,o3,o4,o5,o6,o7)
    o0 <= i0
    o1 <= i1
    o2 <= i2
    o3 <= i3
    o4 <= i4
    o5 <= i5
    o6 <= i6
    o7 <= i7
end

# A benchmark for testing the conversion to ruby array of expressions.
system :with_to_bench do
    [8].inner :val
    inner :b0,:b1,:b2,:b3,:b4,:b5,:b6,:b7

    connect8(*val,b0,b1,b2,b3,b4,b5,b6,b7)

    timed do
        val <= _01101010
        !10.ns
        val <= _01011010
        !10.ns
        val <= _00001111
        !10.ns
    end
end
