typedef(:some_struct) do
    { sub2: bit, sub3: bit[2] }
end

system :my_system do
    inner :x
    [3].inner :y
    { sub0: bit, sub1: bit[2]}.inner :sig0
    some_struct.inner :sig1


   timed do
       x <= 1
       y <= _b000
       !10.ns
       sig0.sub0 <= 0
       sig0.sub1 <= x
       sig1.sub2 <= 0
       sig1.sub3 <= x
       !10.ns
       sig0.sub0 <= x
       sig0.sub1 <= ~sig1.sub3
       sig1.sub2 <= x
       sig1.sub3 <= ~sig0.sub1
       !10.ns
       sig0 <= _b111
       sig1 <= _b111
       !10.ns
       sig0 <= _b100
       !10.ns
       y <= sig0
       sig1 <= sig0
       !10.ns
       sig0 <= _b011
       !10.ns
       sig1 <= sig0
       !10.ns
   end

end
