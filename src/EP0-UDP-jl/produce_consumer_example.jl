using Distributed

function producer(c::Channel, done::Channel)
    for i = 1:10
        println("\33[34m Put msg $i in Channel")
        put!(c, string(i))
        # sleep(1)
    end
    put!(c, "q")
    put!(done, true)

end

function consumer(c::Channel, done::Channel)
    while true
        msg = take!(c)
        if msg == "q" break end
        println("\33[37m Rcv $msg from Channel")
    end

    put!(done, true)

end



function runner()
    c = Channel{String}(10)
    done = Channel(2)

    # Utilizando Tasks (concorrene)
    prod = @async producer(c, done)
    cons = @async consumer(c, done)

    # Utilizando Processos (paralelo ?)
    # prod = @spawn producer(c, done)
    # cons = @spawn consumer(c, done)

    # one iteration of the loop corresponds to one finished task
    println(prod)
    for i=1:2 take!(done) end

    # Encerra os Channels
    close(c)
    close(done)
end

# @time runner()


function teste(ch)
    i = 0
    task = @async begin
        println("quero morrer $(take!(ch))")
    end

    while i < 10
        i+=1
        if istaskdone(task) break end
        println("Tô vivo $i")
        sleep(2)
        açlsmdç
    end
    println("to morrendo mesmo")

end

# ch = Channel(10)
#
#
# @async begin
#     try
#         teste(ch)
#     catch e
#         println(e)
#     end
# end
#
#
# sleep(3)
# put!(ch, 1)
# wait()
# f(x) = sleep(x)
#
# fetch()
#
# t = @async f(2)
# println("antes do fetch")
# fetch(t)
# println("depois do fetch")
#
# wait()


#
# function x(a)
#     a*2+1
# end
#
# A = [1, 2, 3, 4, 5, 6, 7, 8]
#
# B = x.(A)
