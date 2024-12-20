# Samples for testing instantiation of generic system within generic system.


system :inner_generic do |typeI, typeO|
  typeI.input :din
  typeO.output :dout

  dout <= din * 2
end


system :outer_generic do |typeI, typeO|
  typeI.input :din_
  typeO.output :dout_

  inner_generic(typeI,typeO).(:my_inner_generic).(din_,dout_)
end


system :test_generic_in_generic do
  [8].inner :x, :y

  outer_generic(bit[8],bit[16]).(:my_outer_generic).(x,y)

  timed do
    x <= 0
    !10.ns
    x <= 1
    !10.ns
  end
end
