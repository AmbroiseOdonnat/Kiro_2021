# Le but de ce code est d'obtenir une borne inf sur les instances

## On importe les bons packages

include("import_all.jl")

zone = "espagne"

data_zone = open("C:\\Users\\Wael\\Desktop\\SujetProjet20202021\\instance\\$zone.csv") do file
    readlines(file)
end

instance_zone = lire_instance("C:\\Users\\Wael\\Desktop\\SujetProjet20202021\\instance\\$zone.csv")

##Récupération des données sur la zone
dims_zone = lire_dimensions(data_zone[1])

emballages_zone = [lire_emballage(data_zone[1+e], dims_zone) for e in 1:dims_zone.E]

usines_zone = [lire_usine(data_zone[1 + dims_zone.E + u],dims_zone) for u in 1:dims_zone.U]

fournisseurs_zone = [lire_fournisseur(data_zone[1 + dims_zone.E+ dims_zone.U + f],dims_zone) for f in 1:dims_zone.F]

graphe_zone = lire_graphe(data_zone[1+dims_zone.E+dims_zone.U+dims_zone.F+1:end], dims_zone)

instance_zone = lire_instance("C:\\Users\\Wael\\Desktop\\SujetProjet20202021\\instance\\$zone.csv")

##Récupération de variables intéressantes

gamma = instance_zone.γ
c_cam = instance_zone.ccam
c_stop = instance_zone.cstop
L = instance_zone.L

d = graphe_zone.d

U = dims_zone.U
J= dims_zone.J
E= dims_zone.E
F=dims_zone.F


## Packages utiles à la résolution du PLNE

using JuMP
using Gurobi
##

model = Model(Gurobi.Optimizer)

@variable(model, x[1:E, 1:U , 1:F ,1:J],Int)
@variable(model, z_moins[1:E, 1:U , 1:J],Int)
@variable(model, z_plus[1:E, 1:F , 1:J],Int)
@variable(model, s_u[1:E, 1:U , 1:(J + 1)],Int)
@variable(model, s_f[1:E, 1:F , 1:(J + 1)],Int)
@variable(model, sr_plus_u[1:E, 1:U , 1:(J+1)],Int)
@variable(model, sr_plus_f[1:E, 1:F , 1:(J+1)],Int)
@variable(model, bs_plus[1:E, 1:F , 1:(1+J)],Int)

cout_trajet = @expression(model, sum(x[e,u,f,j]*(c_cam + c_stop + gamma*d[u,f]) for e = 1:E, u = 1:U, f = 1:F, j=1:J))
cout_stock_u = @expression(model, sum(usines_zone[u].cs[e]*sr_plus_u[e,u,j+1] for e= 1:E, u=1:U, j=1:J))
cout_stock_f = @expression(model, sum(fournisseurs_zone[f].cs[e]*sr_plus_f[e,f,j+1] for e=1:E, f=1:F, j=1:J))
cout_exc = @expression(model, sum(fournisseurs_zone[f].cexc[e]*bs_plus[e,f,j+1] for e=1:E, f=1:F, j=1:J))

@objective(model, Min, cout_trajet + cout_stock_u + cout_stock_f + cout_exc)

@constraint(model, stock_ini_u[e = 1:E, u = 1:U], s_u[e, u, 1] == usines_zone[u].s0[e] )
@constraint(model, stock_ini_f[e = 1:E, f = 1:F], s_f[e, f, 1] == fournisseurs_zone[f].s0[e] )
@constraint(model, x_pos[e=1:E, u=1:U, f=1:F, j=1:J], x[e,u,f,j]>=0)


@constraint(model, sr_u_2[e = 1:E, u=1:U, j= 1:J], sr_plus_u[e,u,j+1] >= 0)
@constraint(model, sr_f_2[e = 1:E, f=1:F, j= 1:J], sr_plus_f[e,f,j+1] >= 0)

@constraint(model, bs_pos[e=1:E, f=:1:F,j=1:J], bs_plus[e,f,j+1] >= 0)

@constraint(model, sr_u_1[e = 1:E, u=1:U, j= 1:J], sr_plus_u[e,u,j] >= s_u[e,u,j+1]-usines_zone[u].r[e,j])
@constraint(model, sr_f_1[e = 1:E, f=1:F, j= 1:J], sr_plus_f[e,f,j] >= s_f[e,f,j+1]-fournisseurs_zone[f].r[e,j])

@constraint(model, route_u[e = 1:E, u = 1:U, j = 1:J], sum(x[e,u,f,j] for f in 1:F) == z_moins[e,u,j])
@constraint(model, route_f[e = 1:E, f = 1:F, j = 1:J], sum(x[e,u,f,j] for u in 1:U) == z_plus[e,f,j])

@constraint(model, stock_u[e=1:E,u=1:U, j=1:J], s_u[e,u,j+1] == s_u[e,u,j]+ usines_zone[u].b⁺[e,j] - z_moins[e,u,j])
@constraint(model, stock_u_plus[e=1:E, u=1:U, j=1:(J+1)], s_u[e,u,j] >= 0)

@constraint(model, stock_f[e = 1:E, f=1:F, j=1:J], s_f[e,f,j+1] == bs_plus[e,f,j]+z_plus[e,f,j] )

@constraint(model, bs[e=1:E, f=:1:F,j=1:J], bs_plus[e,f,j+1]>=s_f[e,f,j] - fournisseurs_zone[f].b⁻[e,j])

##

optimize!(model)

##
