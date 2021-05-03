function lire_arc(row::String)::NamedTuple
    row_split = split(row, r"\s+")
    v1 = parse(Int, row_split[2]) + 1
    v2 = parse(Int, row_split[3]) + 1
    d = parse(Int, row_split[5])
    return (v1 = v1, v2 = v2, d = d)
end

function lire_d(rows::Vector{String}, dims::NamedTuple)::Matrix{Int}
    d = zeros(Int, dims.U + dims.F, dims.U + dims.F)
    for row in rows
        a = lire_arc(row)
        d[a.v1, a.v2] = a.d
    end
    return d
end
