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
function processTree(writer::PotreeWriter, comaptree::ComaptreeWriter)

	function elaborateNode(writer::PotreeWriter)
		function elaborateNode0(node::CWNode)
			ref_name = name(node)
			node_potree = findNode(writer.root, ref_name)
			file_node = joinpath(writer.workDir, "data", path(node_potree,writer))

			if isLeafNode(node)
				println("leaf node: $ref_name")

				identification(node,file_node)
			else
				println("internal node: $ref_name")
				unification(node,file_node)
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
function identification(node::CWNode,file_node::String)
	println("== identification ==")
	PC = FileManager.source2pc(file_node)
	node.hyperplanes = get_planes(PC)
	println("$(length(node.hyperplanes)) planes found")
end


"""
	unification(node::CWNode)

Unification.
"""
function unification(node::CWNode, file_node::String)
	println("== unification ==")
	PC = FileManager.source2pc(file_node)
	for child in node.children
		if !isnothing(child)
			for hyperplane in child.hyperplanes

			end
		end
	end

	clustering_planes()
end

# tutti i piani trovati nei figli e nel nodo seguente
function clustering_planes(planes::Vector{Detection.Hyperplane})
	cluster = Detection.Hyperplane[]
	for plane in planes
		normal = plane.direction
		found = false
		for i in 1:length(cluster)
			@show Common.abs(Common.dot(cluster[i].direction,normal))
			if Common.abs(Common.dot(cluster[i].direction,normal)) > 0.8

				# è parallelo
				@show Common.norm(Common.dot(cluster[i].direction,cluster[i].centroid)-Common.dot(cluster[i].direction,plane.centroid))
				if Common.norm(Common.dot(cluster[i].direction,cluster[i].centroid)-Common.dot(cluster[i].direction,plane.centroid)) < 0.2
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
