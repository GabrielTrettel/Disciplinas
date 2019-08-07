module FileSystem

export File,
       Movie,
       parse_dir,
       merge_files,
       remove_old_files!,
       persist,
       get_file


include("Styles.jl")
using VideoIO
# using StringDistances


mutable struct File
    name   :: String        # Name of the file itself
    mtime  :: Float64       # Unix timestamp of when the file was last modified
    ctime  :: Float64       # Unix timestamp of when the file was created
    mode   :: UInt          # The protection mode of the file
    size   :: Int64         # The size (in bytes) of the file
    collect_time :: Float64 # Unix timestamp of when the file was parsed
    rcv_time     :: Float64 # Unix timestamp of when the file was recieved by peer
    function File(file_name::String)
        f_stat = stat(file_name)
        name  = file_name
        mtime = f_stat.mtime
        ctime = f_stat.ctime
        mode  = f_stat.mode
        size  = f_stat.size
        new(name, mtime, ctime, mode, size, time(), -1.0)
    end
end


mutable struct Movie
    name     :: String
    content  :: Array{UInt8}
    size     :: Real      # MBytes
    duration :: Real      # minutes
    function Movie(file_with_path::String)
        c = read(file_with_path)
        file_name = split(file_with_path, "/")[end]
        size = stat(file_with_path).size / 1024.0
        duration = VideoIO.get_duration(file_with_path) / 60.0

        new(file_name, c, size, duration)
    end
end



function parse_dir(dir::String) :: Vector{File}
    #=
        Receives a root directory and returns a vector of all the files inside it
        and their metadata. File names resolved as path-to-files in Unix format
    =#
    files_v::Vector{File} = []

    txt = "$(CVIOLET)Updating own FS:\n\tParsing FS. Files:\n"

    for (root, dirs, files) in walkdir(dir)
        for file in files
            fname = joinpath(root, file)
            txt *= "\t - $fname\n"
            push!(files_v, File(fname))
        end
    end
    println(txt*"───────────────────────────────────────────────────────\n\n")
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

    txt = "\n\n$(CGREEN)Replacing old files with new ones: \n"

    for file in keys(union_files)
        if !haskey(f1_table, file)
            push!(final_table, f2_table[file])
            txt *= "\t$file currently in table\n"
        elseif !haskey(f2_table, file)
            push!(final_table, f1_table[file])
            txt *= "\t$file currently in table\n"

        elseif f1_table[file].mtime >= f2_table[file].mtime
            push!(final_table, f1_table[file])
            txt *= "\t$file was replaced by a more recent state\n"

        else
            push!(final_table, f2_table[file])
            txt *= "\t$file was replaced by a more recent state\n"
        end
    end

    txt *= "───────────────────────────────────────────────────────\n\n"

    println(txt)
    return final_table
end


function show_files_data(files::Vector{File}) :: String
    str = ""
    for file in files
        str *= " - $(file.name)\n"
    end

    return str
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
    txt = ""
    flag = false
    for (i,file) in enumerate(files)
        if !f_dt(file)
            txt *= "\t$(CRED)Removing file $(file.name) by inactivity\n"
            flag = true
        end
    end
    if !flag
        txt *= "\t$(CRED)No files to be removed due to inactivity\n"
    end

    txt *= "───────────────────────────────────────────────────────\n\n"

    println(txt)
    filter!(f_dt, files)
end

"""
    persist(file::Movie, path:String)

Persist some file in <path> user filesystem
"""
persist(file::Movie, path::String) = p_movie(file, path)

function p_movie(file::Movie, path::String)
    try
        write(path*file.name, file.content)
    catch
        throw("Invalid path \"$path\" to save \"$file\"")
    end
end



n(x) = split(x, "/")[end]
# cc(t1,t2) = compare(Levenshtein(), n(t1), n(t2)) >= 0.90

function get_file(request::String, my_path::String)
    for (root, dirs, files) in walkdir(my_path)
        for file in files
            n(file) == n(request) ? (return joinpath(root, file)) : continue
        end
    end
    return false

end



end #module
