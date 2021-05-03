#On part de la solution à 9,8 M

include("import_all.jl")

include("bin_packing.jl")

europe = lire_instance("instance/europe.csv")

sol_routes4 = open("solution/routes_de_4_best.txt") do file
    readlines(file)
end

routes = [lire_route(sol_routes4[1 + r]) for r=1:length(sol_routes4)-1]


europe.routes = routes

update_stocks!(europe, routes)


feasibility(europe)
cost(europe)
cost_verbose(europe)

europe.R = length(europe.routes)


## Récupération des variables

usines = europe.usines
fournisseurs = europe.fournisseurs
emballages = europe.emballages

J = europe.J
U = europe.U
F = europe.F
E = europe.E
R = europe.R
γ = europe.γ
ccam = europe.ccam
cstop = europe.cstop
L = europe.L
d = europe.graphe.d

## Regroupement des 3800 routes par trajet commun

# 1ère étape on les regroupe par usine

routes_ju = Array{Vector{Route}}(undef, J, U)

for j=1:J, u=1:U
    routes_ju[j,u] = []
end

for route in routes
    push!(routes_ju[route.j, route.u],route)
end





#2ème étape on parcourt chaque vecteur routes_ju par nombre de stops

routes_ju_1_stop = Array{Vector{Route}}(undef, J, U)
routes_ju_2_stop = Array{Vector{Route}}(undef, J, U)
routes_ju_3_stop = Array{Vector{Route}}(undef, J, U)
routes_ju_4_stop = Array{Vector{Route}}(undef, J, U)

for j=1:J, u=1:U
    routes_ju_1_stop[j,u] = []
    routes_ju_2_stop[j,u] = []
    routes_ju_3_stop[j,u] = []
    routes_ju_4_stop[j,u] = []
end

for j=1:J, u=1:U
    for route in routes_ju[j,u]
        if route.F == 1
            push!(routes_ju_1_stop[j,u], route)
        elseif route.F == 2
            push!(routes_ju_2_stop[j,u], route)
        elseif route.F == 3
            push!(routes_ju_3_stop[j,u], route)
        elseif route.F==4
            push!(routes_ju_4_stop[j,u], route)
        end
    end
end

for j=1:J, u=1:U
    if length(routes_ju_2_stop[j,u])>0
        println(length(routes_ju_2_stop[j,u]))
    end
end


##
#On s'occupe d'abord des routes à 1 stop :

# Regroupement par fournisseur livré


routes_juf = Array{Vector{Route}}(undef, J, U, F)
for j=1:J, u=1:U, f=1:F
    routes_juf[j,u,f]=[]
end

for j=1:J, u=1:U
    for route in routes_ju_1_stop[j,u]
        push!(routes_juf[j,u,route.stops[1].f],route)
    end
end

#Petit test de visualisation

for j=1:J, u=1:U, f=1:F
    if length(routes_juf[j,u,f])>0
        println(length(routes_juf[j,u,f]))
    end
end

#Il y a une 20aine de routes à optimiser


function longeur_pile(e::Emballage)::Int
    return e.l
end


function q_zero(E::Int)::Vector{Int}
    Q = Vector{Int}( undef ,E)
    for q in 1:E
        Q[q]=0
    end
    return Q
end


good_routes_1stop=Route[]
nb_good_routes_1stop = 1

for j=1:J, u=1:U, f=1:F
    if length(routes_juf[j,u,f])>=1
        emballages_a_livrer = Emballage[]
        for route in routes_juf[j,u,f]
            chargement_route = route.stops[1].Q
            for e=1:E
                for pile in 1:chargement_route[e]
                    push!(emballages_a_livrer, emballages[e])
                end
            end
        end
        sort!(emballages_a_livrer, by = longeur_pile, rev = true)
        fit = first_fit(emballages_a_livrer,L)
        nombre_de_nouvelles_routes = findmax(fit)[1]
        nouvelles_routes = Route[]

        for nv_route in 1:nombre_de_nouvelles_routes
            chargement = q_zero(E)
            arret = RouteStop(;f, Q=chargement)
            new_route = Route(; r= nb_good_routes_1stop, j, u, x=1, F=1, stops=[arret])
            nb_good_routes_1stop+=1
            push!(nouvelles_routes,new_route)
        end

        for pile in 1:length(emballages_a_livrer)
            embal = emballages_a_livrer[pile].e
            camion = fit[pile]
            nouvelles_routes[camion].stops[1].Q[embal]+=1
        end

        for route in nouvelles_routes
            push!(good_routes_1stop, route)
        end
    end
end

good_routes_1stop

##
# Test du gain d'argent :

routes_test = Route[]
r = 1

for route in good_routes_1stop
    route.r=r
    r+=1
    push!(routes_test,route)
end

for j=1:J, u=1:U
    for route in routes_ju_2_stop[j,u]
        route.r=r
        r+=1
        push!(routes_test,route)
    end
    for route in routes_ju_3_stop[j,u]
        route.r=r
        r+=1
        push!(routes_test,route)
    end
    for route in routes_ju_4_stop[j,u]
        route.r=r
        r+=1
        push!(routes_test,route)
    end
end

instance_test = lire_instance("instance/europe.csv")

instance_test.routes=routes_test

instance_test.R = length(routes_test)

update_stocks!(instance_test, routes_test)

feasibility(instance_test)

cost(instance_test)

## Cas des routes à 2stops

routes_regroupes_par_chemin_ju=Array{Vector{Vector{Route}}}(undef, J , U)

for j=1:J, u=1:U
    routes_regroupes_par_chemin_ju[j,u]=[]
end


good_routes_2stop=Route[]
nb_good_routes_2stop = 1

for j=1:J, u=1:U
    roads_ju_2 = routes_ju_2_stop[j,u]
    if length(roads_ju_2) >= 2

        
