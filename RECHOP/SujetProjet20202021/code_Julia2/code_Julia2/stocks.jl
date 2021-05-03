## Mettre à jour une instance à partir d'une solution

function update_z!(instance::Instance, solution::Solution)::Bool
    U, F, J, E = instance.U, instance.F, instance.J, instance.E

    # Set to zero
    for j = 1:J, e = 1:E
        for usine in instance.usines
            usine.z⁻[e, j] = 0
        end
        for fournisseur in instance.fournisseurs
            fournisseur.z⁺[e, j] = 0
        end
    end

    # Increase with each route
    for route in list_routes(solution)
        j = route.j
        usine = instance.usines[route.u]
        for e = 1:E
            usine.z⁻[e, j] += route.x * sum(stop.Q[e] for stop in route.stops)
        end
        for stop in route.stops
            fournisseur = instance.fournisseurs[stop.f]
            for e = 1:E
                fournisseur.z⁺[e, j] += route.x * stop.Q[e]
            end
        end
    end
    return true
end

function update_s!(instance::Instance, solution::Solution)::Bool
    U, F, J, E = instance.U, instance.F, instance.J, instance.E

    for j = 1:J, e = 1:E
        for usine in instance.usines
            s_prev = j == 1 ? usine.s0[e] : usine.s[e, j-1]
            usine.s[e, j] = s_prev + usine.b⁺[e, j] - usine.z⁻[e, j]
        end
        for fournisseur in instance.fournisseurs
            s_prev = j == 1 ? fournisseur.s0[e] : fournisseur.s[e, j-1]
            fournisseur.s[e, j] =
                max(0, s_prev - fournisseur.b⁻[e, j]) + fournisseur.z⁺[e, j]
        end
    end
    return true
end

function instance_resolue!(instance::Instance, solution::Solution)::Bool
    update_z!(instance, solution)
    update_s!(instance, solution)
    # update_stocks!(instance, solution)
    instance.routes = collect(list_routes(solution))
    return true
end

## Créer une nouvelle instance résolue

function instance_resolue(instance::Instance, solution::Solution)::Instance
    solved_instance = copy(instance)
    instance_resolue!(solved_instance, solution)
    return solved_instance
end

## Vérifier la cohérence d'une instance avec ses routes

function coherence_routes_stocks(instance::Instance)::Bool
    instance_correcte = instance_resolue(instance, SolutionSimple(instance.routes))
    ia1 = InstanceArrays(instance)
    ia2 = InstanceArrays(instance_correcte)
    return all(ia1.su .== ia2.su) && all(ia1.sf .== ia2.sf)
end

## Deprecated

function update_stocks!(usine::Usine, solution::Solution)::Bool
    error("Deprecated function update_stocks!, use update_z! and update_s! instead")
    E, J = size(usine.s)

    for j = 1:J
        for e = 1:E
            usine.z⁻[e, j] = 0
        end
        for route in list_routes(solution, j, usine.u)
            for e = 1:E
                usine.z⁻[e, j] += chargement(route, usine, e = e, j = j)
            end
        end
    end

    for e = 1:E, j = 1:J
        usine.s[e, j] =
            (j == 1 ? usine.s0[e] : usine.s[e, j-1]) + usine.b⁺[e, j] - usine.z⁻[e, j]
    end

    return true
end

function update_stocks!(fournisseur::Fournisseur, solution::Solution)::Bool
    E, J = size(fournisseur.s)

    for j = 1:J
        for e = 1:E
            fournisseur.z⁺[e, j] = 0
        end
        for route in list_routes(solution, j)
            for e = 1:E
                fournisseur.z⁺[e, j] += livraison(route, fournisseur, e = e, j = j)
            end
        end
    end

    for e = 1:E, j = 1:J
        fournisseur.s[e, j] =
            max(
                0,
                (j == 1 ? fournisseur.s0[e] : fournisseur.s[e, j-1]) - fournisseur.b⁻[e, j],
            ) + fournisseur.z⁺[e, j]
    end

    return true
end

function update_stocks!(instance::Instance, solution::Solution)::Bool
    for usine in instance.usines
        update_stocks!(usine, solution)
    end
    for fournisseur in instance.fournisseurs
        update_stocks!(fournisseur, solution)
    end
    return true
end
