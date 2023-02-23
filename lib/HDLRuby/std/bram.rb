module HDLRuby::High::Std

    # Describe a RAM compatibile with BRAM of FPGAs.
    # - 'widthA': address bit width
    # - 'widthD': data bit width
    # - 'size':   the size of the memory.
    system :bram do |widthA, widthD, size = nil|
        # Process size if required.
        size = 2**widthA unless size
        # puts "widthA=#{widthA} widthD=#{widthD} size=#{size}"

        # Declares the io of the ram.
        input :clk, :rwb
        [widthA].input :addr
        [widthD].input :din
        [widthD].output :dout

        bit[widthD][-size].inner mem: [ :"_b#{"0"*widthD}".to_value ] * size

        par(clk.negedge) do
            hif(rwb == 0) { mem[addr] <= din }
            dout <= mem[addr]
        end
    end

end
