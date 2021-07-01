module PotreeConverter

    using Common
    using FileManager
    using Printf
    using Detection
    using Detection.Search.NearestNeighbors
    using FileManager.LasIO
    using LasIO.FileIO
    using SparseArrays
    using Triangulate
    using OrderedCollections
    using IntervalTrees

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
    include("Potree/struct.jl")
    include("Potree/stuff.jl")
    include("Potree/PotreeWriter.jl")
    include("Potree/PotreeArguments.jl")
    include("Potree/AABB.jl")
    include("Potree/SparseGrid.jl")
    include("Potree/GridCell.jl")
    include("Potree/PWNode.jl")
    include("Potree/Point.jl")
    include("Potree/lasIO.jl")
    include("Potree/cloudjs.jl")
    include("Potree/convert.jl")
    include("Potree/main.jl")

    # COMAPTREE
    include("Comaptree/struct.jl")
    include("Comaptree/expand.jl")
    include("Comaptree/CWNode.jl")
    include("Comaptree/potree2bim.jl")
    include("Comaptree/util.jl")

    # COMAPTREE
    include("LAR/arrangement.jl")
    include("LAR/util.jl")
    include("LAR/boundary.jl")
    include("LAR/planar_arrangement.jl")
    include("LAR/refactoring.jl")
    include("LAR/minimal_cycles.jl")
    include("LAR/tgw3d.jl")
end # module
