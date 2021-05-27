"""
	PotreeWriter(workDir::String, aabb::pAABB, root::Union{Nothing,PWNode}, spacing::Float64, maxDepth::Int64, scale::Float64, quality::ConversionQuality )
"""
function PotreeWriter(workDir::String, aabb::pAABB, root::Union{Nothing,PWNode}, spacing::Float64, maxDepth::Int64, scale::Float64, quality::ConversionQuality )

    outputFormat = OutputFormat
    pointAttributes = "LAS"
    tightAABB = pAABB()
    numAdded = 0
    numAccepted = 0
    hierarchyStepSize = 5
    pointsInMemory = 0
    storeSize = 20_000
    store = Point[]

    if scale == 0
        if Common.norm(aabb.size) > 1_000_000
            scale = 0.01
        elseif Common.norm(aabb.size) > 100_000
            scale = 0.001
        elseif Common.norm(aabb.size) > 1
            scale = 0.001
        else
            scale = 0.0001
        end
    end

    return PotreeWriter(aabb,
            tightAABB,
            workDir,
            spacing,
            scale,
            maxDepth,
            root,
            numAdded,
            numAccepted,
            outputFormat,
            pointAttributes,
            hierarchyStepSize,
            store,
            pointsInMemory,
            quality,
            storeSize,
			nothing)
end

"""
	PotreeWriter(workDir::String, quality::ConversionQuality)
"""
function PotreeWriter(workDir::String, quality::ConversionQuality )

    outputFormat = OutputFormat
    pointAttributes = "LAS"
	aabb = pAABB()
    tightAABB = pAABB()
    numAdded = 0
    numAccepted = 0
    hierarchyStepSize = 5
    pointsInMemory = 0
    storeSize = 20_000
    store = Point[]
	scale = 0.
	spacing = 0.
	maxDepth = -1
	root = PWNode()

    return PotreeWriter(aabb,
            tightAABB,
            workDir,
            spacing,
            scale,
            maxDepth,
            root,
            numAdded,
            numAccepted,
            outputFormat,
            pointAttributes,
            hierarchyStepSize,
            store,
            pointsInMemory,
            quality,
            storeSize,
			nothing)
end

function waitUntilProcessed(potreeWriter::PotreeWriter)
	if !isnothing(potreeWriter.storeThread)
		fetch(potreeWriter.storeThread)
	end
end

"""
	add(potreeWriter::PotreeWriter,p::Point)

Add point in PotreeWriter store and process store.
"""
function add(potreeWriter::PotreeWriter,p::Point)
	# la prima volta crea cartelle utili per il salvataggio dell'albero
	if potreeWriter.numAdded == 0
		dataDir = joinpath(potreeWriter.workDir,"data")
		tempDir = joinpath(potreeWriter.workDir,"temp")

		FileManager.mkdir_if(dataDir);
		FileManager.mkdir_if(tempDir);
	end

	push!(potreeWriter.store,p)
	potreeWriter.numAdded+=1
	# se i punti sono tanti processo lo store
	if length(potreeWriter.store) > 10_000
		processStore(potreeWriter)
	end
end

"""
	processStore(potreeWriter::PotreeWriter)

Move points from PotreeWriter store in a specific node of octree.
"""
function processStore(potreeWriter::PotreeWriter)
	st = copy(potreeWriter.store)
	potreeWriter.store = Point[]

	waitUntilProcessed(potreeWriter)

	 for p in st
		acceptedBy = add(potreeWriter.root, p, potreeWriter)
		if !isnothing(acceptedBy)
			update!(potreeWriter.tightAABB,p.position)

			potreeWriter.pointsInMemory+=1
			potreeWriter.numAccepted+=1
		end
	end

end

"""
	flush(potreeWriter::PotreeWriter, cloudjs::CloudJS)

Write to disk all nodes and entire hierarchy.

Properties:
 - flush all nodes of octree
 - save the metadata of the octree in cloud.js
 - write the hierarchy in a file .hrc
"""
function flush(potreeWriter::PotreeWriter, cloudjs::CloudJS)
	processStore(potreeWriter)

	# waitUntilProcessed(potreeWriter::PotreeWriter)

	flush(potreeWriter.root,potreeWriter)

	# update and saves cloudjs
	update!(cloudjs,potreeWriter)
	save_cloudjs(cloudjs, potreeWriter.workDir)

	# write hierarchy
	hrcTotal = 0
	hrcFlushed = 0

	stack = PWNode[]
	push!(stack, potreeWriter.root)
	while !isempty(stack)
		node = popfirst!(stack)

		hrcTotal+=1

		hierarchy = getHierarchy(node,potreeWriter.hierarchyStepSize + 1)
		needsFlush = false
		for descendant in hierarchy
			if descendant.level == node.level + potreeWriter.hierarchyStepSize
				push!(stack,descendant)
			end

			needsFlush = needsFlush || descendant.addedSinceLastFlush
		end


		if needsFlush
			dest = joinpath(potreeWriter.workDir, "data", hierarchyPath(node,potreeWriter), name(node)*".hrc")
			io = open(dest, "w")

			for descendant in hierarchy
				children = 0
				for j in 0:length(descendant.children)-1
					if !isnothing(descendant.children[j+1])
						children = children | 1 << j
					end
				end


				function to_bytes(n::Integer; bigendian=true, len=sizeof(n))
				   bytes = Array{UInt8}(undef, len)
				   for byte in (bigendian ? (1:len) : reverse(1:len))
				       bytes[byte] = n & 0xff
				       n >>= 8
				   end
				   return bytes
				end

				write(io,to_bytes(children; len=1))
				bytes = to_bytes(descendant.numAccepted; len=4)
				write(io,bytes[1])
				write(io,bytes[2])
				write(io,bytes[3])
				write(io,bytes[4])
			end

			close(io)
			hrcFlushed+=1
		end
	end

	traverse(potreeWriter.root, node->node.addedSinceLastFlush = false)

