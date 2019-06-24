using Distributed

function producer(c::Channel, done::Channel)
    for i = 1:10
        println("\33[34m Put msg $i in Channel")
        put!(c, string(i))
        sleep(1)
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
    # prod = @async producer(c, done)
    # cons = @async consumer(c, done)

    # Utilizando Processos (paralelo ?)
    prod = @spawn producer(c, done)
    cons = @spawn consumer(c, done)

    # one iteration of the loop corresponds to one finished task
    for i=1:2 take!(done) end

    # Encerra os Channels
    close(c)
    close(done)

end

@time runner()
