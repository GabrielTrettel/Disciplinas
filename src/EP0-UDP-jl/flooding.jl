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

const TTL = 3 # Time to live of message

function flooding()
    rcv_msg_buffer = Channel{Any}(1024)   # | Those are used for sending/receiving
    send_msg_buffer = Channel{Any}(1024)  # | messages by flooding protocol, not the file itself.

    net          = get_network_interface()           # |
    flooding_net = get_flooding_interface(net.name)  # | Both are NetUtils.Interface

    flooding_rcv_buffer = Channel{Any}(1024)
    process_flood_controller = Channel{Any}()

    set_sign_of_life(net.name, net.port)
    my_name = net.name

    @async begin
        try
            bind_connections(rcv_msg_buffer, send_msg_buffer, net)
        catch y
            show_stack_trace()
        end # try
    end # async


    @async begin
        try
            bind_connections(flooding_rcv_buffer, flooding_net)
        catch y
            show_stack_trace()
        end # try
    end # async


    @async begin
        try
            search_files_in_ds(send_msg_buffer, flooding_rcv_buffer, process_flood_controller, net, flooding_net)
        catch y
            show_stack_trace()
        end # try
    end # async

    @async begin
        try
            flood_replies_processor(flooding_rcv_buffer, process_flood_controller)
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
                            process_flood_controller::Channel,
                            net::Interface, flooding_net::Interface)

    my_ip   = flooding_net.port
    my_port = flooding_net.host
    my_name = flooding_net.name
    id = 0

    while true
        search_for = get_qry_from_user()

        fl_msg = FloodingMSG(search_for, id, my_ip, my_port, my_name, TTL)

        peers = get_alive_peers()

        while length(peers) < 1 sleep(1) end  # Wait until some kwown peer is online

        put!(process_flood_controller, id)
        id+=1

        # === HERE WE FLOOD MSG TO ALL KNOWN PEERS ===
        for (peer_name, peer_port) in peers
            put!(send_msg_buffer, Message(fl_msg, peer_port))
        end
        # === HERE WE FLOOD MSG TO ALL KNOWN PEERS ===

        take!(process_flood_controller)
end


"""
    flood_replies_processor(flooding_rcv_buffer, process_flood_controller)

Processes all replies from flooded messages, and persist just the first one, ignoring others
"""
function flood_replies_processor(flooding_rcv_buffer::Channel, process_flood_controller::Channel)
    to_consume_ids = Set{Integers}()

    while true
        # Blocks while user does not make a query
        request_id = take!(process_flood_controller)


        # Blocks while not receiving query result
        moovie = take!(flooding_rcv_buffer)



    end

end

end #module
