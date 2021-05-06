include("import_all.jl")

##
using JuMP
using Gurobi



## Extraction Donnees

Val_q = #dictionnaire pour les quai et si jamais NonAffected, ça vaut 1
C_not_affected = #recuperer le cout de non affectation
C_incompatible = #recuperer cout incompatible
delta_same_quai = #tableau avec 0 en entree si t et t' ont meme quai, 1 sinon
## Maintenant on regarde si on arrive a faire tourner sur les autres

model = Model(Gurobi.Optimizer)

@variable(model, q_train[1:T],String) #nom de quai pour le train t
@variable(model, q_iti[1:I],String) #nom de quai pour l'itineraire i_t'
@variable(model, y_train[1:T],Int) #binaire 1 si non affecte pour q_t
@variable(model, y_iti[1:J],Int) #binaire 1 si itineraire incompatible pour i_j

cout_non_affected = @expression(model, sum(y_train[t]*C_non_affected)  for t = 1:T)
cout_incompatible= @expression(model, sum(y_iti[j].C_incompatible[j]for j=1:J))


@objective(model, Min, cout_non_affected + cout_incompatible )

@constraint(model, binary_quai[t = 1:T], y_train[t] == Val_q[q_train[t]])
@constraint(model, binary_iti[j = 1:J], y_iti[j] == Val_q[q_iti[j]])
@constraint(model,coincide[t = 1:T], q_train[t] == q_iti[t.itineraire]] ) #je dois recuperer iti du train t
@constraint(model, x_pos[e=1:E, u=1:U, f=1:F, j=1:J], x[e,u,f,j]>=0)


@constraint(model, sr_u_2[e = 1:E, u=1:U, j= 1:(J+1)], sr_plus_u[e,u,j] >= 0)
@constraint(model, sr_f_2[e = 1:E, f=1:F, j= 1:(J+1)], sr_plus_f[e,f,j] >= 0)

@constraint(model, bs_pos[e=1:E, f=:1:F,j=1:(J+1)], bs_plus[e,f,j] >= 0)

@constraint(model, sr_u_1[e = 1:E, u=1:U, j= 1:J], sr_plus_u[e,u,j+1] >= s_u[e,u,j+1]-usines_zone[u].r[e,j])
@constraint(model, sr_f_1[e = 1:E, f=1:F, j= 1:J], sr_plus_f[e,f,j+1] >= s_f[e,f,j+1]-fournisseurs_new[f].r[e,j])

@constraint(model, route_u[e = 1:E, u = 1:U, j = 1:J], sum(x[e,u,f,j] for f in 1:F) == z_moins[e,u,j])
@constraint(model, route_f[e = 1:E, f = 1:F, j = 1:J], sum(x[e,u,f,j] for u in 1:U) == z_plus[e,f,j])

@constraint(model, stock_u[e=1:E,u=1:U, j=1:J], s_u[e,u,j+1] == s_u[e,u,j]+ usines_zone[u].b⁺[e,j] - z_moins[e,u,j])
@constraint(model, stock_u_plus[e=1:E, u=1:U, j=1:(J+1)], s_u[e,u,j] >= 0)

@constraint(model, stock_f[e = 1:E, f=1:F, j=1:J], s_f[e,f,j+1] == bs_plus[e,f,j]+z_plus[e,f,j] )

@constraint(model, bs[e=1:E, f=:1:F,j=1:J], bs_plus[e,f,j+1]>=fournisseurs_new[f].b⁻[e,j]-s_f[e,f,j])

optimize!(model)

# cout seuil 100 -> 7 961 828
#cout seuil 150 -> 8 141 725
# cout seuil 250 -> 8 882 174
# cout seuil 300 -> 9 105 513

Optimal_livraison = value.(x)

termination_status(model)



## Générer les routes





function q_gen(e::Int,E::Int)::Vector{Int}
    Q = Vector{Int}( undef ,E)
    for q in 1:E
        Q[q]=0
    end
    Q[e]=1
    return Q
end

routes_solution =Route[]
r=1
len_F= length(fournisseurs_new)
for e=1:E, u=1:U, f=1:len_F, j=1:J
    Q = q_gen(e,E)
    stop = RouteStop(;f= fournisseurs_new[f].f,Q)
    stops=[stop]
    x=Int(Optimal_livraison[e, u, f, j])
    if x >0
        F= 1
        route=Route(; r, j, x, u, F, stops)
        push!(routes_solution,route)
        r+=1
    end
end

routes_solution


instance_zone.routes = routes_solution
instance_zone.R = length(routes_solution)

update_stocks!(instance_zone,routes_solution)


cost_verbose(instance_zone)


feasibility(instance_zone)

write_solution_to_file(instance_zone, "solution/flows_$zone.txt")
