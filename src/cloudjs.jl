function save_cloudjs(cloudjs::CloudJS, workdir::String)
    data = DataStructures.OrderedDict()
    data["version"] = cloudjs.version
    data["octreeDir"] = cloudjs.octreeDir
    data["projection"] = cloudjs.projection
    data["points"] = cloudjs.numAccepted
    data["boundingBox"] = DataStructures.OrderedDict()
    data["boundingBox"]["lx"] = cloudjs.boundingBox.min[1]
    data["boundingBox"]["ly"] = cloudjs.boundingBox.min[2]
    data["boundingBox"]["lz"] = cloudjs.boundingBox.min[3]
    data["boundingBox"]["ux"] = cloudjs.boundingBox.max[1]
    data["boundingBox"]["uy"] = cloudjs.boundingBox.max[2]
    data["boundingBox"]["uz"] = cloudjs.boundingBox.max[3]

    data["tightBoundingBox"] = DataStructures.OrderedDict()
    data["tightBoundingBox"]["lx"] = cloudjs.tightBoundingBox.min[1]
    data["tightBoundingBox"]["ly"] = cloudjs.tightBoundingBox.min[2]
    data["tightBoundingBox"]["lz"] = cloudjs.tightBoundingBox.min[3]
    data["tightBoundingBox"]["ux"] = cloudjs.tightBoundingBox.max[1]
    data["tightBoundingBox"]["uy"] = cloudjs.tightBoundingBox.max[2]
    data["tightBoundingBox"]["uz"] = cloudjs.tightBoundingBox.max[3]

    data["pointAttributes"] = cloudjs.pointAttributes
    data["spacing"] = cloudjs.spacing
    data["scale"] = cloudjs.scale
    data["hierarchyStepSize"] = cloudjs.hierarchyStepSize

    open(joinpath(workdir,"cloud.js"),"w") do f
        FileManager.JSON.print(f, data, 4)
    end
end


function update!(cloudjs::CloudJS, potreeWriter::PotreeWriter)
    cloudjs.version = "1.7"
    cloudjs.octreeDir = "data"
    cloudjs.boundingBox = potreeWriter.aabb
    cloudjs.tightBoundingBox = potreeWriter.tightAABB
    cloudjs.outputFormat = potreeWriter.outputFormat
    cloudjs.pointAttributes = potreeWriter.pointAttributes
    cloudjs.spacing = potreeWriter.spacing
    cloudjs.scale = potreeWriter.scale
    cloudjs.hierarchyStepSize = potreeWriter.hierarchyStepSize
    cloudjs.numAccepted = potreeWriter.numAccepted
    cloudjs.projection = ""
end
