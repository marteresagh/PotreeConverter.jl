"""
	writeSources(path::String, sourceFilenames::Vector{String}, numPoints::Vector{Int64}, boundingBoxes::Vector{pAABB})

Write a json file with sources information.
"""
function writeSources(path::String, sourceFilenames::Vector{String}, numPoints::Vector{Int64}, boundingBoxes::Vector{pAABB})
	data = DataStructures.OrderedDict()
	data["bounds"] = DataStructures.OrderedDict()
	data["projection"] = ""
	data["sources"] = DataStructures.OrderedDict[]

	bb = pAABB()

	for i in eachindex(sourceFilenames)
		source = sourceFilenames[i]
		points = numPoints[i]
		boundingBox = boundingBoxes[i]

		update!(bb,boundingBox)
		data_source = DataStructures.OrderedDict()
		data_source["name"] = splitdir(source)[2]
		data_source["points"] = points
		data_source["bounds"] = DataStructures.OrderedDict()
		data_source["bounds"]["min"] = boundingBox.min
		data_source["bounds"]["max"] = boundingBox.max
		push!(data["sources"],data_source)
	end

	data["bounds"]["min"] = bb.min
	data["bounds"]["max"] = bb.max
	#
	# if(!fs::exists(fs::path(path))){
	# 	fs::path pcdir(path);
	# 	fs::create_directories(pcdir);
	# }

	open(joinpath(path,"source.json"),"w") do f
        FileManager.JSON.print(f, data, 4)
    end
end

"""
	potreeconvert(args::PotreeArguments)

Generates an octree LOD structure:
 - Read all points in sources.
 - Add each point to a one node of octree.
 - Write all info and structures to the disk.
"""
function potreeconvert(args::PotreeArguments)
 	start = time()
    pointsProcessed = 0
	# writer = nothing

	# Compute AABB
	if isempty(args.aabbValues)
		args.aabb = calculateAABB(args.sources)
	else
		args.aabb = calculateAABB(aabb)
	end

    println("AABB: ")
    println(args.aabb)

    PotreeConverter.makeCubic(args.aabb)
    println("cubic AABB: ")
    println(args.aabb)

	# Compute spacing in r
    if args.diagonalFraction != 0
		args.spacing = Common.norm(args.aabb.size) / args.diagonalFraction
		println("spacing calculated from diagonal: $(args.spacing)")
	end

	# Instantiate writer
	workdir = FileManager.mkdir_project(args.workDir, args.pageName)
	if isfile(joinpath(workdir,"cloud.js"))
		if args.storeOption == ABORT_IF_EXISTS
			println("ABORTING CONVERSION: target already exists:  $(joinpath(workdir,"cloud.js"))")
			println("If you want to overwrite the existing conversion, specify --overwrite")
			println("If you want add new points to the existing conversion, make sure the new points ")
			println("are contained within the bounding box of the existing conversion and then specify --incremental")
			return 0
		elseif args.storeOption == OVERWRITE
			clearfolder(joinpath(workdir,"data"))
			clearfolder(joinpath(workdir,"temp"))
			rm(joinpath(workdir,"cloud.js"))

			# new writer
			writer = PotreeWriter(workdir, args.aabb, PWNode(), args.spacing, args.maxDepth, args.scale, args.quality)
			root = PWNode(writer,args.aabb)
			writer.root = root
			cloudjs = CloudJS()
			update!(cloudjs, writer)

		elseif args.storeOption == INCREMENTAL
			writer = PotreeWriter(workdir, args.quality)
			cloudjs = loadStateFromDisk(writer)
		end
	else
		# new writer
		writer = PotreeWriter(workdir, args.aabb, PWNode(), args.spacing, args.maxDepth, args.scale, args.quality)
		root = PWNode(writer,args.aabb)
		writer.root = root
		cloudjs = CloudJS() # cloud.js - json of metadata
		update!(cloudjs, writer)
	end

	writer.storeSize = args.storeSize

	boundingBoxes = pAABB[]
	numPoints = Int64[]
	sourceFilenames = String[]


	for source in args.sources # Read all sources
		println("READING: $(source)")
		header, pointdata = load(source,mmap=true)
		# open(source) do s
		# FileManager.LasIO.skiplasf(s)
		# header = FileManager.LasIO.read(s, FileManager.LasIO.LasHeader)
		# n = header.records_count
		# pointtype = FileManager.LasIO.pointformat(header)

		push!(boundingBoxes,pAABB([header.x_min,header.y_min,header.z_min],[header.x_max,header.y_max,header.z_max]));
		push!(numPoints,convert(Int,header.records_count));
		push!(sourceFilenames,source)
		# writeSources(writer.workDir, sourceFilenames, numPoints, boundingBoxes)

		# for each point in source
	  	for p in pointdata
			pointsProcessed += 1
			point = Point(p, header)
			add(writer, point)
			if pointsProcessed % 1_000_000  == 0
				processStore(writer)
				# waitUntilProcessed(writer)

				elapsed = time() - start
				print("INDEXING: ")
				print("$pointsProcessed points processed; ")
				print("$(writer.numAccepted) points written; ")
				println("$elapsed second passed")
			end
			if pointsProcessed % args.flushLimit == 0
				print("FLUSHING: ")
				start_ = time()
				flush(writer, cloudjs)
				elapsed = time() - start_
				println("$elapsed s")
			end
		end

	end # all sources read

	flush(writer, cloudjs)
	println("closing writer")

	writeSources(workdir, sourceFilenames, numPoints, boundingBoxes)

	percent = writer.numAccepted / pointsProcessed
	percent = percent * 100
	duration = time() - start
	println("conversion finished")
	println("$pointsProcessed points were processed and $(writer.numAccepted) points ( $percent% ) were written to the output.")
	println("duration: $duration s")
end
