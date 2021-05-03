## Faisabilité route

function longueur_chargement(route::Route, instance::Instance)::Int
    long = 0
    for stop in route.stops, e = 1:instance.E
        long += stop.Q[e] * instance.emballages[e].l
    end
    return long
end

function faisabilite(route::Route, instance::Instance; verbose::Bool=true)
    if route.x < 1
        if verbose
            @warn "Route avec $route.x camions"
        end
        return false
    elseif !(1 <= route.u <= instance.U)
        if verbose
            @warn "Route avec usine $route.u inexistante"
        end
        return false
    elseif !(1 <= route.j <= instance.J)
        if verbose
            @warn "Route avec jour $route.j inexistant"
        end
        return false
    elseif !(1 <= length(route.stops) <= 4)
        F = length(route.stops)
        if verbose
            @warn "Route de longueur $F"
        end
        return false
    elseif longueur_chargement(route, instance) > instance.L
        long = longueur_chargement(route, instance)
        if verbose
            @warn "Chargement de longueur $long > $(instance.L)"
        end
        return false
    end
    return true
end

## Faisabilite usines

function faisabilite(usine::Usine)::Bool
    if any(usine.s .< 0)
        @warn "Stock négatif usine $usine.u"
        return false
    else
        return true
    end
end

## Faisabilite fournisseurs

function faisabilite(fournisseur::Fournisseur)::Bool
    if any(fournisseur.s .< 0)
        @warn "Stock négatif fournisseur $fournisseur.f"
        return false
    else
        return true
    end
end

## Faisabilité globale

function faisabilite(instance::Instance)::Bool
    for route in instance.routes
        if !faisabilite(route, instance)
            return false
        end
    end
    for usine in instance.usines
        if !faisabilite(usine)
            return false
        end
    end
    for fournisseur in instance.fournisseurs
        if !faisabilite(fournisseur)
            return false
        end
    end
    return true
end

function faisabilite(instance::Instance, solution::Solution)::Bool
    return faisabilite(instance_resolue(instance, solution))
end

function faisabilite(instance::Instance, routes::Vector{Route})::Bool
    return faisabilite(instance_resolue(instance, SolutionSimple(routes)))
end
