#=
 *   y
 *   |-z
 *   |/
 *   O----x
 *
 *   3----7
 *  /|   /|
 * 2----6 |
 * | 1--|-5
 * |/   |/
 * 0----4
 *
 =#
function childAABB(aabb::pAABB,index::Int)::pAABB

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


function nodeIndex(aabb::pAABB, point::Vector{Float64})::Int
	mx = Int(floor(2.0 * (point[1] - aabb.min[1]) / aabb.size[1]))
	my = Int(floor(2.0 * (point[2] - aabb.min[2]) / aabb.size[2]))
	mz = Int(floor(2.0 * (point[3] - aabb.min[3]) / aabb.size[3]))

	mx = min(mx, 1)
	my = min(my, 1)
	mz = min(mz, 1)

	return (mx << 2) | (my << 1) | mz
end

function squaredDistanceTo(a::Vector,b::Vector)
	x,y,z = [a-b]
	return x*x + y*y + z*z
end
