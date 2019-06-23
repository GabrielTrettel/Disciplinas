using Serialization

mutable struct Package
    msg::Any
    sequence::Int64
    total::Int64
    owner::String
end


function encode_and_split(msg::Any)
    # Parte de onde envia a mensagem
    x = IOBuffer()
    Serialization.serialize(x, msg)

    return x.data
end


function decode_and_merge(msgs::Vector{UInt8})
    # Quem recebe os dados de X pelo socket
    stream = IOBuffer(msgs)
    original_data = Serialization.deserialize(stream)
end

msg = encode_and_split(['a', 'b', 'c','a', 'b', 'c'])

decode_and_merge(msg)
Serialization.serialize()
AbstractSerializer


let x = 0, y = 2, z = 1 
    z
end
