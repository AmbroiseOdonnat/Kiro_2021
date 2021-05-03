include("import_all.jl")
include("bin_packing.jl")
instance_zone = lire_instance("instance/france.csv")

sol_flows = open("solution/flows_france.txt") do file
    readlines(file)
end

routes_flows = [lire_route(sol_flows[1+r]) for r=1:length(sol_flows)-1]

instance_flow = lire_solution(instance_zone,"solution/flows_france.txt")


instance_france = lire_instance("instance/france.csv")

# Idée pour améliorer es routes

cost_verbose(instance_france)

instance_flow.routes=routes_flows

update_stocks!(instance_flow,routes_flows)

cost_verbose(instance_flow)

##
E = instance_france.E
U=instance_france.U
F=instance_france.F
J= instance_france.J
R = length(routes_flows)
#Chaque jour, on regroupe les routes u -> f ensemble

##
zone="france"
data_zone = open("instance/$zone.csv") do file
    readlines(file)
end

dims_zone = lire_dimensions(data_zone[1])
emballages_zone = [lire_emballage(data_zone[1+e], dims_zone) for e in 1:dims_zone.E]
usines_zone = [lire_usine(data_zone[1 + dims_zone.E + u],dims_zone) for u in 1:dims_zone.U]

fournisseurs_zone = [lire_fournisseur(data_zone[1 + dims_zone.E+ dims_zone.U + f],dims_zone) for f in 1:dims_zone.F]

graphe_zone = lire_graphe(data_zone[1+dims_zone.E+dims_zone.U+dims_zone.F+1:end], dims_zone)
d=graphe_zone.d

##

routes_juf = Array{Vector{Route}}(undef, J, U, F)

for j=1:J, u=1:U, f=1:F
    routes_juf[j,u,f]=[]
end

for r in 1:R
    route = routes_flows[r]
    push!(routes_juf[route.j, route.u, route.stops[1].f], route)
end




# Maintenant pour chaque jour on connaît l'ensemble des routes allant de u à f ce jour là
# Regroupons ces routes pour préparer le ibn_packing



function longeur_pile(e::Emballage)::Int
    return e.l
end

L = instance_zone.L

function q_zero(E::Int)::Vector{Int}
    Q = Vector{Int}( undef ,E)
    for q in 1:E
        Q[q]=0
    end
    return Q
end


good_routes=Route[]
nb_good_routes = 1
len_F = instance_zone.F

for j=1:J, u=1:U, f=1:len_F
    routes = routes_juf[j,u,f]
    if length(routes)>0
        global a = Emballage[]

        for route in routes
            e = findmax(route.stops[1].Q)[2]
            pile = emballages_zone[e]
            x = route.x
            for obj in 1:x
                push!(a, pile)
            end
        end

        sort!(a, by = longeur_pile, rev= true)
        fit = first_fit(a, L)

        nombre_routes = findmax(fit)[1]
        nouvelles_routes = Route[]

        for r in 1:nombre_routes
            Q = q_zero(E)
            new_stop = RouteStop(; f=fournisseurs_zone[f].f, Q)
            new_x= 1
            new_route = Route(;r=nb_good_routes, j ,u, x=new_x, F=1, stops=[new_stop])
            nb_good_routes = nb_good_routes + 1
            push!(nouvelles_routes, new_route)
        end

        for i in 1:length(a)
            embal = a[i]
            camion = fit[i]
            la_route = nouvelles_routes[camion]
            la_route.stops[1].Q[embal.e] += 1
        end

        for new_route in nouvelles_routes
            push!(good_routes, new_route)
        end
    end
end



good_instance = lire_instance("instance/france.csv")

good_instance.routes=good_routes
good_instance.R = length(good_routes)

update_stocks!(good_instance,good_routes)

feasibility(good_instance)

cost_verbose(good_instance)


write_solution_to_file(good_instance, "solution/binpack_france.txt")
