## fonction de cout
function cost_uf(u::Int,f::Int,instance::Instance)::Int #cout pour aller de u a f
    fournisseurs = Int[]
    push!(fournisseurs,f)
    return cost_dist(u,fournisseurs,instance)
end

function cost_dist(usine::Int,fournisseurs::Vector{Int},instance::Instance) #cout pour faire le chemin u + les fournisseurs
    P_r = []
    push!(P_r,usine)
    for f in fournisseurs
        push!(P_r,f)
    end
    U = instance.U
    d = instance.graphe.d
    c_cam = instance.ccam
    c_stop = instance.cstop
    gamma = instance.γ
    card_chemin = length(P_r)
    return c_cam + c_stop*(length(P_r)-1) + gamma*sum(d[P_r[i],P_r[i+1]] for i in 1:length(P_r)-1)
end

function index_minimize(a::Vector{Int})
    index = 1
    m = a[index]
    for i in 1:length(a)
        if a[i] < m
            m = a[i]
            index = i
        end
    end
    return index
end

function different(a::Vector{Fournisseur}, f::Fournisseur)::Vector{Fournisseur}
    a_ = []
    for l in a
        if l.v!=f.v
            push!(a_,l)
        end
    end
    return a_
end

function possible_route(instance::Instance) #heuristique voisinage de u: 4 fournisseurs de routes possibles
    usines = instance.usines
    fournisseurs = instance.fournisseurs
    possible_route = []
    for u in usines
        routes_4 = []
        Path_f = Int[]
        for f in fournisseurs
            push!(Path_f,cost_uf(u.v,f.v,instance))
        end
        index_1 = index_minimize(Path_f)
        f1 = fournisseurs[index_1]
        push!(routes_4,f1)
        empty!(Path_f)
        prive_1 = different(fournisseurs,f1)
        for f in prive_1
            push!(Path_f,cost_dist(u.v,[f1.v,f.v],instance))
        end
        index_2 = index_minimize(Path_f)
        f2 = fournisseurs[index_2]
        push!(routes_4,f2)
        empty!(Path_f)
        prive_1_2 = different(prive_1,f2)
        for f in prive_1_2
            push!(Path_f,cost_dist(u.v,[f1.v,f2.v,f.v],instance))
        end
        index_3 = index_minimize(Path_f)
        f3 = fournisseurs[index_3]
        push!(routes_4,f3)
        empty!(Path_f)
        prive_1_2_3 = different(prive_1_2,f3)
        for f in prive_1_2_3
            push!(Path_f,cost_dist(u.v,[f1.v,f2.v,f3.v,f.v],instance))
        end
        index_4 = index_minimize(Path_f)
        f4 = fournisseurs[index_4]
        push!(routes_4,f4)
        empty!(Path_f)
        push!(possible_route,(u,routes_4))
    end
    return possible_route
end

function is_in(vect::Vector{Fournisseur},f::Fournisseur)
    for i in vect
        if i == f
            return true
        end
    end
end
