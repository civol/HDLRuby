module HDLRuby::High::Std

##
# Standard HDLRuby::High library: handshake protocols.
#
########################################################################


    ## Module describing a simple client handshake for working.
    #  @param event the event to synchronize the handshake.
    #  @param req   the signal telling a request is there.
    #  @param cond  the condition allowing the protocol.
    system :hs_client do |event, req, cond=_1|
        input :reqI
        output ackI: 0

        # A each synchronization event.
        par(event) do
            # Is the protocol is allowed and a request is present.
            hif(cond & reqI) do
                # Yes perform the action and tell the request has been treated.
                req  <= 1 if req
                ackI <= 1
            end
            helse do
                # No, do not perform the action, and do not acknowledge.
                req  <= 0 if req
                ackI <= 0
            end
        end
    end


    ## Module describing a simple server handshake for working.
    #  @param event the event to synchronize the handshake.
    #  @param req   the signal for asking a new request.
    system :hs_server do |event, req|
        output reqO: 0
        input  :ackO

        # A each synchronization event.
        par(event) do
            # Shall we start the output?
            hif(ackO)  { reqO <= 0 }
            hif(req)   { reqO <= 1 }
        end
    end


    ## Module describing a pipe with handshakes.
    #  @param event the event to synchronize the handshakes.
    #  @param read  the signal telling there is a request from the client side
    #  @param write the signal used for asking the server to issue a request
    system :hs_pipe do |event,read,write|
        inner :cond
        include(hs_client(event,read,cond))
        include(hs_server(event,write))
        cond <= ~reqO
    end
end
