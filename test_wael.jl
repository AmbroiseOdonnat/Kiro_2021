import JSON

test = JSON.parsefile("C:\\Users\\Wael\\Desktop\\instances\\A.json")

groupes = test["trains"]

nb_groupes = length(groupes)

groupe1 = groupes[1]

for i =1:nb_groupes
    groupe = groupes[i]
    for j in 1:length(groupe)
        train = groupe[j]
        id = train["id"]
        println(id)
    end
end
