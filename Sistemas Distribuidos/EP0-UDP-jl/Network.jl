module Network

export bind_connections,
       Message

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

mutable struct Controller
    request :: String
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

        msg_id = dg.msg_id
        if haskey(datagrams_map, msg_id) == false
            datagrams_map[msg_id] = [Datagram() for _ in 1:dg.total]
        end

        msg_seq = dg.sequence
        datagrams_map[msg_id][msg_seq] = dg

        if isempty(filter(x -> "-1" == x.msg_id, datagrams_map[msg_id]))
            msg = decode_msg(pop!(datagrams_map, msg_id))
            put!(rcv_buff, msg)
            send
        end
    end
end


function send_msg(send_msg_buffer::Channel{Message}, net::Interface) ::Nothing
    # Send an string to who is listening on 'host' in 'port'
    socket = net.socket
    host = net.host

    datagrams_map = Dict{String, Tuple{Task,Channel}}()

    while true
        msg = take!(send_msg_buffer)
        send_dg(data_grams, datagrams_map)
    end
end


send_dg!(dg::Any, ch::Channel, dic::Dict{String, Tuple{Task,Channel}}) = _send_dg(dg, msg_hash, ch)
send_dg!(cmd::Controller, ch::Channel, dic::Dict{String, Tuple{Task,Channel}}) = _kill_task(cmd, ch, dic)

function _send_dg(dg::DataGramVec, msg_hash, ch::Channel)
    dic::Dict{String, Tuple{Task,Channel}}


    while 15
        for dg in data_grams
            send(socket, host, msg.destination_port, dg)
        end
        if isready(ch)
            for id in ch
                if id == msg_hash
                    return
                else
                    put!(ch, id)
                end
            end
        end
        sleep(5)
    end
end

function _kill_task(cmd::Controller, dic::Dict{String, Tuple{Task,Channel}})
    1
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
