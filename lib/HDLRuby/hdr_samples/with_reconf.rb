require 'std/reconf.rb'

include HDLRuby::High::Std




# Implementation of a vivado partial reconfiguration system.
reconf(:vivado_reconf) do |clk,rst|

    # Get access to the interface of the reconfigurable component.
    inputs = each_input
    outputs = each_output
    inouts = each_inout

    # Create the main system with the interface and a channel for
    # handling the reconfiguration.
    main = system do
        # Declares the inputs.
        inputs.each do |i|
            i.type.input(i.name)
        end
        # Declares the outputs.
        outputs.each do |o|
            o.type.output(o.name)
        end
        # Declares the inouts.
        inouts.each do |io|
            io.type.inout(io.name)
        end
        # An that's all: in vivado the main system is to be a black-box.
    end

    # And set it as the main system.
    set_main(main)

    # The switching circuit.
    # reconfer = vivado_reconfigurer :do_reconf # Will be that later
    # reconfer.clk <= clk 
    # reconfer.rst <= rst 
    reconfer = proc do |idx|
        puts "Instantiating reconfiguration circuits with #{idx}"
    end

    # Defines the reconfiguring procedure: switch to system idx.
    switcher do |idx,ruby_block|
        reconfer.call(idx)
        ruby_block.call
    end

end


# Some system that can be used for recponfiguration.
system :sys0 do
    input :clk,:rst
    input :d
    output :q

    q <= d
end

system :sys1 do
    input :clk,:rst
    input :d
    output :q

    (q <= d).at(clk.posedge)
end

system :sys2 do
    input :clk,:rst
    input :d
    output :q

    (q <= d & ~rst).at(clk.posedge)
end

# A system with a reconfifurable part.
system :with_reconf do
    input :clk,:rst
    input :d
    output :q
    [2].input :conf # The configuration number

    inner :wait_reconf

    # Create a reconfigurable component.
    vivado_reconf(clk,rst).(:my_reconf)
    # It is to be reconfigured to sys0, sys1 or sys2
    my_reconf.(sys0, sys1, sys2)

    # Connect the reconfigurable instance.
    my_reconf.instance.(clk,rst,d,q)

    par(clk.posedge) do
        hif(rst) { wait_reconf <= 0 }
        helsif(conf != 0 && my_reconf.index != conf && wait_reconf == 0) do
            wait_reconf <= 1
            my_reconf.switch(conf) { wait_reconf <= 0 }
        end
    end
end
