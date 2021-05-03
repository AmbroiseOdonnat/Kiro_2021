include("import_all.jl")

zone = "espagne"

data_zone = open("RECHOP/SujetProjet20202021/instance/$zone.csv") do file
    readlines(file)
end

instance_zone = lire_instance("RECHOP/SujetProjet20202021/instance/$zone.csv")

## matrice des distances

dims_zone = lire_dimensions(data_zone[1])

emballages_zone = [lire_emballage(data_zone[1+e], dims_zone) for e in 1:dims_zone.E]

usines_zone = [lire_usine(data_zone[1 + dims_zone.E + u],dims_zone) for u in 1:dims_zone.U]

fournisseurs_zone = [lire_fournisseur(data_zone[1 + dims_zone.E+ dims_zone.U + f],dims_zone) for f in 1:dims_zone.F]

graphe_zone = lire_graphe(data_zone[1+dims_zone.E+dims_zone.U+dims_zone.F+1:end], dims_zone)

d_zone = graphe_zone.d

## max des distances
global max_d_zone = d_zone[1,1]
for ind in eachindex(d_zone)
    if d_zone[ind] > max_d_zone
         global max_d_zone = d_zone[ind]
    end
end
max_d_zone


## Détection des fournisseurs isolés

function dist_usine_plus_proche(f::Fournisseur)::Int
    min_dist = d_zone[1,f.v]
    for u in usines_zone
        if d_zone[u.v,f.v] < min_dist
            min_dist = d_zone[u.v, f.v]
        end
    end
    return min_dist
end


# On repère les fournisseurs inétressants

fournisseurs_new = []
fournisseurs_isoles = []

seuil = 500

for f in fournisseurs_zone
    if dist_usine_plus_proche(f) < seuil
        push!(fournisseurs_new,f)
    else
        push!(fournisseurs_isoles,f)
    end
end

## Calcul du cout fixe des usines isolés qui utilisent que du carton
usines_zone = usines_zone
fournisseurs_zone = fournisseurs_new

E =length(emballages_zone)
U=length(usines_zone)
F=length(fournisseurs_zone)
J = instance_zone.J

c_cam = instance_zone.ccam
c_stop = instance_zone.cstop
gamma = instance_zone.γ

##
using JuMP, Gurobi
model = Model(Gurobi.Optimizer)

##
x = @variable(model, [1:E, 1:U , 1:F ,1:J],Int)
@variable(model, z_moins[1:E, 1:U , 1:J],Int)
@variable(model, z_plus[1:E, 1:F , 1:J],Int)
@variable(model, s_u[1:E, 1:U , 1:(J + 1)],Int)
@variable(model, s_f[1:E, 1:F , 1:(J + 1)],Int)
@variable(model, sr_plus_u[1:E, 1:U , 1:(J+1)],Int)
@variable(model, sr_plus_f[1:E, 1:F , 1:(J+1)],Int)
@variable(model, bs_plus[1:E, 1:F , 1:(1+J)],Int)

cout_trajet = @expression(model, sum(x[e,u,f,j]*( c_cam + c_stop + gamma*d_zone[usine_zone[u].v,fournisseurs_new[f].v]) for e = 1:E, u = 1:U, f = 1:F, j=1:J))
cout_stock_u = @expression(model, sum(usines_zone[u].cs[e]*sr_plus_u[e,u,j] for e= 1:E, u=1:U, j=1:J+1))
cout_stock_f = @expression(model, sum(fournisseurs_zone[f].cs[e]*sr_plus_f[e,f,j] for e=1:E, f=1:F, j=1:J+1))
cout_exc = @expression(model, sum(fournisseurs_zone[f].cexc[e]*bs_plus[e,f,j] for e=1:E, f=1:F, j=1:J+1))

@objective(model, Min, cout_trajet + cout_stock_u + cout_stock_f + cout_exc)

@constraint(model, stock_ini_u[e = 1:E, u = 1:U], s_u[e, u, 1] == usines_zone[u].s0[e] )
@constraint(model, stock_ini_f[e = 1:E, f = 1:F], s_f[e, f, 1] == fournisseurs_zone[f].s0[e] )
@constraint(model, x_pos[e=1:E, u=1:U, f=1:F, j=1:J], x[e,u,f,j]>=0)


@constraint(model, sr_u_2[e = 1:E, u=1:U, j= 1:J+1], sr_plus_u[e,u,j] >= 0)
@constraint(model, sr_f_2[e = 1:E, f=1:F, j= 1:J+1], sr_plus_f[e,f,j] >= 0)

@constraint(model, bs_pos[e=1:E, f=:1:F,j=1:J+1], bs_plus[e,f,j] >= 0)

@constraint(model, sr_u_1[e = 1:E, u=1:U, j= 1:J], sr_plus_u[e,u,j] >= s_u[e,u,j]-usines_zone[u].r[e,j])
@constraint(model, sr_f_1[e = 1:E, f=1:F, j= 1:J], sr_plus_f[e,f,j] >= s_f[e,f,j]-fournisseurs_zone[f].r[e,j])

@constraint(model, route_u[e = 1:E, u = 1:U, j = 1:J], sum(x[e,u,f,j] for f in 1:F) == z_moins[e,u,j])
@constraint(model, route_f[e = 1:E, f = 1:F, j = 1:J], sum(x[e,u,f,j] for u in 1:U) == z_plus[e,f,j])

@constraint(model, stock_u[e=1:E,u=1:U, j=1:J], s_u[e,u,j+1] == s_u[e,u,j]+ usines_zone[u].b⁺[e,j] - z_moins[e,u,j])
@constraint(model, stock_u_plus[e=1:E, u=1:U, j=1:(J+1)], s_u[e,u,j] >= 0)

@constraint(model, stock_f[e = 1:E, f=1:F, j=1:J], s_f[e,f,j+1] == bs_plus[e,f,j]+z_plus[e,f,j] )

@constraint(model, bs[e=1:E, f=:1:F,j=1:J], bs_plus[e,f,j+1]>=s_f[e,f,j] - fournisseurs_zone[f].b⁻[e,j])


##methode pour recuperer les routes !
optimize!(model)

Optimal_livraison = value.(x)
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

test_x = []
len_F= length(fournisseurs_new)

for e=1:E, u=1:U, f=1:len_F, j=1:J
    Q = q_gen(e,E)
    stop = RouteStop(;f=fournisseurs_new[f].f,Q=Q)
    r= 1 + length(routes_solution)
    stops=[stop]
    x=Int(Optimal_livraison[e, u, f, j])
    if x >0
        push!(test_x,[x,e,u,f,j])
        F= 1
        route=Route(; r=r, j=j, x=x, u=u, F=F, stops=stops)
        push!(routes_solution,route)
    end
end

test_x
instance_zone.routes = routes_solution



cost_verbose(instance_zone)
#cout sans routes = 774692
#cout avec seuil 500 = 798365
feasibility(instance_zone)
