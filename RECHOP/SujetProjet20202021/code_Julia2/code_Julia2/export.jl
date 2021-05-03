## Encodage en chaine de caractères

function Base.string(emballage::Emballage)::String
    str = "e $(emballage.e-1) l $(emballage.l)"
    return str
end

function Base.string(usine::Usine)::String
    E, J = size(usine.b⁺)
    str = "u $(usine.u-1) v $(usine.v - 1) coor $(usine.coor[1]) $(usine.coor[2]) "
    str *= "ce "
    for e = 1:E
        str *= "e $(e-1) cr $(usine.cs[e]) b $(usine.s0[e]) "
    end
    str *= "lib "
    for j = 1:J
        str *= "j $(j-1) "
        for e = 1:E
            str *= "e $(e-1) b $(usine.b⁺[e, j]) r $(usine.r[e, j]) "
        end
    end
    return str[1:end-1]
end

function Base.string(fournisseur::Fournisseur)::String
    E, J = size(fournisseur.b⁻)
    str = "f $(fournisseur.f-1) v $(fournisseur.v - 1) coor $(fournisseur.coor[1]) $(fournisseur.coor[2]) "
    str *= "ce "
    for e = 1:E
        str *= "e $(e-1) cr $(fournisseur.cs[e]) cexc $(fournisseur.cexc[e]) b $(fournisseur.s0[e]) "
    end
    str *= "dem "
    for j = 1:J
        str *= "j $(j-1) "
        for e = 1:E
            str *= "e $(e-1) b $(fournisseur.b⁻[e, j]) r $(fournisseur.r[e, j]) "
        end
    end
    return str[1:end-1]
end

struct Distances
    d::Matrix{Int}
    Distances(; d) = new(d)
end

function Base.string(distances::Distances)::String
    V = size(distances.d, 1)
    str = ""
    for u = 1:V, v = 1:V
        str *= "a $(u-1) $(v-1) d $(distances.d[u, v])\n"
    end
    return str[1:end-1]
end

function Base.string(stop::RouteStop)::String
    E = length(stop.Q)
    str = "f $(stop.f-1)"
    for e = 1:E
        str *= " e $(e-1) q $(stop.Q[e])"
    end
    return str
end

function Base.string(route::Route, r::Int)::String
    j = route.j
    x = route.x
    u = route.u
    F = length(route.stops)
    str = "r $(r-1) j $(j-1) x $x u $(u-1) F $F"
    for stop in route.stops
        str *= " " * string(stop)
    end
    return str
end

## Export dans un fichier

function ecrire_instance(instance::Instance, path::String)::Bool
    J, U, F, E = instance.J, instance.U, instance.F, instance.E
    L, γ, ccam, cstop = instance.L, instance.γ, instance.ccam, instance.cstop
    str = "J $J U $U F $F E $E L $L Gamma $γ CCam $ccam CStop $cstop\n"

    for emballage in instance.emballages
        str *= string(emballage) * "\n"
    end
    for usine in instance.usines
        str *= string(usine) * "\n"
    end
    for fournisseur in instance.fournisseurs
        str *= string(fournisseur) * "\n"
    end
    str *= string(Distances(d = instance.d)) * "\n"
    open(path, "w") do file
        write(file, str)
    end
    return true
end

function ecrire_solution(routes::Vector{Route}, path::String)::Bool
    R = length(routes)
    str = "R $R"
    for (r, route) in enumerate(routes)
        str *= "\n" * string(route, r)
    end
    open(path, "w") do file
        write(file, str)
    end
    return true
end

ecrire_solution(instance::Instance, path::String)::Bool =
    ecrire_solution(instance.routes, path)

ecrire_solution(solution::Solution, path::String)::Bool =
    ecrire_solution(list_routes(solution), path)
