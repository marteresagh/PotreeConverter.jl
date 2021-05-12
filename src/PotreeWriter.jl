function PotreeWriter(workDir::String, aabb::pAABB, root::Union{Nothing,PWNode}, spacing::Float64, maxDepth::Int64, scale::Float64, quality::ConversionQuality )

    outputFormat = OutputFormat
    pointAttributes = "LAS"
    tightAABB = nothing
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
