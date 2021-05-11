mutable struct PotreeWriter

	aabb::pAABB
	tightAABB::Union{Nothing,pAABB}
	workDir::String
	spacing::Float64
	scale::Float64
	maxDepth::Int64
	root::PWNode
	numAdded::Int64
	numAccepted::Int64
	outputFormat::String
	pointAttributes::String
	hierarchyStepSize::Int
	store::Union{Nothing,Vector}
	pointsInMemory::Int
	quality::ConversionQuality
	storeSize::Int64

	function PotreeWriter(workDir::String, aabb::pAABB, root::PWNode, spacing::Float64, maxDepth::Int64, scale::Float64, quality::ConversionQuality )

		outputFormat = OutputFormat
		pointAttributes = "LAS"
		tightAABB = nothing
		numAdded = 0
		numAccepted = 0
		hierarchyStepSize = 5
		pointsInMemory = 0
		storeSize = 20_000
		store = nothing

		if scale == 0
			if Common.norm(aabb.size) > 1_000_000
				scale = 0.01
			elseif Common.norm(aabb.size) > 100_000
				scale = 0.001
			elseif Common.norm(aabb.size) > 1
				scale = 0.001
			else
				scale = 0.0001
			end
		end

		return new(aabb,
				tightAABB,
				workDir,
				spacing,
				scale,
				maxDepth,
				root,
				numAdded,
				numAccepted,
				outputFormat,
				pointAttributes,
				hierarchyStepSize,
				store,
				pointsInMemory,
				quality,
				storeSize)
	end


end

mutable struct PWNode
	index::Int
	aabb::pAABB
	acceptedAABB::pAABB
	level::Int
	# SparseGrid *grid;
	numAccepted::UInt
	parent::Union{Nothing,PWNode}
	children::Vector{PWNode}
	addedSinceLastFlush::Bool
	addCalledSinceLastFlush::Bool
	cache::Vector
	store::Vector
	isInMemory::Bool

	function PWNode(aabb::pAABB)
		index = -1
		acceptedAABB = pAABB([Inf,Inf,Inf],[-Inf,-Inf,-Inf])
		level = 0
		numAccepted = 0
		parent = nothing
		children = PWNode[]
		addedSinceLastFlush = true
		addCalledSinceLastFlush = false
		cache = Float64[]
		store = Float64[]
		isInMemory = true
		return new( index,
					aabb::pAABB
					acceptedAABB,
					level,
					# SparseGrid *grid;
					numAccepted,
					parent,
					children,
					addedSinceLastFlush,
					addCalledSinceLastFlush,
					cache,
					store,
					isInMemory)
	end

	function PWNode(index::Int, aabb::pAABB, level::Int)
		acceptedAABB = pAABB([Inf,Inf,Inf],[-Inf,-Inf,-Inf])
		numAccepted = 0
		parent = nothing
		children = PWNode[]
		addedSinceLastFlush = true
		addCalledSinceLastFlush = false
		cache = Float64[]
		store = Float64[]
		isInMemory = true
		return new( index,
					aabb::pAABB
					acceptedAABB,
					level,
					# SparseGrid *grid;
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

	function spacing(potreeWriter::potreeWriter,node::PWNode)::Float64
		return potreeWriter.spacing/2^level
	end

	function hierarchyPath(potreeWriter::potreeWriter,node::PWNode)::String
		path = "r/"
		hierarchyStepSize = potreeWriter.hierarchyStepSize
		indices = name(node)[2:end]

		numParts = Int(floor(length(a) / hierarchyStepSize))
		for i = 0:numParts-1
			path *= indices[i * hierarchyStepSize+1: hierarchyStepSize] * "/"
		end

		return path
	end

	function path(potreeWriter::potreeWriter,node::PWNode)
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
	#
	# PWNode *createChild(int childIndex);
	#
	# void split();
	#
	#
	# void flush();
	#
	# void traverse(std::function<void(PWNode*)> callback);
	#
	# void traverseBreadthFirst(std::function<void(PWNode*)> callback);
	#
	# vector<PWNode*> getHierarchy(int levels);
	#
	# PWNode* findNode(string name);

end
