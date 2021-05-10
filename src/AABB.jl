mutable struct AABB
    min::Vector{Float64}
	max::Vector{Float64}
	size::Vector{Float64}

	AABB(min::Vector{Float64},max::Vector{Float64}) = new(min,max,max-min)

	function AABB(points::Common.Points)
		dim = size(points,1)
		a = [extrema(points[i,:]) for i in 1:dim]
		min = [a[1][1],a[2][1],a[3][1]]
		max = [a[1][2],a[2][2],a[3][2]]
		return AABB(min,max)
	end
end


function update!(aabb::AABB,point::Common.Point)
	x, y, z = point
	aabb.min[1] = min(aabb.min[1],x)
	aabb.min[2] = min(aabb.min[2],y)
	aabb.min[3] = min(aabb.min[3],z)

	aabb.max[1] = max(aabb.max[1],x)
	aabb.max[2] = max(aabb.max[2],y)
	aabb.max[3] = max(aabb.max[3],z)

	aabb.size = aabb.max - aabb.min;
end

function update!(aabb::AABB, bbcc::AABB)
	update!(aabb,bbcc.min)
	update!(aabb,bbcc.max)
end


"""
	isinside(aabb::AABB,p::Points)

Check if point `p` is in a `aabb`.
"""
function isInside(aabb::AABB,p::Common.Point)::Bool
	return (  p[1]>=aabb.min[1] && p[1]<=aabb.max[1] &&
			  p[2]>=aabb.min[2] && p[2]<=aabb.max[2] &&
			   p[3]>=aabb.min[3] && p[3]<=aabb.max[3] )
end

function makeCubic(aabb::AABB)
	aabb.max = aabb.min + max(aabb.size...)
	aabb.size = aabb.max - aabb.min
end

function Base.show(io::IO, aabb::AABB)
    println(io, "min: $(aabb.min)")
	println(io, "max: $(aabb.max)")
	println(io, "size: $(aabb.size)")
end