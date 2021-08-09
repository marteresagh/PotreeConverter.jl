using PotreeConverter
using Common
using FileManager
using Detection
using Visualization

potree = raw"C:\Users\marte\Documents\Julia_package\UTILS\potreeoriginale\MURI"
# potree = raw"C:\Users\marte\Documents\potreeDirectory\pointclouds\SCAN_TOTALE_CASALETTO"
leaves = FileManager.get_leaf(potree2trie(potree))
leaf = raw"C:\Users\marte\Documents\Julia_package\UTILS\potreeoriginale\MURI\data\r\r0466.las"
INPUT_PC = FileManager.source2pc(leaf,0)
aabb = FileManager.las2aabb(leaf)
model = getmodel(aabb)
cloudmetadata = CloudMetadata(potree)
# PotreeConverter.expand(potree, PotreeConverter.split_leaf)
aabb = cloudmetadata.boundingBox
centroid = Common.centroid(getmodel(aabb)[1])

cmtree = PotreeConverter.potree2comaptree(potree)
writer = PotreeConverter.PotreeWriter(potree, PotreeConverter.DEFAULT)
cloudjs = PotreeConverter.loadStateFromDisk(writer)

PotreeConverter.processTree(writer, cmtree)
# 
# node = PotreeConverter.findNode(cmtree.root,"r0467")
# node_potree = PotreeConverter.findNode(writer.root,"r0467")
# ref_name = PotreeConverter.name(node)
# node_potree = PotreeConverter.findNode(writer.root, ref_name)
# if !node_potree.isInMemory
#     PotreeConverter.loadFromDisk(node_potree,writer)
# end
#
#
# V,cells = PotreeConverter.nuova_procedura(node,node_potree)


Visualization.VIEW([
        Visualization.points(Common.apply_matrix(Common.t(-centroid...),INPUT_PC.coordinates),INPUT_PC.rgbs),
        Visualization.GLGrid(Common.apply_matrix(Common.t(-centroid...),model[1]),model[2],Visualization.COLORS[7]),
        # Visualization.GLExplode(Common.apply_matrix(Common.t(-centroid...),V),cells,1.,1.,1.,99,1)...,
]);



Visualization.VIEW([
        #GL.GLPoints(points),
        Visualization.GLExplode(Common.apply_matrix(Common.t(-Common.centroid(V)...),V),cells,1.,1.,1.,99,1)...,
        Visualization.points(Common.apply_matrix(Common.t(-Common.centroid(V)...),INPUT_PC.coordinates)),
        #GL.GLGrid(V,EV),
        # Visualization.GLFrame
]);

#
# Visualization.VIEW(Visualization.GLExplode(Common.apply_matrix(Common.t(-Common.centroid(V)...),V),cells,1.1,1.1,1.1,99,1));
# Visualization.VIEW(Visualization.GLExplode(Common.apply_matrix(Common.t(-Common.centroid(V)...),V),EVs,1.5,1.5,1.5,99,1));
# Visualization.VIEW(Visualization.GLExplode(Common.apply_matrix(Common.t(-Common.centroid(V)...),V),CVs,1.5,1.5,1.5,99,0.2));
#
#
# #
# V,EV,FV = PotreeConverter.getmodel(node_potree.aabb)
#
# theplanes = [[291250.163608 291250.163543 291249.163633; 4630335.759859 4630336.759817 4630335.759859; 104.083549 104.074402 104.090671]]
#
# plane = Common.apply_matrix(Common.s(1/0.940050,1/0.940050,1/0.940050)*Common.t(-V[:,1]...),theplanes[1])
# Visualization.VIEW([
#         Visualization.GLGrid(Common.apply_matrix(Common.t(-Common.centroid(V)...),V),EV),
#         Visualization.points(Common.apply_matrix(Common.t(-Common.centroid(V)...),V))
#
# ])
#
