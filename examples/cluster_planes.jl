using Common
using Detection
using PotreeConverter
using Visualization


function DrawPlanes(planes::Array{Detection.Hyperplane,1}; box_oriented=true)::Common.LAR
	out = Array{Common.Struct,1}()
	for obj in planes
		plane = Common.Plane(obj.direction,obj.centroid)
		if box_oriented
			box = Common.ch_oriented_boundingbox(obj.inliers.coordinates)
		else
			box = Common.AABB(obj.inliers.coordinates)
		end
		cell = Common.getmodel(plane,box)
		push!(out, Common.Struct([cell]))
	end
	out = Common.Struct( out )
	V, EV, FV = Common.struct2lar(out)
	return V, EV, FV
end


function mesh_planes(PLANES::Array{Detection.Hyperplane,1}, box_oriented = false; affine_matrix = Matrix(Common.I,4,4))

	mesh = []
	for plane in PLANES
		pc = plane.inliers
		V,EV,FV = DrawPlanes([plane]; box_oriented=box_oriented)
		col = Visualization.COLORS[rand(1:12)]
		push!(mesh, Visualization.GLGrid(Common.apply_matrix(affine_matrix,V),FV,col,0.5));
		push!(mesh,	Visualization.points(Common.apply_matrix(affine_matrix,pc.coordinates);color = col,alpha=0.8));
	end

	return mesh
end



function clustering_planes(planes::Vector{Detection.Hyperplane})#,centroids)
	cluster = Detection.Hyperplane[]
	for plane in planes
		normal = plane.direction
		found = false
		for i in 1:length(cluster)
			@show Common.abs(Common.dot(cluster[i].direction,normal))
			if Common.abs(Common.dot(cluster[i].direction,normal)) > 0.8

				# è parallelo
				@show Common.norm(Common.dot(cluster[i].direction,cluster[i].centroid)-Common.dot(cluster[i].direction,plane.centroid))
				if Common.norm(Common.dot(cluster[i].direction,cluster[i].centroid)-Common.dot(cluster[i].direction,plane.centroid)) < 0.2
					# è coincidente
					found = true
					inliers = PointCloud(hcat(cluster[i].inliers.coordinates,plane.inliers.coordinates),hcat(cluster[i].inliers.rgbs,plane.inliers.rgbs))
					direction, centroid = Common.LinearFit(inliers.coordinates)
					cluster[i] = Detection.Hyperplane(inliers,direction,centroid)
					break
				end
			end
		end
		if !found
			push!(cluster,plane)
		end

	end

	return cluster
end

npoints = 100
V2D = rand(2, npoints)
zeta = Float64[]
for i in 1:npoints
	push!(zeta,0.01 * rand())
end
points = vcat(V2D,zeta')


direction, centroid = Common.LinearFit(points)
plane1 = Detection.Hyperplane(PointCloud(points,rand(3,npoints)),direction,centroid)

points2 = Common.apply_matrix(Common.t(0.0001,0,0.0001), points)
direction, centroid = Common.LinearFit(points2)
plane2 = Detection.Hyperplane(PointCloud(points2,rand(3,npoints)),direction,centroid)

points3 = Common.apply_matrix(Common.t(1,2,2)*Common.r(0,pi/3,0), points)
direction, centroid = Common.LinearFit(points3)
plane3 = Detection.Hyperplane(PointCloud(points3,rand(3,npoints)),direction,centroid)

points4 = Common.apply_matrix(Common.t(1,2,2)*Common.r(0,pi/3,0), points)
direction, centroid = Common.LinearFit(points4)
plane4 = Detection.Hyperplane(PointCloud(points4,rand(3,npoints)),direction,centroid)


planes = [plane1,plane2, plane3, plane4]

Visualization.VIEW([mesh_planes(planes)...,Visualization.axis_helper()...]);


cluster =  clustering_planes(planes)

Visualization.VIEW([mesh_planes(planes)...,mesh_planes(cluster)...,Visualization.axis_helper()...]);
