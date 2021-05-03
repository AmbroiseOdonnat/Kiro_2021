using Random

mutable struct RouteStop
    f::Int
    Q::Vector{Int}

    RouteStop(; f, Q) = new(f, Q)
end

mutable struct Route
    id::Tuple{Int, Int, Int}
    j::Int
    x::Int
    u::Int

    stops::Vector{RouteStop}

    Route(; j, x, u, stops) = new((rand(Int), rand(Int), rand(Int)), j, x, u, stops)
end

function Base.show(io::IO, route::Route)
    str = "Route"
    str *= "\n   Jour $(route.j)"
    str *= "\n   Nb de camions $(route.x)"
    str *= "\n   Usine de départ $(route.u)"
    str *= "\n   Nb d'arrêts $(length(route.stops))"
    for (stoprank, stop) in enumerate(route.stops)
        str *= "\n   Stop $stoprank"
        str *= "\n      Fournisseur $(stop.f)"
        str *= "\n      Livraison $(stop.Q)"
    end
    print(io, str)
end

function lire_route(row::String)::Route
    row_split = split(row, r"\s+")
    r = parse(Int, row_split[2]) + 1
    j = parse(Int, row_split[4]) + 1
    x = parse(Int, row_split[6])
    u = parse(Int, row_split[8]) + 1
    F = parse(Int, row_split[10])

    stops = RouteStop[]

    k = 11
    while k <= length(row_split)
        f = parse(Int, row_split[k+1]) + 1
        k += 2

        Q = Int[]
        while (k <= length(row_split)) && (row_split[k] == "e")
            push!(Q, parse(Int, row_split[k+3]))
            k += 4
        end
        push!(stops, RouteStop(f = f, Q = Q))
    end

    return Route(j = j, x = x, u = u, stops = stops)
end

function Base.copy(route::Route)
    return Route(
        j=route.j,
        x=route.x,
        u=route.u,
        stops=copy(route.stops)
    )
end

## Interactions route / sites (TODO : deprecate)

function chargement(route::Route, usine::Usine; e::Int, j::Int)::Int
    error("Inefficient function - deprecated")
    if (route.j == j) && (route.u == usine.u)
        return route.x * sum(stop.Q[e] for stop in route.stops)
    else
        return 0
    end
end

function livraison(route::Route, fournisseur::Fournisseur; e::Int, j::Int)::Int
    error("Inefficient function - deprecated")
    if route.j == j
        d = 0
        for stop in route.stops
            if stop.f == fournisseur.f
                d += route.x * stop.Q[e]
            end
        end
        return d
    else
        return 0
    end
end
