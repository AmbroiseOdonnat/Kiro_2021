include("import_all.jl")

europe = lire_instance("instance/europe.csv")

sol_binpack = open("solution/routes_binpack.txt") do file
    readlines(file)
end

routes = [lire_route(sol_binpack[1 + r]) for r=1:length(sol_binpack)-1]


europe.routes = routes

update_stocks!(europe, routes)

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

## On essaye à nouveau d'améliorer le cout des routes

routes_ju = Array{Vector{Route}}(undef, J, U)

for j=1:J, u=1:U
    routes_ju[j,u] = []
end

for route in routes
    push!(routes_ju[route.j, route.u],route)
end

for j=1:J, u=1:U
    println(length(routes_ju[j,u]))
end

## Pour chaque jour, on classe les routes partant de u par fournisseurs

fourni_ju = Array{Vector{Fournisseur}}(undef, J, U)
for j=1:J, u=1:U
    fourni_ju[j,u] = []
end

for j=1:J, u=1:U
    fournisseurs_livres_par_u = Fournisseur[]
    for route in routes_ju[j,u]
        f = route.stops[1].f
        if !(f in fournisseurs_livres_par_u)
            push!(fournisseurs_livres_par_u,fournisseurs[f])
        end
    end
    fourni_ju[j,u] = fournisseurs_livres_par_u
end


println("Nombre de fournisseurs livrés quotidiennement")


for j=1:J, u=1:U
    if(length(fourni_ju[j,u]))>0
        println(length(fourni_ju[j,u]))
    end
end
