struct Point
	position::Vector{Float64}
	color::Vector{Char}
	normal::Vector{Float64}
	intensity::UInt8
	classification::Char
	returnNumber::Char
	numberOfReturns::Char
	pointSourceID::UInt8
	gpsTime::Float64

	Point() = new([0.,0.,0.],[255,255,255],[0.,0.,0.],0,0,0,0,0,0.0)

	function Point(x,y,z)
		new([x,y,z],[255,255,255],[0.,0.,0.],0,0,0,0,0,0.0)
	end

	function Point(x,y,z,r,g,b)
		new([x,y,z],[r,g,b],[0.,0.,0.],0,0,0,0,0,0.0)
	end
end

mutable struct pAABB
    min::Vector{Float64}
	max::Vector{Float64}
	size::Vector{Float64}

	pAABB(min::Vector{Float64},max::Vector{Float64}) = new(min,max,max-min)

	function pAABB(points::Common.Points)
		dim = size(points,1)
		a = [extrema(points[i,:]) for i in 1:dim]
		min = [a[1][1],a[2][1],a[3][1]]
		max = [a[1][2],a[2][2],a[3][2]]
		return pAABB(min,max)
	end
end

struct GridCell
    points::Vector{Float64}
    neighbours::Vector{GridCell}

end

struct SparseGrid
    width::Int
    height::Int
    depth::Int
    aabb::pAABB
    squaredSpacing::Float64
    numAccepted::Int

    function SparseGrid(aabb::pAABB, spacing::Float64)
    	width =	Int(floor(aabb.size[1] / (spacing * cellSizeFactor) ))
    	height = Int(floor(aabb.size[2] / (spacing * cellSizeFactor) ))
    	depth =	Int(floor(aabb.size[3] / (spacing * cellSizeFactor) ))
    	squaredSpacing = spacing * spacing;
    	numAccepted = 0
    	return new(width,
    				height,
    				depth,
    				aabb,
    				squaredSpacing,
    				numAccepted
    				)
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
	cache::Vector{Point}
	store::Vector{Point}
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
					aabb,
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
					aabb,
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

	PWNode() = nothing;

end


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
	store::Vector{Point}
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
		store = Point[]

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


mutable struct PotreeArguments
	aabb::pAABB
	source::String
	workDir::String
	pointAttributes::String
	spacing::Float64
	maxDepth::Int
	outputFormat::String
	outputAttributes::Vector{String}
	colorRange::Vector{Float64}
	intensityRange::Vector{Float64}
	scale::Float64
	diagonalFraction::Int
	aabbValues::Vector{Float64}
	pageName::String
	storeOption::StoreOption
	quality::ConversionQuality
	material::String
	storeSize::Int
	flushLimit::Int

    function PotreeArguments(workDir::String, source::String)
		aabb = pAABB([Inf,Inf,Inf],[-Inf,-Inf,-Inf])
		pointAttributes = ""
		spacing = 0.
		maxDepth = -1
		outputFormat = OutputFormat
		outputAttributes = ["RGB"]
		colorRange = Float64[]
		intensityRange = Float64[]
		scale = 0.01
		diagonalFraction = 250
		aabbValues = Float64[]
		pageName = ""
		storeOption = ABORT_IF_EXISTS
		quality = DEFAULT
		material = "RGB"
		storeSize = 20_000
	    flushLimit = 10_000_000
		return new(aabb,
				source,
				workDir,
				pointAttributes,
				spacing,
				maxDepth,
				outputFormat,
				outputAttributes,
				colorRange,
				intensityRange,
				scale,
				diagonalFraction,
				aabbValues,
				pageName,
				storeOption,
				quality,
				material,
				storeSize,
				flushLimit
				)
	end
end
