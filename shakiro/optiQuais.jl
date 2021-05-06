import JSON
using Dates
nom_instance= "PMP"

groupes, itineraires, voies_quai, voies_ligne, interdictions, contraintes = lire_instance("C:\\Users\\Wael\\Desktop\\instances\\$nom_instance.json")


nb_trains = nombre_trains()

quais = Vector{Any}(undef, nb_trains)
lignes = Vector{Any}(undef, nb_trains)
sens = Vector{Any}(undef, nb_trains)
itins = Vector{Any}(undef, nb_trains)


function itineraire_possible(voie_ligne,voie_quai,sens)  #renvoie true s'il existe un itineraire entre le quai i et le quai j
    it_possible = []
    n = length(itineraires)
    for id in 1:n
        sensdep,l,q = caracteristique_itineraire(id-1)
        if sens==sensdep && l==voie_ligne && q==voie_quai
            push!(it_possible,id)
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
        itins[i] = list_itin[1]
    else
        itins[i] = -1
    end
end
