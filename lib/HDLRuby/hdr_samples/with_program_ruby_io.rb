system :accum do
  inner :clk
  [32].inner :sigI, :sigO

  program(:ruby,:stdrw) do
    actport clk.posedge
    outport sigI: sigI
    inport  sigO: sigO
    code "stdrw.rb"
  end

  (sigO <= sigO+sigI).at(clk.negedge)

  timed do
    clk <= 0
    sigO <= 0
    sigI <= 0
    repeat(10) do
       !10.ns
       clk <= ~clk
    end
  end
end
