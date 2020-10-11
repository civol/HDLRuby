module HDLRuby::High::Std


    ##
    # Standard HDLRuby::High library: linear algebra functions.
    #
    # NOTE: require channel-like interface.
    #
    ########################################################################

    # Controller of the linear operator.
    # - +num+: the number of computation cycles.
    # - +ev+: event to synchronize the controller on.
    # - +req+: the request to start the linear computation.
    # - +ack+: the ack signal that is set to 1 when the computation completes.
    # - +ruby_block+: the code of the linear computation kernel, it takes
    #                 as argument +ev+, and its own req and ack signals
    #                 (resp. +req_ker+ +ack_ker+).
    function :linearun do |num,ev,req,ack,ruby_block|
        # Ensure ev is really an event.
        ev = ev.posedge unless ev.is_a?(Event)

        # Creates the kernel.
        inner :req_ker, :ack_ker

        HDLRuby::High.top_user.instance_exec(ev,req_ker,ack_ker,&ruby_block)

        # The computation counter.
        [num.width].inner :count
        # Run flag
        inner :run
        par(ev) do
            req_ker <= 0
            ack <= 0
            count <= 1
            run <= 0
            hif(req | run) do
                run <= 1
                req_ker <= 1
                # Is one linear computation completed?
                hif(ack_ker) do
                    # Yes.
                    count <= count + 1
                end
                # Is the full computation completed?
                hif(count == num) do
                    # Yes.
                    ack <= 1
                    run <= 0
                    req_ker <= 0
                end
            end
        end
    end


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
        # Left value, right value and computation temp value.
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
                hif(lvok & rvok) do
                    ack <= 1
                    run <= 0
                    # acc.write(add.(av,mul.(lv,rv)))
                    seq do
                        av <= add.(av,mul.(lv,rv))
                        acc.write(av)
                    end
                end
            end
            helse do
                lvok <= 0
                rvok <= 0
                # acc.write(0)
                av <= 0
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
        woks = lefts.each_with_index.map { |left,i| inner :"wok#{i}" }
        # Run flag
        inner :run
        par(ev) do
            ack <= 0
            run <= 0
            hif(~run) do
                rvok <= 0
                lefts.each_with_index do |left,i|
                    lvoks[i] <= 0
                    # avs[i] <= 0
                    woks[i] <= 0
                end
            end
            hif(req | run) do
                run <= 1
                # Computation request.
                hif(~rvok) { right.read(rv) { rvok <= 1 } }
                lefts.each_with_index do |left,i|
                    hif(~lvoks[i]) { left.read(lvs[i])  { lvoks[i] <= 1 } }
                    # accs[i].read(avs[i])
                    hif(lvoks[i] & rvok & ~woks[i]) do
                        ack <= 1
                        run <= 0
                        seq do
                            avs[i] <= add.(avs[i],mul.(lvs[i],rv))
                            accs[i].write(avs[i]) do
                                woks[i] <= 1
                                # seq do
                                #     lvoks[i] <= 0
                                #     rvok <= lvoks.reduce(:|)
                                # end
                            end
                        end
                    end
                    hif (woks.reduce(:&)) do
                        woks.each { |wok| wok <= 0 }
                        lvoks.each { | lvok| lvok <=0 }
                        rvok <= 0
                    end
                end
            end
            helse { avs.each {|av| av <= 0 } }
            # helse do
            #     rvok <= 0
            #     lefts.each_with_index do |left,i|
            #         lvoks[i] <= 0
            #         # accs[i].write(0)
            #         avs[i] <= 0
            #     end
            # end
        end
    end


    # Declares a simple pipelined multiple mac with single right data.
    #
    # Can be used for the product of a martix-vector product.
    function :mac_np do |typ,ev,req,ack,lefts, rights, last,
        mul = proc { |x,y| x*y }, add = proc { |x,y| x+y }|
        # Ensure ev is really an event.
        ev = ev.posedge unless ev.is_a?(Event)
        # Ensures lefts is an array.
        lefts = lefts.to_a
        # Ensures rights is an array.
        rights = rights.to_a
        # Get the size of the pipeline and ensure lefts and rights have the
        # same.
        size = lefts.size
        if (rights.size != size) then
            raise "Incompatible lefts and rights sizes: lefts size is #{size} and rights size is #{rights.size}"
        end
        # Declares the accumulators.
        accs = size.times.map { |i| typ.inner :"acc#{i}" }
        # Left value and right value.
        lvs = lefts.each_with_index.map { |left,i| typ.inner :"lv#{i}" }
        rvs = rights.each_with_index.map { |right,i| typ.inner :"rv#{i}" }
        # typ.inner :rv
        # lv and rv are valid.
        lvoks = lefts.each_with_index.map { |left,i| inner :"lvok#{i}" }
        # inner :rvok
        rvoks = rights.each_with_index.map { |right,i| inner :"rvok#{i}" }
        # Run flag
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
                        ack <= 1
                        run <= 0
                        if (i < lefts.size-1) then
                            if (i>0) then 
                                accs[i] <= add.(accs[i],mul.(lvs[i],rvs[i])) +
                                    accs[i-1]
                            else
                                accs[i] <= add.(accs[i],mul.(lvs[i],rvs[i]))
                            end
                        else
                            # The last is reached
                            seq do
                                accs[i] <= add.(accs[i],mul.(lvs[i],rvs[i]))
                                last.write(accs[i])
                            end
                        end
                    end
                end
            end
            helse do
                lefts.each_with_index do |left,i|
                    lvoks[i] <= 0
                    rvoks[i] <= 0
                    accs[i] <= 0
                end
            end
        end
    end



end
