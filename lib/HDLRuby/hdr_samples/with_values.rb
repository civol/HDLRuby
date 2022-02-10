
# A benchmark for testing the literal values.
system :with_values do
    inner :v1
    [8].inner :v8
    [16].inner :v16
    [32].inner :v32
    [56].inner :v56
    [64].inner :v64
    [96].inner :v96


    timed do
        v1  <= 0
        v8  <= 0
        v16 <= 0
        v32 <= 0
        v56 <= 0
        v64 <= 0
        v96 <= 0
        !10.ns
        v1  <= 1
        v8  <= 1
        v16 <= 1
        v32 <= 1
        v56 <= 1
        v64 <= 1
        v96 <= 1
        !10.ns
        v1  <= _1010[1]
        v8  <= _uhFF00[15..8]
        !10.ns
        v8  <= 128
        v16 <= 128
        v32 <= 128
        v56 <= 128
        v64 <= 128
        v96 <= 128
        !10.ns
        v16 <= 0x1000
        v32 <= 0x1000
        v56 <= 0x1000
        v64 <= 0x1000
        v96 <= 0x1000
        !10.ns
        v32 <= 0x10000000
        v56 <= 0x10000000
        v64 <= 0x10000000
        v96 <= 0x10000000
        !10.ns
        v56 <= 0x10000000000000
        v64 <= 0x10000000000000
        v96 <= 0x10000000000000
        !10.ns
        v64 <= 0x1000000000000000
        v96 <= 0x1000000000000000
        !10.ns
        v96 <= 0x1000000000000000000
        !10.ns
    end
end
