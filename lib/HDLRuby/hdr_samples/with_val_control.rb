

# A benchmark for testing hif with value condition: the sould produce
# meta programming.
system :with_seq_if_bench do
    inner :clk
    [2].inner :s
    [8].inner :x,:y, :z
    [8].inner :u,:v, :w

    hif(9) do
      puts "hif(9)"
      seq do
        hif(s==2) { x <= 1 }
      end
    end
    helse do
      puts "hif(9) helse"
      seq do
        hif(s==1) { x <= 2 }
      end
    end

    hif(0) do
      puts "hif(0)"
      seq do
        hif(s==2) { y <= 1 }
      end
    end
    helse do
      puts "hif(0) helse"
      seq do
        hif(s==1) { y <= 2 }
      end
    end

    hif(0) do
      puts "hif(0)"
      z <= 0
    end
    helsif(2) do
      puts "hif(0) helsif(2)"
      z <= 4
    end
    helse do
      puts "hif(0) helsif(2) helse"
      z <= 5
    end

    hcase(2)
    hwhen(0) { puts "hcase(2) hwhen(0)"; u <= 0 }
    hwhen(1) { puts "hcase(2) hwhen(1)"; u <= 1 }
    hwhen(2) { puts "hcase(2) hwhen(2)"; u <= 2 }
    helse    { puts "hcase(2) helse"   ; u <= 3 }

    hcase(4)
    hwhen(0) { puts "hcase(4) hwhen(0)"; v <= 0 }
    hwhen(1) { puts "hcase(4) hwhen(1)"; v <= 1 }
    hwhen(2) { puts "hcase(4) hwhen(2)"; v <= 2 }
    helse    { puts "hcase(4) helse"   ; v <= 3 }

    seq(clk.posedge) do
      hif(6) do
        puts "hif(6)"
        w <= w + 1
      end
    end
        

    timed do
      clk <= 0
      w   <= 0
      !10.ns
      clk <= ~clk
      s <= 0
      !10.ns
      clk <= ~clk
      s <= 1
      !10.ns
      clk <= ~clk
      s <= 2
      !10.ns
      clk <= ~clk
      s <= 3
      !10.ns
    end
end
