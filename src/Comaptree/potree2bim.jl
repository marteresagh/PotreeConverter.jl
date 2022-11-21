"""
	potree2comaptree(potreeDir::String)

Given a potree, construct an empty isomorphic tree.
"""
function potree2comaptree(potreeDir::String)

	# tree
	rootDir = joinpath(potreeDir,"data","r")
	hrcPaths = FileManager.searchfile(rootDir,".hrc")

	sort!(hrcPaths, by=length)

	root = CWNode()
	for hrcPath in hrcPaths
		filename = splitdir(hrcPath)[2]
		hrcName = String(Base.split(filename, ".")[1])
		hrcRoot = findNode(root,hrcName)

		current = hrcRoot
		nodes = CWNode[]
		push!(nodes,hrcRoot)

		raw = Base.read(hrcPath)
		treehrc = reshape(raw, (5, div(length(raw), 5)))

		for i in 1:size(treehrc,2)
			children = Int(treehrc[1,i])
			numPoints = parse(Int, bitstring(UInt8(treehrc[5,i]))*bitstring(UInt8(treehrc[4,i]))*bitstring(UInt8(treehrc[3,i]))*bitstring(UInt8(treehrc[2,i])); base=2)
			current = nodes[i]

			if children != 0
				current.children = Vector{Union{Nothing,CWNode}}(nothing,8)
				for j in 0:7
					if children & (1 << j) != 0
						child = CWNode(j, current.level + 1)
						child.parent = current
						current.children[j+1] = child
						push!(nodes,child)
					end
				end
			end
		end
	end
	# end tree

	return ComaptreeWriter(root)
end


"""
	processTree(writer::PotreeWriter, comaptree::ComaptreeWriter)

Elaborate each comaptree node in postorder.
"""
function cut_tree!(comaptree::ComaptreeWriter, LOD::Int64)
	function callback(LOD::Int64)
	    function callback0(node::CWNode)
	        if node.level == LOD
	            empty!(node.children)
	        end
	    end
	    return callback0
	end

	PotreeConverter.traverse(comaptree.root, callback(LOD))
end



### function elabora ogni nodo in postorder
"""
	processTree(writer::PotreeWriter, comaptree::ComaptreeWriter)

Elaborate each comaptree node in postorder.
"""
function processTree(writer::PotreeWriter, comaptree::ComaptreeWriter; par_angle=pi/8, par_dist=0.02)

	function elaborateNode(writer::PotreeWriter)
		function elaborateNode0(node::CWNode)
			ref_name = name(node)
			node_potree = findNode(writer.root, ref_name)
			file_node = joinpath(writer.workDir, "data", path(node_potree,writer))

			if isLeafNode(node)
				println("leaf node: $ref_name")

				identification(node,file_node, 30, par_dist)
			else
				println("internal node: $ref_name")
				identification(node,file_node)
				unification(node,file_node, par_angle, par_dist)
				# resolution(node)
			end
			node_potree.store = Point[]
			node_potree.isInMemory = false
		end
		return elaborateNode0
	end

	postorder(comaptree.root, elaborateNode(writer))
end

"""
	identification(node::CWNode,node_potree::PWNode)

Get cluster of coplanar planes.
"""
function identification(node::CWNode,file_node::String,par_dist)
	println("== identification ==")
	PC = FileManager.source2pc(file_node)
	if PC.n_points>10
		node.hyperplanes = get_planes(PC, 30, par_dist)
		println("$(length(node.hyperplanes)) planes found")
	end
end


"""
	unification(node::CWNode)

Unification.
"""
function unification(node::CWNode, file_node::String, par_angle, par_dist)
	println("== unification ==")
	PC = FileManager.source2pc(file_node)
	planes = copy(node.hyperplanes)

	for child in node.children
		if !isnothing(child)
			union!(planes,child.hyperplanes)
		end
	end

	@show length(planes)
	cluster = clustering_planes(planes, par_angle, par_dist)
	@show length(cluster)


	node.hyperplanes = cluster
end

# cluster planes portandomi dietro i punti
function clustering_planes(planes::Vector{Detection.Hyperplane}, par_angle = 0.8, par_dist = 0.2 )
	cluster = Detection.Hyperplane[]
	for plane in planes
		normal = plane.direction
		found = false
		for i in 1:length(cluster)
			if Common.abs(Common.dot(cluster[i].direction,normal)) > par_angle
				# è parallelo
				if Common.norm(Common.dot(cluster[i].direction,cluster[i].centroid)-Common.dot(cluster[i].direction,plane.centroid)) < par_dist
					# è coincidente
					found = true
					inliers = PointCloud(hcat(cluster[i].inliers.coordinates,plane.inliers.coordinates),hcat(cluster[i].inliers.rgbs,plane.inliers.rgbs))
					direction, centroid = Common.LinearFit(inliers.coordinates)
					cluster[i] = Detection.Hyperplane(inliers,direction,centroid)
					break
				end
			end
		end
		if !found
			push!(cluster,plane)
		end

	end

	return cluster
end



"""
	resolution(node::CWNode)

Resolustion.
"""
function resolution(node::CWNode)
	println("== resolution ==")
end
