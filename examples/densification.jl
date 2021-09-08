using Common
using FileManager
using Detection
using PotreeConverter
using Visualization

# INPUT_PC = FileManager.source2pc(potree,6)

folder_project = raw"C:\Users\marte\Documents\Julia_package\UTILS\potreeoriginale"
potree = raw"C:\Users\marte\Documents\Julia_package\UTILS\potreeoriginale\MURI"
dense_path = FileManager.mkdir_project(folder_project,"DENSE_LOD6")

PotreeConverter.densify_leaves(folder_project, potree, 6)


cloudmetadata = CloudMetadata(potree)
aabb = cloudmetadata.boundingBox
centroid = [aabb.x_min,aabb.y_min,aabb.z_min]
affineMatrix = Common.t(-centroid...)
all_leaves = joinpath.(dense_path,readdir(dense_path))

# una volta ottenute tutte le foglie belle dense vado a calcolare per ognuna piani e poligoni
PotreeConverter.get_planes_and_poligons(all_leaves, dense_path)




# VISUALIZATION
"""
"""
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

"""
"""
function planes(PLANES::Array{Detection.Hyperplane,1}, box_oriented = true; affine_matrix = Matrix(Common.I,4,4))

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

"""
"""
function load_connected_components(filename::String)::Common.Cells
	EV = Array{Int64,1}[]
	io = open(filename, "r")
	string_conn_comps = readlines(io)
	close(io)

	conn_comps = [tryparse.(Float64,split(string_conn_comps[i], " ")) for i in 1:length(string_conn_comps)]
	for comp in conn_comps
		for i in 1:(length(comp)-1)
			push!(EV, [comp[i],comp[i+1]])
		end
		push!(EV,[comp[end],comp[1]])
	end
	return EV
end

"""
"""
function get_boundary_models(folders)
	n_planes = length(folders)
	boundary = Common.LAR[]
	for i in 1:n_planes
		#println("$i of $n_planes")
		if isfile(joinpath(folders[i],"vectorize_2D_boundary.probe"))
			V = FileManager.load_points(joinpath(folders[i],"boundary_points3D.txt"))
			EV = load_connected_components(joinpath(folders[i],"boundary_edges.txt"))
			if length(EV)==0
				@show i,folders[i]
			else
				model = (V,EV)
				push!(boundary,model)
			end
		end
	end
	return boundary
end
folders = filter!(x->isdir(x),joinpath.(dense_path,readdir(dense_path)))
boundary_models = get_boundary_models(folders)
INPUT_PC = FileManager.las2pointcloud(all_leaves...)

Visualization.VIEW([
	[Visualization.GLGrid(Common.apply_matrix(Common.t(-centroid...),model[1]),model[2],Visualization.COLORS[rand(1:1)],0.8) for model in boundary_models]...,
	# Visualization.points(Common.apply_matrix(Common.t(-centroid...),INPUT_PC.coordinates),INPUT_PC.rgbs),
])


function show_las(files; affine_matrix = Matrix{Float64}(Common.I,4,4))
    points = []
    for file in files
        PC = FileManager.las2pointcloud(file)
        push!(points,Visualization.points(Common.apply_matrix(affine_matrix,PC.coordinates),PC.rgbs))
    end
    return points
end


function show_octrees(files; affine_matrix = Matrix{Float64}(Common.I,4,4))
    octrees = []
    for file in files
        aabb = FileManager.las2aabb(file)
        V,EV = Common.getmodel(aabb)
        push!(octrees, Visualization.GLGrid(Common.apply_matrix(affine_matrix,V),EV,Visualization.YELLOW,1.0))
    end
    return octrees
end


pointclouds_mesh = show_las(all_leaves; affine_matrix = affineMatrix)
octrees_mesh = show_octrees(all_leaves; affine_matrix = affineMatrix)
# Visualization.VIEW([Visualization.points(Common.apply_matrix(Common.t(-centroid...),INPUT_PC.coordinates),INPUT_PC.rgbs)])

Visualization.VIEW([pointclouds_mesh...,octrees_mesh...])
