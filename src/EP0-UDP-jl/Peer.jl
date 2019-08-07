module Peer

include("NetProtocols.jl")
using .NetProtocols
# include("gossip.jl")
# using .Gossip
include("flooding.jl")
using .Flooding

function main()
    if length(ARGS) >= 1
        flooding(ARGS[1])
    else
        throw("Missing arg mode\n'c' for client, 's' for server")
    end

    wait()

    # test_broadcast(ARGS[end])
    # gossip()
end
main()

end # module
