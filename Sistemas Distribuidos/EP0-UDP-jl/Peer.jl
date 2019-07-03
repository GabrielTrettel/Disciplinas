module Peer

include("NetProtocols.jl")
using .NetProtocols


function main()
    test_broadcast(ARGS[end])
end
main()

end # module
