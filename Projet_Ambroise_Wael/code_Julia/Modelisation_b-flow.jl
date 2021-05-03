#On se sert de la structure de graphe pour resoudre un problème de b-flow ( reformulation du PLNE pour la question 1 du sujet)

function graph_b_flow(usine::Usine,fournisseur::Fournisseur,emballage::Emballage,instance::Instance)::Data
    upper_bound = 10000
    emballages_par_camion = div(instance.L,emballage.l)
    vertex_nb = 1 + 1 + 2*(instance.J-1) + 3 + 4*(instance.J-1)
    graph_test = Graph(vertex_nb, [Int[] for _ in 1:vertex_nb], Dict())
    data_test = Data(graph_test,Dict(),Dict(),Vector{Int}(undef,vertex_nb))
    jour = 1
    for i in 2:(2*instance.J)
        if i%2==1
            jour += 1
            # usine stock
            data_test.b_flow[i] = 0
            # arc avec l'usine
            add_edge!(data_test.graph,i,i+1,0)
            data_test.lower_cap[(i,i+1)] = 0
            data_test.upper_cap[(i,i+1)] = upper_bound


        else
            # usine
            data_test.b_flow[i] = usine.b⁺[emballage.e,jour]
            if i==2
                data_test.b_flow[i] += usine.s0[emballage.e]
            end
            if i<2*instance.J
                # arc avec usine stock
                add_edge!(data_test.graph,i,i+1,usine.cs[emballage.e])
                data_test.lower_cap[(i,i+1)] = 0
                data_test.upper_cap[(i,i+1)] = upper_bound
                # arc avec le jour d'après
                add_edge!(data_test.graph,i,i+2,0)
                data_test.lower_cap[(i,i+2)] = 0
                data_test.upper_cap[(i,i+2)] = usine.r[emballage.e,jour]
                # arc avec le fournisseur
                add_edge!(data_test.graph,i, 2*(instance.J-1) + jour*4 + 3,div((instance.γ*instance.graphe.d[usine.v,fournisseur.v]+instance.ccam+instance.cstop),emballages_par_camion))
                data_test.lower_cap[(i, 2*(instance.J-1) + jour*4 + 3)] = 0
                data_test.upper_cap[(i, 2*(instance.J-1) + jour*4 + 3)] = upper_bound
            else
                # arc avec carton
                add_edge!(data_test.graph,i,1,0)
                data_test.lower_cap[(i,1)] = 0
                data_test.upper_cap[(i,1)] = upper_bound
            end
        end
    end
    jour = 1
    for i in (2*instance.J+1):vertex_nb
        if i%4==3
            # fournisseur
            data_test.b_flow[i] = 0
            if i==2*instance.J+1
                data_test.b_flow[i] += fournisseur.s0[emballage.e]
            end
            # arc avec fournisseur total
            add_edge!(data_test.graph,i,i+1,0)
            data_test.lower_cap[(i,i+1)] = 0
            data_test.upper_cap[(i,i+1)] = upper_bound
            if i<vertex_nb-2
                # arc avec fournisseur stock
                add_edge!(data_test.graph,i,i+3,fournisseur.cs[emballage.e])
                data_test.lower_cap[(i,i+3)] = 0
                data_test.upper_cap[(i,i+3)] = upper_bound
                # arc avec le jour d'après
                add_edge!(data_test.graph,i,i+4,0)
                data_test.lower_cap[(i,i+4)] = 0
                data_test.upper_cap[(i,i+4)] = fournisseur.r[emballage.e,jour]
            end
            if i==vertex_nb-2
                # arc avec carton
                add_edge!(data_test.graph,i,1,0)
                data_test.lower_cap[(i,1)] = 0
                data_test.upper_cap[(i,1)] = upper_bound
            end
        end
        if i%4==0
            # fournisseur total
            data_test.b_flow[i] = - fournisseur.b⁻[emballage.e,jour]
        end
        if i%4==1
            # fournisseur carton
            data_test.b_flow[i] = 0
            # arc avec fournisseur total
            add_edge!(data_test.graph,i,i-1,fournisseur.cexc[emballage.e])
            data_test.lower_cap[(i,i-1)] = 0
            data_test.upper_cap[(i,i-1)] = upper_bound
        end
        if i%4==2
            jour+=1
            # fournisseur stock
            data_test.b_flow[i] = 0
            # arc avec le jour d'après
            add_edge!(data_test.graph,i,i+1,0)
            data_test.lower_cap[(i,i+1)] = 0
            data_test.upper_cap[(i,i+1)] = upper_bound
        end
    end

    # carton
    sum_b = 0
    for jour in 1:instance.J
        sum_b += fournisseur.b⁻[emballage.e,jour] - usine.b⁺[emballage.e,jour]
    end
    sum_b -= fournisseur.s0[emballage.e]
    sum_b -= usine.s0[emballage.e]
    data_test.b_flow[1] = sum_b
    # arcs avec les fournisseurs carton
    for i in (2*instance.J+1):vertex_nb
        if i%4==1
            add_edge!(data_test.graph,1,i,0)
            data_test.lower_cap[(1,i)] = 0
            data_test.upper_cap[(1,i)] = upper_bound
        end
    end
    return data_test
end

zone = "europe"
current_instance = lire_instance("/Users/ambroise/Projet/sujet/$zone.csv")
u = current_instance.usines[2]
f = current_instance.fournisseurs[3]
e = current_instance.emballages[1]
data_test = graph_b_flow(u,f,e,current_instance)
G = data_test.graph
solution = Solution(data_test)
A = matrice_incidence(G)
b = data_test.b_flow
sum(A[1,j] for j in 1:length(edges(G)))
sum(solution[j] for j in 1:length(edges(G)))
sum( A[1,j]*solution[j] for j=1:length(edges(G)))
-b[1]
