using Random

function show_stack_trace()
    for (exc, bt) in Base.catch_stack()
        showerror(stdout, exc, bt)
        println()
        throw("")
    end
end

const LOG_FILE = "/home/trettel/Documents/projects/DistributedSystems/peers/peers.log"
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

                                  # |  This limits the total amount of known peers
    l = max(1,length(n_p) ÷ 3)    # |  to only one third of the total. So decided
    shuffle!(n_p)                 # |  for didactic reasons, seeking to increase
    n_p = n_p[1 : l]              # |  the amount of search among peers.

    return n_p
end



function set_sign_of_life(name::String, port::Int64)
    IO = open(LOG_FILE, "a+")
    write(IO, "$name\t$port\n")
    close(IO)
    global MY_NAME = name
end

function Input(prompt)
    print(prompt)
    readline()
end


# Someday I will try to make this work
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
