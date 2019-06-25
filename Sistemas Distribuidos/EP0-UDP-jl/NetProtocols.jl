module NetProtocols end

export test_listen_protocol,
       test_bd_protocol

include("Network.jl")
include("NetUtils.jl")

using Sockets



function test_listen_protocol()
    net::Interface = get_network_interface()

    while true
        addr,msg = udp_recv(net)
        println("\33[34m Msg from $addr is: $(msg)")
    end

end


function test_bd_protocol(msg::Any)
    socket = UDPSocket()
    host = Net_utils().host
    ports = [x for x in values(Net_utils().ports_owner)]

    while true
        _udp_broadcast(socket, host, ports, msg)
        break
    end
end



function _udp_broadcast(iface::Interface, msg::Any)
   for port in ports
       udp_send( msg)
   end
end
