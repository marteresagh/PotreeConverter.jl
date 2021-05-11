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


function update!(aabb::pAABB,point::Common.Point)
	x, y, z = point
	aabb.min[1] = min(aabb.min[1],x)
	aabb.min[2] = min(aabb.min[2],y)
	aabb.min[3] = min(aabb.min[3],z)

	aabb.max[1] = max(aabb.max[1],x)
	aabb.max[2] = max(aabb.max[2],y)
	aabb.max[3] = max(aabb.max[3],z)

	aabb.size = aabb.max - aabb.min;
end

function update!(aabb::pAABB, bbcc::pAABB)
	update!(aabb,bbcc.min)
	update!(aabb,bbcc.max)
end


"""
	isinside(aabb::pAABB,p::Points)

Check if point `p` is in a `aabb`.
"""
function isInside(aabb::pAABB,p::Common.Point)::Bool
	return (  p[1]>=aabb.min[1] && p[1]<=aabb.max[1] &&
			  p[2]>=aabb.min[2] && p[2]<=aabb.max[2] &&
			   p[3]>=aabb.min[3] && p[3]<=aabb.max[3] )
end

function makeCubic(aabb::pAABB)
	aabb.max = aabb.min .+ max(aabb.size...)
	aabb.size = aabb.max - aabb.min
end

function Base.show(io::IO, aabb::pAABB)
    println(io, "min: $(aabb.min)")
	println(io, "max: $(aabb.max)")
	println(io, "size: $(aabb.size)")
end

function calculateAABB(aabb::Vector{Float64})::pAABB
	return pAABB([aabb[1],aabb[2],aabb[3]],[aabb[4],aabb[5],aabb[6]])
end

function calculateAABB(source)::pAABB
	aabb = FileManager.las2aabb(source)
	return pAABB([aabb.x_min,aabb.y_min,aabb.z_min],[aabb.x_max,aabb.y_max,aabb.z_max])
end


function childAABB(aabb::pAABB,index::Int)

	min = copy(aabb.min)
	max = copy(aabb.max)

	if (index & 0b0001) > 0
		min[3] += aabb.size[3] / 2
	else
		max[3] -= aabb.size[3] / 2
	end

	if (index & 0b0010) > 0
		min[2] += aabb.size[2] / 2
	else
		max[2] -= aabb.size[2] / 2
	end

	if (index & 0b0100) > 0
		min[1] += aabb.size[1] / 2
	else
		max[1] -= aabb.size[1] / 2
	end

	return pAABB(min, max)
end
