require 'HDLRuby'

configure_high


require 'HDLRuby/std/pipeline'
include HDLRuby::High::Std


# A simple test of the pipeline construct
system :with_pipe do
    input :clk,:rst
    [15..0].input :x, :y
    [31..0].input :z
    [31..0].output :u, :v


    pipeline :pipeI # Shortcut: pipeline(clk,rst).(:fsmI)
    pipeI.for_event { clk.posedge }
    # Shortcut: pipeI.clk = clk
    pipeI.for_reset { rst }
    # Shortcut: pipeI.rst = rst

    pipeI do
        stage        { a <= x + y }
        stage(:a) do
            b <= a + z
            c <= a - z
            d <= a * z
        end
        stage(:b,:c) { e <= b + c }
        stage(:d,:e) { v <= d + e }
    end
end

# Instantiate it for checking.
with_pipe :with_pipeI

# Generate the low level representation.
low = with_pipeI.systemT.to_low

# Displays it
puts low.to_yaml
