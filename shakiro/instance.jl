struct Instance

    trains::Vector{Trains}
    itineraires::Vector{Itineraires}
    voiesAQuai::Vector{VoiesAQuai}
    voiesEnLigne::Vector{VoiesEnLigne}
    interdictionsQuais::Vector{InterdictionsQuais}
    contraintes::Vector{contraintes}

    Instance(; trains, itineraires, voiesAQuai,voiesEnLigne,interdictionQuais,contraintes) =
        new(trains, itineraires, voiesAQuai,voiesEnLigne,interdictionQuais,contraintes)
end

function Base.show(io::IO, instance::Instance)
    str = "\nInstance"
    str *= "\n   Nombre de trains: $(instance.trains)"
    str *= "\n   Nombre d'itinéraires: $(instance.itineraires)"
    str *= "\n   Nombre de voies à quai: $(instance.voiesAQuai)"
    str *= "\n   Nombre de voies en ligne: $(instance.voiesEnLigne)"
    print(io, str)
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
