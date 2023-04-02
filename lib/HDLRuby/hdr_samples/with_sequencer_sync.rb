require 'std/sequencer_sync.rb'

include HDLRuby::High::Std

# Checking the usage of sequencers with synchronizarion.
system :my_seqencer do

    inner :clk,:rst

    [8].inner :res0, :res1
    [8].shared(x0: _hFF,x1: _hFF)

    arbiter(:arbiter0).(x1)

    par(clk.posedge) do
        x0.select <= x0.select + 1
    end

    sequencer(clk.posedge,rst) do
        sloop do
            res0 <= x0 * 2
            res1 <= x1 * 2
        end
    end

    sequencer(clk.posedge,rst) do
        10.stimes do |i|
            x0 <= i
            x1 <= i
            arbiter0 <= 1
        end
        arbiter0 <= 0
    end

    sequencer(clk.posedge,rst) do
        10.stimes do |i|
            x0 <= 10-i
            x1 <= 10-i
            arbiter0 <= 1
            step
        end
        arbiter0 <= 0
    end

    sequencer(clk.posedge,rst) do
        10.stimes do |i|
            step
            arbiter0 <= 1
            x0 <= 128+i
            x1 <= 128+i
            step
            arbiter0 <= 0
        end
    end



    [8].inner :res2, :res20, :res21, :res22
    [8].shared x2: _hFF 

    monitor(:monitor0).(x2)

    sequencer(clk.posedge,rst) do
        sloop do
            res2 <= x2 * 2
        end
    end

    sequencer(clk.posedge,rst) do
        x2 <= 0
        monitor0.lock
        4.stimes do |i|
            res20 <= res2
            x2 <= i + 1
        end
        res20 <= res2
        monitor0.unlock
    end

    sequencer(clk.posedge,rst) do
        5.stimes do |i|
            x2 <= 16 + i
            monitor0.lock
            res21 <= res2
            monitor0.unlock
        end
    end

    sequencer(clk.posedge,rst) do
        5.stimes do |i|
            x2 <= 32 + i
            monitor0.lock
            res22 <= res2
            step
            monitor0.unlock
        end
    end


    timed do
        clk <= 0
        rst <= 0
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        rst <= 1
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        rst <= 0
        !10.ns
        clk <= 1
        repeat(100) do
            !10.ns
            clk <= ~clk
        end
    end
end
