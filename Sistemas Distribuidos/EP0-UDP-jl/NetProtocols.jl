module NetProtocols end

export test_listen_protocol,
       test_bd_protocol,
       _udp_broadcast

include("Network.jl")
include("NetUtils.jl")

using Sockets



function test_listen_protocol()
    net::Interface = get_network_interface()
    full_msg_buffer = Channel{}(1024)

    while true
        addr,msg = udp_recv(net)
        println("\33[34m Msg from $addr is: $(msg)")
    end

end


function test_bd_protocol(msg::Any)
    while true
        _udp_broadcast(msg)
        break
    end
end



function _udp_broadcast(msg::Any)
    socket = UDPSocket()
    host = Net_utils().host
    ifcs = [Interface(socket,p,host,"",) for p in values(Net_utils().ports_owner)]

   for iface in ifcs
       udp_send(iface, msg, "trettel")
   end
end
