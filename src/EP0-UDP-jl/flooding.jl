module Flooding

export flooding

include("Network.jl")
include("NetUtils.jl")
include("Styles.jl")
include("Utils.jl")
include("Filesystem.jl")
using .Network
using .NetUtils
using .FileSystem

using Sockets


const TTL = 3 # Time to live of message

function flooding()
    rcv_msg_buffer = Channel{Any}(1024)   # | Those are used for sending/receiving
    send_msg_buffer = Channel{Any}(1024)  # | messages by flooding protocol, not the file itself.

    net          = get_network_interface()           # |
    flooding_net = get_flooding_interface(net.name)  # | Both are NetUtils.Interface

    flooding_rcv_buffer = Channel{Any}(1024)
    process_flood_controller = Channel{Any}(1)

    set_sign_of_life(net.name, net.port)
    my_name = net.name
    my_path = "../PEERS/$(net.name)/"

    # Binds buffers exclusively for peer-to-peer "conversation" in flooding protocol
    @async begin
        try
            bind_connections(rcv_msg_buffer, send_msg_buffer, net)
        catch y
            show_stack_trace()
        end # try
    end # async

    # Binds buffers exclusively for peer-to-peer data transactions
    @async begin
        try
            bind_connections(flooding_rcv_buffer, flooding_net)
        catch y
            show_stack_trace()
        end # try
    end # async

    # Runs query dealer for searching data in distributed system
    @async begin
        try
            search_files_in_ds(send_msg_buffer, flooding_rcv_buffer, process_flood_controller, net, flooding_net)
        catch y
            show_stack_trace()
        end # try
    end # async


    # Runs query dealer for answering searched data in distributed system
    @async begin
        try
            flood_handler(rcv_msg_buffer, send_msg_buffer, net)
        catch y
            show_stack_trace()
        end # try
    end # async


end



mutable struct FloodingMSG
    query :: String
    query_id :: Integer
    TTL   :: Integer
    sender_ip :: IPAddr
    sender_port :: Integer
    sender_name :: String
    function FloodingMSG(qry, id, sip, sp, name, ttl=3)
        new(qry, id, ttl, sip, sp, name)
    end
end



"""
    search_files_in_ds(send_msg_buffer, net, flooding_net)

Interface for searching files in distributed system
"""
function search_files_in_ds(send_msg_buffer::Channel,
                            flooding_rcv_buffer::Channel,
                            net::Interface, flooding_net::Interface)

    my_ip   = flooding_net.port
    my_port = flooding_net.host
    my_name = flooding_net.name
    id = 0

    to_process_controller  = Channel()
    already_fetched_controller = Channel()
    @async begin
        try
            flood_replies_processor(flooding_rcv_buffer, to_process_controller, already_fetched_controller)
        catch y
            show_stack_trace()
        end # try
    end # async


    while true
        search_for = get_qry_from_user()
        fl_msg = FloodingMSG(search_for, id, my_ip, my_port, my_name, TTL)

        put!(to_process_controller, id)
        id+=1

        flood_msg(fl_msg, send_msg_buffer)

        t = @async force_exit(already_fetched_controller)
        # Blocks while not receiving query result, or user forces exit
        take!(already_fetched_controller)

        if !istaskdone(t)
            Base.throwto(t, InterruptException())
        end
    end
end


"""
    flood_msg(args)

Flood msg to all kwnow peers
"""
function flood_msg(msg::FloodingMSG, s_buff::Channel)
    peers = get_alive_peers()

    while length(peers) < 1 sleep(2)
        peers = get_alive_peers()
    end  # Wait until some kwown peer is online

    # === HERE WE FLOOD MSG TO ALL KNOWN PEERS ===
    for (peer_name, peer_port) in peers
        put!(s_buff, Message(fl_msg, peer_port))
    end
    # === HERE WE FLOOD MSG TO ALL KNOWN PEERS ===
end


"""
    flood_replies_processor(flooding_rcv_buffer, process_flood_controller)

Processes all replies from flooded messages, and persist just the first one, ignoring others
"""
function flood_replies_processor(flooding_rcv_buffer::Channel, process_flood_controller::Channel, already_fetched_controller)

    while true
        # Blocks while user does not make a query
        request_id = take!(process_flood_controller)
        if request_id == true continue end

        # Blocks while not receiving query result
        movie = take!(flooding_rcv_buffer)
        if moovie.query_id == request_id
            persist(movie)
            put!(already_fetched_controller, true)
        else
            put!(process_flood_controller, request_id)
        end
    end
end



function force_exit(ch::Channel)
    while lowercase(Input("Type 'q' to quit search ")) != "q" continue end
    put!(ch, true)
end

"""
    flood_handler(rcv_msg_buffer, send_msg_buffer, my_path, net)

Handles incoming requests and forwards messages if doesn't have the file
"""
function flood_handler(rcv_msg_buffer, send_msg_buffer, my_path, net)
    received_requests = Set()

    while true
        request::FloodingMSG = take!(rcv_msg_buffer)

        if !haskey(received_requests, request)
            i_have_file(request) ? reply_to_sender(request,send_msg_buffer) : flood_request(request,send_msg_buffer)
        else
            # REQUEST ALREADY PROCESSED, IGNORING
            continue
        end

end

end
