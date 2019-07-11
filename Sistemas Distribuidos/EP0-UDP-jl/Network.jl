module Network

export bind_connections,
       Message,
       MsgRcvd,
       get_network_interface

using Sockets

include("Styles.jl")
include("Package.jl")
include("NetUtils.jl")
include("Utils.jl")
using .Package
using .NetUtils


mutable struct Message
    value :: Any
    destination_port :: Int64
end


function bind_connections(rcv_buff::Channel, send_buff::Channel, net=nothing)

    if net == nothing
        net::Interface = get_network_interface()
    end

    @async begin
        try
            recv_msg(rcv_buff, net)
        catch
            show_stack_trace()
        end
    end

    @async begin
        try
            send_msg(send_buff, net)
        catch
            show_stack_trace()
        end
    end

end


function recv_msg(rcv_buff::Channel{Any}, net::Interface)
        datagrams_map = Dict{String, Array{Datagram}}()

        while true
            addr,package = recvfrom(net.socket)
            dg::Datagram = decode(package)

            msg_id = dg.msg_id
            if haskey(datagrams_map, msg_id) == false
                datagrams_map[msg_id] = [Datagram() for _ in 1:dg.total]
            end

            msg_seq = dg.sequence
            datagrams_map[msg_id][msg_seq] = dg

            if isempty(filter(x -> "-1" == x.msg_id, datagrams_map[msg_id]))
                msg = decode_msg(pop!(datagrams_map, msg_id))
                put!(rcv_buff, msg)
            end
        end
    end



function send_msg(send_msg_buffer::Channel{Any}, net::Interface) ::Nothing
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
            println("$CGREEN Port $port in use by $name $CEND")
            break
        end
    end

    return Interface(socket, port, host, name)
end

end # module
