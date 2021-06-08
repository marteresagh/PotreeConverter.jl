using Common
dir1 = [0.893679; 0.448692; -0.003746]
cen1 = [291252.748397;4630336.890479;105.354979]
d1 = Common.dot(dir1,cen1)
plane1 = [dir1...,d1]
dir2 = -[ 0.891640; 0.452742; 0.001727]
cen2 = [291252.742216; 4630336.895044; 104.645304]
d2 = Common.dot(dir2,cen2)
plane2 = [dir2...,d2]
Common.angle_between_directions(dir1,dir2)*180/pi

V = hcat(dir1,dir2,[0,0,0.])

EV = [[3,1],[3,2]]

Visualization.VIEW([
     Visualization.GLGrid(V,EV)
     Visualization.points(V)
])

function dist(x,y)
    return min(Common.norm(x-y),Common.norm(x+y))
end

dist(plane1,plane2)
