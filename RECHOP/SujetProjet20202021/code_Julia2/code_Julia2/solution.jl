abstract type Solution end;

mutable struct SolutionSimple <: Solution
    routes::Vector{Route}
    SolutionSimple() = new(Route[])
    SolutionSimple(routes::Vector{Route}) = new(routes)
end

mutable struct SolutionStructuree <: Solution
    routes_par_jour_et_usine::Matrix{Vector{Route}}
    SolutionStructuree(routes_par_jour_et_usine::Matrix{Vector{Route}}) = new(routes_par_jour_et_usine)
    SolutionStructuree(J::Int, U::Int) = begin
        routes_par_jour_et_usine = Matrix{Vector{Route}}(undef, J, U)
        for j = 1:J, u = 1:U
            routes_par_jour_et_usine[j, u] = Route[]
        end
        new(routes_par_jour_et_usine)
    end
end

## Listes pour solution simple

list_routes(solution::SolutionSimple) = solution.routes
list_routes(solution::SolutionSimple, j::Int) =
    filter(route -> route.j == j, list_routes(solution))
list_routes(solution::SolutionSimple, j::Int, u::Int) =
    filter(route -> route.u == u, list_routes(solution, j))

## Listes, ajouts, suppressions pour solution structurée

get_J(solution::SolutionStructuree) = size(solution.routes_par_jour_et_usine, 1)
get_U(solution::SolutionStructuree) = size(solution.routes_par_jour_et_usine, 2)

nb_routes(solution::SolutionSimple) = length(solution.routes)

nb_routes(solution::SolutionStructuree) = sum(length.(solution.routes_par_jour_et_usine))
nb_routes(solution::SolutionStructuree, j::Int) =
    sum(length.(@view solution.routes_par_jour_et_usine[j, :]))
nb_routes(solution::SolutionStructuree, j::Int, u::Int) =
    length(solution.routes_par_jour_et_usine[j, u])


function list_routes(solution::SolutionStructuree, j::Int, u::Int)
    solution.routes_par_jour_et_usine[j, u]
end
function list_routes(solution::SolutionStructuree, j::Int)
    routes = Vector{Route}(undef, nb_routes(solution, j))
    r = 0
    for u = 1:get_U(solution)
        for route in list_routes(solution, j, u)
            r += 1
            routes[r] = route
        end
    end
    return routes
end
function list_routes(solution::SolutionStructuree)
    routes = Vector{Route}(undef, nb_routes(solution))
    r = 0
    for j = 1:get_J(solution), u = 1:get_U(solution)
        for route in list_routes(solution, j, u)
            r += 1
            routes[r] = route
        end
    end
    return routes
end

function get_route(solution::SolutionStructuree, j::Int, u::Int, r::Int)::Route
    return list_routes(solution, j, u)[r]
end

## Copie

function Base.copy(solution::SolutionStructuree)
    return SolutionStructuree([
        [copy(route) for route in list_routes(solution, j, u)]
        for j = 1:get_J(solution), u = 1:get_U(solution)
    ])
end

## Modification

delete_route!(solution::SolutionSimple, r::Int) = deleteat!(solution.routes, r)

delete_routes!(solution::SolutionStructuree, j::Int, u::Int, rs::Vector{Int}) =
    deleteat!(solution.routes_par_jour_et_usine[j, u], rs)
delete_route!(solution::SolutionStructuree, j::Int, u::Int, r::Int) =
    delete_routes!(solution, j, u, [r])
function delete_route!(solution::SolutionStructuree, route::Route)
    j, u = route.j, route.u
    for r = 1:nb_routes(solution, j, u)
        if get_route(solution, j, u, r).id == route.id
            delete_route!(solution, j, u, r)
            return true
        end
    end
    return false
end

add_route!(solution::SolutionSimple, route::Route) = push!(solution.routes, route)
add_route!(solution::SolutionStructuree, route::Route) =
    push!(solution.routes_par_jour_et_usine[route.j, route.u], route)

## Affichage

function Base.show(io::IO, solution::Solution)
    routes = list_routes(solution)
    R = length(routes)
    str = "Solution contenant $R routes"
    println(io, str)
    for route in list_routes(solution)
        print(io, "\n")
        print(io, route)
    end
end

## Lecture

function lire_solution(path::String)::SolutionSimple
    sol = open(path) do file
        readlines(file)
    end
    R = parse(Int, split(sol[1], r"\s+")[2])
    routes = [lire_route(sol[1+r]) for r = 1:R]
    return SolutionSimple(routes)
end

## Conversion

SolutionStructuree(instance::Instance) = SolutionStructuree(instance.J, instance.U)

SolutionStructuree(instance::Instance, routes::Vector{Route})::SolutionStructuree = begin
    solution = SolutionStructuree(instance)
    for route in routes
        add_route!(solution, route)
    end
    return solution
end

SolutionStructuree(instance::Instance, solution::SolutionSimple)::SolutionStructuree = begin
    return SolutionStructuree(instance, list_routes(solution))
end
