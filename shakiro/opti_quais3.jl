import JSON
using Dates
nom_instance= "PMP"

groupes, itineraires, voies_quai, voies_ligne, interdictions, contraintes = lire_instance("C:\\Users\\Wael\\Desktop\\instances\\$nom_instance.json")

old_solution = JSON.parsefile("shakiro\\solutions\\$(nom_instance)_un.json")

#J'ai besoin de savoir pour chaque train ses quais autorisés

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



nb_trains = number_trains()

quais_autorises_train = Array{Any}(undef, nb_trains)

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



for i=1:nb_trains
    quais_autorises_train[i] = []
    sensdep,l,q,type_circul,date_heure,materiel = caracteristique_train(i-1)

    for quai in voies_quai
        if !((type_circul in Circ_interdit_quai[quai]) || length(intersect(materiel, Mat_interdit_quai[quai]))>=1)
            append!(quais_autorises_train[i], quai)
        end
    end
end

voies_quai

for i=1:nb_trains
    quais_autorises_train[i] = unique(quais_autorises_train[i])
end

quais_autorises_train[3]

solution["2"]["itineraire"]
#Pour tous les non affectés, on leur affecte quelqu'un d'autre

quais = [old_solution[string(i-1)]["voieAQuai"] for i=1:nb_trains]
itins = [old_solution[string(i-1)]["itineraire"] for i=1:nb_trains]


for t=1:nb_trains
    if quais[t]== "notAffected"
        sensdep,l,q,type_circul,date_heure,materiel = caracteristique_train(t-1)
        allowed = quais_autorises_train[t]

        for quai in allowed
            list_itin = itineraire_possible(l, quai, sensdep)
            if length(list_itin)>=1
                itins[t] = list_itin[1]-1
                quais[t] = quai
                break
            else
                itins[t] = "notAffected"
                quais[t] = "notAffected"
            end
        end
    end
end



solution = Dict(string(i-1) => Dict("voieAQuai" => quais[i], "itineraire" => itins[i]) for i=1:nb_trains)


json_string = JSON.json(solution)



open("shakiro\\solutions\\$(nom_instance)_deux.json","w") do f
  print(f, json_string)
end
