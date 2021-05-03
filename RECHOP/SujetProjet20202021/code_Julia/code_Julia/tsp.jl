# Le but de ce code est de résoudre le TSP sur des petites instance


# Entrée un ensemble {u,f_1,..f_p} et la matrice d

function cost_tsp(u::Usine, fourni_u::Vector{Fournisseur},d::Array{Int64,2})
    n = length(fourni_u)
    cost_function = Matrix{Int64}(undef, n + 1, n + 1)
    #Sommets 1 à n : fournisseurs, sommet n+1 : usine
    for f in 1:n
        cost_function[f, n + 1] = cstop + d[u.v,fourni_u[f].v]*γ
        cost_function[n + 1, f] = cost_function[f, n + 1]
        for f_2 in 1:n
            cost_function[f,f_2]= cstop + d[fourni_u[f].v, fourni_u[f_2].v]
        end
    end
    for v = 1:n+1
        cost_function[v, v] = 0
    end
    return cost_function
end

test=cost_tsp(usines[1],[fournisseurs[1],fournisseurs[2]],d)


function tsp_uf(u::Usine, fourni_u::Vector{Fournisseur},d::Array{Int64,2})
    couts_trajets = cost_tsp(u, fourni_u,d)
end
