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
            storeSize)
end

function add(potreeWriter::PotreeWriter,p::Point)
	if potreeWriter.numAdded == 0
		dataDir = joinpath(potreeWriter.workDir,"data")
		tempDir = joinpath(potreeWriter.workDir,"temp")

		FileManager.mkdir_if(dataDir);
		FileManager.mkdir_if(tempDir);
	end

	push!(potreeWriter.store,p)
	potreeWriter.numAdded+=1
	if length(potreeWriter.store) > 10_000
		processStore(potreeWriter)
	end
end


function processStore(potreeWriter::PotreeWriter)
	st = copy(potreeWriter.store)
	potreeWriter.store = Point[]

	for p in st
		acceptedBy = add(potreeWriter.root, p, potreeWriter)
		if !isnothing(acceptedBy)
			update!(potreeWriter.tightAABB,p.position)

			potreeWriter.pointsInMemory+=1
			potreeWriter.numAccepted+=1
		end
	end

end


function flush(potreeWriter::PotreeWriter, cloudjs::CloudJS)
	processStore(potreeWriter)

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
		node = pop!(stack)

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
			dest = joinpath(potreeWriter.workDir, "data", hierarchyPath(node), name(node)*".hrc")
			io = open(dest, "w")

			for descendant in hierarchy
				children = Int8(0)
				for j in 0:length(descendant.children)-1
					if !isnothing(descendant.children[j+1])
						children = children | Int8(1 << j)
					end
				end

				write(io,children)
				write(io,Int32(descendant.numAccepted))
			end

			close(io)
			hrcFlushed+=1
		end
	end

	traverse(potreeWriter.root, node->node.addedSinceLastFlush = false)

end
