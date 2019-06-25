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
    msg::Datagram = decode_and_merge(package)

    return addr,msg
end


# function udp_recv



function udp_send(iface::Interface, msg::Any)
    # Send an string to who is listening on 'host' in 'port'
    # TODO: break msg into parts and send individually
    msg = encode_and_split(msg, owner)
    send(iface.socket, iface.host, iface.port, msg)
end



function get_network_interface() :: Interface
    socket = UDPSocket()

    host = Net_utils().host
    name,port = ("","")
    for a in Net_utils().port_queue
        name,port = a
        if bind(socket, HOST, port)
            println("\33[32mPort $port in use by $name")
            break
        end
    end

    return Interface(socket,port,host,name)
end
