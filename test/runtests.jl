using Test
using PotreeConverter
using Visualization

aabb = PotreeConverter.pAABB([0.,0.,0.],[10.,10.,10.])

p0 = [1.,1,1.]
p1 = [1.,1.,6.]
p2 = [1.,6,1.]
p3 = [1.,6.,6.]
p4 = [6.,1.,1.]
p5 = [6.,1,6.]
p6 = [6.,6.,1.]
p7 = [6.,6.,6.]

for p in [p0,p1,p2,p3,p4,p5,p6,p7]
    index = PotreeConverter.nodeIndex(aabb, p)
    @show index
end
