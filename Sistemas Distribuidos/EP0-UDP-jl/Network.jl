module Network

export bind_connections,
       Message,
       MsgRcvd

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


mutable struct MsgRcvd
    msg_id :: String
end


function bind_connections(rcv_buff::Channel, send_buff::Channel)
    net::Interface = get_network_interface()
    controller = Channel{MsgRcvd}(1024)

    @async begin
        try
            recv_msg(rcv_buff, send_buff, net, controller)
        catch
            show_stack_trace()
        end
    end

    @async begin
        try
            send_msg(send_buff, net, controller)
        catch
            show_stack_trace()
        end
    end

end


function recv_msg(rcv_buff::Channel{Any}, send_buff::Channel, net::Interface, controller::Channel)
    datagrams_map = Dict{String, Array{Datagram}}()

    while true
        addr,package = recvfrom(net.socket)
        dg = decode(package)
        println("tipo $(typeof(package)) --- $dg")

        msg_id = dg.msg_id
        if haskey(datagrams_map, msg_id) == false
            datagrams_map[msg_id] = [Datagram() for _ in 1:dg.total]
        end

        msg_seq = dg.sequence
        datagrams_map[msg_id][msg_seq] = dg

        if isempty(filter(x -> "-1" == x.msg_id, datagrams_map[msg_id]))
            msg = decode_msg(pop!(datagrams_map, msg_id))

            if length(dg.command) > 0
                put!(controller, MsgRcvd(msg_id))
            end

            put!(rcv_buff, msg)
            confirm_rcv(net, msg_id, dg.sender_port)
        end
    end
end


function confirm_rcv(net, msg_id, port)
    dgs = encode_and_split(msg_id, net, "recieved")

    for dg in dgs
        send(net.socket, net.host, port, dg)
    end
end



function send_msg(send_msg_buffer::Channel{Any}, net::Interface, controller) ::Nothing
    # Send an string to who is listening on 'host' in 'port'
    socket = net.socket
    host = net.host

    datagrams_map = Dict{String, Tuple{Task,Channel}}()
    while true
        msg = take!(send_msg_buffer)
        send_dg(msg, controller, net)
    end
end


send_dg(msg::Message, controller::Channel{MsgRcvd}, net::Interface) = _send_dg(msg, controller, net)

function _send_dg(msg::Message, controller::Channel{MsgRcvd}, net::Interface)
    msg_h, data_grams = encode_and_split(msg, net, "")
    i = 1

    task = @async begin
        try
            task = whatch_for_rcv_msg(msg_h, controller)
        catch
            show_stack_trace()
        end
    end

    while i < 15
        i += 1
        if istaskdone(task) break end

        println("\n {$(net.name), $(net.port)} Trying to send msg=$msg_h to $(msg.destination_port) attempt $i")
        for dg in data_grams
            send(net.socket, net.host, msg.destination_port, dg)
        end
        sleep(5)
    end
end


function whatch_for_rcv_msg(msg_h::String, controller::Channel)
    for id in controller
        println(id)
        if id.msg_id == msg_h
            println("Msg of id=$msg_h has bem rcvd")
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
            println("$CGREEN Port $port in use by $name $CEND")
            break
        end
    end

    return Interface(socket, port, host, name)
end

end # module
