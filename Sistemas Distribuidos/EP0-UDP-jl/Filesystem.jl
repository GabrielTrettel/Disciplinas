module FileSystem

export File,
       parse_dir,
       merge_files,
       remove_old_files


mutable struct File
    name   :: String        # Name of the file itself
    owner  :: String        # Name of sender peer
    mtime  :: Float64       # Unix timestamp of when the file was last modified
    ctime  :: Float64       # Unix timestamp of when the file was created
    mode   :: UInt          # The protection mode of the file
    size   :: Int64         # The size (in bytes) of the file
    collect_time :: Float64 # Unix timestamp of when the file was parsed
    rcv_time     :: Float64 # Unix timestamp of when the file was recieved by peer
    function File(file_name::String, owner::String)
        f_stat = stat(file_name)
        name  = file_name
        owner = owner
        mtime = f_stat.mtime
        ctime = f_stat.ctime
        mode  = f_stat.mode
        size  = f_stat.size
        new(name, owner, mtime, ctime, mode, size, time(), -1.0)
    end
end



function parse_dir(dir::String, owner::String="Trettel") :: Vector{File}
    #=
        Receives a root directory and returns a vector of all the files inside it
        and their metadata. File names resolved as path-to-files in Unix format
    =#
    files_v::Vector{File} = []

    for (root, dirs, files) in walkdir(dir)
        for file in files
            push!(files_v, File(joinpath(root, file), owner))
            # println(joinpath(root, file))
        end
    end
    return files_v
end



function merge_files(files1::Vector{File}, files2::Vector{File}) :: Vector{File}
    #=
        Gets two File vectors and merges them using the last mtime of the
        corresponding names. The elements in the symmetric difference set
        are all included, regardless of mtime.
    =#

    f1_table = Dict( f.name => f for f in files1 )
    f2_table = Dict( f.name => f for f in files2 )
    union_files  = merge(f1_table, f2_table)

    final_table::Vector{File} = []

    for file in keys(union_files)
        if !haskey(f1_table, file)
            push!(final_table, f2_table[file])

        elseif !haskey(f2_table, file)
            push!(final_table, f1_table[file])

        elseif f1_table[file].mtime >= f2_table[file].mtime
            push!(final_table, f1_table[file])

        else
            push!(final_table, f2_table[file])
        end
    end
    return final_table
end



function remove_old_files!(files::Vector{File}, t::Float64, dt::Float64)
    #= Removes all old files from files

        "Old" refers to the received time of the File, not the mtime itself.
        Remove's inplace.

        Args
        ----
        t  -> Unix timestamp of actual time for peer
        dt -> Time difference, in seconds, of File.rcv_time and *t*
    =#

    f_dt(t1) = (t - t1.rcv_time) <= dt
    return filter!(f_dt, files)
end



end #module
