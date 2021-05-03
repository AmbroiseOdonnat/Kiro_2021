include("import_all.jl")



## Générer les routes
Optimal_solution = value.(x)

routes_solution =[]

function q_gen(e::Int,E::Int)::Vector{Int}
    Q = Vector{Int}( undef ,E)
    for q in 1:E
        Q[q]=0
    end
    Q[e]=1
    return Q
end


for e=1:E, u=1:U, f=1:F, j=1:J
    Q = q_gen(e,E)
    stop = RouteStop(;f,Q)
    r= 1 + length(routes_solution)
    stops=[stop]
    x=Int(Optimal_livraison[e, u, f, j])
    if x >0
        F= fournisseurs_new[f].f
        route=Route(; r, j, x, u, F, stops)
        push!(routes_solution,route)
    end
end

routes_solution


instance_zone.routes = routes_solution


cost_verbose(instance_zone)

feasibility(instance_zone)
