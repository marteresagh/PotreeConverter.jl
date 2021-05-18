using PotreeConverter
using FileManager
source = "D:/pointclouds/cava.las"

data = DataStructures.OrderedDict()
data["version"] = "1.7"
data["octreeDir"] = "data"
data["projection"] = ""
data["points"] = 8779619

AABB=PotreeConverter.pAABB([0,0,0.],[45.453456786545463636564564,11,12.])
data["boundingBox"] = DataStructures.OrderedDict()
data["boundingBox"]["lx"] = AABB.min[1]
data["boundingBox"]["ly"] = AABB.min[2]
data["boundingBox"]["lz"] = AABB.min[3]
data["boundingBox"]["ux"] = AABB.max[1]
data["boundingBox"]["uy"] = AABB.max[2]
data["boundingBox"]["uz"] = AABB.max[3]


data["tightBoundingBox"] = DataStructures.OrderedDict()
data["tightBoundingBox"]["lx"] = AABB.min[1]
data["tightBoundingBox"]["ly"] = AABB.min[2]
data["tightBoundingBox"]["lz"] = AABB.min[3]
data["tightBoundingBox"]["ux"] = AABB.max[1]
data["tightBoundingBox"]["uy"] = AABB.max[2]
data["tightBoundingBox"]["uz"] = AABB.max[3]


data["pointAttributes"] = "LAS"
data["spacing"] = 33432523
data["scale"] = 0.001
data["hierarchyStepSize"] = 5
open("cloud.json","w") do f
    FileManager.JSON.print(f, data, 4)
end
