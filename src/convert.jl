function writeSources(path::String, sourceFilenames::Vector{String}, numPoints::Vector{Int64}, boundingBoxes::Vector{pAABB})
	#scrive il json source.js
end

function convert(args::PotreeArguments)

    pointsProcessed = 0

    println("AABB: ")
    println(args.aabbValues)

    PotreeConverter.makeCubic(args.aabbValues)
    println("cubic AABB: ")
    println(args.aabbValues)

    if args.diagonalFraction != 0
		args.spacing = Common.norm(args.aabbValues.size) / args.diagonalFraction
		println("spacing calculated from diagonal: $(args.spacing)")
	end

	workdir = FileManager.mkdir_project(args.outdir, args.pageName)
	if isfile(joinpath(workdir,"cloud.js"))
		if args.storeOption == ABORT_IF_EXISTS
			return 0
		end
	else
		# writer();#TODO
	end

	boundingBoxes = pAABB[]
	numPoints=Int64[]
	sourceFilenames=String[]

	# // for source in sources PER ORA UNA SINGOLA SOURCE
	println("READING: $(args.source)")

	# reader of LAS file
	open(args.source) do s
		FileManager.LasIO.skiplasf(s)
		header = FileManager.LasIO.read(s, FileManager.LasIO.LasHeader)

		n = header.records_count
		pointtype = FileManager.LasIO.pointformat(header)
		pointdata = Vector{pointtype}(undef, n)
		for i=1:n
			pointdata[i] = FileManager.LasIO.read(s, pointtype)
		end
		@show pointdata
	end
	# header,lasPoints = FileManager.LasIO.load(source)

	# push!(boundingBoxes,pAABB([header.x_min,header.y_min,header.z_min],[header.x_max,header.y_max,header.z_max]));
	# push!(numPoints,convert(Int,header.records_count));
	# push!(sourceFilenames,source)
	#
	# for lasPoint in lasPoints
	# 	pointsProcessed += 1
	# 	p = FileManager.xyz(lasPoint,header)
	# 	# writer.add(p) #TODO
	# 	if pointsProcessed % 1_000_000  == 0
	# 		writer->processStore();
	# 		writer->waitUntilProcessed();
	#
	# 		print("INDEXING: ")
	# 		print("$pointsProcessed points processed;")
	# 		print("$(writer.numAccepted) points written; ")
	# 	end
	# 	if pointsProcessed % flushLimit == 0
	# 		println("FLUSHING: ")
	# 		# writer->flush() #TODO
	# 	end
	# end
	# #close file las
	# # // end
	#
	# println("closing writer")
	# writer->flush();
	# writer->close();
	#
	# # writeSources() #TODO
	#
	# percent = writer.numAccepted / pointsProcessed
	# percent = percent * 100
	# println("conversion finished")
	# println("$pointsProcessed points were processed and $(writer.numAccepted) points ( $percent% ) were written to the output.")

end
