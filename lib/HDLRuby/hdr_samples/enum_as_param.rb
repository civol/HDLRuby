# Check if an enum can be passed as generic parameter.


system :machin do |vals|
    input :clk,:rst
    [8].output :res
    sequencer(clk,rst) do
        vals.seach { |val| res <= val }
    end
end

system :truc do |sig|
    [8].output :res

    res <= sig
end

system :machin_bench do
    inner :clk,:rst

    bit[8][-4].inner vals: [ _h01,_h02,_h03,_h05 ]
    [8].inner :res0

    machin(vals).(:my_machin).(clk,rst,res0)
    
    [8].inner :val, :res1
    truc(val).(:my_truc).(res1)

    timed do
        val <= 10
        clk <= 0
        rst <= 0
        !10.ns
        clk <= 1
        rst <= 0
        !10.ns
        clk <= 0
        rst <= 1
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        rst <= 0
        !10.ns
        repeat(15) do
            clk <= 1
            !10.ns
            clk <= 0
            !10.ns
        end
    end
end
