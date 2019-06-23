module NetProtocols end

export test_listen_protocol,
       test_bd_protocol

include("Network.jl")
include("NetUtils.jl")

using Sockets



function test_listen_protocol()
    socket = UDPSocket()
    HOST = Net_utils().host
    PORT,owner = bind_port(socket)

    task = @async begin
        while true
            addr,msg = udp_recv(socket, HOST, PORT)
            println("\33[34m Msg from $addr is: $(msg)")
        end
    end
    wait(task)
end


function test_bd_protocol(msg::Any)
    socket = UDPSocket()
    HOST = Net_utils().host
    ports = [x for x in values(Net_utils().ports_owner)]

    while true
        _udp_broadcast(socket, HOST, ports, msg)
        break
    end
end



function _udp_broadcast(socket::UDPSocket, host::IPAddr, ports::AbstractArray{Int64}, msg::Any)
   for port in ports
       udp_send(socket, host, port, msg)
   end
end
