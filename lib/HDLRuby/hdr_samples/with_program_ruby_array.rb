
# A benchmark for testing the use of Ruby software code with array ports.
system :with_ruby_prog do
  inner :clk
  bit[8][-8].inner ar: [ _h00, _h01, _h04, _h09, _h10, _h19, _h24, _h31 ]

  program(:ruby,:show) do
    actport clk.posedge
    arrayport arP: ar
    code(proc do
      def show
        8.times do |i|
          val = RubyHDL.arP[i]
          puts "# ar[#{i}]=#{val}"
          RubyHDL.arP[i] = i+i
        end
      end
    end)
  end


  timed do
    clk <= 0
    hprint("ar[0]=",ar[0],"\n")
    hprint("ar[1]=",ar[1],"\n")
    hprint("ar[2]=",ar[2],"\n")
    hprint("ar[3]=",ar[3],"\n")
    hprint("ar[4]=",ar[4],"\n")
    hprint("ar[5]=",ar[5],"\n")
    hprint("ar[6]=",ar[6],"\n")
    hprint("ar[7]=",ar[7],"\n")
    !10.ns
    repeat(8) do
      clk <= ~clk
      !10.ns
    end
    !10.ns
    hprint("ar[0]=",ar[0],"\n")
    hprint("ar[1]=",ar[1],"\n")
    hprint("ar[2]=",ar[2],"\n")
    hprint("ar[3]=",ar[3],"\n")
    hprint("ar[4]=",ar[4],"\n")
    hprint("ar[5]=",ar[5],"\n")
    hprint("ar[6]=",ar[6],"\n")
    hprint("ar[7]=",ar[7],"\n")
    !10.ns
  end
end
