system :my_system do
    inner :x
    { sub0: bit, sub1: bit}.inner :sig

   timed do
       x <= 1
       !10.ns
       sig.sub0 <= 0
       sig.sub1 <= x
       !10.ns
       sig.sub0 <= x
       sig.sub1 <= ~sig.sub0
       !10.ns
       sig <= _b11
       !10.ns
   end

end
