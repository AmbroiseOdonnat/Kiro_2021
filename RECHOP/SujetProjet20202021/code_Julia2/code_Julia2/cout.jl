## Couts routes

function nb_km(route::Route, instance::Instance)::Int
    U = instance.U
    d = instance.d

    v1, v2 = 0, 0
    dist = 0
    for (k, stop) in enumerate(route.stops)
        if k == 1
            v1, v2 = route.u, U+stop.f
        else
            v1, v2 = v2, U+stop.f
        end
        dist += d[v1, v2]
    end
    return dist
end

function nb_etapes(route::Route)::Int
    return length(route.stops)
end

function cout_camion(instance::Instance)::Int
    return instance.ccam
end

function cout_etapes(route::Route, instance::Instance)::Int
    return instance.cstop * nb_etapes(route)
end

function cout_kms(route::Route, instance::Instance)::Int
    return instance.γ * nb_km(route, instance)
end

function cout_route_unitaire(route::Route, instance::Instance)::Int
    return cout_camion(instance) + cout_etapes(route, instance) + cout_kms(route, instance)
end

function cout_route(route::Route, instance::Instance)::Int
    return route.x * cout_route_unitaire(route, instance)
end

## Couts usines

function cout_stock(usine::Usine, j::Int)::Int
    E, J = size(usine.s)
    return sum(usine.cs[e] * max(0.0, usine.s[e, j] - usine.r[e, j]) for e = 1:E)
end

function cout_stock(usine::Usine)::Int
    E, J = size(usine.s)
    return sum(cout_stock(usine, j) for j = 1:J)
end

## Couts fournisseurs

function cout_stock(fournisseur::Fournisseur, j::Int)::Int
    E, J = size(fournisseur.s)
    c = sum(
        fournisseur.cs[e] * max(0.0, fournisseur.s[e, j] - fournisseur.r[e, j]) for e = 1:E
    )
    return c
end

function cout_stock(fournisseur::Fournisseur)
    E, J = size(fournisseur.s)
    return sum(cout_stock(fournisseur, j) for j = 1:J)
end

function cout_expedition_cartons(fournisseur::Fournisseur, j::Int)::Int
    E, J = size(fournisseur.s)
    c = sum(
        fournisseur.cexc[e] * max(
            0.0,
            fournisseur.b⁻[e, j] - (j == 1 ? fournisseur.s0[e] : fournisseur.s[e, j-1]),
        ) for e = 1:E
    )
    return c
end

function cout_expedition_cartons(fournisseur::Fournisseur)
    E, J = size(fournisseur.s)
    return sum(cout_expedition_cartons(fournisseur, j) for j = 1:J)
end

## Cout total

function cout_pas_detaille(instance::Instance)::Int
    usines, fournisseurs, routes = instance.usines, instance.fournisseurs, instance.routes

    c = 0.0
    for usine in instance.usines
        c += cout_stock(usine)
    end
    for fournisseur in instance.fournisseurs
        c += cout_stock(fournisseur) + cout_expedition_cartons(fournisseur)
    end
    for route in instance.routes
        c += cout_route(route, instance)
    end
    return c
end

