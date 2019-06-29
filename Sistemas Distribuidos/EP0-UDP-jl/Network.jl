module Network end

export recv_msg,
       send_msg,
       Message


include("NetUtils.jl")
include("Package.jl")

mutable struct Message
    value :: Any
    destination_port :: Int64
end



function recv_msg(rcv_msg_buffer::Channel{Any})
    net::Interface = get_network_interface()
    datagrams_map = Dict{String, Array}()

    while true
        addr,package = recvfrom(net.socket)
        dg::Datagram = decode(package)

        msg_id = dg.msg_id
        if haskey(datagrams_map, msg_id) == false
            datagrams_map[msg_id] = Any[0 for _ in 1:dg.total]
        end

        msg_seq = dg.sequence
        datagrams_map[msg_id][msg_seq] = dg


        possible_msg = verify_to_send(datagrams_map)
        if possible_msg != -1
            msg = decode_msg(possible_msg)
            put!(rcv_msg_buffer, msg)
        end
    end
end


function verify_to_send(datagrams_map::Dict{String, Array})
    for (key, value) in datagrams_map
        if isempty(filter(x -> 0 == x, value))
            return pop!(datagrams_map, key)
        end
    end
    return -1
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
