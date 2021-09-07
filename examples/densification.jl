using Common
using FileManager
using Detection
using PotreeConverter
using Visualization

folder_project = raw"C:\Users\marte\Documents\Julia_package\UTILS\potreeoriginale"
potree = raw"C:\Users\marte\Documents\Julia_package\UTILS\potreeoriginale\MURI"
dense_path = FileManager.mkdir_project(folder_project,"DENSE")

PotreeConverter.densify_leaves(folder_project, potree, 3)

# INPUT_PC = FileManager.source2pc(potree,6)
# cloudmetadata = CloudMetadata(potree)
# # PotreeConverter.expand(potree, PotreeConverter.split_leaf)
# aabb = cloudmetadata.boundingBox
# centroid = Common.centroid(getmodel(aabb)[1])
# Visualization.VIEW([Visualization.points(Common.apply_matrix(Common.t(-centroid...),INPUT_PC.coordinates),INPUT_PC.rgbs)])
