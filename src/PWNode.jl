function PWNode()
	return nothing
end

function PWNode(potreeWriter::PotreeWriter,aabb::pAABB)
	index = -1
	acceptedAABB = pAABB()
	level = 0
	numAccepted = 0
	spacing = get_spacing(potreeWriter.spacing,level)
	parent = nothing
	children = Union{Nothing,PWNode}[]
	addedSinceLastFlush = true
	addCalledSinceLastFlush = false
	cache = Float64[]
	store = Float64[]
	isInMemory = true
	grid = SparseGrid(aabb,spacing)
	return PWNode( index,
				aabb,
				acceptedAABB,
				level,
				spacing,
				grid,
				numAccepted,
				parent,
				children,
				addedSinceLastFlush,
				addCalledSinceLastFlush,
				cache,
				store,
				isInMemory)
end

function PWNode(potreeWriter::PotreeWriter, index::Int, aabb::pAABB, level::Int)
	acceptedAABB = pAABB()
	numAccepted = 0
	spacing = get_spacing(potreeWriter.spacing,level)
	parent = nothing
	children = Union{Nothing,PWNode}[]
	addedSinceLastFlush = true
	addCalledSinceLastFlush = false
	cache = Float64[]
	store = Float64[]
	isInMemory = true
	grid = SparseGrid(aabb,spacing)
	return PWNode( index,
				aabb,
				acceptedAABB,
				level,
				spacing,
				grid,
				numAccepted,
				parent,
				children,
				addedSinceLastFlush,
				addCalledSinceLastFlush,
				cache,
				store,
				isInMemory)
end

function name(node::PWNode)::String
	if isnothing(node.parent)
		return "r"
	else
		return name(node.parent)*string(node.index)
	end
end

function hierarchyPath(node::PWNode,potreeWriter::PotreeWriter)::String
	path = "r/"
	hierarchyStepSize = potreeWriter.hierarchyStepSize
	indices = name(node)[2:end]

	numParts = Int(floor(length(indices) / hierarchyStepSize))
	for i = 0:numParts-1
		path *= indices[i * hierarchyStepSize+1: hierarchyStepSize] * "/"
	end

	return path
end

function path(node::PWNode,potreeWriter::PotreeWriter)::String
	path = hierarchyPath(node,potreeWriter)*name(node)*".las"
	return path
end

function isLeafNode(node::PWNode)::Bool
	return isempty(node.children)
end

function isInnerNode(node::PWNode)::Bool
	return length(node.children) > 0
end


function loadFromDisk(node::PWNode, potreeWriter::PotreeWriter)
	file_node = joinpath(potreeWriter.workDir, "data", path(node,potreeWriter))
	open(file_node) do s
		FileManager.LasIO.skiplasf(s)
		header = FileManager.LasIO.read(s, FileManager.LasIO.LasHeader)
		n = header.records_count
		pointtype = FileManager.LasIO.pointformat(header)
		pointdata = Vector{pointtype}(undef, n)

		for i = 1:n
			pointdata[i] = FileManager.LasIO.read(s, pointtype)
			p = Point(pointdata[i], header)
			if isLeafNode(node)
				push!(node.store,p)
			else
				addWithoutCheck(node.grid, p.position, potreeWriter)
			end
		end
	end
	node.grid.numAccepted = node.numAccepted
	node.isInMemory = true;
end


function add(node::PWNode, point::Point, potreeWriter::PotreeWriter)::Union{Nothing,PWNode}
	node.addCalledSinceLastFlush = true;
	if !node.isInMemory
		loadFromDisk(node,potreeWriter)
	end

	if isLeafNode(node)
		push!(node.store,point)
		if length(node.store) >= potreeWriter.storeSize
			split(node,potreeWriter)
		end
		return node
	else
		accepted = false
		accepted = add(node.grid, point.position)
		if accepted
			push!(node.cache, point)
			update!(node.acceptedAABB, point.position)
			node.numAccepted+=1

			return node
		else
			if potreeWriter.maxDepth != -1 && node.level >= potreeWriter.maxDepth
				return nothing
			end

			childIndex = nodeIndex(node.aabb, point.position)
			if childIndex >= 0
				if isLeafNode(node)
					node.children = Vector{Union{Nothing,PWNode}}(nothing,8)
				end
				if isnothing(node.children[childIndex+1])
					child = createChild(node,childIndex,potreeWriter)
				else
					child = node.children[childIndex+1]
				end

				return add(child,point,potreeWriter)
			 else
				return nothing
			end
		end
	end
end

function createChild(node::PWNode, childIndex::Int, potreeWriter::PotreeWriter)::PWNode
	cAABB = childAABB(node.aabb, childIndex)
	child = PWNode(potreeWriter, childIndex, cAABB, node.level+1)
	child.parent = node
	node.children[childIndex+1] = child

	return child
end

