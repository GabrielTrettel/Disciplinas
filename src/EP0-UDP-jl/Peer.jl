module Peer

include("NetProtocols.jl")
include("gossip.jl")
using .NetProtocols
using .Gossip

function main()
    # test_broadcast(ARGS[end])
    gossip()
end
main()

end # module
