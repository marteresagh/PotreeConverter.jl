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
				# @assert isInnerNode(node_potree) == isInnerNode(node) "comaptree not isomorphic to potree"
				# println("internal node: $ref_name")
				# unification(node)
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
	hyperplanes = get_planes(PC)
	println("$(length(hyperplanes)) planes found")
	# for hyperplane in hyperplanes
	# 	dir = Common.approxVal(4).(hyperplane.direction)
	# 	if haskey(node.dict,dir)
	# 		push!(node.dict[dir], Common.approxVal(4).(hyperplane.centroid))
	# 	else
	# 		node.dict[dir] = [Common.approxVal(4).(hyperplane.centroid)]
	# 	end
	# end

end


"""
	unification(node::CWNode)

Unification.
"""
# function unification(node::CWNode, node_potree::PWNode)
# 	println("== unification ==")
# 	planes = Vector{Float64}[]
# 	key_norm = nothing
# 	temp = Dict()
# 	for child in node.children
# 		if !isnothing(child)
# 			for (k,v) in child.dict
# 				if isnothing(key_norm)
# 					key_norm = k # solo la prima volta
# 				end
#
# 				if Common.dot(key_norm,k) < 0
# 					# @show "qui"
# 					# for cen in v
# 					# 	push!(planes,[-k..., Common.dot(-k,cen)])
# 					# end
#
# 				else
# 					# @show "qua"
# 					# for cen in v
# 					# 	push!(planes,[k..., Common.dot(k,cen)])
# 					# end
# 				end
# 			end
# 		end
# 	end
#
# 	@show length(planes)
# 	covectors = hcat(planes...)
# 	@show size(covectors)
# 	tree = KDTree(covectors)
#
# 	labels = inrange(tree,covectors,0.01)
# 	clustering = unique(labels)
#
#
# 	for cluster in clustering
# 		plane = Common.centroid(covectors[:,cluster])
# 		inliers = Vector{Float64}[]
# 		for point in node_potree.store
# 			if Common.distance_point2plane(plane[1:3]*plane[4],plane[1:3])(point.position) < 0.02
# 				push!(inliers,point.position)
# 			end
# 		end
# 		if length(inliers)>=3
# 			plane = Plane(hcat(inliers)...)
# 			flag = false
# 			for (k,v) in node.dict
# 				if Common.angle_between_directions(plane.normal,k)<pi/3
# 					push!(node.dict[k],plane.centroid)
# 					flag = true
# 					break
# 				end
# 			end
# 			if !flag
# 				node.dict[plane.normal] = [plane.centroid]
# 			end
#
# 		end
# 	end
#
# end
#
#
function unification(node::CWNode)
	println("== unification ==")
	for child in node.children
		if !isnothing(child)
			for (k,v) in child.dict
				flag = false
				for (k0,v0) in node.dict
					if Common.abs(Common.dot(k0,k)) > 0.8
						union!(node.dict[k0],v)
						flag = true
						break
					end
				end
				if !flag
					node.dict[k] = v
				end
			end
		end
	end
	# prima di lasciare il nodo unifico i centroidi

	for (k,v) in node.dict
		res = reshape([Common.dot(k,cen) for cen in v],1,length(v))
		label = merge_verts(res,0.01)
		new_verts = []
	    visited = Int64[]
	    for i in 1:length(v)
	        ind = label[i]
	        if !(ind in visited)
	            element = findall(x->x==ind, label)
	            cent = Common.centroid(hcat(v[element]...))
	            push!(new_verts,cent)
	            push!(visited,ind)
	        end
	    end
	  	node.dict[k] = new_verts
	end
end
"""
	resolution(node::CWNode)

Resolustion.
"""
function resolution(node::CWNode)
	println("== resolution ==")
end
