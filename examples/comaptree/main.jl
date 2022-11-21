using PotreeConverter
using Common
using FileManager
using Detection
using Visualization

potree = raw"D:\potreeDirectory\pointclouds\MURI"
# potree = raw"C:\Users\marte\Documents\potreeDirectory\pointclouds\SCAN_TOTALE_CASALETTO"
leaves = FileManager.get_leaf(potree2trie(potree))
cloudmetadata = CloudMetadata(potree)
aabb = cloudmetadata.boundingBox
centroid = Common.centroid(getmodel(aabb)[1])

# Dal potree al comaptree
cmtree = PotreeConverter.potree2comaptree(potree)

# load writer
# writer = PotreeConverter.PotreeWriter(potree, PotreeConverter.DEFAULT)
# cloudjs = PotreeConverter.loadStateFromDisk(writer)
# PotreeConverter.processTree(writer, cmtree) # elaborazione dei nodi da sistemare
