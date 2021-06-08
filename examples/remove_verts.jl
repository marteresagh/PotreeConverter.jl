function merge_verts(points, radius = 0.01)
    n_points = size(points,2)
    label = collect(1:n_points)
    kdtree = Detection.Search.KDTree(points)
    visited = Int64[]
    for vi in 1:n_points
        if !(label[vi] in visited)
            nearvs = Detection.Search.inrange(kdtree, points[:,vi], radius)
            label[nearvs] .= vi
            push!(visited,vi)
        end
    end
    new_verts = []
    visited = Int64[]
    for i in 1:n_points
        ind = label[i]
        if !(ind in visited)
            element = findall(x->x==ind, label)
            cent = Common.centroid(points[:,element])
            push!(new_verts,cent)
            push!(visited,ind)
        end
    end
    return hcat(new_verts...)
end

points = rand(1,10)

new = merge_verts(points, 0.1)
