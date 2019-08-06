include("Styles.jl")



"""
    get_qry_from_user()

Get what file user is looking for
"""
function get_qry_from_user()
    conf = true
    search_for = ""
    while conf
        search_for = Input("$CYELLOW What movie are you looking for? ")
        conf = "y" != lowercase(Input("Are you sure of: $search_for? (y/n)"))
    end
    return search_for
end


function Input(prompt)
    print(prompt)
    string(readline())
end
