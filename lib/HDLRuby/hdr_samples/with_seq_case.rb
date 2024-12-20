

# A benchmark for testing case in seq blocks.
system :with_seq_case_bench do
    [2].inner :s
    [8].inner :z

    seq do
       z <= 4
       hcase(s)
       hwhen(0) { z <= 0 }
       hwhen(1) { z <= 1 }
       hwhen(2) {        } # Intentionally left blank
       helse    { z <= 3 }
       z <= z+1
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
