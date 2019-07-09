module NetProtocols

export test_broadcast

include("Network.jl")
include("NetUtils.jl")
include("Styles.jl")
include("Utils.jl")
using .Network
using .NetUtils



function test_broadcast(type)
    rcv_msg_buffer = Channel{Any}(1024)
    send_msg_buffer = Channel{Any}(1024)
    @async begin
        try
            bind_connections(rcv_msg_buffer, send_msg_buffer)
        catch y
            show_stack_trace()
        end
    end


    if type == "s"
        test_listen_protocol(rcv_msg_buffer)
    else
        test_bd_protocol(send_msg_buffer)
    end
end


function test_listen_protocol(channel::Channel)
    while true
        msg = take!(channel)

        println("$CVIOLET2 recieved: $msg of type $(typeof(msg))")
    end
end


function test_bd_protocol(channel)
    sleep(1)
    while true
        print("$CBLUE Hit enter to send big msg: ")
        msg = string(readline())

        for port in values(Net_utils().ports_owner)
            msg_s = Message(msg,port)
            put!(channel, msg_s)
        end
    end
end

end # module
