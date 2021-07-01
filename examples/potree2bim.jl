using PotreeConverter
using Common
using FileManager
using Detection
using Visualization

# potree = raw"C:\Users\marte\Documents\Julia_package\UTILS\potreeoriginale\MURI"
# procedura su tutte le foglie
# V,FVs = PotreeConverter.potree2bim(potree; LOD=-1)
#
# Visualization.VIEW([
#     Visualization.points(Common.apply_matrix(traslazione,PC.coordinates),PC.rgbs),
#     Visualization.GLGrid(Common.apply_matrix(traslazione,octree[1]),octree[2],Visualization.COLORS[7]),
#     Visualization.GLExplode(Common.apply_matrix(traslazione,V),FVs,1,1,1,99,1)...
#     ]);

# collection = PotreeConverter.get_nodes(potree; LOD = -1)

node = raw"C:\Users\marte\Documents\Julia_package\UTILS\potreeoriginale\MURI\data\r/r0.las"#collection[1]

hyperplanes = PotreeConverter.plane_identification(node)

#### VIEW
PC = FileManager.las2pointcloud(node)
aabb = FileManager.las2aabb(node)
octree = Common.getmodel(aabb)
aabbs = [aabb for i in 1:length(hyperplanes)]
planes = [Plane(hyperplane.direction,hyperplane.centroid) for hyperplane in hyperplanes]
V_plane,EV_plane,FV_plane = Common.DrawPlanes(planes, aabb)

traslazione = Common.t(-aabb.x_min,-aabb.y_min,-aabb.z_min)

Visualization.VIEW([
    Visualization.points(Common.apply_matrix(traslazione,PC.coordinates),PC.rgbs)
    Visualization.GLGrid(Common.apply_matrix(traslazione,octree[1]),octree[2],Visualization.COLORS[7])
    ])

Visualization.VIEW([
    Visualization.points(Common.apply_matrix(traslazione,PC.coordinates),PC.rgbs)
    Visualization.GLGrid(Common.apply_matrix(traslazione,octree[1]),octree[2],Visualization.COLORS[7])
    Visualization.GLGrid(Common.apply_matrix(traslazione,V_plane),FV_plane, Visualization.COLORS[1],0.5)
    ])
####

# intersezione piani-octree
W, FW, EW = PotreeConverter.myget_intersection(node, hyperplanes)

# W, FW, EW = PotreeConverter.get_intersection(node, hyperplanes)
Visualization.VIEW([
    Visualization.GLGrid(Common.apply_matrix(traslazione,W),EW,Visualization.COLORS[2],0.5)
    Visualization.points(Common.apply_matrix(traslazione,PC.coordinates),PC.rgbs)
    Visualization.GLGrid(Common.apply_matrix(traslazione,octree[1]),octree[2],Visualization.COLORS[7])
    ])

# arrangement
open("modello.txt","w") do s
    write(s,"W = $W\n\n")
    write(s,"FW = $FW\n\n")
    write(s,"EW = $EW\n\n")
end


V, copEV, copFE, copCF = PotreeConverter.arrangement(W, FW, EW)

# costruzione modello
V = permutedims(V)
model = PotreeConverter.pols2tria(V, copEV, copFE, copCF)
V, CVs, FVs, EVs = model
Visualization.VIEW([
    Visualization.points(Common.apply_matrix(traslazione,PC.coordinates),PC.rgbs),
    Visualization.GLExplode( Common.apply_matrix(traslazione,V),FVs,1.1,1.1,1.1,99,0.6)...]);
Visualization.VIEW(Visualization.GLExplode(Common.apply_matrix(traslazione,V),EVs,1.5,1.5,1.5,99,1));
Visualization.VIEW(Visualization.GLExplode(Common.apply_matrix(traslazione,V),CVs,1,1,1,99,0.2));


# pulitura del modello
F, FFs = PotreeConverter.get_cells(model, hyperplanes)

Visualization.VIEW([
    #Visualization.points(Common.apply_matrix(traslazione,PC.coordinates),PC.rgbs),
    Visualization.GLGrid(Common.apply_matrix(traslazione,octree[1]),octree[2],Visualization.COLORS[7]),
    Visualization.GLExplode(Common.apply_matrix(traslazione,F),FFs,1,1,1,99,1)...
    ]);
