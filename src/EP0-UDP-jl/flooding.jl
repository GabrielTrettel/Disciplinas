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
            flood_replies_processor(flooding_rcv_buffer, to_process_controller)
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
    end
end


"""
    flood_msg(args)

Flood msg to all kwnow peers
"""
function flood_msg(msg::FloodingMSG, s_buff::Channel)
    if msg.TTL < 0 return end


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
function flood_replies_processor(flooding_rcv_buffer::Channel, process_flood_controller::Channel)
    queries_request = Set()
    movies = []

    while true
        sleep(0.5)
        request_id = 0
        # Blocks while user does not make a query
        if isready(process_flood_controller)
            request_id = take!(process_flood_controller)
            push!(queries_request, request_id) # Now, I'm expecting for this ID to arrive.
        end

        # Blocks while not receiving query result
        flag = false
        while isready(flooding_rcv_buffer)
            flag = true
            push!(movies,take!(flooding_rcv_buffer))
        end
        if flag map(x->decide_if_save!(x,queries_request), movies) end

    end
end

function decide_if_save!(movie::Movie, queries_request)
    if movie.query_id in queries_request
        persist(movie)
        pop!(queries_request, movie.query_id)
    end
end



"""
    flood_handler(rcv_msg_buffer, send_msg_buffer, my_path, net)

Handles incoming requests and forwards messages if doesn't have the file
"""
function flood_handler(rcv_msg_buffer, send_msg_buffer, my_path, net)
    received_requests = Set()

    while true
        request::FloodingMSG = take!(rcv_msg_buffer)
        r_id = "$(request.sender_name)-$(request.query_id)"

        if !haskey(received_requests, r_id)
            request.TTL -= 1
            file = get_file(request, my_path)
            file != false ? reply_to_sender(request, send_msg_buffer, my_path, file) : flood_msg(request,send_msg_buffer)
            push!(received_requests, r_id)
        else
            # REQUEST ALREADY PROCESSED, IGNORING
            continue
        end
    end
end


"""
    reply_to_sender(request::FloodingMSG, s_buff::Channel)

Reply the asked file to sender
"""
function reply_to_sender(request::FloodingMSG, s_buff::Channel, my_path::String, file::String)
    full_path = path * (path[end] == "/" ? "" : "/") * file

    movie = Movie(my_path*file)

    put!(s_buff, Message(movie, movie.sender_port))
end


end
