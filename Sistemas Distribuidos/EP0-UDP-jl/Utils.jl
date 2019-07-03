
function show_stack_trace()
    for (exc, bt) in Base.catch_stack()
        showerror(stdout, exc, bt)
        println()
    end
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
