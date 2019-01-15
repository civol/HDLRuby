require '../std/fsm.rb'

include HDLRuby::High::Std

# A sequential 16x16 -> 32 multer
system :multer do
    input       :clk, :rst
    input       :start
    [16].input  :x,:y
    [32].output :s
    output      :done

    [32].inner :wx
    [16].inner :wy

    fsm(clk.posedge,rst) do
        state(:init) { s <= 0 ; wx <= x ; wy <= y ; done <= 0 
                       goto(start,:test,:init) }

        state(:test) { goto(wy[0],:add,:next) }

        state(:add)  { s <= s + wx }

        state(:next) { wx <= wx << 1 ; wy <= wy >> 1
                       goto(wy == 0,:end,:test) }

        state(:end)  { done <= 1
                       goto(:end) }
    end
end
