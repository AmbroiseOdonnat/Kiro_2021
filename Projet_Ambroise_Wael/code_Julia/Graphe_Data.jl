include("/Users/ambroise/Projet/code_Julia/Resolution_PL_Graphe(b-flow).jl")
include("/Users/ambroise/Projet/code_Julia/Struct_Graph.jl")


function create_graphe(path::String)::Graph
    lecture = open(joinpath(path)) do file
                readlines(file)
              end
    dims = lire_dimensions(lecture[1])
    rows = lecture[1+dims.E+dims.U+dims.F+1:end]
    G = lire_graphe(rows,dims).G
    N = LightGraphs.nv(G)
    V = []
    for i in LightGraphs.vertices(G)
        push!(V,i)
    end
    push!(V,N+1) #source
    push!(V,N+2) #puit
    push!(V,N+3) #carton
    Adj = Vector{Vector{Int}}(undef,length(V))
    for v in V
         Adj[v] = []
     end
    D = Dict()
    g = Graph(N,Adj,D)
    @showprogress "Reading graph " for row in rows
        a = lire_arc(row)
        add_edge!(g, a.v1, a.v2,0)
    end
    return g
end


function create_data(path::String,e::Emballage,jour::Int64)::Data #on considère pour une journée, avec un emballage
    Instance = lire_instance(path)
    Gra = Instance.graphe
    G = Gra.G
    usines = Instance.usines
    fournisseurs = Instance.fournisseurs
    emballages = Instance.emballages
    N=LightGraphs.nv(G)
    V = []
    for i in LightGraphs.vertices(G)
        push!(V,i)
    end
    push!(V,N+1) #on compte l'usine à cartons
    adj = Vector{Vector{Int}}(undef,N+1)
    for v in V
         adj[v] = []
    end
    D = Dict()
    graphe = Graph(N+1,adj,D)
    for u in usines
        for f in fournisseurs
            cost = cost_unique_arret(path,u,f)
            add_edge!(graphe,u.v,f.v,floor(Int,cost))
        end
    end
    for f in fournisseurs
        add_edge!(graphe,f.v,N+1,f.cexc[e.e])
    end
    b = Vector{Int}(undef,N+1)
    for i in 1:N+1
        b[i] = 0
    end
    for u in usines
        b[u.v] = b_plus(u,jour,e)
    end
    b[usines[1].u] = b_plus(usines[1],jour,e) + usines[1].s0[e.e]
    for f in fournisseurs
        b[f.v] = - b_moins(f,jour,e)
    end
    b[N+1] = -(sum( b[u.v] for u in usines ) + sum( b[f.v] for f in fournisseurs )) #il doit reinjecter dans le graphe ce qu'il faut de carton
    low = Dict()
    up = Dict()
    for i in 1:N+1
        for j in 1:N+1
            low[(i,j)] = 0
            up[(i,j)] = typemax(Int64)
        end
    end
    for u in usines
        for f in fournisseurs
            low[(u.v,f.v)] = 0
            up[(u.v,f.v)] = typemax(Int64)
        end
    end
    D = Data(graphe,low,up,b)
    return D
end

#test sur les données


data_petite = open(joinpath("/Users/ambroise/Projet/sujet/petite.csv")) do file
              readlines(file)
              end
Instance_test = lire_instance("/Users/ambroise/Projet/sujet/petite.csv")
Route_test = Instance_test.routes
dims_petite = lire_dimensions(data_petite[1])
graphe = lire_graphe(data_petite[1+dims_petite.E+dims_petite.U+dims_petite.F+1:end], dims_petite)
graph_new = create_graphe("/Users/ambroise/Projet/sujet/petite.csv")
l = u=b=[]
Data(graph_new,l,u,b)

Maroc = lire_instance("/Users/ambroise/Projet/sujet/maroc.csv")
cout_par_jour = sum(Solution(create_data("/Users/ambroise/Projet/sujet/maroc.csv",e,1)) for e in Maroc.emballages)
Test = lire_instance("/Users/ambroise/Projet/sujet/petite.csv")
e = Test.emballages[2]
data = create_data("/Users/ambroise/Projet/sujet/petite.csv",e,1)
Solution(data)
"
G = graphe.G
N = LightGraphs.nv(G)
V = []
LightGraphs.vertices(G)#on compte usine à carton, source et puit
for i in LightGraphs.vertices(G)
    push!(V,i)
end
V
push!(V,N+1) #source
push!(V,N+2) #puit
push!(V,N+3) #carton
Adj = Vector{Vector{Int}}(undef,length(V))
for v in V
     Adj[v] = []
 end

D = Dict{Tuple{Int, Int}, Int64}()
g = Graph(N,Adj,D)"
