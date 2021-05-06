import JSON
using Dates
nom_instance= "A"

groupes, itineraires, voies_quai, voies_ligne, interdictions, contraintes = lire_instance("C:\\Users\\Wael\\Desktop\\instances\\$nom_instance.json")

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


function number_trains()
    nb = 0
    for groupe in groupes
        nb += length(groupe)
    end
    return nb
end

nb_trains = number_trains()

Circ_interdit_quai = Dict(quai => [] for quai in voies_quai)
Mat_interdit_quai = Dict(quai => [] for quai in voies_quai)



for f = 1:length(interdictions)
    forbid = interdictions[f]
    my_quais = forbid["voiesAQuaiInterdites"]
    for quai in my_quais
        append!(Circ_interdit_quai[quai], forbid["typesCirculation"])
        append!(Mat_interdit_quai[quai], forbid["typesMateriels"])
    end
end

function itineraire_possible(voie_ligne,voie_quai,sens)  #renvoie true s'il existe un itineraire entre le quai i et le quai j
    it_possible = []
    n = length(itineraires)
    for id in 1:n
        sensdep,l,q = caracteristique_itineraire(id-1)
        if sens==sensdep
            if l==voie_ligne && q==voie_quai
            push!(it_possible,id)
            end
        end
    end
    return it_possible
end
