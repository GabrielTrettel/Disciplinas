module NetProtocols end

export test_listen_protocol,
       test_bd_protocol

include("Network.jl")
include("NetUtils.jl")

using Sockets


function test_listen_protocol()
    rcv_msg_buffer = Channel{Any}(1024)

    @async recv_msg(rcv_msg_buffer)

    while true
        msg = take!(rcv_msg_buffer)
        println("\33[34m Msg recieved: $msg of type $(typeof(msg))")
    end
end


function test_bd_protocol()
    send_msg_buffer = Channel{Message}(1024)
    @async send_msg(send_msg_buffer)

    while true
        sleep(1)
        print("Enter to send big msg")
        msg = string(readline())
        msg = "x -> x+1"

        for port in values(Net_utils().ports_owner)
            msg_s = Message(msg,port)
            put!(send_msg_buffer, msg_s)
        end

    end
end
