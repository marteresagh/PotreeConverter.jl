function get_planes(points,rgb)
    INPUT_PC = Common.PointCloud(points,rgb)
    par = 0.04
    failed = 10
    N = 10
    k = 10
    threshold = Detection.Features.estimate_threshold(INPUT_PC,2*k)
    INPUT_PC.normals = Detection.Features.compute_normals(INPUT_PC.coordinates,threshold,k)
    params = Detection.Initializer(INPUT_PC, par, threshold, failed, N, k, Int64[])
    hyperplanes = Detection.iterate_detection(params; debug = true)
    return hyperplanes
end

function getmodel(aabb::pAABB)::Common.LAR
	V = [	aabb.min[1]  aabb.min[1]  aabb.min[1]  aabb.min[1]  aabb.max[1]  aabb.max[1]  aabb.max[1]  aabb.max[1];
		 	aabb.min[2]  aabb.min[2]  aabb.max[2]  aabb.max[2]  aabb.min[2]  aabb.min[2]  aabb.max[2]  aabb.max[2];
		 	aabb.min[3]  aabb.max[3]  aabb.min[3]  aabb.max[3]  aabb.min[3]  aabb.max[3]  aabb.min[3]  aabb.max[3] ]
	EV = [[1, 2],  [3, 4], [5, 6],  [7, 8],  [1, 3],  [2, 4],  [5, 7],  [6, 8],  [1, 5],  [2, 6],  [3, 7],  [4, 8]]
	FV = [[1, 2, 3, 4],  [5, 6, 7, 8],  [1, 2, 5, 6],  [3, 4, 7, 8],  [1, 3, 5, 7],  [2, 4, 6, 8]]
	return V,EV,FV
end


function draw_planes(planes::Array{Common.Plane,1}, box::Common.AABB)::Common.LAR
	octree = Common.getmodel(box)
	out = [Common.Struct([octree]) ]

	for i in 1:length(planes)
		plane = planes[i]
		V,EV,FV = Common.getmodel(plane, box)
		push!(out, Common.Struct([(V,EV,[union(FV...)])])) # unique cells
	end

	out = Common.Struct( out )
	V, EV, FV = Common.struct2lar(out)

	return V, EV, FV
end
