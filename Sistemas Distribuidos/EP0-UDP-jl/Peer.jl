module Peer end

include("NetProtocols.jl")


function main()
    if ARGS[end] == "s"
        test_listen_protocol()

    elseif ARGS[end] == "c"
        test_bd_protocol()
    end
end

main()
