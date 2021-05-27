module PotreeConverter

    using Common
    using FileManager
    using Printf
    using Detection
    
    macro format(ex)
       quote
           Base.show(io::IO, x::Float64) = write(io, @sprintf($ex, x))
       end
    end
    @format "%f"
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

    # POTREE CONVERTER
    include("struct.jl")
    include("stuff.jl")
    include("PotreeWriter.jl")
    include("PotreeArguments.jl")
    include("AABB.jl")
    include("SparseGrid.jl")
    include("GridCell.jl")
    include("PWNode.jl")
    include("Point.jl")
    include("lasIO.jl")
    include("cloudjs.jl")
    include("convert.jl")
    include("main.jl")

    # COMAPTREE
    include("Comaptree/struct.jl")
    include("Comaptree/expand.jl")
    include("Comaptree/CWNode.jl")
    include("Comaptree/comaptree.jl")

end # module
