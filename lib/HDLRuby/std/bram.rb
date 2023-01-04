module HDLRuby::High::Std

    # Describe a RAM compatibile with BRAM of FPGAs.
    # - 'widthA': address bit width
    # - 'widthD': data bit width
    system :bram do |widthA, widthD|
        input :clk, :rwb
        [widthA].input :addr
        [widthD].input :din
        [widthD].output :dout

        # puts "widthA=#{widthA} widthD=#{widthD}"

        bit[widthD][-2**widthA].inner mem: [ :"_b#{"0"*widthD}".to_value ] * 2**widthA

        par(clk.negedge) do
            hif(rwb == 1) { mem[addr] <= din }
            dout <= mem[addr]
        end
    end

end
