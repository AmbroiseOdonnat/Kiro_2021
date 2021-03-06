import JSON
using Dates
<<<<<<< HEAD
name= "A"
=======
nom_instance= "A"
>>>>>>> 242c13dea161acfd245ef73609a9de0f243ef2b4

groupes, itineraires, voies_quai, voies_ligne, interdictions, contraintes = lire_instance("/Users/ambroise/instances/$name.json")

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

quais = Vector{Any}(undef, nb_trains)
lignes = Vector{Any}(undef, nb_trains)
sens = Vector{Any}(undef, nb_trains)
itins = Vector{Any}(undef, nb_trains)


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


for i=1:nb_trains
    sensdep,l,q,type_circul,date_heure,materiel = caracteristique_train(i-1)
    quais[i] = q
    lignes[i] = l
    sens[i] = sensdep

    list_itin = itineraire_possible(l,q,sensdep)



    if length(list_itin)>=1
        itins[i] = list_itin[1]-1
    else
        itins[i] = "notAffected"
        quais[i] = "notAffected"
    end
end

<<<<<<< HEAD
include("chevauchement_Ambroise.jl")
=======

solution = Dict(string(i-1) => Dict("voieAQuai" => quais[i], "itineraire" => itins[i]) for i=1:nb_trains)


json_string = JSON.json(solution)



open("shakiro\\solutions\\$(nom_instance)_zero.json","w") do f
  print(f, json_string)
end
>>>>>>> 242c13dea161acfd245ef73609a9de0f243ef2b4
