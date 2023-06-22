require 'std/sequencer_func.rb'

include HDLRuby::High::Std


# A factorial with default stack depth.
sdef(:fact) do |n|
    hprint("n=",n,"\n")
    sif(n > 1) { sreturn(n*fact(n-1,20)) } #Recurse setting the stack depth to 20
    selse      { sreturn(1) }
end

# A factiorial with very low stack depth for checking overflow.
sdef(:fact_over,2,proc { stack_overflow_error <= 1 }) do |n|
    hprint("n2=",n,"\n")
    sif(n > 1) { sreturn(n*fact_over(n-1)) }
    selse      { sreturn(1) }
end

# Checking the usage of sequencers functions.
system :my_seqencer do

    inner :clk,:rst

    [16].inner :val
    [16].inner :res

    inner stack_overflow_error: 0

    sequencer(clk.posedge,rst) do
        5.stimes do |i|
            val <= i
            res <= fact(val)
        end
        hprint("Going to overflow...\n")
        4.stimes do |i|
            val <= i
            res <= fact_over(val)
        end
        hprint("stack_overflow_error=",stack_overflow_error,"\n")
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
        repeat(500) do
            !10.ns
            clk <= ~clk
        end
    end
end
