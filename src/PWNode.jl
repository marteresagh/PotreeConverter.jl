function name(node::PWNode)::String
	if isnothing(node.parent)
		return "r"
	else
		return name(node.parent)*string(node.index)
	end
end

function spacing(potreeWriter::PotreeWriter,node::PWNode)::Float64
	return potreeWriter.spacing/2^level
end

function hierarchyPath(potreeWriter::PotreeWriter,node::PWNode)::String
	path = "r/"
	hierarchyStepSize = potreeWriter.hierarchyStepSize
	indices = name(node)[2:end]

	numParts = Int(floor(length(a) / hierarchyStepSize))
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
#
# PWNode *add(Point &point);
function add(node::PWNode,point::Point)
	node.addCalledSinceLastFlush = true;
	if !node.isInMemory
		# loadFromDisk();#TODO
	end

	if isLeafNode(node)
		push!(node.store,point)
		if length(node.store) >= potreeWriter.storeSize
			split(node::PWNode)
		end

		return node
	else
		accepted = false
		accepted = add(point.position, grid)
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
					node.children = PWNode[NULL]
				end
				child = node.children[childIndex];

				# create child node if not existent
				if isnothing(child)
					child = createChild(node,childIndex);
				end

				return add(child,point)
			 else
				return
			end
		end
	end
end

function createChild(node::PWNode, childIndex::Int)::PWNode
	cAABB = childAABB(node.aabb, childIndex)
	child = PWNode(childIndex, cAABB, node.level+1)
	child.parent = node.parent
	node.children[childIndex] = child

	return child
end

function split(node::PWNode)
	# filepath = workDir() + "/data/" + path()
	# if isfile(filepath)
	# 	remove(filepath)
	# end
	#
	# for point in store
	# 	add(point)
	# end
	#
	# store = [];
end

# void flush();
#
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


function add(potreeWriter::PotreeWriter,p::Point)
	if potreeWriter.numAdded == 0
		dataDir = joinpath(potreeWriter.workDir,"data")
		tempDir = joinpath(potreeWriter.workDir,"temp")

		FileManager.mkdir_if(dataDir);
		FileManager.mkdir_if(tempDir);
	end

	push!(potreeWriter.store,p)
	potreeWriter.numAdded+=1
	if length(potreeWriter.store) > 10_000
		processStore(potreeWriter)
	end
end


function processStore(potreeWriter::PotreeWriter)
	st = copy(potreeWriter.store)
	potreeWriter.store = Point[]

	for p in st
		acceptedBy = add(potreeWriter.root,p)
		if !isnothing(acceptedBy)
			update!(potreeWriter.tightAABB,p.position)

			potreeWriter.pointsInMemory+=1
			potreeWriter.numAccepted+=1
		end
	end

end
