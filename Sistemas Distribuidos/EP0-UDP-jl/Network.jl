module Network end

export recv_msg,
       send_msg,
       Message
       # udp_init_server,
       # udp_init_client


include("NetUtils.jl")
include("Package.jl")

mutable struct Message
    value :: Any
    destination_port :: Int64
end


function recv_msg(rcv_msg_buffer::Channel{Any})
    net::Interface = get_network_interface()

    while true
        addr,package = recvfrom(net.socket)

        # TODO implement multiple msg recv
        dg::Datagram = decode(package)
        msg = decode_msg([dg])

        put!(rcv_msg_buffer, msg)
    end
end



function send_msg(send_msg_buffer::Channel{Message})
    # Send an string to who is listening on 'host' in 'port'
    socket = UDPSocket()
    host = ip"127.0.0.1"

    while true
        msg = take!(send_msg_buffer)
        
        data_grams = encode_and_split(msg.value)
        for dg in data_grams
            send(socket, host, msg.destination_port, dg)
        end
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
