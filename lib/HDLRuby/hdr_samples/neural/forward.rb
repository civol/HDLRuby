require "./counter.rb"
require "./selector.rb"
require "./bw.rb"
require "./z.rb"
require "./a.rb"
require "./mem.rb"


##
# Module Generating a foward propagation structure of a NN.
# Params:
# - +typ+:   the data type for standard computations.
# - +arch+:  the architecture of the NN as a array of columns sizes
# - +samps+: the NN input and expected outputs samples as a 3D array
# - +b_init+:the bias initial values as a 2D array
# - +w_init+:the weights initial values as a 3D array
# - +actP+:  the activation proc, default: ReLU
# - +sopP+:  the sum of production function, default: basic operators
system :forward do |typ,arch,samps,b_init,w_init,
                    actP = proc { |z| mux(z < 0, 0, z) },
                    sopP = proc do |xs,ws| 
                        xs.zip(ws).map{ |x,w| x*w }.reduce(:+)
                    end |
    ###
    # The interface signals

    # The control signals
    input :clk, :reset
    input :din, :select_initial
    # The input signals for updating of the weights and biases,
    # and the output signals giving the corresponding current values.
    cap_bs = []
    bs = []
    cap_ws = []
    ws = []
    arch[1..-1].each.with_index do |col,i|
        # puts "col=#{col} i=#{i}"
        cap_bs << []
        bs << []
        # The biase updates
        col.times do |j| 
            cap_bs[-1] << typ.input(:"cap_b#{i+1}_#{j+1}")
            # puts "cap_bs[-1][-1] class: #{cap_bs[-1][-1].class}"
            bs[-1] << typ.output(:"b#{i+1}_#{j+1}")
        end
        # The weigh updates
        cap_ws << []
        ws << []
        col.times do |j0|
            cap_ws[-1] << []
            ws[-1] << []
            arch[i].times do |j1|
                cap_ws[-1][-1] << typ.input(:"cap_w#{i+1}_#{j0+1}#{j1+1}")
                ws[-1][-1] << typ.output(:"w#{i+1}_#{j0+1}#{j1+1}")
            end
        end
    end
    # The output signals giving each neuron output.
    as = []
    arch[1..-1].each.with_index do |col,i|
        as << []
        col.times do |j|
            as[-1] << typ.output(:"a#{i+1}_#{j+1}")
        end
    end
    # The output signals indicating the current NN input and expected
    # answer (they are provided by an inner memory).
    ks = []
    arch[0].times do |i|
        # NN input
        ks << typ.output(:"k#{i+1}")
    end
    ts = []
    arch[-1].times do |i|
        # NN expected answer
        ts << typ.output(:"t#{i+1}")
    end

    ###
    # The inner signals

    # The control signals
    inner :select_update
    typedef(:outT) { [Math::log2(samps[0][0].size).ceil] } # Sample counter type
    outT.inner :out

    # The neurons sum results.
    zs = []
    arch[1..-1].each.with_index do |col,i|
        zs << []
        col.times do |j|
            zs[-1] << typ.inner(:"z#{i+1}_#{j+1}")
        end
    end

    ###
    # The structural description (instantiation of thre neuron computation
    # systems)

    # Sample counter
    counter(outT,samps[0][0].size).(:counterI).(clk, reset, out)
    # Neuron update selector, the skip size is (NN depth)*4+1
    # (4-cycle neurons and one addition sync cycle).
    selector(arch.size*4+1).(:selectorI).(clk, reset, select_update)
    # Input and expected output memories
    arch[0].times do |i|
        # Input samples are the first ones.
        mem(typ,outT,samps[0][i]).(:"k#{i+1}I").(clk, din, out, ks[i])
    end
    arch[-1].times do |i|
        # Expected output samples are the second ones.
        mem(typ,outT,samps[1][i]).(:"t#{i+1}I").(clk, din, out, ts[i])
    end
    # Biases and weights
    arch[1..-1].each.with_index do |col,i|
        # Biases
        col.times do |j|
            # puts "bs[i][j]=#{bs[i][j]}"
            bw(typ,b_init[i][j]).
                (:"b#{i+1}_#{j+1}I").(clk, reset, cap_bs[i][j],
                    select_initial, select_update, bs[i][j])
        end
        # Weights
        col.times do |j0|
            arch[i].times do |j1|
            # puts "i=#{i} j0=#{j0} j1=#{j1}"
            # puts "w_init[i][j1][j0]=#{w_init[i][j0][j1]}"
            # puts "cap_ws[i][j0][j1]=#{cap_ws[i][j0][j1]}"
                bw(typ,w_init[i][j0][j1]).
                    (:"w#{i+1}_#{j0+1}#{j1+1}I").(clk,reset,cap_ws[i][j0][j1],
                    select_initial, select_update, ws[i][j0][j1])
            end
        end
    end
    # Sums
    # First column
    arch[1].times do |j|
        # puts "j=#{j} bs[0][j]=#{bs[0][j]} zs[0][j]=#{zs[0][j]}"
        z(typ,ks.size,sopP).(:"z2_#{j+1}I").
            (clk, reset, *ks, *ws[0][j], bs[0][j], zs[0][j])
    end
    # Other columns
    arch[2..-1].each.with_index do |col,i|
        col.times do |j|
            z(typ,as[i].size,sopP).(:"z#{i+3}_#{j+1}I").
                (clk, reset, *as[i], *ws[i+1][j], bs[i+1][j], zs[i+1][j])
        end
    end
    # Activations.
    arch[1..-1].each.with_index do |col,i|
        col.times do |j|
            a(typ,actP).(:"a#{i+1}_#{j+1}I").(clk, reset, zs[i][j], as[i][j])
        end
    end
end