function split(node::PWNode, potreeWriter::PotreeWriter)
	node.children = Vector{Union{Nothing,PWNode}}(nothing,8)
	filepath = joinpath(potreeWriter.workDir, "data", path(node,potreeWriter))

	if isfile(filepath)
		rm(filepath)
	end

	for point in node.store
		add(node, point, potreeWriter)
	end

	node.store = Point[];
end


function flush(node::PWNode, potreeWriter::PotreeWriter)

	function writeToDisk(points::Vector{Point}, append::Bool)
		filepath = joinpath(potreeWriter.workDir,"data", path(node,potreeWriter))

		dir = joinpath(potreeWriter.workDir, "data", hierarchyPath(node,potreeWriter))
		FileManager.mkdir_if(dir)

		mainHeader = nothing

		if append
			temppath = joinpath(potreeWriter.workDir,"temp","prepend.las")
			if isfile(filepath)
				mv(filepath, temppath)
			end

			io = open(filepath,"w")
			mainHeader = newHeader(node.aabb; npoints = node.numAccepted, scale=potreeWriter.scale)
			write(io, FileManager.LasIO.magic(FileManager.LasIO.format"LAS"))
			write(io,mainHeader)

			if isfile(temppath)
				#appena apro devo salvare l'header
				open(temppath) do s
					io = open(filepath,"w")
					mainHeader = newHeader(node.aabb; npoints = node.numAccepted, scale=potreeWriter.scale)
					write(io, FileManager.LasIO.magic(FileManager.LasIO.format"LAS"))
					write(io,mainHeader)
					FileManager.LasIO.skiplasf(s)
					header = FileManager.LasIO.read(s, FileManager.LasIO.LasHeader)
					n = header.records_count
					pointtype = FileManager.LasIO.pointformat(header)
					pointdata = Vector{pointtype}(undef, n)

					for i in 1:n
						pointdata[i] = FileManager.LasIO.read(s, pointtype)
						write(io,pointdata[i])
					end

				end
				rm(temppath)
			end
		else
			if isfile(filepath)
				rm(filepath)
			end
			io = open(filepath,"w")
			mainHeader = newHeader(node.aabb; npoints = length(points), scale=potreeWriter.scale)
			write(io, FileManager.LasIO.magic(FileManager.LasIO.format"LAS"))
			write(io,mainHeader)
		end

		# punti da appendere o da salvare
		for e_c in points
			p = newPointRecord(e_c.position,
								reinterpret.(FileManager.LasIO.N0f16,e_c.color),
								FileManager.LasIO.LasPoint2,
								mainHeader;
								raw_classification = e_c.classification,
								intensity = e_c.intensity,
								pt_src_id = e_c.pointSourceID,
								gps_time = e_c.gpsTime)
			write(io,p)
		end

		close(io)
		# @assert !append && writer.numPoints == node.numAccepted "writeToDisk $(writer.numPoints) != $(node.numAccepted)"
	end


	if isLeafNode(node)
		if node.addCalledSinceLastFlush
			# println("n_points: $(length(node.store)), points in node: $(reinterpret(Int,node.numAccepted)), name: $(path(node,potreeWriter))")
			writeToDisk(node.store, false)

		elseif !node.addCalledSinceLastFlush && node.isInMemory
			node.store = Point[]
			node.isInMemory = false;
		end
	else
		if node.addCalledSinceLastFlush
			# println("n_points: $(length(node.cache)), points in node: $(reinterpret(Int,node.numAccepted)), name: $(path(node,potreeWriter))")
			writeToDisk(node.cache, true)

			node.cache = Point[]
		elseif !node.addCalledSinceLastFlush && node.isInMemory
			node.grid = SparseGrid(node.aabb, node.spacing);
			node.isInMemory = false
		end
	end

	node.addCalledSinceLastFlush = false

	if !isempty(node.children)
		for i in 1:8
			if !isnothing(node.children[i])
				child = node.children[i]
				flush(child, potreeWriter)
			end
		end
	end

end

# void traverse(std::function<void(PWNode*)> callback);
function traverse(this_node::PWNode, callback::Function)
	callback(this_node)
	for child in this_node.children
		if !isnothing(child)
			traverse(child, callback)
		end
	end
end

# vector<PWNode*> getHierarchy(int levels);
function getHierarchy(this_node::PWNode,levels::Int)::Vector{PWNode}

	hierarchy = PWNode[]

	stack = PWNode[]
	push!(stack,this_node)
	while !isempty(stack)
		node = popfirst!(stack)

		if node.level >= this_node.level + levels
			break
		end

		push!(hierarchy,node)

		for child in node.children
			if !isnothing(child)
				push!(stack,child)
			end
		end
	end

	return hierarchy
end


function findNode(node::PWNode, ref_name::String)
	thisName = name(node)

	if length(ref_name) == length(thisName)
		return ref_name == thisName ? node : nothing
	elseif length(ref_name) > length(thisName)
		childIndex = parse(Int,ref_name[length(thisName)+1])
		if !isLeafNode(node) && !isnothing(node.children[childIndex+1])
			return findNode(node.children[childIndex],ref_name);
		else
			return nothing
		end
	else
		return nothing
	end
end
