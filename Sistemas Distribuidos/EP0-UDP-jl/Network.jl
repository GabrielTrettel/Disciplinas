module Network end

export udp_recv,
       udp_send
       # udp_init_server,
       # udp_init_client


include("NetUtils.jl")
include("Package.jl")


function udp_recv(socket::UDPSocket, host::IPAddr, port::Integer)
    # TODO: merge msgs in correct order and build the entire msg

    addr,package = recvfrom(socket)

    msg = decode_and_merge(package)
    return addr,msg
end




function udp_send(socket::UDPSocket, host::IPAddr, port::Integer, msg::Any)
    # Send an string to who is listening on 'host' in 'port'
    # TODO: break msg into parts and send individually
    msg = encode_and_split(msg)
    send(socket, host, port, msg)
end



function bind_port(socket::UDPSocket)
    HOST = Net_utils().host
    name,port = ("","")
    for a in Net_utils().port_queue
        name,port = a
        if bind(socket, HOST, port)
            println("\33[32mPort $port in use by $name")
            break
        end
    end

   return port,name
end
