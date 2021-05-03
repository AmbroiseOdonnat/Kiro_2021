include("import_all.jl")

zone = "maroc"

data_zone = open(".../sujet/$zone.csv") do file
    readlines(file)
end

instance_zone = lire_instance("/Users/ambroise/Projet/sujet/$zone.csv")

##

dims_zone = lire_dimensions(data_zone[1])

emballages_zone = [lire_emballage(data_zone[1+e], dims_zone) for e in 1:dims_zone.E]

usines_zone = [lire_usine(data_zone[1 + dims_zone.E + u],dims_zone) for u in 1:dims_zone.U]

fournisseurs_zone = [lire_fournisseur(data_zone[1 + dims_zone.E+ dims_zone.U + f],dims_zone) for f in 1:dims_zone.F]

graphe_zone = lire_graphe(data_zone[1+dims_zone.E+dims_zone.U+dims_zone.F+1:end], dims_zone)
d=graphe_zone.d


##

gamma = instance_zone.γ
c_cam = instance_zone.ccam
c_stop = instance_zone.cstop
L = instance_zone.L


##
global max_d=0
for u=1:instance_zone.U, f=1:instance_zone.F
    if d[u,f+instance_zone.U] > max_d
        global max_d = d[u,f+ instance_zone.U]
    end
end

max_d


## Détection des fournisseurs isolés

function dist_usine_plus_proche(f::Int)::Int
    min_dist = Inf
    for u in 1:instance_zone.U
        if d[u, instance_zone.U + f] < min_dist
            min_dist = d[u, instance_zone.U + f]
        end
    end
    return min_dist
end


dist_usine_plus_proche(3)
# On repère les fournisseurs inétressants

fournisseurs_bien = []
fournisseurs_isoles = []

seuil = 400

for f in 1:instance_zone.F
    if dist_usine_plus_proche(f) < seuil
        push!(fournisseurs_bien,f)
    else
        push!(fournisseurs_isoles,f)
    end
end
##
using JuMP
using Gurobi

## Calcul du cout fixe des usines isolés qui utilisent que du carton

fournisseurs_carton = [fournisseurs_zone[f] for f in fournisseurs_isoles]

U=0
F=length(fournisseurs_carton)
E=instance_zone.E
J=instance_zone.J


model = Model(Gurobi.Optimizer)



@variable(model, z_plus[1:E, 1:F , 1:J],Int)
@variable(model, s_f[1:E, 1:F , 1:(J + 1)],Int)
@variable(model, sr_plus_f[1:E, 1:F , 1:(J+1)],Int)
@variable(model, bs_plus[1:E, 1:F , 1:(1+J)],Int)



cout_stock_f = @expression(model, sum(fournisseurs_carton[f].cs[e]*sr_plus_f[e,f,j+1] for e=1:E, f=1:F, j=1:J))
cout_exc = @expression(model, sum(fournisseurs_carton[f].cexc[e]*bs_plus[e,f,j+1] for e=1:E, f=1:F, j=1:J))

@objective(model, Min, cout_stock_f + cout_exc)

@constraint(model, stock_ini_f[e = 1:E, f = 1:F], s_f[e, f, 1] == fournisseurs_carton[f].s0[e] )

@constraint(model, sr_f_2[e = 1:E, f=1:F, j= 1:J], sr_plus_f[e,f,j+1] >= 0)

@constraint(model, bs_pos[e=1:E, f=:1:F,j=1:J], bs_plus[e,f,j+1] >= 0)

@constraint(model, sr_f_1[e = 1:E, f=1:F, j= 1:J], sr_plus_f[e,f,j] >= s_f[e,f,j+1]-fournisseurs_carton[f].r[e,j])

@constraint(model, route_f[e = 1:E, f = 1:F, j = 1:J], sum(x[e,u,f,j] for u in 1:U) == z_plus[e,f,j])

@constraint(model, stock_f[e = 1:E, f=1:F, j=1:J], s_f[e,f,j+1] == bs_plus[e,f,j]+z_plus[e,f,j] )

@constraint(model, bs[e=1:E, f=:1:F,j=1:J], bs_plus[e,f,j+1]>=fournisseurs_carton[f].b⁻[e,j]-s_f[e,f,j])

optimize!(model)

#pour france, seuil 150 usines bidons = 703410
#811693 idem pour seuil = 100
#175360 pour seuil = 400
#pour europe
# Cout des usines bidons : 2 548 148 pour seuil= 200
# 2 817 238 pour seuil = 150
# 3 029 016 pour seuil = 100

## Maintenant on regarde si on arrive a faire tourner sur les autres

fournisseurs_new = [fournisseurs_zone[f] for f in fournisseurs_bien]
F = length(fournisseurs_new)
U=instance_zone.U
E=instance_zone.E
J=instance_zone.J

model = Model(Gurobi.Optimizer)

