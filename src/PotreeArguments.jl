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

const storeSize = 20_000
const flushLimit = 10_000_000

mutable struct PotreeArguments
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
	aabbValues::pAABB
	pageName::String
	conversionQuality::ConversionQuality
	conversionQualityString::String
	material::String

	function PotreeArguments(source,outdir,pageName;aabb=nothing::Union{Nothing,Vector{Float64}}, spacing = 0, d = 0, levels = -1, colorRange=Float64[], intensityRange=Float64[], scale = 0)
		storeOption = ABORT_IF_EXISTS
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

		if isnothing(aabb)
			aabbValues = calculateAABB(source)
		else
			aabbValues = calculateAABB(aabb)
		end

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
				conversionQuality,
				conversionQualityString,
				material
				)
	end

end
