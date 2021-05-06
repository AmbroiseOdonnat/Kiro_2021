function lire_instance(path::String)
    dict = JSON.parsefile(path)

    groupes = dict["trains"]
    itineraires = dict["itineraires"]
    voies_quai = dict["voiesAQuai"]
    voies_ligne = dict["voiesEnLigne"]
    interdictions = dict["interdictionsQuais"]
    contraintes = dict["contraintes"]

    return groupes, itineraires, voies_quai, voies_ligne, interdictions, contraintes
end


groupes, itineraires, voies_quai, voies_ligne, interdictions, contraintes = lire_instance("C:\\Users\\Emma\\Desktop\\instances\\A.json")

function nb_trains()
    nb = 0
    for groupe in groupes
        nb += length(groupe)
    end
    return nb
end

function nb_itineraire()
    return length(itineraires)
end

nb_itineraire()

function caracteristique_train(id)
    for groupe in groupes
        for train in groupe
            if id == train["id"]
                sensdep = train["sensDepart"]
                l = train["voieEnLigne"]
                q = train["voieAQuai"]
                type_circul = train["typeCirculation"]
                date_heure = train["dateHeure"]
                materiel = train["typesMateriels"]
                return sensdep,l,q,type_circul,date_heure,materiel
            end
        end
    end
end


caracteristique_train(15)

function caracteristique_itineraire(id)
    for itineraire in itineraires
        if id == itineraire["id"]
            sensdep = itineraire["sensDepart"]
            l = itineraire["voieEnLigne"]
            q = itineraire["voieAQuai"]
            return sensdep,l,q
            exit
        end
    end
    println("itinéraire non existant")
end

caracteristique_itineraire(300000)
