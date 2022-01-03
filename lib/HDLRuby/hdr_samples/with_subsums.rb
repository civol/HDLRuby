
# A benchmark for sum of sub parts of a vector.
system :with_concat do
    [8].inner :count
    [16].inner :val0, :val1, :val2, :val3, :val4, :val5, :val6
    bs = []
    10.times do |i|
        bs << [16].inner(:"b#{i}")
    end

    vals = [val1,val2,val3,val4]
    par do
        vals.each.with_index { |val,i| val <= val0[(i*4+3)..i*4] }
    end
    val5 <= vals.reduce(:+)

    par do
        bs.each.with_index { |b,i| b <= val0[i..i] }
    end
    val6 <= bs.reduce(:+)

    timed do
        val0 <= _1111000011110000
        count <= 0
        !10.ns
        val0 <= _0000111100001111
        count <= 1
        !10.ns
        val0 <= _1010101010101010
        count <= 2
        !10.ns
    end
end
