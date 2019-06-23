# module NetUtils end

export Net_utils,
       Input

using Sockets

mutable struct Net_utils
    port_queue  :: Array{Tuple{String,Int64}}
    ports_owner :: Dict{String,Int64}
    used_ports  :: Array{Tuple{String,Int64}}
    host        :: IPAddr
    mtu         :: Int64

    function Net_utils()
        port_queue= [("T1", 4301), ("T2", 4302), ("T3", 4303), ("T4", 4304),
                  ("T5", 4305), ("T6", 4306), ("T7", 4307), ("T8", 4308)]

        ports_owner = Dict(port_queue)
        used_ports = similar(port_queue)
        host = ip"127.0.0.1"
        mtu = 65508 # mtu arg of loopback from ifconfig

        new(port_queue, ports_owner, used_ports, host, mtu)
    end
end


function Input(prompt)
    print(prompt)
    readline()
end