@variable(model, x[1:E, 1:U , 1:F ,1:J],Int)
@variable(model, z_moins[1:E, 1:U , 1:J],Int)
@variable(model, z_plus[1:E, 1:F , 1:J],Int)
@variable(model, s_u[1:E, 1:U , 1:(J + 1)],Int)
@variable(model, s_f[1:E, 1:F , 1:(J + 1)],Int)
@variable(model, sr_plus_u[1:E, 1:U , 1:(J+1)],Int)
@variable(model, sr_plus_f[1:E, 1:F , 1:(J+1)],Int)
@variable(model, bs_plus[1:E, 1:F , 1:(1+J)],Int)

cout_trajet = @expression(model, sum(x[e,u,f,j]*(c_cam + c_stop + gamma*d[u,U + fournisseurs_new[f].f]) for e = 1:E, u = 1:U, f = 1:F, j=1:J))
cout_stock_u = @expression(model, sum(usines_zone[u].cs[e]*sr_plus_u[e,u,j+1] for e= 1:E, u=1:U, j=1:J))
cout_stock_f = @expression(model, sum(fournisseurs_zone[f].cs[e]*sr_plus_f[e,f,j+1] for e=1:E, f=1:F, j=1:J))
cout_exc = @expression(model, sum(fournisseurs_zone[f].cexc[e]*bs_plus[e,f,j+1] for e=1:E, f=1:F, j=1:J))

@objective(model, Min, cout_trajet + cout_stock_u + cout_stock_f + cout_exc)

@constraint(model, stock_ini_u[e = 1:E, u = 1:U], s_u[e, u, 1] == usines_zone[u].s0[e] )
@constraint(model, stock_ini_f[e = 1:E, f = 1:F], s_f[e, f, 1] == fournisseurs_new[f].s0[e] )
@constraint(model, x_pos[e=1:E, u=1:U, f=1:F, j=1:J], x[e,u,f,j]>=0)


@constraint(model, sr_u_2[e = 1:E, u=1:U, j= 1:J], sr_plus_u[e,u,j+1] >= 0)
@constraint(model, sr_f_2[e = 1:E, f=1:F, j= 1:J], sr_plus_f[e,f,j+1] >= 0)

@constraint(model, bs_pos[e=1:E, f=:1:F,j=1:J], bs_plus[e,f,j+1] >= 0)

@constraint(model, sr_u_1[e = 1:E, u=1:U, j= 1:J], sr_plus_u[e,u,j] >= s_u[e,u,j+1]-usines_zone[u].r[e,j])
@constraint(model, sr_f_1[e = 1:E, f=1:F, j= 1:J], sr_plus_f[e,f,j] >= s_f[e,f,j+1]-fournisseurs_new[f].r[e,j])

@constraint(model, route_u[e = 1:E, u = 1:U, j = 1:J], sum(x[e,u,f,j] for f in 1:F) == z_moins[e,u,j])
@constraint(model, route_f[e = 1:E, f = 1:F, j = 1:J], sum(x[e,u,f,j] for u in 1:U) == z_plus[e,f,j])

@constraint(model, stock_u[e=1:E,u=1:U, j=1:J], s_u[e,u,j+1] == s_u[e,u,j]+ usines_zone[u].b⁺[e,j] - z_moins[e,u,j])
@constraint(model, stock_u_plus[e=1:E, u=1:U, j=1:(J+1)], s_u[e,u,j] >= 0)

@constraint(model, stock_f[e = 1:E, f=1:F, j=1:J], s_f[e,f,j+1] == bs_plus[e,f,j]+z_plus[e,f,j] )

@constraint(model, bs[e=1:E, f=:1:F,j=1:J], bs_plus[e,f,j+1]>=fournisseurs_new[f].b⁻[e,j]-s_f[e,f,j])

optimize!(model)
Optimal_livraison = value.(x)
#France
#cout seuil 150 -> 3 905 980
#cout seuil 100 -> 3 822 880
#Europe
# cout seuil 100 -> 7 961 828
#cout seuil 150 -> 8 141 725
## Générer les routes
E = length(instance_zone.emballages)
routes_solution =[]




function q_gen(e::Int,E::Int)::Vector{Int}
    Q = Vector{Int}( undef ,E)
    for q in 1:E
        Q[q]=0
    end
    Q[e]=1
    return Q
end

len_F= length(fournisseurs_new)
for e=1:E, u=1:U, f=1:len_F, j=1:J
    Q = q_gen(e,E)
    stop = RouteStop(;f=f,Q=Q)
    r= 1 + length(routes_solution)
    stops=[stop]
    x=Int(Optimal_livraison[e, u, f, j])
    if x >0
        F= 1
        route=Route(; r=r, j=j, x=x, u=u, F=F, stops=stops)
        push!(routes_solution,route)
    end
end

routes_solution


instance_zone.routes = routes_solution


cost_verbose(instance_zone)


feasibility(instance_zone)
