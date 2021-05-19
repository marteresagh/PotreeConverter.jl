struct Point
	position::Vector{Float64}
	color::Vector{UInt16}
	normal::Vector{Float64}
	intensity::UInt16
	classification::Char
	returnNumber::Char
	numberOfReturns::Char
	pointSourceID::UInt16
	gpsTime::Float64
end

mutable struct pAABB
    min::Vector{Float64}
	max::Vector{Float64}
	size::Vector{Float64}

	pAABB() = new([Inf,Inf,Inf],[-Inf,-Inf,-Inf],[NaN,NaN,NaN])

	pAABB(min::Vector{Float64},max::Vector{Float64}) = new(min,max,max-min)
end

struct GridIndex
	i::Int
	j::Int
	k::Int

	GridIndex() = new(0,0,0)
	GridIndex(i::Int,j::Int,k::Int) = new(i,j,k)
end

struct GridCell
    points::Vector{Vector{Float64}}
    neighbours::Vector{GridCell}

	GridCell() = new(Float64[],GridCell[])
end

mutable struct SparseGrid
	map::Dict{Int64,GridCell}
    width::Int
    height::Int
    depth::Int
    aabb::pAABB
    squaredSpacing::Float64
    numAccepted::UInt64
end

mutable struct PWNode
	index::Int
	aabb::pAABB
	acceptedAABB::pAABB
	level::Int
	spacing::Float64
	grid::SparseGrid
	numAccepted::UInt
	parent::Union{Nothing,PWNode}
	children::Vector{Union{Nothing,PWNode}}
	addedSinceLastFlush::Bool
	addCalledSinceLastFlush::Bool
	cache::Vector{Point}
	store::Vector{Point}
	isInMemory::Bool
end


mutable struct PotreeWriter
	aabb::pAABB
	tightAABB::pAABB
	workDir::String
	spacing::Float64
	scale::Float64
	maxDepth::Int64
	root::Union{Nothing,PWNode}
	numAdded::Int64
	numAccepted::Int64
	outputFormat::String
	pointAttributes::String
	hierarchyStepSize::Int
	store::Vector{Point}
	pointsInMemory::Int
	quality::ConversionQuality
	storeSize::Int64
	storeThread::Union{Nothing,Task}
end


mutable struct PotreeArguments
	aabb::pAABB
	sources::Vector{String}
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
end


struct Node
	name::String
	pointCount::Int
end

mutable struct CloudJS
	version::String
	octreeDir::String
	boundingBox::pAABB
	tightBoundingBox::pAABB
	outputFormat::String
	pointAttributes::String
	spacing::Float64
	hierarchy::Vector{Node}
	scale::Float64
	hierarchyStepSize::Int
	numAccepted::Int
	projection::String

	function CloudJS()
		version = ""
		octreeDir = ""
		boundingBox = pAABB()
		tightBoundingBox = pAABB()
		outputFormat = OutputFormat
		pointAttributes = OutputFormat
		spacing = 0.0
		hierarchy = Vector{Node}[]
		scale = 0.0
		hierarchyStepSize = -1
		numAccepted = 0
		projection = ""
		return new(version,
				octreeDir,
				boundingBox,
				tightBoundingBox,
				outputFormat,
				pointAttributes,
				spacing,
				hierarchy,
				scale,
				hierarchyStepSize,
				numAccepted,
				projection,
				)
	end
end
