println("Voies lignes : ", voies_ligne)
println("Voies quai : ", voies_quai)


function itineraire_possible(voie_ligne,voie_quai,sens)  #renvoie true s'il existe un itineraire entre le quai i et le quai j
    it_possible = []
    n = nb_itineraire()
    for id in 1:n
        sensdep,l,q = caracteristique_itineraire(id-1)
        if sens==sensdep && l==voie_ligne && q==voie_quai
            push!(it_possible,id)
        end
    end
    return it_possible
end

l = itineraire_possible("D4","11",true)
print(l)
