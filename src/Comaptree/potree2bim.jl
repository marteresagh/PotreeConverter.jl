"""
    potree2bim(potree::String)
"""
function potree2bim(potree::String; LOD::Int64=-1)
    collection = get_nodes(potree; LOD = LOD)
end

function get_nodes(potree::String; LOD::Int64=-1)

    writer = PotreeWriter(potree, PotreeConverter.DEFAULT)
    cloudjs = PotreeConverter.loadStateFromDisk(writer)

    collection = String[]
    dataDir = joinpath(potree,"data")

    if LOD == -1

        @show "sono qui"
        function leafnode(collection::Vector{String})
            function callback0(node::PWNode)
                if isLeafNode(node)
                    push!(collection, joinpath(dataDir,path(node.parent,writer)))
                end
            end
            return callback0
        end

        traverse(writer.root, leafnode(collection))
        return unique(collection)
    else

        @show "oppure qui"
        function levelnode(collection::Vector{String})
            function callback0(node::PWNode)
                if node.level == LOD
                    push!(collection, joinpath(dataDir,path(node,writer)))
                end
            end
            return callback0
        end

        traverse(writer.root, levelnode(collection))
        return collection
    end


end



"""
	identification(node::CWNode,node_potree::PWNode)

Get cluster of coplanar planes.
"""
function identification(node::CWNode, node_potree::PWNode)
    println("== identification ==")

    points_pos = map(s -> s.position, node_potree.store)
    points = hcat(points_pos...)

    points_rgb = map(s -> s.color, node_potree.store)
    rgb = hcat(points_rgb...)

    hyperplanes = nothing

    if size(points, 2) >= 3
        direction, centroid = Common.LinearFit(points)
        residuals =
            Common.distance_point2plane(
                centroid,
                direction,
            ).([c[:] for c in eachcol(points)])
        coplanar = max(residuals...) < 0.2
        if !coplanar
            hyperplanes = get_planes(points, rgb)
        else
            hyperplanes =
                [Detection.Hyperplane(PointCloud(points), direction, centroid)]
        end
    end

    println("HYPERPLANES = $(length(hyperplanes))")
    return hyperplanes

end


function nuova_procedura(node, node_potree)
    hyperplanes = identification(node, node_potree)
    n_planes = length(hyperplanes)

    if n_planes != 0
        aabb_octree = node_potree.aabb
        V, EV, FV = getmodel(aabb_octree)
        box = [Common.Struct([(V, FV, EV)])]

        cells = Vector{Vector{Vector{Int64}}}()
        for k = 1:n_planes
            hyperplane = hyperplanes[k]
            pl = Plane(hyperplane.direction, hyperplane.centroid)
            plane =
                hyperplane.centroid .+ hcat(
                    [0.0, 0.0, 0.0],
                    pl.basis[:, 1] * 0.01,
                    pl.basis[:, 2] * 0.01,
                )
            planes(box, plane, aabb_octree)
        end


        W, FW, EW = Common.struct2lar(Common.Struct(box))

        cop_EV = coboundary_0(EW)
        cop_FE = coboundary_1(W, FW, EW)
        W = permutedims(W)

        V, copEV, copFE, copCF = space_arrangement(W, cop_EV, cop_FE)
        println("FINE ARRANGEMENT")

        V = permutedims(V)
        V, CVs, FVs, EVs = pols2tria(V, copEV, copFE, copCF) # whole assembly
        # return V,CVs,FVs,EVs

        # per ogni 2-cella in FVs andare ad eliminare le celle che non fanno parte del modello
        # sfruttando gli inliers
        for k = 1:n_planes
            hyperplane = hyperplanes[k]
            inliers = hyperplane.inliers.coordinates
            kdtree = Detection.Search.KDTree(inliers)
            for fv in FVs
                index = union(fv...)
                points = V[:, index]
                centroid = Common.centroid(points)
                near = Detection.Search.inrange(kdtree, centroid, 0.05)
                if !isempty(near)
                    push!(cells, fv)
                end
            end
        end

        node.cells = Common.Struct([(V, cells)])
        return V, cells
    end

end
