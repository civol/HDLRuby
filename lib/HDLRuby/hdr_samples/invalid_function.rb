# Sample for testing an invalid function: should generate an error.


hdef :func do |val|
  [8].inner :res
  hif (val == 1) { res <= _h60 }
  helse          { res <= _h70 }
end


system :with_func do
    [8].inner :val,:res

    res <= func(val)

    timed do
        val <= 0
        !10.ns
        val <= 1
        !10.ns
        val <= 2
        !10.ns
        val <= 3
        !10.ns
    end
end
