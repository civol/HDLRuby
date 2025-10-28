# Sample code for testing unary reduction operators.

system :with_unary_reduction do
  [8].inner :val
  inner :red0, :red1

  red0 <= val.|()
  red1 <= val.&()

  timed do
    val <= 0
    !10.ns
    val <= 1
    !10.ns
    val <= 2
    !10.ns
    val <= 3
    !10.ns
    val <= 255
    !10.ns
  end

end
