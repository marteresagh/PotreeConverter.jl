"""
    potree2bim(potree::String)
"""
function potree2bim(potree::String; LOD::Int64=-1)

    collection = get_nodes(potree; LOD = LOD)
    out = Array{Common.Struct,1}()

    for node in collection
		println("=== node: $node ===")
        V,FVs = node2bim(node)
        push!(out, Common.Struct([(V,FVs)])) # triangles cells
    end

    out = Common.Struct( out )
	V, FVs = Common.struct2lar(out)
	return V,FVs

end

"""
    get_nodes(potree::String; LOD::Int64=-1)
"""
function get_nodes(potree::String; LOD::Int64=-1)

    writer = PotreeWriter(potree, PotreeConverter.DEFAULT)
    cloudjs = PotreeConverter.loadStateFromDisk(writer)

    collection = String[]
    dataDir = joinpath(potree,"data")

    if LOD == -1

        function leafnode(collection::Vector{String})
            function callback0(node::PWNode)
                if isLeafNode(node)
                    push!(collection, joinpath(dataDir,path(node.parent,writer))) #node.parent
                end
            end
            return callback0
        end

        traverse(writer.root, leafnode(collection))
        return unique(collection)
    else

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
    node2bim(node::String)
"""
function node2bim(node::String)
    hyperplanes = plane_identification(node)

		try
    if !isempty(hyperplanes)

		# intersezione piani-octree
		W, FW, EW = myget_intersection(node, hyperplanes)

		# arrangement
        V, copEV, copFE, copCF = arrangement(W, FW, EW)
        println("FINE ARRANGEMENT")

		# costruzione modello
        V = permutedims(V)
        model = pols2tria(V, copEV, copFE, copCF)

		# pulitura del modello
		V, FVs = get_cells(model, hyperplanes)

		return V,FVs
    end
	catch y
	end

end


"""
	plane_identification(node::CWNode,node_potree::PWNode)

Get cluster of coplanar planes.
"""
function plane_identification(node::String)

    pc = FileManager.las2pointcloud(node)
    points = pc.coordinates
    rgb = pc.rgbs

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


function myget_intersection(node, hyperplanes)
	aabb = FileManager.las2aabb(node)
	planes = [Plane(hyperplane.direction,hyperplane.centroid) for hyperplane in hyperplanes]
	# intersezione piani-octree
	W,EW,FW = draw_planes(planes, aabb)
	return W,FW,EW
end


"""
	get_intersection(node, hyperplanes)
"""
function get_intersection(node, hyperplanes)
	n_planes = length(hyperplanes)

	aabb_octree = FileManager.las2aabb(node)
	V, EV, FV = Common.getmodel(aabb_octree)

	box = [Common.Struct([(V, FV, EV)])]

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

	return W, FW, EW
end

"""
	arrangement(W, FW, EW)
"""
function arrangement(W, FW, EW)
	cop_EV = coboundary_0(EW)
	cop_FE = coboundary_1(W, FW, EW)
	W = permutedims(W)

	V, copEV, copFE, copCF = space_arrangement(W, cop_EV, cop_FE);
end

"""
	get_cells(model, hyperplanes)
"""
function get_cells(model, hyperplanes)
	V, CVs, FVs, EVs = model
	tokeep = Vector{Vector{Vector{Int64}}}()

	for k = 1:length(hyperplanes)
		hyperplane = hyperplanes[k]
		inliers = hyperplane.inliers.coordinates
		kdtree = Detection.Search.KDTree(inliers)
		for fv in FVs
			index = union(fv...)
			points = V[:, index]
			centroid = Common.centroid(points)
			near = Detection.Search.inrange(kdtree, centroid, 0.05)
			if !isempty(near)
				push!(tokeep, fv)
			end
		end
	end

	return V, tokeep
end
