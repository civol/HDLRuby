

# A benchmark for testing if in seq blocks.
system :with_seq_if_bench do
    [2].inner :s
    [8].inner :u, :v

    seq do
       hif(s==0)    { u <= 0; v <= 3 }
       helsif(s==1) { u <= 1; v <= 2 }
       helsif(s==2) { u <= 2; v <= 1 }
       helse        { u <= 3; v <= 0 }
       u <= u + 1
       v <= v + 2
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
