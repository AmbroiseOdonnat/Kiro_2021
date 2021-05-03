include("import_all.jl")

europe = lire_instance("instance/europe.csv")

solution_binpack = lire_solution(europe, "solution/bons_flows_350.txt")

binpack = open("solution/bons_flows_350.txt") do file
    readlines(file)
end

routes_binpack = [lire_route(binpack[r+1]) for r in 1:length(binpack)-1 ]

solution_binpack.routes = routes_binpack
solution_binpack.R= length(routes_binpack)
update_stocks!(solution_binpack, routes_binpack)

feasibility(solution_binpack)

cost(solution_binpack)
cost_verbose(solution_binpack)


plot_sites(solution_binpack)

plot_routes(solution_binpack, j=15)

plot_folium(solution_binpack)


data_routes_4 = open("solution/solution_europe_best_route_4.txt") do file
    readlines(file)
end


routes_4 = [lire_route(data_routes_4[r+1]) for r in 1:length(data_routes_4)-1]

solution_routes4 = lire_instance("instance/europe.csv")


solution_routes4.routes = routes_4
solution_routes4.R = length(routes_4)

update_stocks!(solution_routes4, routes_4)


feasibility(solution_routes4)
cost(solution_routes4)

cost_verbose(solution_routes4)

r=1
for route in routes_4
    route.r =r
    r+=1
end

solution_routes4.routes = routes_4

write_solution_to_file(solution_routes4, "solution/routes_de_4_best.txt")


for route in routes_4
        println("Route $(route.r) passe par $(route.F) fournisseurs et utilise $(route.x) camions ")
end
