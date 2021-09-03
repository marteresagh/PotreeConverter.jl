using PotreeConverter
using Common
using FileManager
using Detection
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



# potree = raw"D:\potreeDirectory\pointclouds\CASALETTO_TERRY_CONCLUSO_DECIMATO"
potree = raw"C:\Users\marte\Documents\Julia_package\UTILS\potreeoriginale\MURI"

INPUT_PC = FileManager.source2pc(potree,0)
cloudmetadata = CloudMetadata(potree)
# PotreeConverter.expand(potree, PotreeConverter.split_leaf)
aabb = cloudmetadata.boundingBox
centroid = Common.centroid(getmodel(aabb)[1])

cmtree = PotreeConverter.potree2comaptree(potree)

PotreeConverter.cut_tree!(cmtree, 3)

writer = PotreeConverter.PotreeWriter(potree, PotreeConverter.DEFAULT)
cloudjs = PotreeConverter.loadStateFromDisk(writer)

PotreeConverter.processTree(writer, cmtree, 0.8, 0.2)


Visualization.VIEW([mesh_planes(cmtree.root.hyperplanes; affine_matrix = Common.t(-centroid...))...]);
