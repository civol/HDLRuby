module HDLRuby::High::Std

##
# Standard HDLRuby::High library: connectors between channels
# 
########################################################################

    # Function for generating a connector that duplicates the output of
    # channel +in_ch+ and connect it to channels +out_chs+ with data of
    # +typ+.
    # The duplication is done according to event +ev+.
    # The optional req and ack arguments are the signals for controlling the
    # duplicator using a handshake protocol. If set to nil, the duplicator
    # runs automatically.
    function :duplicator do |typ, ev, in_ch, out_chs, req = nil, ack = nil|
        ev = ev.poswedge unless ev.is_a?(Event)
        inner :in_ack
        inner :in_req
        out_acks = out_chs.size.times.map { |i| inner(:"out_ack#{i}") }
        typ.inner :data
        par(ev) do
            if (ack) then
                # Output ack mode.
                ack <= 0
            end
            if (req) then
                # Input request mode.
                in_req <= 0
                hif(req) { in_req <= 1 }
            else
                # Automatic mode.
                in_req <= 1
            end
            out_acks.each { |ack| ack <= 0 }
            out_acks.each do |ack| 
                hif(ack == 1) { in_req <= 0 }
            end
            hif(in_req) do
                in_ack <= 0
                in_ch.read(data) { in_ack <= 1 }
            end
            hif(in_ack) do
                out_chs.zip(out_acks).each do |ch,ack|
                    hif(ack == 0) { ch.write(data) { ack <= 1 } }
                end
                hif (out_acks.reduce(_1) { |sum,ack| ack & sum }) do
                    out_acks.each { |ack| ack <= 0 }
                    if (ack) then
                        # Output ack mode.
                        ack <= 1
                    end
                end
            end
        end
    end

    # Function for generating a connector that merges the output of
    # channels +in_chs+ and connects the result to channel +out_ch+ with
    # data of types from +typs+.
    # The merge is done according to event +ev+.
    function :merger do |typs, ev, in_chs, out_ch|
        ev = ev.posedge unless ev.is_a?(Event)
        inner :out_ack
        in_reqs = in_chs.size.times.map { |i| inner(:"in_req#{i}") }
        in_acks = in_chs.size.times.map { |i| inner(:"in_ack#{i}") }
        datas =   typs.map.with_index { |typ,i| typ.inner(:"data#{i}") }
        par(ev) do
            in_reqs.each { |req| req <= 1 }
            out_ack <= 0
            hif(out_ack == 1) { in_reqs.each { |req| req <= 0 } }
            hif(in_reqs.reduce(_1) { |sum,req| req & sum }) do
                in_chs.each_with_index do |ch,i|
                    in_acks[i] <= 0
                    ch.read(datas[i]) { in_acks[i] <= 1 }
                end
            end
            hif(in_acks.reduce(_1) { |sum,req| req & sum }) do
                hif(out_ack == 0) { out_ch.write(datas) { out_ack <= 1 } }
                hif (out_ack == 1) { out_ack <= 0 }
            end
        end
    end


    # Function for generating a connector that serialize to the output of
    # channels +in_chs+ and connects the result to channel +out_ch+ with
    # data of +typ+.
    # The merge is done according to event +ev+.
    function :serializer do |typ, ev, in_chs, out_ch|
        ev = ev.posedge unless ev.is_a?(Event)
        size = in_chs.size
        inner :out_ack
        # in_reqs = size.times.map { |i| inner(:"in_req#{i}") }
        in_acks = size.times.map { |i| inner(:"in_ack#{i}") }
        datas =   size.times.map { |i| typ.inner(:"data#{i}") }
        # The inpt channel selector
        [size.width].inner :idx
        inner :reading
        par(ev) do
            # in_reqs.each { |req| req <= 1 }
            idx <= 0
            reading <= 0
            out_ack <= 0
            hif(idx == size-1) { in_acks.each { |ack| ack <= 0 } }
            # hif((idx == 0) & (in_reqs.reduce(_1) { |sum,req| req & sum })) do
            hif(idx == 0) do
                hif(~reading) do
                    size.times { |i| in_acks[i] <= 0 }
                end
                reading <= 1
                in_chs.each_with_index do |ch,i|
                    hif(~in_acks[i]) do
                        ch.read(datas[i]) { in_acks[i] <= 1 }
                    end
                end
            end
            hif(in_acks.reduce(_1) { |sum,req| req & sum }) do
                hcase(idx)
                datas.each_with_index do |data,i|
                    hwhen(i) do
                        out_ch.write(data) { idx <= idx + 1; out_ack <= 1 }
                    end
                end
            end
        end
    end


end 
