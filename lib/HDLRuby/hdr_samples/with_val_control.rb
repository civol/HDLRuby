

# A benchmark for testing hif with value condition: the sould produce
# meta programming.
system :with_seq_if_bench do
    inner :clk
    [2].inner :s
    [8].inner :x,:y, :z
    [8].inner :u,:v, :w
    [8].inner :a, :b

    hif(9) do
      puts "hif(9)"
      [8].inner q: 6
      seq do
        hif(s==2) { x <= 1 }
      end
    end
    helse do
      [8].inner r: 6
      puts "hif(9) helse"
      seq do
        hif(s==1) { x <= 2 }
      end
    end

    hif(0) do
      puts "hif(0)"
      [8].inner q: 7
      seq do
        hif(s==2) { y <= 1 }
      end
    end
    helse do
      [8].inner r: 7
      puts "hif(0) helse"
      seq do
        hif(s==1) { y <= 2 }
      end
    end

    hif(0) do
      puts "hif(0)"
      [8].inner q: 9
      z <= 0
    end
    helsif(2) do
      puts "hif(0) helsif(2)"
      [8].inner r: 9
      z <= 4
    end
    helse do
      puts "hif(0) helsif(2) helse"
      [8].inner t: 9
      z <= 5
    end

    hcase(2)
    hwhen(0) { puts "hcase(2) hwhen(0)"; [8].inner(q: 13); u <= 0 }
    hwhen(1) { puts "hcase(2) hwhen(1)"; [8].inner(q: 14); u <= 1 }
    hwhen(2) { puts "hcase(2) hwhen(2)"; [8].inner(q: 15); u <= 2 }
    helse    { puts "hcase(2) helse"   ; [8].inner(q: 16); u <= 3 }

    hcase(4)
    hwhen(0) { puts "hcase(4) hwhen(0)"; [8].inner(r: 13); v <= 0 }
    hwhen(1) { puts "hcase(4) hwhen(1)"; [8].inner(r: 14); v <= 1 }
    hwhen(2) { puts "hcase(4) hwhen(2)"; [8].inner(r: 15); v <= 2 }
    helse    { puts "hcase(4) helse"   ; [8].inner(r: 16); v <= 3 }

    seq(clk.posedge) do
      hif(6) do
        [8].inner q: 20
        puts "hif(6)"
        w <= w + 1
      end
    end

    seq(mux(1,s,clk.posedge)) do
      a <= a + 1
    end

    seq(mux(0,s,clk.posedge)) do
      b <= b + 1
    end

        

    timed do
      clk <= 0
      w   <= 0
      a   <= 0
      b   <= 0
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
