include("import_all.jl")

function b_plus(u::Usine,j::Int64,e::Emballage)::Int64 #return le b_plus de u au jour j pour emballage e
    return u.b⁺[e.e,j]
end

function b_moins(f::Fournisseur,j::Int64,e::Emballage)::Int64 #return le b_moins de f au jour j pour emballage e
    return f.b⁻[e.e,j]
end

function r_u(u::Usine,j::Int64,e::Emballage)::Int64 #return le ru de u au jour j pour emballage e
    return u.ru[e.e,j]
end

function r_f(f::Fournisseur,j::Int64,e::Emballage)::Int64 #return le rf de f au jour j pour emballage e
    return f.rf[e.e,j]
end

function c_s_u(u::Usine,e::Emballage)::Int64 #return le csu de u pour emballage e
    return u.csu[e.e]
end

function c_s_f(f::Fournisseur,e::Emballage)::Int64 #return le csf de f pour emballage e
    return f.csf[e.e]
end

function cost_unique_arret(path::String,u::Usine,f::Fournisseur)::Float64
    instance = lire_instance(path)
    u_coor = u.coor
    f_coor = f.coor
    return instance.cstop + instance.ccam + instance.γ*sqrt((u_coor[1]-f_coor[1])^2+ (u_coor[2]-f_coor[2])^2 )
end
