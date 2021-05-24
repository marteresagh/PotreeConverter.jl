"""
user input
"""
function main(sources,outdir,pageName)
	spacing = 0
	d = 0
	levels = -1
	colorRange = Float64[]
	intensityRange = Float64[]
	scale = 0
	aabbValues = Float64[]
	storeOption = OVERWRITE
	outFormat = OutputFormat
	outputAttributes = ["RGB"]
	conversionQuality = DEFAULT
	conversionQualityString = ""
	material = "RGB"

	if d != 0
		spacing = 0
	elseif spacing == 0
		d = 200
	end

	pc = PotreeArguments(outdir,sources)
	pc.spacing = spacing
	pc.diagonalFraction = d
	pc.maxDepth = levels
	pc.colorRange = colorRange
	pc.intensityRange = intensityRange
	pc.scale = scale
	pc.outputFormat = outFormat
	pc.outputAttributes = outputAttributes
	pc.aabbValues = aabbValues
	pc.pageName = pageName
	pc.storeOption = storeOption
	pc.quality = conversionQuality
	pc.material = material

	println("=== params ===")
	for i in 1:length(pc.sources)
		println("source[$i]: $(pc.sources[i])")
	end
	println("outdir: $(pc.workDir)")
	println("pageName: $(pc.pageName)")
	println("spacing: $(pc.spacing)")
	println("diagonal-fraction: $(pc.diagonalFraction)")
	println("levels: $(pc.maxDepth)")
	println("scale: $(pc.scale)")
	println(" ")

	potreeconvert(pc)
end
