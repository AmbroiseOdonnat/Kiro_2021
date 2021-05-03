#test de mutualisation sur france après le PLNE
include("/Users/ambroise/Projet/code_Julia/import_all.jl")
using LinearAlgebra
#test
zone = "france"
A_PLNE_sol_flows = open("/Users/ambroise/Projet/sujet/flows_$zone.txt") do file
    readlines(file)
end

A_PLNE_routes_flows = [lire_route(A_PLNE_sol_flows[1+r]) for r=1:length(A_PLNE_sol_flows)-1]

#ecriture solution
A_PLNE_instance_zone = lire_instance("/Users/ambroise/Projet/sujet/$zone.csv")
A_PLNE_test_instance_flow = lire_solution(A_PLNE_instance_zone,"/Users/ambroise/Projet/sujet/flows_$zone.txt")
A_PLNE_opti_routes_flows = optimiser_routes(A_PLNE_routes_flows,A_PLNE_instance_zone)
A_PLNE_test_instance_flow.routes = A_PLNE_opti_routes_flows
A_PLNE_test_instance_flow.R = length(A_PLNE_opti_routes_flows)
update_stocks!(A_PLNE_test_instance_flow,A_PLNE_opti_routes_flows)
#write_solution_to_file(test_instance_flow,"/Users/ambroise/Projet/sujet/solution_$usedroutes.txt")
#faisabilité
usines = A_PLNE_test_instance_flow.usines
usines[2].s
feasibility(A_PLNE_instance_zone)

#cout
cost_verbose(A_PLNE_test_instance_flow)
