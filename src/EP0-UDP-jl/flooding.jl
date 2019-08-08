module Flooding

export flooding

include("Network.jl")
include("Styles.jl")
include("Utils.jl")
include("Filesystem.jl")
include("flooding_utils.jl")

using .Network
using .Network.NetUtils
using .FileSystem

using Sockets

mode = ""
const TTL = 3 # Time to live of message

# "Doing a macgyver" to only printing the correct informations,
# based on what mode this peer are.
Base.println(m::String, x::String) = if m == mode println(x) end

function flooding(modes::String="c")
    global mode = modes
    rcv_msg_buffer = Channel{Any}(1024)   # | Those are used for sending/receiving
    send_msg_buffer = Channel{Any}(1024)  # | messages by flooding protocol, not the file itself.

    net          = get_network_interface()           # |
    flooding_net = get_flooding_interface(net.name)  # | Both are NetUtils.Interface

    flooding_rcv_buffer = Channel{Any}(1024)  # This is used to receive the movie.
    to_process_controller  = Channel{Any}(100)


    set_sign_of_life(net.name, net.port)
    my_name = net.name
    my_path = "../../peers/$(net.name)/"

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


    @async begin
        try
            flood_replies_processor(flooding_rcv_buffer, to_process_controller, my_path)
        catch y
            show_stack_trace()
        end # try
    end # async


    # Runs query dealer for answering searched data in distributed system
    @async begin
        try
            flood_handler(rcv_msg_buffer, send_msg_buffer, my_path, net)
        catch y
            show_stack_trace()
        end # try
    end # async


    # If in server mode, there is no need for interfacing with user, so return
    if mode == "s" return end

    # Runs query dealer for searching data in distributed system
    @async begin
        try
            search_files_in_ds(send_msg_buffer, to_process_controller, flooding_net)
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
    reply       :: Union{Movie, Nothing} # Field reserved to msg reply content
    function FloodingMSG(qry, id, sip, sp, name, ttl=3)
        new(qry, id, ttl, sip, sp, name, nothing)
    end
end



"""
    search_files_in_ds(send_msg_buffer, net, flooding_net)

Interface for searching files in distributed system
"""
function search_files_in_ds(send_msg_buffer::Channel,
                            to_process_controller::Channel,
                            flooding_net::Interface)

    my_ip   = flooding_net.host
    my_port = flooding_net.port
    my_name = flooding_net.name
    id = 0

    while true
        search_for = get_qry_from_user()
        fl_msg = FloodingMSG(search_for, id, my_ip, my_port, my_name, TTL)
        println("c", " Searching for $search_for file in DS...")
        put!(to_process_controller, id)
        id+=1

        flood_msg(fl_msg, send_msg_buffer)
    end
end


"""
    flood_replies_processor(flooding_rcv_buffer, to_process_controller)

Processes all replies from flooded messages, and persist just the first one (per query), ignoring others
"""
function flood_replies_processor(flooding_rcv_buffer::Channel, to_process_controller::Channel, path::String)
    queries_request = Set()
    movies = []

    while true
        sleep(0.5)
        request_id = 0
        # Blocks while user does not make a query
        if isready(to_process_controller)
            request_id = take!(to_process_controller)
            push!(queries_request, request_id) # Now, I'm expecting for this ID to arrive.
        end

        # Blocks while not receiving query result
        flag = false
        while isready(flooding_rcv_buffer)
            flag = true
            push!(movies, take!(flooding_rcv_buffer))
        end
        if flag map(x->decide_if_save!(x,queries_request, path), movies) end
    end
end


function decide_if_save!(ans::FloodingMSG, queries_request::Set, path::String)
    if ans.query_id in queries_request
        movie = ans.reply
        println("c", " \n$CGREEN $(movie.name) found. Already downloaded\n\n")

        persist(movie, path)
        pop!(queries_request, ans.query_id)
    end
end



"""
    flood_msg(args)

Flood msg to all kwnow peers
"""
function flood_msg(msg::FloodingMSG, s_buff::Channel)
    if msg.TTL < 0
        println("s", " Request \"$(msg.query)\"\n from   $(msg.sender_name)\nDying here because TTL == 0")
        return
    end

    peers = get_alive_peers()
    while length(peers) < 1 sleep(2)
        peers = get_alive_peers()
    end  # Wait until some kwown peer is online

    # === HERE WE FLOOD MSG TO ALL KNOWN PEERS ===
    ss = ""
    for (peer_name, peer_port) in peers
        if peer_name == msg.sender_name continue end
        ss *= "$peer_name, "
        put!(s_buff, Message(msg, peer_port))
    end

    println("s", " Flooding msg to those peers $(ss[1 : end-1])\n")
    # === HERE WE FLOOD MSG TO ALL KNOWN PEERS ===
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

        if !(r_id in received_requests)
            request.TTL -= 1
            println("s", " $CYELLOW $(request.sender_name) is asking for $(request.query): ")
            file = get_file(request.query, my_path)

            if file != false
                reply_to_sender(request, send_msg_buffer, my_path, file)
            else
                println("s", " $CYELLOW I don't have it, flooding to others...")
                flood_msg(request,send_msg_buffer)
            end

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
    full_path = my_path * (my_path[end] == "/" ? "" : "/") * file

    movie = Movie(my_path*file)
    request.reply = movie

    println("s", " $CYELLOW\t I have $(file), SENDING TO HIM...\n")
    put!(s_buff, Message(request, request.sender_port))
    movie = nothing
end


end # module
