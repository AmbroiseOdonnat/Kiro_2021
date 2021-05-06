include("import_all.jl")

##
using JuMP
using Gurobi



## Extraction Donnees
##
name = "NS"
groupes, itineraires, voies_quai, voies_ligne, interdictions, contraintes = lire_instance("/Users/ambroise/instances/$name.json")
T = nombre_trains()
I = nb_itineraire()
Q = length(voies_quai)
J = length(contraintes)

trains = []
for g in groupes
    for t in g
        push!(trains,t["id"])
    end
end
sort!(trains)

contraintes
groupes
##
Val_q = Dict{String,Int}() #dictionnaire pour les quai et si jamais NonAffected, ça vaut 1
Val_q["notAffected"] = 1
for q in voies_quai
    Val_q[q] = 0
end

Val_s = Dict{Bool,Int}(true=>1, false => 0) #dictionnaire pour les iti et si jamais NonAffected, ça vaut 1

C_not_affected = 10000 #recuperer le cout de non affectation (pas la vraie valeur)
C_incompatible = []
for j in 1:J
    push!(C_incompatible,contraintes[j][5])#recuperer cout incompatible
end

## Maintenant on regarde si on arrive a faire tourner sur les autres

model = Model(Gurobi.Optimizer)

@variable(model, q_train[1:T],Int) #nom de quai pour le train t
#@variable(model, itineraire_id[1:T],Dict) #nom de quai pour l'itineraire i_t'
@variable(model, y_train[1:T],Int) #binaire 1 si non affecte pour q_t
@variable(model, y_iti[1:J],Int) #binaire 1 si itineraire incompatible pour i_j

cout_non_affected = @expression(model, sum(y_train[t]*C_not_affected  for t = 1:T))
cout_incompatible= @expression(model, sum(y_iti[j]*C_incompatible[j] for j=1:J))


@objective(model, Min, cout_non_affected + cout_incompatible )

#@constraint(model, binary_quai[t = 1:T], y_train[t] == Val_q[voies_quai[q_train[t]]])
@constraint(model, binary_iti[j = 1:J], y_iti[j] == Val_s[contraintes[j][1] == contraintes[j][3] && contraintes[j][2] == contraintes[j][4]])
#@constraint(model,coincide[t = 1:T], q_train[t] == itineraires.quai[q] ) #je dois recuperer iti du train t


optimize!(model)

# cout seuil 100 -> 7 961 828
#cout seuil 150 -> 8 141 725
# cout seuil 250 -> 8 882 174
# cout seuil 300 -> 9 105 513

Optimal_quai = value.(q_train)
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
