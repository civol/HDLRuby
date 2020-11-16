module HDLRuby::High::Std

##
# Standard HDLRuby::High library: connectors between channels
# 
########################################################################

    # Function for generating a connector that duplicates the output of
    # channel +inch+ and connect it to channels +outchs+ with data of
    # +typ+.
    # The duplication is done according to event +ev+.
    function :duplicator do |typ, ev, inch, outchs|
        ev = ev.poswedge unless ev.is_a?(Event)
        inner :in_ack, :in_req
        out_chacks = outchs.map.with_index do |ch,i|
            [ ch, inner(:"out_ack#{i}") ]
        end
        typ.inner :data
        par(ev) do
            in_req <= 1
            out_chacks.each { |ch,ack| ack <= 0 }
            out_chacks.each do |ch,ack| 
                hif(ack == 1) { in_req <= 0 }
            end
            hif(in_req) do
                in_ack <= 0
                inch.read(data) { in_ack <= 1 }
            end
            hif(in_ack) do
                out_chacks.each do |ch,ack|
                    hif(ack == 0) { ch.write(data) { ack <= 1 } }
                end
                hif (out_chacks.reduce(_1) { |sum,(ch,ack)| ack & sum }) do
                    out_chacks.each { |ch,ack| ack <= 0 }
                end
            end
        end
    end



end 
