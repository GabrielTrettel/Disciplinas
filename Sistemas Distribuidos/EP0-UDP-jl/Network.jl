module Network end

export udp_recv,
       udp_send,
       get_network_interface
       # udp_init_server,
       # udp_init_client


include("NetUtils.jl")
include("Package.jl")


function udp_recv(net::Interface)
    addr,package = recvfrom(net.socket)
    dg::Datagram = decode(package)

    return addr,decode_msg([dg])
end



function udp_send(iface::Interface, msg::Any, owner::String)
    # Send an string to who is listening on 'host' in 'port'
    # TODO: break msg into parts and send individually
    msg = encode_and_split(msg, owner)
    for dg in msg
        send(iface.socket, iface.host, iface.port, dg)
    end
end



function get_network_interface() :: Interface
    socket = UDPSocket()

    host = Net_utils().host
    name,port = ("","")
    for a in Net_utils().port_queue
        name,port = a
        if bind(socket, host, port)
            println("\33[32mPort $port in use by $name")
            break
        end
    end

    return Interface(socket,port,host,name)
end
