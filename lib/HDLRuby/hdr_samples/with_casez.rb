# Test the casez statement.

# A benchmark for the case statement.
system :case_bench do
    [8].inner :x, :z

    par do
        hcasez(x)
        hwhen(_b0000_0000)  { z <= 0 }
        hwhen(_b000z_0001)  { z <= 1 }
        hwhen(_b00z0_0010)  { z <= 4 }
        hwhen(_b00zz_0011)  { z <= 9 }
        hwhen(_b0z00_0100)  { z <= 16 }
        hwhen(_b0z0z_0101)  { z <= 25 }
        hwhen(_b0zz0_0110)  { z <= 36 }
        hwhen(_b0zzz_0111)  { z <= 49 }
        hwhen(_bz000_1000)  { z <= 64 }
        hwhen(_bz00z_1001)  { z <= 81 }
        hwhen(_bz0z0_1010) { z <= 100 }
        hwhen(_bz0zz_1011) { z <= 121 }
        hwhen(_bzz00_1100) { z <= 144 }
        hwhen(_bzz0z_1101) { z <= 169 }
        hwhen(_bzzz0_1110) { z <= 196 }
        hwhen(_bzzzz_1111) { z <= 225 }
        helse    { z <= _zzzzzzzz }
    end

    timed do
        !10.ns
        20.times do |i|
            x <= i
            !10.ns
        end
    end
end