function cout_detaille(instance::Instance)::Int
    U, F, J = instance.U, instance.F, instance.J
    usines, fournisseurs, routes = instance.usines, instance.fournisseurs, instance.routes
    R = length(routes)

    println()

    println("$U usines, $F fournisseurs, $R routes")

    cout_stock_usines = sum(cout_stock(usine) for usine in usines)
    println("Cout stock usines : $cout_stock_usines soit $(cout_stock_usines / U) par usine")

    cout_stock_fournisseurs = sum(cout_stock(fournisseur) for fournisseur in fournisseurs)
    println("Cout stock fournisseurs : $cout_stock_fournisseurs soit $(cout_stock_fournisseurs / F) par fournisseur")

    cout_exc_fournisseurs =
        sum(cout_expedition_cartons(fournisseur) for fournisseur in fournisseurs)
    println("Cout cartons fournisseurs : $cout_exc_fournisseurs soit $(cout_exc_fournisseurs / F) par fournisseur")

    if length(routes) > 0
        cout_camion_routes = sum(cout_camion(instance) for route in routes)
        println("Cout camion routes : $cout_camion_routes soit $(cout_camion_routes / R) par route")
        cout_etapes_routes = sum(cout_etapes(route, instance) for route in routes)
        println("Cout etapes routes : $cout_etapes_routes soit $(cout_etapes_routes / R) par route")
        cout_kms_routes = sum(cout_kms(route, instance) for route in routes)
        println("Cout kms routes : $cout_kms_routes soit $(cout_kms_routes / R) par route")
        cout_total =
            cout_stock_usines +
            cout_stock_fournisseurs +
            cout_exc_fournisseurs +
            cout_camion_routes +
            cout_etapes_routes +
            cout_kms_routes
        println("Cout total : $cout_total")
        return cout_total
    else
        cout_total = cout_stock_usines + cout_stock_fournisseurs + cout_exc_fournisseurs
        println("Cout total : $cout_total")
        return cout_total
    end
end

function cout_super_detaille(instance::Instance)::Int
    U, F, J = instance.U, instance.F, instance.J
    usines, fournisseurs, routes = instance.usines, instance.fournisseurs, instance.routes
    R = length(routes)
    c = 0

    println()
    println("$U usines, $F fournisseurs, $R routes")
    println()

    for u = 1:U
        println("Usine $u")
        for j = 1:J
            cujs = cout_stock(usines[u], j)
            c += cujs
            println("   Jour $j")
            println("      Coût stock: $cujs")
        end
    end
    cu = c

    println()

    for f = 1:F
        println("Fournisseur $f")
        for j = 1:J
            cfjs = cout_stock(fournisseurs[f], j)
            cfje = cout_expedition_cartons(fournisseurs[f], j)
            c += cfjs + cfje
            println("   Jour $j")
            println("      Coût stock: $cfjs")
            println("      Coût expédition: $cfje")
            println("      Coût total: " * string(cfjs + cfje))
        end
    end
    cf = c - cu

    println()

    for (r, route) in enumerate(routes)
        println("Route $r - jour $(route.j), usine $(route.u)")
        crt = cout_camion(instance)
        crs = cout_etapes(route, instance)
        crk = cout_kms(route, instance)
        rx = route.x
        c += route.x * (crt + crs + crk)
        println("   Coût camion: $crt")
        println("   Coût arrêts: $crs")
        println("   Coût kilométrique: $crk")
        println("   Nb camions: $rx")
        println("   Coût total: " * string(route.x * (crt + crs + crk)))
    end
    cr = c - cf - cu

    return c
end

function cout(instance::Instance; details::Int = 0)::Int
    if details == 0
        return cout_pas_detaille(instance)
    elseif details == 1
        return cout_detaille(instance)
    elseif details == 2
        return cout_super_detaille(instance)
    end
end

function cout(instance::Instance, solution::Solution; details::Int = 0)::Int
    return cout(instance_resolue(instance, solution), details = details)
end

function cout(instance::Instance, routes::Vector{Route}; details::Int = 0)::Int
    return cout(instance_resolue(instance, SolutionStructuree(instance, routes)), details = details)
end

## Analyser les caractéristiques d'une solution

function longueur_chargement_moyenne(solution::Solution, instance::Instance)::Float64
    lmoy =
        sum(longueur_chargement(route, instance) for route in list_routes(solution)) /
        nb_routes(solution)
    return lmoy
end

function nb_km_moyen(solution::Solution, instance::Instance)
    nmoy =
        sum(nb_km(route, instance) for route in list_routes(solution)) / nb_routes(solution)
    return nmoy
end

function nb_etapes_moyen(solution::Solution)
    nmoy = sum(nb_etapes(route) for route in list_routes(solution)) / nb_routes(solution)
    return nmoy
end
