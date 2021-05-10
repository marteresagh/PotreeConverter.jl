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
