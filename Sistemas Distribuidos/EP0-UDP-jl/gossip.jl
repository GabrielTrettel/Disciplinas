module Gossip

include("Network.jl")
include("NetUtils.jl")
include("Styles.jl")
include("Utils.jl")
include("Filesystem.jl")
using .Network
using .NetUtils
using .FileSystem


mutable struct PeerFS
    name  :: String
    port  :: Int64
    table :: Array{File}
end # PeerFS

# At each interval T1 (seconds), update the FS states
const T1 = 11
# At each interval T2 (seconds), X sends its states to a random peer W
const T2 = 7
# At each interval T3 (seconds), W sends the states of X to a random Z
const T3 = 5
# At each interval T4 (seconds), delete the files that were not received by some peer
const T4 = 37

const peers_table = Dict{String, PeerFS}

update_FS_table!(dir::String, tables_ch::Channel, owner_name::String, owner_port::Int64) =
          update_own_FS!(dir, tables_ch, owner_name, owner_port)

update_FS_table!(tables_ch::Channel, peer::Channel) = update_others_FS!(tables_ch, peer)
update_FS_table!(tables_ch::Channel, t::Float64, dt::Float64) = update_old_files!(tables_ch, t, dt)


function update_own_FS!(dir::String, tables_ch::Channel, owner_name::String, owner_port::Int64)
    while true
        files_vec = parse_dir(dir)

        tables = take!(tables_ch)

        if !haskey(tables, owner_name)
            tables[owner_name] = PeerFS(owner_name, owner_port, files_vec)
        else
            tables[owner_name].table = merge_files(tables[owner_name].table, files_vec)
        end

        put!(tables_ch, tables)
        sleep(T1)
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

        tables = take!(tables_ch)

        if !haskey(tables, peer.name)
            tables[peer.name] = peer
        else
            tables[peer.name].table = merge_files(tables[peer.name].table, peer.table)
        end

        put!(tables_ch, tables)
    end
end # function update_others_FS



"""
    update_old_files!(tables_ch, local_time, dt)

Removes all old files from all tables received from others peers
"""
function update_old_files!(tables_ch::Channel, t::Float64, dt::Float64)
    while true
        tables = take!(tables_ch)

        for (name,table) in tables
            tables[name] = remove_old_files!(table, t, dt)
        end

        put!(tables_ch, tables)
        sleep(T4)
    end

end # function update_old_files




"""
    gossip()

Instantiates all data structures and controls the timer of all behaviors.
"""
function gossip()
    tables = peers_table()

    tables_ch = Channel{peers_table}(1)

    rcv_msg_buffer = Channel{Any}(1024)
    send_msg_buffer = Channel{Any}(1024)
    @async begin
        try
            bind_connections(rcv_msg_buffer, send_msg_buffer)
        catch y
            show_stack_trace()
        end # try
    end # async


    @async begin
        try
            bind_connections(rcv_msg_buffer, send_msg_buffer)
        catch y
            show_stack_trace()
        end # try
    end # async




end # function


end  # module Gossip
