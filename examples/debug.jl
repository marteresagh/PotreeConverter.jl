using PotreeConverter
using Common
using FileManager
using Detection
using Visualization
#################################################
# trie = FileManager.potree2trie(potree)
# leaf_files = FileManager.get_leaf(trie)
#
# function test_tree()
# 	r = PotreeConverter.CWNode()
# 	r0 = PotreeConverter.CWNode(0,1)
# 	r1 = PotreeConverter.CWNode(1,1)
# 	r01 = PotreeConverter.CWNode(1,2)
# 	r010 = PotreeConverter.CWNode(0,3)
# 	r011 = PotreeConverter.CWNode(1,3)
# 	r11 = PotreeConverter.CWNode(1,2)
# 	r12 = PotreeConverter.CWNode(2,2)
# 	r121 = PotreeConverter.CWNode(1,3)
# 	r122 = PotreeConverter.CWNode(2,3)
# 	r123 = PotreeConverter.CWNode(3,3)
# 	r124 = PotreeConverter.CWNode(4,3)
# 	r.children = Vector{Union{Nothing,PotreeConverter.CWNode}}(nothing,8)
# 	r.children[1] = r0; r.children[2] = r1;
# 	r0.children = Vector{Union{Nothing,PotreeConverter.CWNode}}(nothing,8)
# 	r0.children[2] = r01;
# 	r1.children = Vector{Union{Nothing,PotreeConverter.CWNode}}(nothing,8)
# 	r1.children[2] = r11; r1.children[3] = r12;
# 	r01.children = Vector{Union{Nothing,PotreeConverter.CWNode}}(nothing,8)
# 	r01.children[1] = r010; r01.children[2] = r011;
# 	r12.children = Vector{Union{Nothing,PotreeConverter.CWNode}}(nothing,8)
# 	r12.children[2] = r121; r12.children[3] = r122; r12.children[4] = r123; r12.children[5] = r124;
# 	r0.parent = r;
# 	r1.parent = r;
# 	r01.parent = r0;
# 	r010.parent = r01;r011.parent = r01;
# 	r11.parent = r1;r12.parent = r1;
# 	r121.parent = r12;r122.parent = r12;r123.parent = r12;r124.parent = r12;
# 	return r
# end
# printname(node::PotreeConverter.CWNode) = println(PotreeConverter.name(node))
#################################################

# potree = raw"C:\Users\marte\Documents\Julia_package\UTILS\potreeoriginale\MURI"
potree = raw"C:\Users\marte\Documents\potreeDirectory\pointclouds\SCAN_TOTALE_CASALETTO"
leaves = FileManager.get_leaf(potree2trie(potree))
INPUT_PC = FileManager.source2pc(potree,0)
cloudmetadata = CloudMetadata(potree)
# PotreeConverter.expand(potree, PotreeConverter.split_leaf)
aabb = cloudmetadata.boundingBox
centroid = Common.centroid(getmodel(aabb)[1])
cmtree = PotreeConverter.potree2comaptree(potree)
writer = PotreeConverter.PotreeWriter(potree, PotreeConverter.DEFAULT)
cloudjs = PotreeConverter.loadStateFromDisk(writer)

PotreeConverter.processTree(writer, cmtree)

node = PotreeConverter.findNode(cmtree.root,"r240")
cmtree.root.dict
# #
# hyperplanes = Detection.Hyperplane[]
# INPUT_PC = FileManager.source2pc(raw"C:\Users\marte\Documents\potreeDirectory\pointclouds\MURI\data\r\r0464.las") #r0464 r0465
# par = 0.04
# failed = 10
# N = 1000
# k = 10
# threshold = Detection.Features.estimate_threshold(INPUT_PC,2*k)
# INPUT_PC.normals = Detection.Features.compute_normals(INPUT_PC.coordinates,threshold,k)
# params = Detection.Initializer(INPUT_PC, par, threshold, failed, N, k, Int64[])
# hyperplanes0 = Detection.iterate_detection(params; debug = true)
#
# union!(hyperplanes,hyperplanes0)
# function DrawPlanes(planes::Array{Detection.Hyperplane,1}; box_oriented=true)::Common.LAR
# 	out = Array{Common.Struct,1}()
# 	for obj in planes
# 		plane = Common.Plane(obj.direction,obj.centroid)
# 		if box_oriented
# 			box = Common.ch_oriented_boundingbox(obj.inliers.coordinates)
# 		else
# 			box = Common.AABB(obj.inliers.coordinates)
# 		end
# 		cell = Common.getmodel(plane,box)
# 		push!(out, Common.Struct([cell]))
# 	end
# 	out = Common.Struct( out )
# 	V, EV, FV = Common.struct2lar(out)
# 	return V, EV, FV
# end
# function DrawPlanes(plane::Detection.Hyperplane; box_oriented=true)
# 	return DrawPlanes([plane],box_oriented=box_oriented)
# end
#
# V,FV = DrawPlanes(hyperplanes; box_oriented = false)
#
# Visualization.VIEW([
# 	Visualization.GLGrid(Common.apply_matrix(Common.t(-centroid...),V),FV,Visualization.COLORS[1],0.8)
# ])

function DrawPlanes(dict, AABB::Common.AABB)::Common.LAR
	out = Array{Common.Struct,1}()
	n_planes=0
	for (k,v) in dict
		for c in v
			plane = Common.Plane(k,c)
			cell = Common.getmodel(plane,AABB)
			push!(out, Common.Struct([cell]))
			n_planes+=1
		end
	end
	out = Common.Struct( out )
	V, EV, FV = Common.struct2lar(out)
	@show n_planes
	return V, EV, FV
end


V,EV,FV = DrawPlanes(cmtree.root.dict,aabb)

Visualization.VIEW([
	Visualization.points(Common.apply_matrix(Common.t(-centroid...),INPUT_PC.coordinates),INPUT_PC.rgbs)
	Visualization.GLGrid(Common.apply_matrix(Common.t(-centroid...),V),FV,Visualization.COLORS[1],0.2)
])
