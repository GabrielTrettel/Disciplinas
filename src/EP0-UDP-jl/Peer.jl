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
    end
    flooding()

    # test_broadcast(ARGS[end])
    # gossip()
end
main()

end # module
