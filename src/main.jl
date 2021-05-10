function main(source,outdir,pageName)
	args = PotreeArguments(source,outdir,pageName; spacing = 0, d = 0, levels = -1, colorRange=Float64[], intensityRange=Float64[], scale = 0)
	println("=== params ===")
	println("source: $(args.source)")
	println("outdir: $(args.outdir)")
	println("pageName: $(args.pageName)")
	println("spacing: $(args.spacing)")
	println("diagonal-fraction: $(args.diagonalFraction)")
	println("levels: $(args.levels)")
	println("scale: $(args.scale)")


	convert(args)
	return 0;
end
