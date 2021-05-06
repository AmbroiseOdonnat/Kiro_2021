import JSON

nom_instance= "PMP"

groupes, itineraires, voies_quai, voies_ligne, interdictions, contraintes = lire_instance("C:\\Users\\Wael\\Desktop\\instances\\$nom_instance.json")


nb_trains = nombre_trains()

quais = Vector{Any}(undef, nb_trains)
lignes = Vector{Any}(undef, nb_trains)
for i=1:nb_trains
    sensdep,l,q,type_circul,date_heure,materiel = caracteristique_train(i-1)
    quais[i]=q
    lignes[i]=l
end
