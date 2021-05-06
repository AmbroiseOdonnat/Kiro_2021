using Dates

struct Train
    t::Int
    sensDepart::Bool
    l::String
    q::String
    type_circulation::String
    date::DateTime
    materials::Vector{String}

    Train(; t, sensDepart, l, q, type_circulation, date, materials) = new(t, sensDepart, l, q, type_circulation,date)
end
