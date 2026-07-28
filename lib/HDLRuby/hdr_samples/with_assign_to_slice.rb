system :assign_to_slice do
  [8].inner :reg

  timed do
    !10.ns
    reg[1..0] <= _b00
    !10.ns
    reg[3..2] <= _b01
    !10.ns
    reg[5..4] <= _b10
    !10.ns
    reg[7..6] <= _b11
    !10.ns
    reg[3..0] <= _ha
    !10.ns
    reg[7..4] <= _h5
    !10.ns
  end
end
