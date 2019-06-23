using Sockets
using Serialization

function Input(prompt)
    print(prompt)
    readline()
end

PORTS_OWNER = Dict([("Jorge", 4301), ("Cleiton", 4302), ("Romildo", 430), ("Chirley", 4304),
                ("Claudiene", 4305), ("Winderson", 4306), ("Rosvaldo", 4307)])

const HOST = ip"127.0.0.1"



function udp_recv(socket::UDPSocket, host::IPAddr, port::Integer)
    # TODO: merge msgs in correct order and build the entire msg

    task = @async begin
        while true
            addr,package = recvfrom(socket)
            msg = String(package)
            println("Mensagem de $addr é: $msg")
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
            name = String(Input("\nDigite para quem enviar a mensagem $(keys(PORTS_OWNER)): "))
            if name == "q" close(socket); break end

            port = PORTS_OWNER[name]
            msg = String(Input("Digite a mensagem a enviar para $name: "))

            udp_send(socket,HOST,port,msg)
        end
    end
end

main()
