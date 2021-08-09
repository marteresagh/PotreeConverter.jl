using PotreeConverter
using Common
using FileManager
using Detection
using Visualization

# potree = raw"D:\potreeDirectory\pointclouds\CASALETTO_TERRY_CONCLUSO_DECIMATO"
potree = raw"C:\Users\marte\Documents\Julia_package\UTILS\potreeoriginale\MURI"

INPUT_PC = FileManager.source2pc(potree,0)
cloudmetadata = CloudMetadata(potree)
# PotreeConverter.expand(potree, PotreeConverter.split_leaf)
aabb = cloudmetadata.boundingBox
centroid = Common.centroid(getmodel(aabb)[1])

cmtree = PotreeConverter.potree2comaptree(potree)

PotreeConverter.cut_tree!(cmtree, 2)

# function print_name(node)
#     println(PotreeConverter.name(node))
# end
# PotreeConverter.postorder(cmtree.root, print_name)

writer = PotreeConverter.PotreeWriter(potree, PotreeConverter.DEFAULT)
cloudjs = PotreeConverter.loadStateFromDisk(writer)

PotreeConverter.processTree(writer, cmtree)
