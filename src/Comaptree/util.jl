function get_planes(points,rgb)
    INPUT_PC = Common.PointCloud(points,rgb)
    par = 0.04
    failed = 10
    N = 10
    k = 10
    threshold = Detection.Features.estimate_threshold(INPUT_PC,2*k)
    INPUT_PC.normals = Detection.Features.compute_normals(INPUT_PC.coordinates,threshold,k)
    params = Detection.Initializer(INPUT_PC, par, threshold, failed, N, k, Int64[])
    hyperplanes = Detection.iterate_detection(params; debug = true)
    return hyperplanes
end


#
# """
#     merge_verts(points, radius = 0.01)
# Merge congruent points.
# """
# function merge_verts(points, radius = 0.01)
#     n_points = size(points,2)
#     label = collect(1:n_points)
#     kdtree = Detection.Search.KDTree(points)
#     visited = Int64[]
#     for vi in 1:n_points
#         if !(label[vi] in visited)
#             nearvs = Detection.Search.inrange(kdtree, points[:,vi], radius)
#             label[nearvs] .= vi
#             push!(visited,vi)
#         end
#     end
#     new_verts = []
#     visited = Int64[]
#     for i in 1:n_points
#         ind = label[i]
#         if !(ind in visited)
#             element = findall(x->x==ind, label)
#             cent = Common.centroid(points[:,element])
#             push!(new_verts,cent)
#             push!(visited,ind)
#         end
#     end
#     return hcat(new_verts...)
# end
