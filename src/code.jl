# PER ORA SOLO LAS
# enum class OutputFormat{
# 	BINARY,
# 	LAS,
# 	LAZ
# };
const OutputFormat = "LAS"
# enum class StoreOption{
# 	ABORT_IF_EXISTS,
# 	OVERWRITE,
# 	INCREMENTAL
# };
@enum StoreOption ABORT_IF_EXISTS=1 OVERWRITE=2 INCREMENTAL=3
# enum class ConversionQuality{
# 	FAST,
# 	DEFAULT,
# 	NICE
# };
@enum ConversionQuality FAST=1 DEFAULT=2 NICE=3

struct PotreeArguments
	storeOption::StoreOption
	source::String # per ora un singolo file
	outdir::String
	spacing::Float64
	levels::Int64
	scale::Float64
	diagonalFraction::Int64
	outFormat::String
	colorRange::Vector{Float64}
	intensityRange::Vector{Float64}
	outputAttributes::Vector{String}
	aabbValues::Common.AABB
	pageName::String
	sourceListingOnly::Bool
	conversionQuality::ConversionQuality
	conversionQualityString::String
	material::String

	function PotreeArguments(source,outdir,pageName; spacing = 0, d = 0, levels = -1, colorRange=Float64[], intensityRange=Float64[], scale = 0)
		storeOption = ABORT_IF_EXISTS
		outFormat = OutputFormat
		outputAttributes = ["RGB"]
		sourceListingOnly = false
		conversionQuality = DEFAULT
		conversionQualityString = ""
		material = "RGB"

		if d != 0
			spacing = 0
		elseif spacing == 0
			d = 200
		end

		aabbValues = calculateAABB(source)
		return new(
				storeOption,
				source,
				outdir,
				spacing,
				levels,
				scale,
				d,
				outFormat,
				colorRange,
				intensityRange,
				outputAttributes,
				aabbValues,
				pageName,
				projection,
				sourceListingOnly,
				conversionQuality,
				conversionQualityString,
				material
				)
	end

end

function calculateAABB(source)::AABB
	aabb = FileManager.las2aabb(source)
	return aabb
end


function main(source,outdir,pageName)
	args = PotreeArguments(source,outdir,pageName; spacing = 0, d = 0, levels = -1, colorRange=Float64[], intensityRange=Float64[], scale = 0)
	println("=== params ===")
	println("source: $(args.source)")
	println("outdir: $(args.outdir)")
	println("pageName: $(args.pageName)")
	println("spacing: $(args.spacing)")
	println("diagonal: $(args.diagonalFraction)")
	println("levels: $(args.levels)")
	println("scale: $(args.scale)")

	#convert(args)
	return 0;
end
