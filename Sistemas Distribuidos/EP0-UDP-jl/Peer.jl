module Peer end

export udp_recv,
       udp_send
       # udp_init_server,
       # udp_init_client


using Sockets
using Serialization

include("Package.jl")


function Input(prompt)
    print(prompt)
    readline()
end

PORTS_OWNER = Dict([("T1", 4301), ("T2", 4302), ("T3", 430), ("T4", 4304),
                ("T5", 4305), ("T6", 4306), ("T7", 4307)])

const HOST = ip"127.0.0.1"



function udp_recv(socket::UDPSocket, host::IPAddr, port::Integer)
    # TODO: merge msgs in correct order and build the entire msg

    task = @async begin
        while true
            addr,package = recvfrom(socket)
            msg = String(package)
            println("Msg from $addr is: $msg")
            if msg == "break"
                close(socket)
                break
            end
        end
    end
    return task
end



function udp_send(socket::UDPSocket, host::IPAddr, port::Integer, msg::Any)
    # Send an string to who is listening on 'host' in 'port'
    # TODO: break msg into parts and send individually
    send(socket, host, port, msg)
end

function bind_port(socket::UDPSocket)
    name,port = ("","")
    for n in keys(PORTS_OWNER)
        name,port = n,PORTS_OWNER[n]
        if bind(socket, HOST, port)
            break
        end
    end

    println("\33[31m Bind listen on $port of $name\33[37m")
    return port,name
end


function main()
    socket = UDPSocket()

    if ARGS[end] == "s"
        PORT,owner = bind_port(socket)
        task = udp_recv(socket, HOST, PORT)
        wait(task)

    elseif ARGS[end] == "c"
        while true
            name = String(Input("\nWho do you want to call? $(keys(PORTS_OWNER)): "))
            if name == "q" close(socket); break end

            port = PORTS_OWNER[name]
            msg = String(Input("Type msg to $name: "))

            udp_send(socket,HOST,port,msg)
        end
    end
end

main()
