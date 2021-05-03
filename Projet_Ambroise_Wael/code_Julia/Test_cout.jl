include("import_all.jl")

##

zone = "maroc"

data_zone = open("/Users/ambroise/Projet/sujet/$zone.csv") do file
    readlines(file)
end

instance_zone = lire_instance("/Users/ambroise/Projet/sujet/$zone.csv")

## matrice des distances

dims_zone = lire_dimensions(data_zone[1])

emballages_zone = [lire_emballage(data_zone[1+e], dims_zone) for e in 1:dims_zone.E]

usines_zone = [lire_usine(data_zone[1 + dims_zone.E + u],dims_zone) for u in 1:dims_zone.U]

fournisseurs_zone = [lire_fournisseur(data_zone[1 + dims_zone.E+ dims_zone.U + f],dims_zone) for f in 1:dims_zone.F]

graphe_zone = lire_graphe(data_zone[1+dims_zone.E+dims_zone.U+dims_zone.F+1:end], dims_zone)

d_zone = graphe_zone.d

##
E = length(instance_zone.emballages)
e = instance_zone.emballages[1]
data = create_data("/Users/ambroise/Projet/sujet/$zone.csv",e,1)
Optimal_livraison = Solution(data)
G = data.graph
##
## Générer les routes

routes_solution =[]



function q_gen(e::Int,E::Int)::Vector{Int}
    Q = Vector{Int}( undef ,E)
    for q in 1:E
        Q[q]=0
    end
    Q[e]=1
    return Q
end

for k in 1:length(edges(G))
    Q = q_gen(e.e,E)
    stop = RouteStop(;f = edges(G)[k][2], Q=Q)
    r= 1 + length(routes_solution)
    stops=[stop]
    x=Int(Optimal_livraison[k])
    if x >0
        F= 1
        route=Route(;r=r, j=1, x=x, u=edges(G)[k][1], F=F, stops=stops)
        push!(routes_solution,route)
    end
end

routes_solution


instance_zone.routes = routes_solution


cost_verbose(instance_zone)


feasibility(instance_zone)
