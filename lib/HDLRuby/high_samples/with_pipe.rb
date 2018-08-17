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

    # The multiplication part
    sub :mul do
        [15..0].inner :x, :y
        [31..0].inner :prod
        prod <= x*y
    end 

    # The addition part
    sub :add do
        [31..0].inner :x, :y
        [31..0].inner :sum
        sum <= x+y
    end

    # The subtraction part
    sub :subs do
        [31..0].inner :x, :y
        [31..0].inner :diff
        diff <= x-y
    end

    # The pipeline
    pipeline(:pipo,clk.posedge,rst.posedge)

    pipo.add      mul => 0, add => 1, subs => 1
    pipo.connect  x=> mul.x, y => mul.y
    pipo.connect  mul.prod => add.x,  z => add.y,  add.sum => u
    pipo.connect  mul.prod => subs.x, z => subs.y, subs.diff => v
end

# Instantiate it for checking.
with_pipe :with_pipeI

# Generate the low level representation.
low = with_pipeI.systemT.to_low

# Displays it
puts low.to_yaml
