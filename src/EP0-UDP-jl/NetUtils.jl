module NetUtils

using Sockets

export Net_utils,
       Interface


mutable struct Interface
    socket::Union{UDPSocket,Nothing}
    port::Union{Int64,Nothing}
    host::Union{IPAddr,Nothing}
    name::Union{String,Nothing}
    function Interface(socket=nothing, port=nothing, host=nothing, name=nothing)
        new(socket,port,host,name)
    end
end


mutable struct Net_utils
    port_queue  :: Array{Tuple{String,Int64}}
    ports_owner :: Dict{String,Int64}
    used_ports  :: Array{Tuple{String,Int64}}
    host        :: IPAddr
    mtu         :: Int64

    function Net_utils()
        port_queue= [("PEER1", 4301), ("PEER2", 4302), ("PEER3", 4303), ("PEER4", 4304),
                  ("PEER5", 4305), ("PEER6", 4306), ("PEER7", 4307), ("PEER8", 4308),
                  ("PEER9", 4309), ("PEER10", 4310), ("PEER11", 4311), ("PEER12", 4312)]

        ports_owner = Dict(port_queue)
        used_ports = similar(port_queue)
        host = ip"127.0.0.1"
        #=
            Maximum Transmission Unit (mtu) is a value defined by OS
            indicating how long a msg can be. In my computer, 65508 is the limit.
            - 1024 by convention
        =#
        mtu = 50508

        new(port_queue, ports_owner, used_ports, host, mtu)
    end
end



end # module
