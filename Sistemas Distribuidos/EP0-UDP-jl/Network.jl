module Network

export bind_connections,
       Message,
       MsgRcvd

using Sockets

include("Styles.jl")
include("Package.jl")
include("NetUtils.jl")
using .Package
using .NetUtils


mutable struct Message
    value :: Any
    destination_port :: Int64
end


mutable struct MsgRcvd
    msg_id :: String
end


function bind_connections(rcv_buff::Channel, send_buff::Channel) :: Nothing
    net::Interface = get_network_interface()

    @async recv_msg(rcv_buff, send_buff, net)
    @async send_msg(send_buff, net)
end


function recv_msg(rcv_buff::Channel{Any}, send_buff::Channel, net::Interface) :: Nothing
    datagrams_map = Dict{String, Array{Datagram}}()

    while true
        addr,package = recvfrom(net.socket)
        dg::Datagram = decode(package)

        if length(dg.command) > 0
            put!(send_buff, dg.command)
            continue
        end

        msg_id = dg.msg_id
        if haskey(datagrams_map, msg_id) == false
            datagrams_map[msg_id] = [Datagram() for _ in 1:dg.total]
        end

        msg_seq = dg.sequence
        datagrams_map[msg_id][msg_seq] = dg

        if isempty(filter(x -> "-1" == x.msg_id, datagrams_map[msg_id]))
            msg = decode_msg(pop!(datagrams_map, msg_id))
            put!(rcv_buff, msg)
            put!(send_buff, Message(MsgRcvd(msg_id), dg.sender_port))
        end
    end
end


function send_msg(send_msg_buffer::Channel{Any}, net::Interface) ::Nothing
    # Send an string to who is listening on 'host' in 'port'
    socket = net.socket
    host = net.host

    datagrams_map = Dict{String, Tuple{Task,Channel}}()

    controller = Channel{MsgRcvd}(1024)
    while true
        msg = take!(send_msg_buffer)
        send_dg(msg, controller, datagrams_map, net)
    end
end


send_dg!(msg::Any,      controller::Channel{MsgRcvd}, net::Interface) = _send_dg(msg, controller, net)
send_dg!(msg::MsgRcvd, controller::Channel{MsgRcvd}, net::Interface) = _kill_task(msg, controller, net)

function _send_dg(msg::DataGramVec, controller::Channel{MsgRcvd}, net)
    msg_h, dg = encode_and_split(msg, net, "")
    i = 1

    task = @async whatch_for_rcv_msg(msg_h, controller)

    while i < 15
        i += 1
        if istaskdone(task) break end

        for dg in data_grams
            send(socket, host, msg.destination_port, dg)
        end
        sleep(5)
    end
end


function _kill_task(msg::MsgRcvd, controller::Channel{MsgRcvd}, net::Interface)
    put!(controller, msg)
end


function whatch_for_rcv_msg(msg_h::String, controller::Channel)
    for id in controller
        if id.msg_id == msg_h
            return
        else
            put!(controller, id)
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
            println("$CBLINK $CGREEN Port $port in use by $name $CEND")
            break
        end
    end

    return Interface(socket,port,host,name)
end

end # module