end


function loadStateFromDisk(potreeWriter::PotreeWriter)
	# cloudjs
	cloudJSPath = joinpath(potreeWriter.workDir, "cloud.js")

	cloudjs = CloudJS()
	dict = nothing
	open(cloudJSPath, "r") do f
		dict = FileManager.JSON.parse(f)
	end

	cloudjs.version = dict["version"]
	cloudjs.octreeDir = dict["octreeDir"]
	cloudjs.boundingBox = pAABB([dict["boundingBox"]["lx"],dict["boundingBox"]["ly"],dict["boundingBox"]["lz"]],
								[dict["boundingBox"]["ux"],dict["boundingBox"]["uy"],dict["boundingBox"]["uz"]])
	cloudjs.tightBoundingBox = pAABB([dict["tightBoundingBox"]["lx"],dict["tightBoundingBox"]["ly"],dict["tightBoundingBox"]["lz"]],
								[dict["tightBoundingBox"]["ux"],dict["tightBoundingBox"]["uy"],dict["tightBoundingBox"]["uz"]])
	cloudjs.outputFormat = dict["pointAttributes"]
	cloudjs.pointAttributes = dict["pointAttributes"]
	cloudjs.spacing = dict["spacing"]
	cloudjs.scale = dict["scale"]
	cloudjs.hierarchyStepSize = dict["hierarchyStepSize"]
	cloudjs.numAccepted = dict["points"]
	cloudjs.projection = dict["projection"]
	# end cloudjs

	# potreeWriter
	potreeWriter.outputFormat = cloudjs.outputFormat
	potreeWriter.pointAttributes = cloudjs.pointAttributes
	potreeWriter.hierarchyStepSize = cloudjs.hierarchyStepSize
	potreeWriter.spacing = cloudjs.spacing
	potreeWriter.scale = cloudjs.scale
	potreeWriter.aabb = cloudjs.boundingBox
	potreeWriter.tightAABB = cloudjs.tightBoundingBox
	potreeWriter.numAccepted = cloudjs.numAccepted
	# end potreeWriter

	# tree
	rootDir = joinpath(potreeWriter.workDir,"data","r")
	hrcPaths = FileManager.searchfile(rootDir,".hrc")

	sort!(hrcPaths, by=length)

	root = PWNode(potreeWriter, cloudjs.boundingBox);
	for hrcPath in hrcPaths
		filename = splitdir(hrcPath)[2]
		hrcName = String(Base.split(filename, ".")[1])
		hrcRoot = findNode(root,hrcName)

		current = hrcRoot
		current.addedSinceLastFlush = false
		current.isInMemory = false
		nodes = PWNode[]
		push!(nodes,hrcRoot)

		raw = Base.read(hrcPath)
		treehrc = reshape(raw, (5, div(length(raw), 5)))

		for i in 1:size(treehrc,2)
			children = Int(treehrc[1,i])
			numPoints = parse(Int, bitstring(UInt8(treehrc[5,i]))*bitstring(UInt8(treehrc[4,i]))*bitstring(UInt8(treehrc[3,i]))*bitstring(UInt8(treehrc[2,i])); base=2)
			current = nodes[i]

			current.numAccepted = numPoints

			if children != 0
				current.children = Vector{Union{Nothing,PWNode}}(nothing,8)
				for j in 0:7
					if children & (1 << j) != 0
						cAABB = childAABB(current.aabb, j)
						child = PWNode(potreeWriter, j, cAABB, current.level + 1);
						child.parent = current
						child.addedSinceLastFlush = false
						child.isInMemory = false
						current.children[j+1] = child
						push!(nodes,child)
					end
				end
			end
		end
	end

	potreeWriter.root = root
	# end tree

	return cloudjs
end
