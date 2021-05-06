import JSON

nom_instance= "PMP"

instance = JSON.parsefile("C:\\Users\\Wael\\Desktop\\instances\\$nom_instance.json")

groupes = instance["trains"]


ids = []

push!(ids,1)

for i =1:length(groupes)
    groupe = groupes[i]
    for j=1:length(groupe)
        train = groupe[j]
        id = Int(train["id"])
        push!(ids,id)
    end
end

nb_trains = maximum(ids)+1

solution = Dict(string(i) => Dict("voieAQuai" => "notAffected", "itineraire" => "notAffected") for i=1:nb_trains)


json_string = JSON.json(solution)



open("shakiro\\solutions\\$(nom_instance)_nulle.json","w") do f
  print(f, json_string)
end
