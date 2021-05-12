function PotreeArguments(workDir::String, source::String)
    aabb = pAABB([Inf,Inf,Inf],[-Inf,-Inf,-Inf])
    pointAttributes = ""
    spacing = 0.
    maxDepth = -1
    outputFormat = OutputFormat
    outputAttributes = ["RGB"]
    colorRange = Float64[]
    intensityRange = Float64[]
    scale = 0.01
    diagonalFraction = 250
    aabbValues = Float64[]
    pageName = ""
    storeOption = ABORT_IF_EXISTS
    quality = DEFAULT
    material = "RGB"
    storeSize = 20_000
    flushLimit = 10_000_000
    return PotreeArguments(aabb,
            source,
            workDir,
            pointAttributes,
            spacing,
            maxDepth,
            outputFormat,
            outputAttributes,
            colorRange,
            intensityRange,
            scale,
            diagonalFraction,
            aabbValues,
            pageName,
            storeOption,
            quality,
            material,
            storeSize,
            flushLimit
            )
end
