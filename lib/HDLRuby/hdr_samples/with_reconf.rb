
# Some system that can be used for reconfiguration.
system :sys0 do
    input :clk,:rst
    input :d
    output :q

    par(clk.posedge) do
        hprint("sys0\n")
        q <= d & ~rst
    end
end

system :sys1 do
    input :clk,:rst
    input :d
    output :q

    par(clk.posedge, rst.posedge) do
        hprint("sys1\n")
        q <= d & ~rst
    end
end

system :sys2 do
    input :clk,:rst
    input :d
    output :q

    par(clk.posedge, rst.negedge) do
        hprint("sys2\n")
        q <= d & ~rst
    end
end

# A system with a reconfifurable part.
system :with_reconf do
    input :clk,:rst
    input :d
    output :q

    # Instantiate the default configuration.
    sys0(:my_dff).(clk,rst,d,q)

    # Adds the additional configuration.
    my_dff.choice(conf1: sys1, conf2: sys2)

    timed do
        clk <= 0
        rst <= 0
        d <= 0
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        rst <= 1
        !10.ns
        clk <= 1
        !10.ns
        clk <= 0
        rst <= 0
        !10.ns
        3.times do |i|
            clk <= 1
            !10.ns
            clk <= 0
            d <= 1
            !10.ns
            clk <= 1
            !10.ns
            clk <= 0
            d <= 0
            !10.ns
            clk <= 1
            my_dff.configure((i+1)%3)
            !10.ns
            clk <= 0
            !10.ns
        end
        clk <= 1
        !10.ns
        clk <= 0
        d <= 1
        !10.ns
        clk <= 1
        my_dff.configure(:conf1)
        !10.ns
        clk <= 0
        d <= 0
        !10.ns
        clk <= 1
        my_dff.configure(:conf2)
        !10.ns
        clk <= 0
        d <= 1
        !10.ns
        clk <= 1
        my_dff.configure(:my_dff)
        !10.ns
        clk <= 0
        d <= 0
        !10.ns
        clk <= 1
        !10.ns
    end
end
