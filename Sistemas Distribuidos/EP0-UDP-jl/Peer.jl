module Peer end

include("NetProtocols.jl")


function main()
    if ARGS[end] == "s"
        test_listen_protocol()

    elseif ARGS[end] == "c"
        while true
            msg = "Message broadcasted to EVERYONE"
            test_bd_protocol(msg)
            sleep(1)
        end
    end
end

main()
