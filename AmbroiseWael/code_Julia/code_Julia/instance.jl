using PolygonOps
import GADM

mutable struct Instance
    J::Int
    U::Int
    F::Int
    E::Int

    L::Int
    γ::Int
    ccam::Int
    cstop::Int

    emballages::Vector{Emballage}
    usines::Vector{Usine}
    fournisseurs::Vector{Fournisseur}
    graphe::Graphe

    R::Int
    routes::Vector{Route}

    Instance(; J, U, F, E, L, γ, ccam, cstop, emballages, usines, fournisseurs, graphe) =
        new(
            J,
            U,
            F,
            E,
            L,
            γ,
            ccam,
            cstop,
            emballages,
            usines,
            fournisseurs,
            graphe,
            0,
            Route[],
        )
end

function Base.show(io::IO, instance::Instance)
    str = "\nInstance"
    str *= "\n   Nombre de jours: $(instance.J)"
    str *= "\n   Nombre d'usines: $(instance.U)"
    str *= "\n   Nombre de fournisseurs: $(instance.F)"
    str *= "\n   Nombre de types d'emballages: $(instance.E)"
    str *= "\n   Nombre de routes: $(length(instance.routes))"
    print(io, str)
end

function lire_dimensions(row::String)::NamedTuple
    row_split = split(row, r"\s+")
    return (
        J = parse(Int, row_split[2]),
        U = parse(Int, row_split[4]),
        F = parse(Int, row_split[6]),
        E = parse(Int, row_split[8]),
        L = parse(Int, row_split[10]),
        γ = parse(Int, row_split[12]),
        ccam = parse(Int, row_split[14]),
        cstop = parse(Int, row_split[16]),
    )
end

function lire_instance(path::String)::Instance
    data = open(path) do file
        readlines(file)
    end

    dims = lire_dimensions(data[1])
    emballages = [lire_emballage(data[1+e], dims) for e = 1:dims.E]
    usines = [lire_usine(data[1+dims.E+u], dims) for u = 1:dims.U]
    fournisseurs = [lire_fournisseur(data[1+dims.E+dims.U+f], dims) for f = 1:dims.F]
    graphe = lire_graphe(data[1+dims.E+dims.U+dims.F+1:end], dims)

    return Instance(
        J = dims.J,
        U = dims.U,
        F = dims.F,
        E = dims.E,
        L = dims.L,
        γ = dims.γ,
        ccam = dims.ccam,
        cstop = dims.cstop,
        emballages = emballages,
        usines = usines,
        fournisseurs = fournisseurs,
        graphe = graphe,
    )
end

function restrict(instance::Instance, countrycode::String = "FRA")::Instance
    polygons_country = [pol[1] for pol in GADM.coordinates(countrycode)]

    usines_country = [
        usine
        for
        usine in instance.usines if
        any(inpolygon(reverse(usine.coor), polygon) == 1 for polygon in polygons_country)
    ]
    fournisseurs_country = [
        fournisseur
        for
        fournisseur in instance.fournisseurs if
        any(
            inpolygon(reverse(fournisseur.coor), polygon) == 1
            for polygon in polygons_country
        )
    ]

    new_vertices = vcat(
        [usine.v for usine in usines_country],
        [fournisseur.v for fournisseur in fournisseurs_country],
    )

    G_country = induced_subgraph(instance.graphe.G, new_vertices)[1]
    d_country = instance.graphe.d[new_vertices, new_vertices]
    graphe_country = Graphe(G = G_country, d = d_country)
    
    U_country = length(usines_country)
    F_country = length(fournisseurs_country)
    usines_country_renumbered = [
        renumber(usine, u=u, v=u) for (u, usine) in enumerate(usines_country)
    ]
    fournisseurs_country_renumbered = [
        renumber(fournisseur, f=f, v=U_country+f) for (f, fournisseur) in enumerate(fournisseurs_country)
    ]

    instance_country = Instance(
        J = instance.J,
        U = U_country,
        F = F_country,
        E = instance.E,
        L = instance.L,
        γ = instance.γ,
        ccam = instance.ccam,
        cstop = instance.cstop,
        emballages = instance.emballages,
        usines = usines_country_renumbered,
        fournisseurs = fournisseurs_country_renumbered,
        graphe = graphe_country,
    )

    return instance_country
end