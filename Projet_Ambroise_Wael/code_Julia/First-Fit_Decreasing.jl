#On implémente le first fit


# Fonction qui prend en entrée une liste de poids a1,..., a_n et une taille
# maximale W et qui fait le first fit


function first_fit_decreasing(a::Vector{Emballage}, W::Int)
    n = length(a)
    f=Vector{Int}(undef,n)
    Box = zeros(n)
    if a[1].l <= W
        f[1] = 1
        Box[f[1]] += a[1].l
    end
    for i in 2:n
        global j = 1
        while Box[j] + a[i].l > W
            j+=1
        end
        f[i] = j
        Box[f[i]]+= a[i].l
    end
    return sort!(f,rev=true)
end

a = Vector{Emballage}(undef,3)
a[1],a[2],a[3] = Emballage(;e=3,l=3),Emballage(;e=2,l=2),Emballage(;e=1,l=1)
W = 3
first_fit_decreasing(a,W)
