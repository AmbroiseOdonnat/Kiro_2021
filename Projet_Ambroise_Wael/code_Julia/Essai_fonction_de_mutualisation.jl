#test d'une autre fonction de mutualisation
#cela fonctionn
include("/Users/ambroise/Projet/code_Julia/import_all.jl")
function order_stops(route, instance)
    u = route.u
    fourn_stops = [(route.stops[i].f, i) for i = 1:size(route.stops)[1]]
    dist_fourn_stops =
        [(instance.graphe.d[u, instance.U+f[1]], f[2]) for f in fourn_stops]
    dist_fourn_stops = sort(dist_fourn_stops)
    fourn_stops = [fourn_stops[i[2]] for i in dist_fourn_stops]
    new_stops = [route.stops[i[2]] for i in dist_fourn_stops]
    route.stops = new_stops
    return route
end
function build_optimized_routes(Routes, instance)::Vector{Route}
    Groupes = Grouper_routes(Routes, instance)
    Routes_opti = []
    for groupe in Groupes
        groupe_ordoned, chargement_ordoned = trier_routes(groupe, instance)
        groupe_opti =
            optimize_routes(groupe_ordoned, chargement_ordoned, instance)
        for route in groupe_opti
            route = order_stops(route, instance)
            if route_worth(route, instance)
                push!(Routes_opti, route)
            end
        end
    end
    return Routes_opti
end
function route_worth(route, instance)
    cost_route = cost(route, instance)
    Q_tot = [0] * instance.E
    for stop in route.stops
        Q_tot = stop.Q .+ Q_tot
    end
    cost_si_carton =
        sum(Q_tot .* (instance.fournisseurs[1].cexc + instance.usines[1].cs))
    return cost_route < cost_si_carton
end

function Grouper_routes(Routes, instance)
    Routes_ = copy(Routes)
    Groupes = Array{Vector{Route}}(undef,instance.J,instance.U)
    for i in 1:instance.J, u in 1:instance.U
        Groupes[i,u] = Route[]
    end
    for route in Routes_
        push!(Groupes[route.j, route.u], route)
    end
    return Groupes
end

function trier_routes(Routes, instance)
    Rt = []
    Chargement_trié = []
    Routes_to_sort = copy(Routes)
    long_emballages = [instance.emballages[e].l for e = 1:instance.E]
    Chargement_route = Any[]

    for i = 1:size(Routes)[1]
        chargement = transpose(Routes[i].stops[1].Q) * long_emballages
        push!(Chargement_route, (chargement, i))
    end
    Chargement_route = sort(Chargement_route, rev = true)
    Routes_sorted = [Routes[i[2]] for i in Chargement_route]

    Chargement = [i[1] for i in Chargement_route]
    return Routes_sorted, Chargement
end


function mutualise(Routes, Chargement, ind)
    Chargement[ind-1] += Chargement[ind]
    deleteat!(Chargement, ind)
    Routes[ind-1].F += 1
    push!(Routes[ind-1].stops, Routes[ind].stops[1])
    deleteat!(Routes, ind)
    return Routes, Chargement
end

function optimize_routes(Routes, Chargement, instance)
    ind = 2
    Taille = size(Routes)[1]
    while ind <= Taille
        route = Routes[ind-1]
        if Routes[ind-1].u == Routes[ind].u
            if Chargement[ind] + Chargement[ind-1] < instance.L && route.F < 4
                Routes, Chargement = mutualise(Routes, Chargement, ind)
                ind -= 1
            end
            ind += 1
            Taille = size(Routes)[1]
        end
    end
    return Routes
end

##test
include("/Users/ambroise/Projet/code_Julia/import_all.jl")
using LinearAlgebra
#test
zone = "europe"
A_PLNE_sol_flows = open("/Users/ambroise/Projet/sujet/flows_$zone.txt") do file
    readlines(file)
end

A_PLNE_routes_flows = [lire_route(A_PLNE_sol_flows[1+r]) for r=1:length(A_PLNE_sol_flows)-1]

#ecriture solution
A_PLNE_instance_zone = lire_instance("/Users/ambroise/Projet/sujet/$zone.csv")
A_PLNE_test_instance_flow = lire_solution(A_PLNE_instance_zone,"/Users/ambroise/Projet/sujet/flows_$zone.txt")

##creation route otpimisee
#tri = trier_routes(A_PLNE_routes_flows,A_PLNE_instance_zone)

A_PLNE_opti_routes_flows = build_optimized_routes(A_PLNE_routes_flows,A_PLNE_instance_zone)


##
A_PLNE_test_instance_flow.routes = A_PLNE_opti_routes_flows
A_PLNE_test_instance_flow.R = length(A_PLNE_opti_routes_flows)
update_stocks!(A_PLNE_test_instance_flow,A_PLNE_opti_routes_flows)
#write_solution_to_file(test_instance_flow,"/Users/ambroise/Projet/sujet/solution_$usedroutes.txt")
#faisabilité
usines = A_PLNE_test_instance_flow.usines
usines[2].s
feasibility(A_PLNE_instance_zone)

#cout
cost_verbose(A_PLNE_test_instance_flow)

##
#test
#recuperation routes

instance_zone = lire_instance("/Users/ambroise/Projet/sujet/europe.csv")

sol_flows = open("/Users/ambroise/Projet/sujet/routes_binpack_europe.txt") do file
    readlines(file)
end

routes_flows = [lire_route(sol_flows[1+r]) for r=1:length(sol_flows)-1]

instance_flow = lire_solution(instance_zone,"/Users/ambroise/Projet/sujet/routes_binpack_europe.txt")


# Idée pour améliorer es routes
a = 1
cost_verbose(instance_zone)
instance_flow.routes=build_optimized_routes(routes_flows,instance_zone)
a=1
update_stocks!(instance_flow,routes_flows)
feasibility(instance_flow)
cost_verbose(instance_flow)
