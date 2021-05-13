struct Point
	position::Vector{Float64}
	color::Vector{UInt8}
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

struct GridIndex
	i::Int
	j::Int
	k::Int

	function GridIndex()
		return new(0,0,0)
	end

	function GridIndex(i::Int,j::Int,k::Int)
		return new(i,j,k)
	end

end

struct GridCell
    points::Vector{Float64}
    neighbours::Vector{GridCell}

	function GridCell()
		new(Float64[],Vector{GridCell}(undef,26))
	end

end

struct SparseGrid
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
	tightAABB::Union{Nothing,pAABB}
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
end
