require '../std/fsm.rb'

include HDLRuby::High::Std

# Implementation of an 8-bit calculator.
system :calculator do
    input :clk,:rst
    [1..0].input :opr
    [7..0].input :x, :y
    [7..0].output :s
    output :zf, :sf, :cf, :vf

    [8..0].inner :tmp

    def common
        s   <= tmp[7..0]
        zf  <= (s == 0)
        sf  <= tmp[7]
        cf  <= tmp[8]
        vf  <= tmp[8] ^ tmp[7]
        goto(:choice)
    end

    fsm(clk.posedge,rst) do
        state(:zero) do
            s <= 0;
            zf <= 0;
            sf <= 0;
            cf <= 0;
            vf <= 0;
        end
        state(:choice) do
            goto(opr, :add,:sub,:neg, :zero)
        end
        state(:add) do
            tmp <= x + y
            common
        end
        state(:sub) do
            tmp <= x - y
            common
        end
        state(:neg) do
            tmp <= -x
            common
        end
    end
end
