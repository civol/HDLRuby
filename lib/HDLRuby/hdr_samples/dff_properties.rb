# A simple D-FF
system :dff do
    input :clk, :rst, :d
    output :q, :qb

    qb <= ~q

    par(clk.posedge) { q <= d & ~rst }

    clk.properties[:xcd] = "CLK"
    rst.properties[:xcd] = "RST"
    d.properties[:xcd]   = "PORT0"
    q.properties[:xcd]   = "PORT1"
    qb.properties[:xcd]  = "PORT2"
    cur_system.properties[:xcd_target] = "dummy"
    cur_system.properties[:xcd_file] = "dff.xcd"
    cur_system.properties[:post_driver] = "drivers/xcd.rb", :xcd_generator
end

