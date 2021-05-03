include("/Users/ambroise/Projet/code_Julia/import_all.jl")
# structure de graphe
mutable struct Graph
    n::Int #nombre de sommets
    adj::Vector{Vector{Int}} #sommets adjacent à un u donné
    weights::Dict{Tuple{Int, Int}, Int} #poids sur les arcs du graphe = cost
end


function nv(G::Graph)::Int
    return G.n
end

function vertices(G::Graph)::Vector{Int}
    V = collect(1:G.n)
    return V
end

function add_vertex!(G::Graph)
    G.n += 1
    push!(G.adj, Int[])
end

function add_edge!(G::Graph, u::Int, v::Int, weight::Int)
    push!(G.adj[u],v)
    G.weights[(u, v)] = weight
end

function matrice_incidence(G::Graph)
    n = nv(G)
    m = number_edges(G)
    V = vertices(G)
    E = edges(G)
    A = Matrix{Int}(undef,n,m)
    for i in 1:n
        for j in 1:m
            if E[j][2] in outneighbors(G,V[i]) && E[j][1]==V[i]
                A[i,j] = -1
            elseif E[j][1] in inneighbors(G,V[i]) && E[j][2]==V[i]
                A[i,j] = 1
            else
                A[i,j] = 0
            end
        end
    end
    return A
end


function has_edge(G::Graph, u::Int, v::Int)::Bool
    return v in G.adj[u]
end

function outneighbors(G::Graph, u::Int)::Vector{Int}
    return G.adj[u]
end

function inneighbors(G::Graph, v::Int)::Vector{Int}
    r = []
    for u in vertices(G)
        if has_edge(G,u,v)
            push!(r,u)
        end
    end
    return r
end

function edges(G::Graph)::Vector{Tuple{Int, Int}}
    E = collect((u, v) for u in vertices(G) for v in outneighbors(G, u))
    return unique(E)
end

function number_edges(G::Graph)::Int
    return length(edges(G))
end

function weight(G::Graph, u::Int, v::Int)
    return G.weights[(u, v)]
end
