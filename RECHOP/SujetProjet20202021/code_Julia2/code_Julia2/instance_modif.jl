using PolygonOps
import GADM

## Restriction géographique

function reduire(instance::Instance; countrycode::String = "FRA")::Instance
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

    d_country = instance.d[new_vertices, new_vertices]

    U_country = length(usines_country)
    F_country = length(fournisseurs_country)
    usines_country_renumbered =
        [renumber(usine, u = u, v = u) for (u, usine) in enumerate(usines_country)]
    fournisseurs_country_renumbered = [
        renumber(fournisseur, f = f, v = U_country + f)
        for (f, fournisseur) in enumerate(fournisseurs_country)
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
        d = d_country,
    )

    return instance_country
end
