require 'HDLRuby'

configure_high

def after(number, clk = $clk, rst = $rst, &code)
    if in_behavior? and cur_behavior.on_edge? then
        counter = uniq_name
        counter = [Math::log2(number).to_i+1].inner counter
        hif(rst) { counter <= 0 }
        helsif(counter < number) do
            counter <= counter + 1
        end
        # hif(counter >= number) { code.call }
        hif(counter >= number) { instance_eval(&code) }
    else
        counter = uniq_name
        cur_system.open do
            counter = [Math::log2(number).to_i+1].inner counter
            par(clk.posedge,rst.posedge) do
                hif(rst) { counter <= 0 }
                helse { counter <= counter + 1 }
            end
        end
        # hif(counter >= number) { code.call }
        hif(counter >= number) { instance_eval(&code) }
    end
end


system :test_after0 do
    input :clk,:rst
    inner :sig0, :sig1

    after(10,clk,rst) { sig0 <= 1 }
    helse             { sig0 <= 0 }

    par(clk.posedge,rst.posedge) do
        sig1 <= 0
        after(20) { sig1 <= 1 }
    end
end


test_after0 :test_after0I

low  = test_after0I.systemT.to_low

# Displays it
puts low.to_yaml
