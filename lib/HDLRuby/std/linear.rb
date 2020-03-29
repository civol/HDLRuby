module HDLRuby::High::Std


    ##
    # Standard HDLRuby::High library: linear algebra functions.
    #
    # NOTE: require channel-like interface.
    #
    ########################################################################


    # Delcares a vector product by a scalar value.
    #
    # Can be used for scaling a vector.
    function :scale do |typ,ev,req,ack,left,rights,prods,
                        mul = proc { |x,y| x*y }|
        # Ensure ev is really an event.
        ev = ev.posedge unless ev.is_a?(Event)
        # Ensures rights and prods are arrays.
        rights = rights.to_a
        prods = prods.to_a
        # Left value (the scale) and right value.
        typ.inner :lv
        rvs = rights.each_with_index.map { |left,i| typ.inner :"rv#{i}" }
        # lv and rv are valid.
        inner :lvok
        rvoks = rights.each_with_index.map { |left,i| inner :"rvok#{i}" }
        # Run flag
        inner :run
        par(ev) do
            ack <= 0
            run <= 0
            hif(req | run) do
                run <= 1
                # Computation request.
                left.read(lv) { lvok <= 1 }
                rights.each_with_index do |right,i|
                    right.read(rvs[i]) { rvoks[i] <= 1 }
                    hif(lvok & rvoks[i]) do
                        ack <= 1
                        run <= 0
                        prods[i].write(mul.(lv,rvs[i]))
                    end
                end
            end
            helse do
                lvok <= 0
                rights.each_with_index do |right,i|
                    rvoks[i] <= 0
                end
            end
        end
    end


    # Declares a 1-dimension vector adder.
    #
    # Can be used for the sum of two vectors.
    function :add_n do |typ,ev,req,ack,lefts, rights, sums,
                        add = proc { |x,y| x+y }|
        # Ensure ev is really an event.
        ev = ev.posedge unless ev.is_a?(Event)
        # Ensures lefts and rights and sums are arrays.
        lefts = lefts.to_a
        rights = rights.to_a
        sums = sums.to_a
        # Left value and right value.
        lvs = lefts.each_with_index.map { |left,i| typ.inner :"lv#{i}" }
        rvs = lefts.each_with_index.map { |left,i| typ.inner :"rv#{i}" }
        # lv and rv are valid.
        lvoks = lefts.each_with_index.map { |left,i| inner :"lvok#{i}" }
        rvoks = lefts.each_with_index.map { |left,i| inner :"rvok#{i}" }
        # Run flag.
        inner :run
        par(ev) do
            ack <= 0
            run <= 0
            hif(req | run) do
                run <= 1
                # Computation request.
                lefts.zip(rights).each_with_index do |(left,right),i|
                    left.read(lvs[i])  { lvoks[i] <= 1 }
                    right.read(rvs[i]) { rvoks[i] <= 1 }
                    hif(lvoks[i] & rvoks[i]) do
                        run <= 0
                        ack <= 1
                        sums[i].write(add.(lvs[i],rvs[i]))
                    end
                end
            end
            helse do
                lefts.each_with_index do |left,i|
                    lvoks[i] <= 0
                    rvoks[i] <= 0
                end
            end
        end
    end

    # Declares a 1-dimension vector element-wise multiplier.
    function :mul_n do |typ,ev,req,ack,lefts, rights, prods,
                        mul = proc { |x,y| x*y }|
        add_n(typ,ev,req,ack,lefts,rights,prods,mul)
    end


    # Declares a simple multiplier accumulator.
    #
    # Can be used for the scalar product of two vectors.
    function :mac do |typ,ev,req,ack,left, right, acc,
        mul = proc { |x,y| x*y }, add = proc { |x,y| x+y }|
        # Ensure ev is really an event.
        ev = ev.posedge unless ev.is_a?(Event)
        # Left value and right value.
        typ.inner :lv, :rv, :av
        # lv and rv are valid.
        inner :lvok, :rvok
        # Run flag
        inner :run
        par(ev) do
            ack <= 0
            run <= 0
            hif(req | run) do
                run <= 1
                # Computation request.
                left.read(lv)  { lvok <= 1 }
                right.read(rv) { rvok <= 1 }
                # ( acc <= add.(acc,mul.(lv,rv)) ).hif(lvok & rvok)
                acc.read(av)
                hif(lvok & rvok) do
                    ack <= 1
                    run <= 0
                    acc.write(add.(av,mul.(lv,rv)))
                end
            end
            helse do
                lvok <= 0
                rvok <= 0
                acc.write(0)
            end
        end
    end


    # Declares a simple multiple mac with single right data.
    #
    # Can be used for the product of a martix-vector product.
    function :mac_n1 do |typ,ev,req,ack,lefts, right, accs,
        mul = proc { |x,y| x*y }, add = proc { |x,y| x+y }|
        # Ensure ev is really an event.
        ev = ev.posedge unless ev.is_a?(Event)
        # Ensures lefts is an array.
        lefts = lefts.to_a
        # Ensures accs is an array.
        accs = accs.to_a
        # Left value and right value.
        lvs = lefts.each_with_index.map { |left,i| typ.inner :"lv#{i}" }
        # Accumutated values.
        avs = lefts.each_with_index.map { |left,i| typ.inner :"av#{i}" }
        typ.inner :rv
        # lv and rv are valid.
        lvoks = lefts.each_with_index.map { |left,i| inner :"lvok#{i}" }
        inner :rvok
        # Run flag
        inner :run
        par(ev) do
            ack <= 0
            run <= 0
            hif(req | run) do
                run <= 1
                # Computation request.
                right.read(rv) { rvok <= 1 }
                lefts.each_with_index do |left,i|
                    left.read(lvs[i])  { lvoks[i] <= 1 }
                    # accs.read(i,avs[i])
                    accs[i].read(avs[i])
                    hif(lvoks[i] & rvok) do
                        ack <= 1
                        run <= 0
                        # accs.write(i,add.(avs[i],mul.(lvs[i],rv)))
                        accs[i].write(add.(avs[i],mul.(lvs[i],rv)))
                    end
                end
            end
            helse do
                rvok <= 0
                lefts.each_with_index do |left,i|
                    lvoks[i] <= 0
                    # accs.write(i,0)
                    accs[i].write(0)
                end
            end
        end
    end


end
