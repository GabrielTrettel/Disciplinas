module Gossip

export gossip

using Random

include("Network.jl")
include("NetUtils.jl")
include("Styles.jl")
include("Utils.jl")
include("Filesystem.jl")
using .Network
using .NetUtils
using .FileSystem


mutable struct PeerFS
    name  :: Union{String, Nothing}
    port  :: Union{Int64, Nothing}
    table :: Union{Array{File}, Nothing}
end # PeerFS

# At each interval T1 (seconds), update the FS states
const T1 = 11
# At each interval T2 (seconds), X sends its states to a random peer W
const T2 = 7
# At each interval T3 (seconds), W sends the states of X to a random Z
const T3 = 5
# At each interval T4 (seconds), delete the files that were not received by some peer
const T4 = 37.0

const peers_table = Dict{String, PeerFS}
MY_NAME = ""


function print_rcv(peer::PeerFS)
    str = "$(CBLUE)Message received by gossip of peer $(peer.name) containing this files:\n"

    if length(peer.table) < 1
        str *= "\tEMPTY FS\n"
    end

    for f in peer.table
        str *= "\t - $(f.name)\n"
    end
    println(str)
end

function update_own_FS!(dir::String, tables_ch::Channel, owner_name::String, owner_port::Int64)
    while true
        try
            println("\n$(CGREEN2)Updating own FS:")
            files_vec = parse_dir(dir)

            tables = take!(tables_ch)
            # println("========= update_own_FS TAKE")


            if !haskey(tables, owner_name)
                tables[owner_name] = PeerFS(owner_name, owner_port, files_vec)
            else
                tables[owner_name].table = merge_files(tables[owner_name].table, files_vec)
            end

            put!(tables_ch, tables)
            # println("========= update_own_FS TAKE")

            sleep(T1)
        catch
            show_stack_trace()
        end
    end
end # function update_own_FS



"""
    update_others_FS!(tables_channel, peer)
Updates local table by other peer's informations.
Just updates files with a more recent mtime time.
"""
function update_others_FS!(tables_ch::Channel, rcv_ch::Channel)
    while true
        peer = take!(rcv_ch)

        if typeof(peer) != PeerFS
            println("$CVIOLET =====DEBUG PORPOSE:=====\nWeird msg rcved:\nTypeof rcvd msg $(typeof(peer)) $CEND")
            continue
        end

        t = time()
        for p in peer.table
            p.rcv_time = t
        end

        tables = take!(tables_ch)
        # println("========= update_others_FS TAKE")
        print_rcv(peer)

        if !haskey(tables, peer.name)
            tables[peer.name] = peer
        else
            tables[peer.name].table = merge_files(tables[peer.name].table, peer.table)
        end

        put!(tables_ch, tables)
        # println("========= update_others_FS PUT")

    end
end # function update_others_FS



"""
    update_old_files!(tables_ch, local_time, dt)

Removes all old files from all tables received from others peers
"""
function update_old_files!(tables_ch::Channel)
    while true
        tables = take!(tables_ch)
        # println("=========update_old_files TAKE")

        t = time()
        for (name,peer) in tables
            println("$(CRED2)Deleting old files of $name")
            tables[name].table = remove_old_files!(peer.table, t, T4)
        end

        put!(tables_ch, tables)
        # println("=========update_old_files PUT")

        sleep(T4)
    end

end # function update_old_files


"""
    send_table_x(tables_channel, send_buff, name)

Send information of peer `name` to peer in port `destination`
"""
function send_table_x(tables_ch::Channel, send_buff::Channel, name::String, dest_p::Int64, dest_n::String)
    tables = take!(tables_ch)
    # println("=========send_table_x TAKE")

    if !haskey(tables, name)
        println("$name has empty FS to send")
        put!(tables_ch, tables)
        return
     end

    peer = tables[name]
    println("$CGREEN Sending $(name) files by gossip to peer $(dest_n) in port $dest_p")
    put!(send_buff, Message(peer, dest_p))

    put!(tables_ch, tables)
    # println("=========send_table_x PUT")

end # function


function send_my_table(tables_ch::Channel, send_buff::Channel, name::String)
    while true
        peers = get_alive_peers()
        if length(peers) < 1 sleep(1); continue; end
        peer = peers[rand(1:end)]

        send_table_x(tables_ch, send_buff, name, peer[2], peer[1])
        sleep(T2)
    end
end

function send_others_table(tables_ch::Channel, send_buff::Channel)
    while true
        peers = get_alive_peers()
        if length(peers) < 2 sleep(1); continue; end
        peers = shuffle!(peers)
        des_name,des_port = peers[end]

        tables = take!(tables_ch)
        # println("=========send_others_table TAKE")
        names = shuffle(collect(keys(tables)))
        if length(names) < 1
            put!(tables_ch, tables)
            sleep(T3)
        end
        src_name = names[end]

        # println("=========send_others_table PUT")

        send_table_x(tables_ch, send_buff, src_name, des_port, des_name)

        sleep(T3)
    end
end

"""
    gossip()

Instantiates all data structures and controls the timer of all behaviors.
"""
function gossip()
    rcv_msg_buffer = Channel{Any}(1024)
    send_msg_buffer = Channel{Any}(1024)

    net = get_network_interface()
    set_sign_of_life(net.name, net.port)
    my_name = net.name

    tables = peers_table()
    tables_ch = Channel{peers_table}(1)
    put!(tables_ch, tables)

    @async begin
        try
            bind_connections(rcv_msg_buffer, send_msg_buffer, net)
        catch y
            show_stack_trace()
        end # try
    end # async


    @async begin
        try
            update_own_FS!("../$(net.name)/", tables_ch, net.name, net.port)
        catch y
            show_stack_trace()
        end # try
    end # async


    @async begin
        try
            update_others_FS!(tables_ch, rcv_msg_buffer)
        catch y
            show_stack_trace()
        end # try
    end # async


    @async begin
        try
            update_old_files!(tables_ch)
        catch y
            show_stack_trace()
        end # try
    end # async


    @async begin
        try
            send_my_table(tables_ch, send_msg_buffer, my_name)
        catch y
            show_stack_trace()
        end # try
    end # async


    @async begin
        try
            send_others_table(tables_ch, send_msg_buffer)
        catch y
            show_stack_trace()
        end # try
    end # async


    show_stack_trace()

    wait()

end # function

end  # module Gossip
