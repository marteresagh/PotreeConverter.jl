mutable struct Annotations
    nFiles::Int
    filesProcessed::Int
    filesFailed::Int
    txt::Union{Nothing,IOStream}
    octreePlanes::Array{Common.Struct,1}
    octreeLeaves::Array{Common.Struct,1}
end

function Annotations()
    nFiles = 0
    filesProcessed = 0
    filesFailed = 0
    txt = nothing
    octreeLeaves = Array{Common.Struct,1}()
    octreePlanes = Array{Common.Struct,1}()
    return Annotations(nFiles, filesProcessed, filesFailed, txt, octreePlanes, octreeLeaves)
end

"""
    potree2bim(potree::String)
"""
function potree2bim(potree::String; txt::String = "log_errored_files.txt", LOD::Int64 = -1)

    annotations = Annotations()
    collection = get_nodes(potree; LOD = LOD)
    annotations.nFiles = length(collection)
    out = Array{Common.Struct,1}()

    annotations.txt = open(txt,"w")
    hyperplanes = Detection.Hyperplane[]
    for node in collection
        println("=== node: $node ===")
        hypes = node2bim(node, annotations)
        # # model = node2bim(node, annotations)
        # if !isnothing(model)
        #     push!(out, Common.Struct([model])) # triangles cells
        # end
        union!(hyperplanes,hypes)
    end
    close(annotations.txt)

    # out = Common.Struct(out)
    # # V, FVs
    # W, FW, EW = Common.struct2lar(out)
    #
    # # V, FVs
    # return W, FW, EW, annotations
    return hyperplanes
end

"""
    get_nodes(potree::String; LOD::Int64=-1)
"""
function get_nodes(potree::String; LOD::Int64 = -1)

    writer = PotreeWriter(potree, PotreeConverter.DEFAULT)
    cloudjs = PotreeConverter.loadStateFromDisk(writer)

    collection = String[]
    dataDir = joinpath(potree, "data")

    if LOD == -1

        function leafnode(collection::Vector{String})
            function callback0(node::PWNode)
                if isLeafNode(node)
                    push!(
                        collection,
                        joinpath(dataDir, path(node, writer)),
                    ) #node.parent non va bene questa cosa del parent a -1,
                end
            end
            return callback0
        end

        traverse(writer.root, leafnode(collection))
        return unique(collection)
    else

        function levelnode(collection::Vector{String})
            function callback0(node::PWNode)
                if node.level == LOD
                    push!(collection, joinpath(dataDir, path(node, writer)))
                end
            end
            return callback0
        end

        traverse(writer.root, levelnode(collection))
        return collection
    end

end


"""
    node2bim(node::String)
"""
function node2bim(node::String, annotations::Annotations)
    function killafterseconds(s,task)
        @async begin
             schedule(task)
         end

        begin
            sleep(s)
            println("terminating after $s seconds")
            if !istaskdone(task)
                println("INTERROTTO")
                Base.throwto(task, InterruptException())
            else
                println("TERMINATO")
                return fetch(task)
            end
        end

    end

    hyperplanes = plane_identification(node)
    return hyperplanes

    try
        if !isempty(hyperplanes)

            # intersezione piani-octree
            println("intersezioni")
            myget_intersection(node, hyperplanes, annotations)
            # return W, FW, EW
            # arrangement e kill task if loop

            task = @task arrangement(W, FW, EW)
            println("INIZIO ARRANGEMENT")
            V, copEV, copFE, copCF = killafterseconds(60, task)
            println("FINE ARRANGEMENT")

            # costruzione modello
            V = permutedims(V)
            model = pols2tria(V, copEV, copFE, copCF)

            # pulitura del modello
            V, FVs = get_cells(model, hyperplanes)
            annotations.filesProcessed +=1
            return V, FVs
        end
    catch y
        annotations.filesFailed +=1
        write(annotations.txt,"node: $node\n")
        write(annotations.txt,"#planes: $(length(hyperplanes))\n")
        write(annotations.txt," ")
    end

    return nothing
end


"""
	plane_identification(node::CWNode,node_potree::PWNode)

Get cluster of coplanar planes.
"""
function plane_identification(node::String)

    pc = FileManager.las2pointcloud(node)
    points = pc.coordinates
    rgb = pc.rgbs

    hyperplanes = Detection.Hyperplane[]

    if size(points, 2) >= 3
        direction, centroid = Common.LinearFit(points)
        residuals =
            Common.distance_point2plane(
                centroid,
                direction,
            ).([c[:] for c in eachcol(points)])
        coplanar = max(residuals...) < 0.2
        if !coplanar
            hyperplanes = get_planes(points, rgb)
        else
            hyperplanes =
                [Detection.Hyperplane(PointCloud(points), direction, centroid)]
        end
    end

    println("HYPERPLANES = $(length(hyperplanes))")
    return hyperplanes

end


function myget_intersection(node, hyperplanes, annotations)
    aabb = FileManager.las2aabb(node)
    planes = [
        Plane(hyperplane.direction, hyperplane.centroid)
        for hyperplane in hyperplanes
    ]
    # intersezione piani-octree
    W, FW, EW = draw_planes(planes, aabb)
    # push!(annotations.octreeLeaves, Common.Struct([Common.getmodel(aabb)]))
    # push!(annotations.octreePlanes, Common.Struct([model]))
    # @show "FATTO"
    return W, FW, EW
end


"""
	get_intersection(node, hyperplanes)
"""
function get_intersection(node, hyperplanes)
    n_planes = length(hyperplanes)

    aabb_octree = FileManager.las2aabb(node)
    V, EV, FV = Common.getmodel(aabb_octree)

    box = [Common.Struct([(V, FV, EV)])]

    for k = 1:n_planes
        hyperplane = hyperplanes[k]
        pl = Plane(hyperplane.direction, hyperplane.centroid)
        plane =
            hyperplane.centroid .+
            hcat([0.0, 0.0, 0.0], pl.basis[:, 1] * 0.01, pl.basis[:, 2] * 0.01)
        planes(box, plane, aabb_octree)
    end

    W, FW, EW = Common.struct2lar(Common.Struct(box))

    return W, FW, EW
end

"""
	arrangement(W, FW, EW)
"""
function arrangement(W, FW, EW)
    cop_EV = coboundary_0(EW)
    cop_FE = coboundary_1(W, FW, EW)
    W = permutedims(W)

    V, copEV, copFE, copCF = space_arrangement(W, cop_EV, cop_FE)
end

"""
	get_cells(model, hyperplanes)
"""
function get_cells(model, hyperplanes)
    V, CVs, FVs, EVs = model
    tokeep = Vector{Vector{Vector{Int64}}}()

    for k = 1:length(hyperplanes)
        hyperplane = hyperplanes[k]
        inliers = hyperplane.inliers.coordinates
        kdtree = Detection.Search.KDTree(inliers)
        for fv in FVs
            index = union(fv...)
            points = V[:, index]
            centroid = Common.centroid(points)
            near = Detection.Search.inrange(kdtree, centroid, 0.05)
            if !isempty(near)
                push!(tokeep, fv)
            end
        end
    end

    return V, tokeep
end
