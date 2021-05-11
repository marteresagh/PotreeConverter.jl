module PotreeConverter

    using Common
    using FileManager

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

    const cellSizeFactor = 5.0
##### APPUNTI
# PotreeWriter globale???
####
    include("struct.jl")
    include("stuff.jl")
    include("AABB.jl")
    include("PWNode.jl")
    include("convert.jl")
    include("main.jl")
    # include("PotreeArguments.jl")
    # include("PotreeWriter.jl")
end # module
