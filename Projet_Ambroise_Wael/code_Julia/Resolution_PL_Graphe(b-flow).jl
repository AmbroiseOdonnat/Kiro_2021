# structure données du problème
mutable struct Data
    graph::Graph
    lower_cap
    upper_cap
    b_flow
end

mutable struct Define_Model
    data::Data
    m
    x
    c_eq
    c_ineq
end

#faire fonction qui construit un graphe à partir de l instance
#faire fonction qui donne les contraintes à partir de l instance
#faire fonction qui calcule cout et b-flow
#faire foncion qui renvoie un Problem_model avec les contraintes et les capacités''
#Fonctions pour creer graphe
#Fonctions pour capacités
#Fonctions pour b-flow

#utiliser gurobi911
ENV["GUROBI_HOME"] = "/Library/gurobi911/mac64"
import Pkg
Pkg.add("Gurobi")
Pkg.build("Gurobi")
# definition du modèle
using JuMP, Gurobi


#Fonctions pour creer le probleme_model
function basic_model(d::Data)::Define_Model
  G = d.graph
  E = edges(G)
  V = vertices(G)
  b = d.b_flow
  l = d.lower_cap
  A = matrice_incidence(G)
  u = d.upper_cap
  m = Model(Gurobi.Optimizer)
  n = nv(G)
  k = number_edges(G)
  x = @variable(m,[1:k],lower_bound =0,Int)
  #c_eq = @constraint(m,[j = 1:k], 0<=x[j] )
  #c_ineq = @constraint(m,[j in 1:k], 0 <= x[j])
  c_eq = @constraint(m,[i in 1:n], sum( A[i,j]*x[j] for j=1:k ) == -b[i] ) #egalité avec matrice d'incidence à coder
  c_ineq = @constraint(m,[j in 1:k], l[(E[j][1],E[j][2])] <= x[j] <= u[(E[j][1],E[j][2])])
  #x = @variable(m, [e in edges(G)], lower_bound = 0)
  #c_eq = @constraint(m,[u in vertices(G)], sum( x[e] for e in outneighbors(G,u)) - sum( x[e] for e in inneighbors(G,u))  == b(u))
  #c_ineq = @constraint(m,[e in edges(G)], l[e]<=x[e]<=u[e] )

  return Define_Model(d,m,x,c_eq,c_ineq)
end

#solution
function Solution(data::Data)
    P = basic_model(data)
    d = P.data
    G = d.graph
    E = edges(G)
    W = G.weights
    x = P.x
    m = P.m
    k = number_edges(G)
    @objective(m, Min, sum( W[(E[j][1],E[j][2])]*x[j] for j=1:k) )
    optimize!(m)
    status = termination_status(m)
    return value.(x)
end



#creation graphe et données :: test
n=10
g = Base.OneTo(n)
v = Vector{Vector{Int}}(undef,n)
for i in g
     v[i] = []
 end
D = Dict{Tuple{Int, Int}, Float64}()
G = Graph(4,v,D)
add_edge!(G, 1, 2,0)
add_edge!(G, 1, 3,0)
add_edge!(G, 2, 4,0)
add_edge!(G, 3, 4,0)
E = edges(G)
b = Vector{Int}(undef,n)
b[1] = 2
b[4] = -2
b[2] = b[3] = 0
l = Dict{Tuple{Int, Int}, Float64}()
for e in E
    l[(e[1],e[2])] = 0
end
u = Dict{Tuple{Int, Int}, Float64}()
for e in E
    u[(e[1],e[2])] = 3
end
data = Data(G,l,u,b)
Solution(data)
A = matrice_incidence(G)
