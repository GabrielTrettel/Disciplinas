
function show_stack_trace()
    for (exc, bt) in Base.catch_stack()
        showerror(stdout, exc, bt)
        println()
    end
end

const LOG_FILE = "/home/trettel/Documents/projects/Disciplinas/Sistemas Distribuidos/testes/peers.log"
MY_NAME = ""

function get_alive_peers()
    IO = open(LOG_FILE, "r")
    n_p = Tuple[]
    for line in readlines(IO)
        name,port = split(strip(line, '\n'), '\t')
        if name == MY_NAME continue end

        name = string(name)
        port = parse(Int64, port)
        push!(n_p, (name,port))
    end
    close(IO)
    return n_p
end


function set_sign_of_life(name::String, port::Int64)
    IO = open(LOG_FILE, "a+")
    write(IO, "$name\t$port\n")
    close(IO)
    global MY_NAME = name
end



# macro try_or_print_error(arg)
#     try
#         result = eval(arg)
#         # print(result)
#         return result
#     catch
#         for (exc, bt) in Base.catch_stack()
#            s = IOBuffer()
#            showerror(s, exc, bt)
#            println(s)
#        end
#    end
# end
#
#
# f(x) = 2x
# @try_or_print_error f(4)
