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

			if isLeafNode(node_potree)
				@assert isLeafNode(node_potree) == isLeafNode(node) "comaptree not isomorphic to potree"
				println("leaf node: $ref_name")
				if !node_potree.isInMemory
					PotreeConverter.loadFromDisk(node_potree,writer)
				end

				identification(node,node_potree)

				node_potree.store = Point[]
				node_potree.isInMemory = false
			else
				@assert isInnerNode(node_potree) == isInnerNode(node) "comaptree not isomorphic to potree"
				println("internal node: $ref_name")
				unification(node)
			end

		end
		return elaborateNode0
	end

	postorder(comaptree.root, elaborateNode(writer))
end

"""
	identification(node::CWNode,node_potree::PWNode)

Get cluster of coplanar planes.
"""
function identification(node::CWNode,node_potree::PWNode)
	println("identification")
	# TODO DETECTION hyperplanes
	# points_pos = map(s->s.position,node_potree.store)
	# points = hcat(points_pos...)
	# direction = nothing
	# centroid = nothing
	# if size(points,2) > 10
	# 	direction, centroid = Common.LinearFit(points)
	# 	node.dict[direction] = [c[:] for c in eachcol(points)]
	# end
end

"""
	unification(node::CWNode)

Unification.
"""
function unification(node::CWNode)
	println("unification")
	# TODO merge covectors
	# for child in node.children
	# 	if !isnothing(child)
	# 		merge!(node.dict,child.dict)
	# 	end
	# end
end
