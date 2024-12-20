

# A benchmark for testing if in seq blocks.
system :with_seq_if_bench do
    [2].inner :s
    [8].inner :z

    seq do
       hif(s==0)    { z <= 0 }
       helsif(s==1) { z <= 1 }
       helsif(s==2) { z <= 2 }
       helse        { z <= 3 }
    end

    timed do
        s <= 0
        !10.ns
        s <= 1
        !10.ns
        s <= 2
        !10.ns
        s <= 3
        !10.ns
    end
end
