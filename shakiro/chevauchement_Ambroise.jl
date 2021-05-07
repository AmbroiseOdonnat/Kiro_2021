name = "NS"
groupes, itineraires, voies_quai, voies_ligne, interdictions, contraintes = lire_instance("/Users/ambroise/instances/$name.json")
L = length(voies_ligne)
Q = length(voies_quai)

##
function potential_itineraire(voies_ligne,voies_quai,sensdep) #T quais avec T nb de trains
    L = length(voies_ligne)
    Q = length(voies_quai)
    A = []
    for l in 1:L
        for q in 1:Q
            push!(A,itineraire_possible(voies_ligne[l],voies_quai[q],sensdep))
        end
    end
    return A
end

A = potential_itineraire(voies_ligne,voies_quai,true)

acc = []
for a in A
    push!(acc,length(a))
end
print(sum(acc))


A[]
function chevauchement(quais,itins)
    for t in 1:693
        if quais[t] != "notAffected"
            sensdepart,l,q,type_circul,date_heure,materiel = caracteristique_train(t)
            it = itins[t]
            conflits = conflit_trains[t]
            for conflit in conflits
                if it == conflit[1]
                    train = conflit[2]
                    if itins[train] == conflit[3]
                        potential_itins = itineraire_possible(l,voies_quai[t],sensdepart)
                        if length(potential_itins) > 1
                            itins[t] = potential_itins[2]
                        end
                    end
                end
            end
        end
    end
    return itins
end


test = chevauchement(quais,itins)
##

conflit_trains = []
for t in 1:693
    conflit_train = []
    for c in contraintes
        if c[1] == t
            push!(conflit_train,[c[2],c[3],c[4]])
        end
    end
    push!(conflit_trains,unique!(conflit_train))
end


conflit_trains
##
