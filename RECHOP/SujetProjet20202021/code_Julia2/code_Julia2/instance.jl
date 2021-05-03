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
    d::Matrix{Int}

    routes::Vector{Route}

    function Instance(; J, U, F, E, L, γ, ccam, cstop, emballages, usines, fournisseurs, d)
        return new(
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
            d,
            Route[],
        )
    end
end

mutable struct InstanceArrays
    J::Int
    U::Int
    F::Int
    E::Int

    L::Int
    γ::Int
    ccam::Int
    cstop::Int
    d::Matrix{Int}

    l::Vector{Int}

    csu::Matrix{Int}
    csf::Matrix{Int}
    cexcf::Matrix{Int}

    su0::Matrix{Int}
    sf0::Matrix{Int}

    ru::Array{Int,3}
    rf::Array{Int,3}

    b⁺::Array{Int,3}
    b⁻::Array{Int,3}

    z⁻::Array{Int,3}
    z⁺::Array{Int,3}

    su::Array{Int,3}
    sf::Array{Int,3}

    routes::Vector{Route}

    function InstanceArrays(instance::Instance)
        U, F, J, E = instance.U, instance.F, instance.J, instance.E
        L, γ, cstop, ccam = instance.L, instance.γ, instance.cstop, instance.ccam
        usines, fournisseurs = instance.usines, instance.fournisseurs
        d = instance.d

        l = Int[instance.emballages[e].l for e = 1:E]

        csu = [usines[u].cs[e] for e = 1:E, u = 1:U]
        csf = [fournisseurs[f].cs[e] for e = 1:E, f = 1:F]
        cexcf = [fournisseurs[f].cexc[e] for e = 1:E, f = 1:F]

        su0 = [usines[u].s0[e] for e = 1:E, u = 1:U]
        sf0 = [fournisseurs[f].s0[e] for e = 1:E, f = 1:F]

        ru = [usines[u].r[e, j] for e = 1:E, u = 1:U, j = 1:J]
        rf = [fournisseurs[f].r[e, j] for e = 1:E, f = 1:F, j = 1:J]

        b⁺ = [usines[u].b⁺[e, j] for e = 1:E, u = 1:U, j = 1:J]
        b⁻ = [fournisseurs[f].b⁻[e, j] for e = 1:E, f = 1:F, j = 1:J]

        z⁻ = [usines[u].z⁻[e, j] for e = 1:E, u = 1:U, j = 1:J]
        z⁺ = [fournisseurs[f].z⁺[e, j] for e = 1:E, f = 1:F, j = 1:J]

        su = [usines[u].s[e, j] for e = 1:E, u = 1:U, j = 1:J]
        sf = [fournisseurs[f].s[e, j] for e = 1:E, f = 1:F, j = 1:J]

        routes = instance.routes

        return new(
            J,
            U,
            F,
            E,
            L,
            γ,
            ccam,
            cstop,
            d,
            l,
            csu,
            csf,
            cexcf,
            su0,
            sf0,
            ru,
            rf,
            b⁺,
            b⁻,
            z⁻,
            z⁺,
            su,
            sf,
            routes
        )
    end
end

## Affichage

function Base.show(io::IO, instance::Instance)
    str = "\nInstance"
    str *= "\n   Nombre de jours: $(instance.J)"
    str *= "\n   Nombre d'usines: $(instance.U)"
    str *= "\n   Nombre de fournisseurs: $(instance.F)"
    str *= "\n   Nombre de types d'emballages: $(instance.E)"
    str *= "\n   Nombre de routes: $(length(instance.routes))"
    print(io, str)
end

## Lecture

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
    d = lire_d(data[1+dims.E+dims.U+dims.F+1:end], dims)

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
        d = d,
    )
end

## Copie

function Base.copy(instance::Instance)
    return Instance(
        J = instance.J,
        U = instance.U,
        F = instance.F,
        E = instance.E,
        L = instance.L,
        γ = instance.γ,
        ccam = instance.ccam,
        cstop = instance.cstop,
        emballages = [copy(emballage) for emballage in instance.emballages],
        usines = [copy(usine) for usine in instance.usines],
        fournisseurs = [copy(fournisseur) for fournisseur in instance.fournisseurs],
        d = copy(instance.d),
    )
end
