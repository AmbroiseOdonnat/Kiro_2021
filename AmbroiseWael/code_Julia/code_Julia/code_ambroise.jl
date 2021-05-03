include("import_all.jl")
using LinearAlgebra
#recuperation routes
zone = "europe"
sol_flows = open("solution/routes_binpack_$zone.txt") do file
    readlines(file)
end

routes_flows = [lire_route(sol_flows[1+r]) for r=1:length(sol_flows)-1]

#ecriture solution
instance_zone = lire_instance("instance/$zone.csv")
instance_flow = lire_solution(instance_zone,"solution/routes_binpack_$zone.txt")
instance_flow.routes = routes_flows
instance_flow.R = length(routes_flows)
update_stocks!(instance_flow,routes_flows)
#faisabilité
feasibility(instance_flow)

#cout
cost_verbose(instance_flow)

#test
test_instance_flow = lire_solution(instance_zone,"solution/routes_binpack_$zone.txt")
opti_routes_flows = optimiser_routes(routes_flows,instance_zone)
test_instance_flow.routes = opti_routes_flows
test_instance_flow.R = length(opti_routes_flows)
update_stocks!(test_instance_flow,opti_routes_flows)
#faisabilité
feasibility(test_instance_flow)

#cout
cost_verbose(test_instance_flow)

##
instance_zone.graphe.d

## fonction de cout
function cost_uf(u::Int,f::Int,instance::Instance)::Int #cout pour aller de u a f
    fournisseurs = Int[]
    push!(fournisseurs,f)
    return cost_dist(u,fournisseurs,instance)
end

function cost_dist(usine::Int,fournisseurs::Vector{Int},instance::Instance) #cout pour faire le chemin u + les fournisseurs
    P_r = []
    push!(P_r,usine)
    for f in fournisseurs
        push!(P_r,f)
    end
    U = instance.U
    d = instance.graphe.d
    c_cam = instance.ccam
    c_stop = instance.cstop
    gamma = instance.γ
    card_chemin = length(P_r)
    return c_cam + c_stop*(length(P_r)-1) + gamma*sum(d[P_r[i],P_r[i+1]] for i in 1:length(P_r)-1)
end

function index_minimize(a::Vector{Int})
    index = 1
    m = a[index]
    for i in 1:length(a)
        if a[i] < m
            m = a[i]
            index = i
        end
    end
    return index
end

function different(a::Vector{Fournisseur}, f::Fournisseur)::Vector{Fournisseur}
    a_ = []
    for l in a
        if l.v!=f.v
            push!(a_,l)
        end
    end
    return a_
end

function possible_route(instance::Instance) #heuristique voisinage de u: 4 fournisseurs de routes possibles
    usines = instance.usines
    fournisseurs = instance.fournisseurs
    possible_route = []
    for u in usines
        routes_4 = []
        Path_f = Int[]
        for f in fournisseurs
            push!(Path_f,cost_uf(u.v,f.v,instance))
        end
        index_1 = index_minimize(Path_f)
        f1 = fournisseurs[index_1]
        push!(routes_4,f1)
        empty!(Path_f)
        prive_1 = different(fournisseurs,f1)
        for f in prive_1
            push!(Path_f,cost_dist(u.v,[f1.v,f.v],instance))
        end
        index_2 = index_minimize(Path_f)
        f2 = fournisseurs[index_2]
        push!(routes_4,f2)
        empty!(Path_f)
        prive_1_2 = different(prive_1,f2)
        for f in prive_1_2
            push!(Path_f,cost_dist(u.v,[f1.v,f2.v,f.v],instance))
        end
        index_3 = index_minimize(Path_f)
        f3 = fournisseurs[index_3]
        push!(routes_4,f3)
        empty!(Path_f)
        prive_1_2_3 = different(prive_1_2,f3)
        for f in prive_1_2_3
            push!(Path_f,cost_dist(u.v,[f1.v,f2.v,f3.v,f.v],instance))
        end
        index_4 = index_minimize(Path_f)
        f4 = fournisseurs[index_4]
        push!(routes_4,f4)
        empty!(Path_f)
        push!(possible_route,(u,routes_4))
    end
    return possible_route
end

function is_in(vect::Vector{Fournisseur},f::Fournisseur)
    for i in vect
        if i == f
            return true
        end
    end
end



##
function l_emballage(instance::Instance)
    return [instance.emballages[e].l for e = 1:instance.E]
end

function q(route::Route)
    return sum(route.stops[i].Q for i in 1:length(route.stops))
end

function Q(route::Route,instance::Instance)##probleme ici bien faire fonction chargement
    return dot(q(route), l_emballage(instance))
end
Q(routes_flows[1],instance_zone)


function routes_uj(instance::Instance,routes::Vector{Route},usine::Usine,j::Int)::Vector{Route}
    emballages = instance.emballages
    routes_uj = []
    for r in routes
        if r.j == j && r.u == usine.v
            push!(routes_uj,r)
        end
    end
    chargement = []
    for r in routes
        push!(chargement,Q(r,instance))
    end
    for i in 1:length(routes)
        for j in 1:length(routes)
            if chargement[i] > chargement[j]
                routes[i],routes[j] = routes[j],routes[i]
            end
        end
    end
    return routes_uj
end

routes_uj(routes_flows,test_instance.usines[1],1)


function mutualiser_routes(instance::Instance,routes::Vector{Route}, id1::Int,id2::Int)::Vector{Route}
    push!(routes[id1].stops,routes[id2].stops[1])
    routes[id1].F+=1
    deleteat!(routes,id2)
    return routes
end

function sort_stop(instance::Instance,route::Route)::Route
    u = route.u
    Stops = route.stops
    dist = []
    for s in Stops
        push!(dist,cost_uf(u,s.f,instance))
    end
    for i in 1:length(dist), j in 1:length(dist)
        if dist[i] > dist[j]
            Stops[i],Stops[j] = Stops[j],Stops[i]
        end
    end
    route.stops = Stops
    return route
end


function optimiser_routes(routes::Vector{Route},instance::Instance)::Vector{Route}
    usines = instance.usines
    J = instance.J
    L = instance.L
    routes_final = []
    for u in usines,j in 1:J
        global mut_routes_uj = routes_uj(instance,routes,u,j)
        global N = length(mut_routes_uj)
        global index = 1
        while index <= N-1
            if mut_routes_uj[index].F < 4 && Q(mut_routes_uj[index],instance) + Q(mut_routes_uj[index+1],instance) <= instance.L
                mut_routes_uj = mutualiser_routes(instance,mut_routes_uj,index,index+1)
                index-=1
            end
            global N = length(mut_routes_uj)
            index +=1
        end
        for r in mut_routes_uj
            r = sort_stop(instance,r)
            push!(routes_final,r)
        end
    end
    return routes_final
end
