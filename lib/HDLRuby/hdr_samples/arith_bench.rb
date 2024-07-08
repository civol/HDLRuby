
# A benchmark for the arithmetic operations.
system :arith_bench do
    signed[8].inner :x8,:y8,:z8,:s8
    signed[10].inner :s10
    signed[16].inner :x16,:y16,:z16,:s16
    signed[18].inner :s18
    signed[32].inner :x32,:y32,:z32,:s32
    signed[34].inner :s34

    s8 <= x8+y8+z8
    s10 <= x8.as(signed[10])+y8+z8

    s16 <= x16+y16+z16
    s18 <= x16.as(signed[18])+y16+z16

    s32 <= x32+y32+z32
    s34 <= x32.as(signed[34])+y32+z32

    timed do
        x8  <= 0
        y8  <= 0
        z8  <= 0
        x16 <= 0
        y16 <= 0
        z16 <= 0
        x32 <= 0
        y32 <= 0
        z32 <= 0
        !10.ns
        x8  <= 1
        y8  <= 1
        z8  <= 1
        x16 <= 1
        y16 <= 1
        z16 <= 1
        x32 <= 1
        y32 <= 1
        z32 <= 1
        !10.ns
        x8  <= 2
        y8  <= 2
        z8  <= 2
        x16 <= 4
        y16 <= 4
        z16 <= 4
        x32 <= 8
        y32 <= 8
        z32 <= 8
        !10.ns
        x8  <= 0x7F
        y8  <= 0x7F
        z8  <= 0x7F
        x16 <= 0x7FFF
        y16 <= 0x7FFF
        z16 <= 0x7FFF
        x32 <= 0x7FFFFFFF
        y32 <= 0x7FFFFFFF
        z32 <= 0x7FFFFFFF
        !10.ns
        x8  <= -1
        y8  <= -1
        z8  <= -1
        x16 <= -1
        y16 <= -1
        z16 <= -1
        x32 <= -1
        y32 <= -1
        z32 <= -1
        !10.ns
        x8  <= -2
        y8  <= -2
        z8  <= -2
        x16 <= -4
        y16 <= -4
        z16 <= -4
        x32 <= -8
        y32 <= -8
        z32 <= -8
        !10.ns
        x8  <= -0x80
        y8  <= -0x80
        z8  <= -0x80
        x16 <= -0x8000
        y16 <= -0x8000
        z16 <= -0x8000
        x32 <= -0x80000000
        y32 <= -0x80000000
        z32 <= -0x80000000
        !10.ns
    end
end
