module Package end

export encode_and_split,
       decode_and_merge

include("NetUtils.jl")


using Serialization

mutable struct Datagram
    msg::Any
    command::String
    sequence::Int64
    total::Int64
    owner::String
end


function encode_and_split(msg::Any, owner::String)
    iob = IOBuffer()
    Serialization.serialize(iob, msg)
    byte_array = iob.data

    MAX_MSG_SIZE = Net_utils().mtu - sizeof(Datagram)
    # MAX_MSG_SIZE = 1024 - sizeof(Datagram)

    MSG_SIZE = sizeof(byte_array)
    TOTAL_OF_PKGS = ceil(MSG_SIZE / MAX_MSG_SIZE)

    dg_vec = Datagram[]

    i = 1; j = MAX_MSG_SIZE
    seq = 1
    while i < MSG_SIZE
        msg_split = byte_array[i:min(MSG_SIZE, j)]

        dg = Datagram(msg_split,"",seq,TOTAL_OF_PKGS,owner)

        i += MAX_MSG_SIZE ; j+= MAX_MSG_SIZE ; seq += 1
        push!(dg_vec, dg)

    end

    return dg_vec

end



function decode_datagram(msgs::Vector{UInt8}) :: Datagram
    stream = IOBuffer(msgs)
    original_data::Datagram = Serialization.deserialize(stream)
end


function decode_msg(dgrams::Vector{Datagram}) :: Datagram
    total_msg = UInt8[]
    for dg in dgrams
        sub_msg = decode_datagram(dg)

end



function _teste()
    teste = encode_and_split("a"^10024,"owner")

    print(decode_and_merge(teste))

end
