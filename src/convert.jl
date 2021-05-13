# function writeSources(path::String, sourceFilenames::Vector{String}, numPoints::Vector{Int64}, boundingBoxes::Vector{pAABB})
# 	#scrive il json source.js
# end

function potreeconvert(args::PotreeArguments)

    pointsProcessed = 0

	if isempty(args.aabbValues)
		args.aabb = calculateAABB(args.source)
	else
		args.aabb = calculateAABB(aabb)
	end

    println("AABB: ")
    println(args.aabb)

    PotreeConverter.makeCubic(args.aabb)
    println("cubic AABB: ")
    println(args.aabb)

    if args.diagonalFraction != 0
		args.spacing = Common.norm(args.aabb.size) / args.diagonalFraction
		println("spacing calculated from diagonal: $(args.spacing)")
	end

	workdir = FileManager.mkdir_project(args.workDir, args.pageName)
	if isfile(joinpath(workdir,"cloud.js"))
		if args.storeOption == ABORT_IF_EXISTS
			return 0
		end
	else
		writer = PotreeWriter(workdir, args.aabb, PWNode(), args.spacing, args.maxDepth, args.scale, args.quality)
		root = PWNode(writer,args.aabb)
		writer.root = root
	end
	writer.storeSize = args.storeSize

	boundingBoxes = pAABB[]
	numPoints = Int64[]
	sourceFilenames = String[]

	# // for source in sources PER ORA UNA SINGOLA SOURCE
	println("READING: $(args.source)")

	# reader of LAS file
	open(args.source) do s
		FileManager.LasIO.skiplasf(s)
		header = FileManager.LasIO.read(s, FileManager.LasIO.LasHeader)

		n = header.records_count
		pointtype = FileManager.LasIO.pointformat(header)
		pointdata = Vector{pointtype}(undef, n)
		push!(boundingBoxes,pAABB([header.x_min,header.y_min,header.z_min],[header.x_max,header.y_max,header.z_max]));
		push!(numPoints,convert(Int,n));
		push!(sourceFilenames,args.source)

		for i=1:n
			pointsProcessed += 1
			pointdata[i] = FileManager.LasIO.read(s, pointtype)
			p = FileManager.xyz(pointdata[i],header)
			pt = Point(p...)
			add(writer, pt)
			if i == 10
				break
			end
			if pointsProcessed % 1_000_000  == 0
				processStore(writer)
				print("INDEXING: ")
				print("$pointsProcessed points processed;")
				print("$(writer.numAccepted) points written; ")
			end
			if pointsProcessed % args.flushLimit == 0
				println("FLUSHING: ")
				flush(writer)
			end
		end
	end
	#close file las

	println("closing writer")
	flush(writer)

	# writeSources() #TODO

	percent = writer.numAccepted / pointsProcessed
	percent = percent * 100
	println("conversion finished")
	println("$pointsProcessed points were processed and $(writer.numAccepted) points ( $percent% ) were written to the output.")
	return writer
end
