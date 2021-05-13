function PWNode()
	return nothing
end

function PWNode(potreeWriter::PotreeWriter,aabb::pAABB)
	index = -1
	acceptedAABB = pAABB([Inf,Inf,Inf],[-Inf,-Inf,-Inf])
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

function PWNode(potreeWriter::PotreeWriter,index::Int, aabb::pAABB, level::Int)
	acceptedAABB = pAABB([Inf,Inf,Inf],[-Inf,-Inf,-Inf])
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

function get_spacing(spacing::Float64,level::Int)::Float64
	return spacing/2^level
end

function hierarchyPath(potreeWriter::PotreeWriter,node::PWNode)::String
	path = "r/"
	hierarchyStepSize = potreeWriter.hierarchyStepSize
	indices = name(node)[2:end]

	numParts = Int(floor(length(indices) / hierarchyStepSize))
	for i = 0:numParts-1
		path *= indices[i * hierarchyStepSize+1: hierarchyStepSize] * "/"
	end

	return path
end

function path(potreeWriter::PotreeWriter,node::PWNode)
	path = hierarchyPath(potreeWriter,node)*name(node)*".las"
	return path
end

function isLeafNode(node::PWNode)::Bool
	return isempty(node.children)
end

function isInnerNode(node::PWNode)
	return length(node.children) > 0
end

# void loadFromDisk();
function loadFromDisk(node::PWNode, potreeWriter::PotreeWriter)
	file_node = joinpath(potreeWriter.workDir, "data", path(potreeWriter, node))
	open(file_node) do s
		FileManager.LasIO.skiplasf(s)
		header = FileManager.LasIO.read(s, FileManager.LasIO.LasHeader)
		n = header.records_count
		pointtype = FileManager.LasIO.pointformat(header)
		pointdata = Vector{pointtype}(undef, n)

		for i=1:n
			pointdata[i] = FileManager.LasIO.read(s, pointtype)
			p = FileManager.xyz(pointdata[i],header)
			pt = Point(p...)
			if isLeafNode(node)
				push!(node.store,p)
			else
				addWithoutCheck(node.grid, p, potreeWriter)
			end
		end
	end
	node.grid.numAccepted = node.numAccepted
	node.isInMemory = true;
end

# PWNode *add(Point &point);
function add(node::PWNode, point::Point, potreeWriter::PotreeWriter)
	node.addCalledSinceLastFlush = true;
	if !node.isInMemory
		loadFromDisk(node,potreeWriter)
	end

	if isLeafNode(node)
		push!(node.store,point)
		if length(node.store) >= potreeWriter.storeSize
			split(potreeWriter,node)
		end
		return node
	else
		accepted = false
		accepted = add(node.grid, point.position)
		if accepted
			push!(node.cache,point)
			update!(node.acceptedAABB,point.position)
			node.numAccepted+=1

			return node
		else
			if potreeWriter.maxDepth != -1 && node.level >= potreeWriter.maxDepth
				return
			end

			childIndex = nodeIndex(node.aabb, point.position);
			if childIndex >= 0
				if isLeafNode(node)
					node.children = Vector{Union{Nothing,PWNode}}(nothing,8)
				end
				if !isnothing(children[childIndex])
					child = createChild(potreeWriter,node,childIndex);
				else
					child = node.children[childIndex]
				end

				return add(child,point,potreeWriter)
			 else
				return
			end
		end
	end
end

function createChild(potreeWriter::PotreeWriter, node::PWNode, childIndex::Int)::PWNode
	cAABB = childAABB(node.aabb, childIndex)
	child = PWNode(potreeWriter, childIndex, cAABB, node.level+1)
	child.parent = node.parent
	node.children[childIndex] = child

	return child
end

function split(potreeWriter::PotreeWriter, node::PWNode)
	node.children = Vector{Union{Nothing,PWNode}}(nothing,8)
	filepath = joinpath(potreeWriter.workDir, "data", path(potreeWriter,node))

	if isfile(filepath)
		rm(filepath)
	end

	for point in node.store
		add(node, point, potreeWriter)
	end

	node.store = Point[];
end

# void flush();
function flush(node::PWNode, potreeWriter::PotreeWriter)

	function writeToDisk(points::Vector{Point}, append::Bool)
		filepath = joinpath(potreeWriter.workDir,"data", path(potreeWriter,node)

		dir = joinpath(potreeWriter.workDir, "data", hierarchyPath(potreeWriter,node))
		FileManager.mkdir_if(dir)

		if append
			temppath = joinpath(potreeWriter.workDir,"temp","prepend.las")
			if isfile(filepath)
				mv(filepath, temppath)
			end
			# IDEA: leggo i punti da temp uno ad uno e li metto in file
			# writer = createWriter(filepath);# TODO apro il file per salvare i punti
			# devo costruire l'header e salvare come al solito i punti
			if isfile(temppath)
				# PointReader *reader = createReader(temppath);# TODO Apri il file e leggi i punti come prima
				for p in pointdata
					# write(writer,p);# TODO salva i punti sul file e poi concludo dopo di salvare il resto
				end
				rm(temppath)
			end
		else
			if isfile(filepath)
				rm(filepath)
			end
			# IDEA allora li salvo su file i punti
			# writer = createWriter(filepath);# TODO
		end

		# punti da appendere o da salvare
		for e_c in points
			write(writer,e_c)
		end

		@assert !append && writer.numPoints == node.numAccepted) "writeToDisk $(writer.numPoints) != $(node.numAccepted)"
	end


	if isLeafNode(node)
		if node.addCalledSinceLastFlush
			writeToDisk(node.store, false)

		elseif !node.addCalledSinceLastFlush && node.isInMemory
			node.store = Point[]
			node.isInMemory = false;
		end
	else
		if node.addCalledSinceLastFlush
			writeToDisk(node.cache, true)

			node.cache = Point[]
		elseif !node.addCalledSinceLastFlush && node.isInMemory
			node.grid = SparseGrid(node.aabb, node.spacing);
			node.isInMemory = false
		end
	end

	node.addCalledSinceLastFlush = false

	for i in 1:8
		if !isnothing(node.children[i])
			child = node.children[i]
			flush(child, potreeWriter)
		end
	end


end

# void traverse(std::function<void(PWNode*)> callback);
function traverse(this_node::PWNode)
	for child in this_node.children
		traverse(child)
	end
end

# void traverseBreadthFirst(std::function<void(PWNode*)> callback);
#
# vector<PWNode*> getHierarchy(int levels);
function getHierarchy(this_node::PWNode,levels::Int)::Vector{PWNode}

	hierarchy = PWNode[]

	stack = Stack{PWNode}()
	push!(stack,this_node)
	while isempty(stack)
		node = pop!(stack)

		if node.level >= this_node.level + levels
			break
		end

		push!(hierarchy,node)

		for child in node.children
			# if child != NULL
				push!(stack,child)
			# end
		end
	end

	return hierarchy
end
# PWNode* findNode(string name);
