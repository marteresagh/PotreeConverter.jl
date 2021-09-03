using Common
using Detection
using PotreeConverter
using Visualization

function average_orientation(normals)
    M = sum([normals[:,i]*normals[:,i]' for i in 1:size(normals,2)])
    EIG = Common.eigen(M)

    orientation = EIG.vectors[:,3]
    return Common.normalize(orientation)
end



n_v = 100
vects = [Common.normalize((-1)^rand(2:2)*rand(3)) for i in 1:n_v-1]
vectors = hcat([0.;0;0],hcat(vects...))
EV = [[1,i] for i in 2:n_v]

centroid = Common.centroid(hcat(vects...))

orientation = average_orientation(hcat(vects...))
vect_direction = hcat([0.;0;0],-Common.normalize(orientation))
EV_1 = [[1,2]]

vect_direction_2 = hcat([0.;0;0],centroid)
EV_2 = [[1,2]]


Visualization.VIEW([Visualization.GLGrid(vectors,EV),Visualization.GLGrid(vect_direction,EV_1,Visualization.COLORS[12]),Visualization.GLGrid(vect_direction_2,EV_2,Visualization.COLORS[10]), Visualization.axis_helper()...])
