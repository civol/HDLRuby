typedef(:some_struct) do
    { sub2: bit, sub3: bit }
end

system :my_system do
    inner :x
    { sub0: bit, sub1: bit}.inner :sig0
    some_struct.inner :sig1


   timed do
       x <= 1
       !10.ns
       sig0.sub0 <= 0
       sig0.sub1 <= x
       sig1.sub2 <= 0
       sig1.sub3 <= x
       !10.ns
       sig0.sub0 <= x
       sig0.sub1 <= ~sig0.sub0
       sig1.sub2 <= x
       sig1.sub3 <= ~sig1.sub2
       !10.ns
       sig0 <= _b11
       sig1 <= _b11
       !10.ns
   end

end
